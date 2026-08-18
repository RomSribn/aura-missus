# AURAT-0027 — 004 context

Date: 2026-08-17

Sources checked, and the findings that actually change the build. Ground truth
is the code under `slave-1/master`; the brain is the authority on policy.

## The money path already has the right shape

`PrismaWalletsRepository.credit()` is `$transaction` + `SELECT … FOR UPDATE` on
the wallet row + append entry + update the cached balance, with `P2002` mapped
to `DuplicateLedgerEntryError` so the caller converges on the winner of a race.
`AURAD-0004`'s pattern, already proven by `AURAT-0007` and reused by the session
debit. **The Play credit reuses this shape; it does not invent one.**

`LedgerEntry` is append-only by code discipline (the repository exposes no
update/delete), signed amounts, `@@unique([walletId, idempotencyKey])`.

## Finding 1 — the existing unique constraint cannot be the token's

`@@unique([walletId, idempotencyKey])` is scoped **per wallet**. `AURAD-0010`
requires "one token = one ledger entry", which is a **global** statement: the
same token presented against a second wallet must not credit twice. The
per-wallet key cannot express that.

## Finding 2 — the token cannot live on `ledger_entries` either

The obvious shortcut — `purchaseToken String? @unique` on `ledger_entries` —
**breaks refunds** (`AURAF-0010-006`): a refund is a *second* ledger entry for
the *same* token (`AURAD-0010`, "a refund is a compensating negative entry"),
so a unique column on the ledger row would reject the very entry the decision
requires. It also puts a rail-specific column on the table that StoreKit and a
PSP would each want their own of.

So the token gets its **own table**, which is also where Google's facts belong
(product, order id, the account id we matched) rather than on a money row.

## Finding 3 — `purchaseAccountId` should come from the database, not the app

Requirements: opaque, stable, per-wallet, ≤64 chars, no PII, and unguessable —
the whole point is that the app cannot derive somebody else's.

`gen_random_uuid()` as a column default gives all of that with no code: 36
chars, crypto-random, unique by constraint, no write on the read path, and the
`ALTER TABLE … ADD COLUMN … DEFAULT gen_random_uuid()` rewrite fills every
existing wallet with its **own** value (a volatile default is evaluated per
row). Minting it in the service would mean a write during `GET /v1/wallet` and
a race to lose.

Deliberately **not** the wallet's `id`: a primary key is an internal handle,
and a cuid encodes a timestamp and a counter — opaque enough to log, not
opaque enough to hand to Google and to the device.

## Finding 4 — the house style for an external API is hand-rolled, not an SDK

`ChatwootClient` is `fetch` + a 10s timeout + hand-typed wire shapes, sealed in
its module (build rule 1). A Play client follows it. `google-auth-library`
**10.9.0 is already in the tree** (transitively, via `firebase-admin`), so the
service-account JWT → access-token exchange costs no new install — only an
explicit dependency line, which is the honest way to depend on it.

Migrations are hand-written SQL with the reasoning in comments
(`20260814140000_interval_occupancy` is the model), which is what `TECH-DEBT #7`
needs anyway.

## Finding 5 — the contract, taken from the package rather than from prose

`AURAT-0026-005-spec.md` describes `GooglePlayTopUpRequest` as
`{purchaseToken, productId, packageName}` and the `obfuscatedAccountId` as a
client-side hash. **Both were changed during implementation** (its
`007-execute.md`, decisions 1 and 2) and `AURAD-0010` was amended to match. The
shapes below are read out of the installed v0.7.0 package
(`dist/index.js` + `dist/index.d.ts`), which is the only copy that cannot be
stale:

```ts
WalletResponse          { balanceMinor: int, currency: 'USD',
                          purchaseAccountId?: string.min(1).max(64) }
GooglePlayTopUpRequest  { purchaseToken: string.min(1), productId: string.min(1) }
GooglePlayTopUpResponse { entryId: string, balanceMinor: int, currency: 'USD',
                          creditedMinor: int.nonneg, replayed: boolean }
```

`src/contracts/` is a hand-kept mirror (**TECH-DEBT #11**) — the BFF does not
install the package — so these get mirrored here and pinned by a spec file, the
way `message.spec.ts` and `session.spec.ts` already pin theirs.

## Finding 6 — what is gated, and on what

| Gate | Owner step | Blocks |
|---|---|---|
| Play service account JSON | `AURAS-0002` **step 7** | the real `purchases.products.get` call |
| RTDN Pub/Sub topic | `AURAS-0002` **step 8** | the refund subscriber (`AURAF-0010-006`) |
| Products published | `AURAS-0002` step 5 | any real purchase at all |

Nothing on that list blocks the endpoint, the tier table, the token constraint
or `purchaseAccountId`.

## Finding 7 — the tier table is policy, so it is a constant

`AURAS-0002` step 5 and the app's `features/store-topup/config/products.ts`
both carry `aura.topup.usd10 / usd25 / usd50 / usd100` → `1000 / 2500 / 5000 /
10000` minor units. The two copies are deliberate (`001-initial.md` §4): the
app's drives four cards, ours is the money.

It is **not** env config, following the precedent already written into
`env.schema.ts`: the mechanics of the slot grid are config, the policy numbers
of `AURAD-0009` are constants in the module, "because making them
per-environment invites staging and production to disagree about what a refund
is". A per-environment credit amount is the same mistake with money in it.

## Contradictions found

One, resolved above: `AURAT-0026-005-spec.md` vs the shipped package
(finding 5). The package wins — it is what the app compiles against.

## Next

`005-spec`.
