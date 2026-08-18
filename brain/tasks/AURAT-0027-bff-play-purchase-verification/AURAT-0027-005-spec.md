# AURAT-0027 — 005 spec

Date: 2026-08-17
Kind: **task** (BFF). The feature is `AURAF-0010`, already written; the spec is
`AURAD-0010`, already ratified. Nothing new to mint.

Rows this closes: `AURAF-0010-001..005` BE ✗ → ✓. Row **006** (refunds) — see
decision **D6**.

---

## Part 1 — `purchaseAccountId`, because nothing else can be exercised without it

`GET /v1/wallet` gains it. Requirements from `AURAD-0010`: opaque, stable,
per-wallet, ≤64 chars, no PII, and **not derivable by the app** — "an app that
can derive its own can derive somebody else's".

**It comes from the database, not from code.** A new column on `wallets`:

```prisma
purchaseAccountId String @unique @default(dbgenerated("gen_random_uuid()")) @db.Uuid
```

36 chars, crypto-random, unique by constraint, no write on a read path, no race
to lose. The `ALTER TABLE … ADD COLUMN … DEFAULT gen_random_uuid()` rewrite
gives **every existing wallet its own value** — a volatile default is evaluated
per row — so there is no backfill script and no nullable window. Postgres 16
(`docker-compose.yml`), where `gen_random_uuid()` is built in.

Deliberately **not** the wallet's `id`: a primary key is an internal handle, and
a cuid encodes a timestamp and a counter. Opaque enough to log, not opaque
enough to hand to Google and to a device.

Served whenever the wallet is served — the route is already behind
`BILLING_ENABLED`. It is never logged.

## Part 2 — `POST /v1/wallet/top-ups/google`

Body `GooglePlayTopUpRequest {purchaseToken, productId}` — **no amount, no
package name**. Caller from the Firebase ID token like every other route.

Credits only when **all** of `AURAD-0010`'s four conditions hold:

| Condition | Failure |
|---|---|
| `productId` is in the BFF's own tier table | **400** |
| Google returns a purchase for our package + this token | **404** |
| `purchaseState` is *purchased* | **409** |
| Google's `productId` matches the claim | **409** |
| Google's `obfuscatedExternalAccountId` == the caller's `purchaseAccountId` | **403** |
| the token has not been redeemed before | **200 + `replayed: true`** |

The credit amount is read from the tier table keyed by the SKU — **never from
the request**, which is why the contract has no amount field at all. Every
refusal leaves the purchase un-consumed on the device, which is the benign
failure `AURAD-0010` designed for: Google auto-refunds anything unacknowledged
after three days.

### The tier table

```ts
aura.topup.usd10 → 1000   aura.topup.usd25 → 2500
aura.topup.usd50 → 5000   aura.topup.usd100 → 10000
```

A **module constant, not env config**, following the precedent already written
into `env.schema.ts`: grid mechanics are config, `AURAD-0009`'s policy numbers
are constants, "because making them per-environment invites staging and
production to disagree about what a refund is". A per-environment credit amount
is that mistake with money in it. The second copy in the app
(`features/store-topup/config/products.ts`) is deliberate (`001-initial.md` §4).

### Idempotency — a constraint, not a check

`AURAD-0010` requires **one token = one ledger entry**, which is a *global*
statement. The existing `@@unique([walletId, idempotencyKey])` is per-wallet and
cannot express it, and a `purchaseToken @unique` column on `ledger_entries`
**breaks refunds** — a refund is a *second* entry for the *same* token.

So a new table owns the token:

```prisma
model PlayPurchase {
  id            String @id @default(cuid())
  purchaseToken String @unique          // ← the idempotency guarantee
  productId     String
  walletId      String
  ledgerEntryId String @unique
  creditedMinor Int
  orderId       String?
  createdAt     DateTime @default(now())
  @@map("play_purchases")
}
```

Written **inside the existing credit transaction** (`SELECT … FOR UPDATE` on the
wallet row → append entry → insert purchase → update balance), so a lost race
aborts the whole thing and converges on the winner exactly as `topUp()` already
does. The ledger row's own `idempotencyKey` is server-derived —
`play:<sha256(token)>` — bounded regardless of how long Play tokens get, and
never a client-chosen value.

**A replay belongs to its owner.** On a token already redeemed, the original
entry comes back with `replayed: true` — but only to the wallet that owns it. A
token presented by a *different* wallet is **409**, never a replay: returning
one would hand user B user A's entry id and balance. The account-id check should
already have refused it; this is the second lock.

## Part 3 — the verifier, and the reason a fake one is dangerous

Google is sealed behind an adapter (build rule 1), exactly as Chatwoot is. New
module `src/modules/play/`: a `PlayPurchaseVerifier` port returning our own
`VerifiedPurchase` shape, and two implementations selected by config.

**A fake verifier that approves what it is handed *is* "the app credits its own
balance".** That is the one unrecoverable mistake in `AURAD-0010`, so it is
closed twice:

1. **Boot refuses it.** `NODE_ENV=production` **and** `BILLING_ENABLED=true` ⇒
   the three `GOOGLE_PLAY_*` vars are **required** (env-schema refinement, build
   rule 3 — fail fast). Production therefore always has the real verifier.
2. **The fake refuses itself** in production, unit-tested directly.

And the fake **does not rubber-stamp real purchases**. It answers only tokens in
a documented dev shape — `dev:<purchaseAccountId>:<state>[:<productId>]` — and
returns *not found* for anything else. So a BFF with no service account refuses
a genuine Play purchase, which is the correct answer: it genuinely cannot verify
it, and refusing loses nobody's money. The account check stays real in dev
because the dev token has to carry the caller's own id.

## Part 4 — `TECH-DEBT #7`, taken here

`ledger_entries` is append-only by code discipline only. This is the first rail
where an **outside party** can reverse an entry, which is what `001-initial.md`
and the debt register both flag. A `BEFORE UPDATE OR DELETE` trigger that raises
— portable, and unlike `REVOKE` it also binds the table owner.

Hand-written SQL migration, in the house style of
`20260814140000_interval_occupancy`. **It cannot be run here** (no DB in a
slave); it runs in the manor.

---

## Decisions for you

**D1 — the real Google client: build it now, or a follow-up task?**
You said to build behind a fake "rather than waiting". Read strictly that is
the fake only — and then the rail provably cannot work until another task,
because a credential-less BFF refuses real purchases by design (Part 3).

*Recommendation: build it now.* It is a hand-rolled `fetch` client in the
`ChatwootClient` mould — service-account JWT via `google-auth-library` (already
in the tree at 10.9.0 under `firebase-admin`; it gets an explicit dependency
line), then `GET …/applications/{pkg}/purchases/products/{sku}/tokens/{token}`.
Google's response is parsed **strictly with Zod and refused on anything
unexpected**, so the unverifiable-until-`AURAS-0002`-step-7 risk points at
"refuses a good purchase" and never at "credits a bad one". Unit-tested against
a mocked fetch; proven against Google only in the manor, after step 7.

**D2 — refunds (`AURAF-0010-006`) now or later?**
*Recommendation: later.* The RTDN subscriber needs the Pub/Sub topic from
`AURAS-0002` **step 8**, which does not exist, and unlike the verifier it has no
reachable trigger at all — it would be dead code, which build rule 8 forbids.
The schema above already accommodates it (a refund is a new negative ledger
entry; `play_purchases` links them) so it lands as one migration plus a
processor. Row 006 stays ✗ and I will note the follow-up in `AURAF-0010`.

**D3 — `TECH-DEBT #7` in this task?** *Recommendation: yes* (Part 4). Say no and
it stays in the register.

---

## What I will not touch

- The stub `POST /v1/wallet/top-ups` and its production 503 (`AURAT-0007`).
  The store rail is a **second** endpoint, per `AURAF-0010`'s context note.
- Consuming the purchase — Play-side, the app's, deliberately after our 200.
- iOS / StoreKit; subscriptions; chatter payouts.

## Files

**New** — `src/modules/play/{play.module.ts, play-purchase.port.ts,
google-play.verifier.ts(+spec), fake-play.verifier.ts(+spec)}`;
`src/modules/wallet/play-top-up.service.ts(+spec)`; one migration.

**Changed** — `prisma/schema.prisma`; `src/config/env.schema.ts`;
`src/contracts/{wallet.ts, wallet.spec.ts, openapi.ts}`;
`src/modules/wallet/{wallet.controller.ts, wallet.service.ts,
wallets.repository.ts, prisma-wallets.repository.ts, wallet.module.ts,
wallet.service.spec.ts}`; `TECH-DEBT.md`; `README.md`; `AURAF-0010`.

## Gates

`npx tsc --noEmit`, `npx eslint "src/**/*.ts"`, `npx jest` — all in the slave.
`prisma migrate deploy`, the trigger, and anything touching Google are
**manor-only**, and the real Google call is manor-only *and* gated on
`AURAS-0002` step 7.

## Honest limits

No purchase can be verified against Google until the service account exists.
What the tests will prove is the tier table, the refusal paths, the token
constraint, the replay-to-owner rule and the production lockout — the parts
that mint money when wrong.

## Next

`006-approval`.
