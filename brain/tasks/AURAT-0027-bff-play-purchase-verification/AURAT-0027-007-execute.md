# AURAT-0027 — 007 execute

Date: 2026-08-17
Branch: `feature/AURAT-0027-bff-play-purchase-verification` (off `develop`
`eda5339`). **Staged, not committed** — awaiting the IDE review.

Gates: `npx tsc --noEmit` clean · `npx eslint "src/**/*.ts"` clean ·
`npx jest` **32 suites / 394 tests**, of which **51 are the four new suites**
(`play-tiers`, `play-top-up.service`, `fake-play.verifier`,
`google-play.verifier`) — the rest of the growth is in `wallet.spec.ts`,
`env.schema.spec.ts` and `wallet.service.spec.ts` · `nest build` clean ·
`prisma validate` clean.

---

## 1. `purchaseAccountId` — the thing that switches the rail on

`GET /v1/wallet` now answers with it, so the app stops treating the store rail
as unconfigured.

It is a column on `wallets`, defaulted by Postgres:

```prisma
purchaseAccountId String @unique @default(dbgenerated("gen_random_uuid()")) @db.Uuid
```

The migration's `ADD COLUMN … DEFAULT gen_random_uuid()` gives **every existing
wallet its own value** — the default is volatile, so Postgres rewrites the table
and evaluates it per row. That is the whole backfill. If it were evaluated once,
every wallet would share one id and any user could redeem any other user's
purchase; the migration says so next to the line, because it is the kind of
thing that reads as a detail right up until it isn't.

Not the wallet's `id`: a primary key is an internal handle, and a cuid encodes a
timestamp and a counter.

## 2. `POST /v1/wallet/top-ups/google`

`PlayTopUpService` — thin controller, business logic in the service, Google
behind an adapter. Refusals, in the order they are checked:

| Condition | Answer |
|---|---|
| SKU not in our tier table | **400**, before the DB is touched at all |
| Google knows no such purchase | **409** |
| state is `PENDING` / `CANCELLED` | **409** |
| Google names a different product | **409** |
| `obfuscatedExternalAccountId` ≠ this wallet's | **403** |
| token already redeemed, by us | **200**, `replayed: true` |
| token already redeemed, by someone else | **409** |

**Deviation from `005-spec.md`, worth flagging:** the spec said 404 for an
unverifiable purchase. It ships as 409. A 404 on this route is
indistinguishable from the `BillingEnabledGuard`'s 404 — the whole wallet
surface answers 404 when billing is off — so the app could not tell "we do not
know this purchase" from "the wallet does not exist here". Same for a token
redeemed by another account.

### The tier table

`play-tiers.ts`, a frozen module constant: `usd10/25/50/100 → 1000/2500/5000/
10000`. Not env config, following `env.schema.ts`'s own precedent that policy
numbers are constants "because making them per-environment invites staging and
production to disagree". Lookup goes through `creditForProduct`, which uses
`hasOwnProperty` — a plain record index answers `toString` and `__proto__`, and
those are pinned as no-credit cases.

### Idempotency

New table `play_purchases`, `purchaseToken` unique, written **inside** the same
locked credit transaction (`SELECT … FOR UPDATE` on the wallet → ledger entry →
purchase row → balance). A duplicate rolls the ledger entry back with it, which
is why it is one repository call and not `credit()` plus an insert.

Two findings drove that table rather than a column on `ledger_entries`:

- the existing `@@unique([walletId, idempotencyKey])` is **per wallet**, and
  `AURAD-0010`'s "one token = one entry" is a global statement;
- a `purchaseToken @unique` column on `ledger_entries` would **reject the refund
  row** — a refund is a second entry for the same token — so it would have made
  `AURAF-0010-006` unimplementable.

The ledger row's own key is `play:<sha256(token)>`: server-derived so it can
never collide with a client uuid from the stub rail, hashed so an unbounded Play
token never lands in a btree index.

**A replay belongs to its owner.** `replay()` refuses when the stored purchase's
`walletId` is not the caller's — returning it would hand user B user A's entry
id, credit and balance. The account check should already have stopped that; this
is the second lock. `creditedMinor` comes from the stored row too, so a token
first redeemed as usd25 and re-claimed as usd10 answers 2500 and mints nothing.

## 3. Google, sealed in `src/modules/play/`

`PlayPurchaseVerifier` is the port; nothing outside the module sees Google's
dialect (build rule 1). Which implementation answers is decided once at boot by
whether the three `GOOGLE_PLAY_*` vars are set.

**`GooglePlayVerifier`** — hand-rolled `fetch` in the `ChatwootClient` mould
(one endpoint, one auth flow, same 10s timeout), service-account JWT via
`google-auth-library` (added explicitly; it was already in the tree at 10.9.x
under `firebase-admin`). It has never spoken to Google, so it is built to fail
in the safe direction: the response is parsed by a strict Zod schema and
**anything unexpected returns "no purchase" rather than crediting**; an unknown
`purchaseState` has no mapping at all. 404/410 are the ordinary "we don't know
this token". Errors never quote Google's body — it can echo the token back, and
a purchase token has no business in our logs.

**`FakePlayVerifier`** — and the reason it is safe to ship at all. A fake that
approves what it is handed *is* the app crediting its own balance, so:

1. **boot refuses it** — `env.schema.ts` makes the three vars mandatory when
   `NODE_ENV=production` **and** `BILLING_ENABLED=true`. Scoped to the flag
   because production has shipped with billing off since v1;
2. **it refuses itself** in production, unit-tested directly;
3. **it does not rubber-stamp a real purchase.** It answers only
   `dev:<purchaseAccountId>:<state>[:<productId>]` and returns "not found" for
   anything else, a genuine Play token included. A BFF with no service account
   truly cannot verify a purchase, and refusing costs nobody money: the app
   leaves it un-consumed and Google auto-refunds after three days.

The account check stays honest in dev, because the dev token has to carry the
caller's own id — so every refusal path is drivable by hand in the manor.

## 4. `TECH-DEBT #7`, paid

Trigger `ledger_entries_append_only` raises on `BEFORE UPDATE OR DELETE`. A
trigger rather than `REVOKE`: privileges do not bind the table owner, which is
the role the app and a hand-run `psql` usually connect as.

---

## Files

**New** — `src/modules/play/{play-purchase.port,google-play.verifier,
fake-play.verifier,play.module}.ts` + 2 specs; `src/modules/wallet/{play-tiers,
play-top-up.service}.ts` + 2 specs;
`prisma/migrations/20260817120000_play_purchases/migration.sql`.

**Changed** — `prisma/schema.prisma`; `src/config/env.schema.ts` (+spec);
`src/contracts/{wallet.ts,wallet.spec.ts,openapi.ts}`;
`src/modules/wallet/{wallet.controller,wallet.module,wallet.service,
wallets.repository,prisma-wallets.repository}.ts` (+`wallet.service.spec.ts`);
`package.json` / `package-lock.json`; `.env.example`; `README.md`;
`TECH-DEBT.md`.

**Missus** — `AURAF-0010` scope table, `AURAS-0002` step-7 update, this task
folder.

## Decisions taken during implementation

1. **409, not 404, for an unverifiable purchase** — see above; 404 is already
   taken by the billing flag.
2. **`play_purchases` as its own table** rather than a column on
   `ledger_entries`, because the column shape cannot express a refund.
3. **The dev verifier refuses real tokens.** The alternative — echoing the
   caller's account id so any purchase passes in dev — is the money-minting
   configuration wearing a dev label.
4. **`AURAF-0010-003`'s `BE` corrected `✗ → —`.** Google's localized price is
   `fetchProducts` against Play; there was never server work pending there.
5. **`google-auth-library` promoted to an explicit dependency.** It was already
   resolvable through `firebase-admin`, and depending on a transitive package is
   how a minor bump elsewhere becomes an outage here.

## Open / not done

- **The verifier has never spoken to Google** (`AURAS-0002` step 7). Logged as
  **`TECH-DEBT #17`** with the specific thing to check on the first real
  purchase: that `obfuscatedExternalAccountId` actually comes back, since the
  entire account guarantee rests on it.
- **Refunds (`AURAF-0010-006`) deliberately not built** — needs the Pub/Sub
  topic from `AURAS-0002` step 8; without a trigger it would be dead code. The
  schema accommodates it; needs an ID minted in `aura-app-manor`.
- **Nothing here ran against a database.** The migration, the trigger and the
  per-row `gen_random_uuid()` backfill are manor-only.

## Next

Staged in both repos, uncommitted (skill step 6f). `008-*` after the owner's
read.
