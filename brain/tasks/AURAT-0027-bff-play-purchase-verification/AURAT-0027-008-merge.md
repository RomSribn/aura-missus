# AURAT-0027 — 008 merge

Date: 2026-08-18

Owner reviewed the diff in the IDE and approved ("проверил, всё ок — коммить и
мёржить"). Merge confirmed explicitly in the same turn before `wts-finish` ran.

## What happened

| | |
|---|---|
| Feature branch | `feature/AURAT-0027-bff-play-purchase-verification` |
| Commit | `a9ba336` — 28 files, +1660 / −22 |
| Manor `develop` after merge | **`445a3f6`** (`Merge feature/AURAT-0027-…`) |
| Push | `eda5339..445a3f6 develop -> develop` — clean, no warnings |
| Manor missus | "Already up to date" — **correct**, docs are still uncommitted |
| Idle slaves | 2–5 refreshed to the new master |

Slave-1 stays on the feature branch for post-merge step files, as the lifecycle
expects. Authorship checked before the merge: author and committer are
`RomSribn <steeper.fest@gmail.com>`, and the body carries no trailer and no
mention of a code assistant.

## What the manor can verify, and what it cannot

The BFF stack has never run this code, and the parts that need a database are
exactly the parts a slave could not touch.

**Run first — `npx prisma migrate deploy`.** The whole migration is new
territory:

1. **The backfill that isn't one.** After `ADD COLUMN … DEFAULT
   gen_random_uuid()`, check that pre-existing wallets got **distinct** ids:

   ```sql
   SELECT count(*), count(DISTINCT "purchaseAccountId") FROM wallets;
   ```

   The two numbers must be equal. If they are not, the default was evaluated
   once instead of per row and every wallet shares one store account id — which
   would let any user redeem any other user's purchase. This is the single most
   important line in the migration.

2. **The append-only trigger** (`TECH-DEBT #7`, now paid):

   ```sql
   UPDATE ledger_entries SET "amountMinor" = 1 WHERE id = (SELECT id FROM ledger_entries LIMIT 1);
   DELETE FROM ledger_entries WHERE id = (SELECT id FROM ledger_entries LIMIT 1);
   ```

   Both must **raise**. If either succeeds, `balance = Σ ledger` is no longer
   enforced by anything but discipline.

3. **The rail end to end, on dev tokens.** With `BILLING_ENABLED=true` and no
   `GOOGLE_PLAY_*` set, take `purchaseAccountId` from `GET /v1/wallet` and drive
   every path through `POST /v1/wallet/top-ups/google`:

   | `purchaseToken` | Expected |
   |---|---|
   | `dev:<your id>:purchased` | **200**, balance +2500 for `aura.topup.usd25` |
   | the same token again | **200**, `replayed: true`, balance **unchanged** |
   | `dev:<someone else's id>:purchased` | **403** |
   | `dev:<your id>:pending` | **409** |
   | `dev:<your id>:purchased:aura.topup.usd10` | **409** (product mismatch) |
   | a real-looking Play token | **409** — the dev verifier must refuse it |
   | `productId: aura.topup.usd9999` | **400** |

   And the one that matters most: the replay must leave `ledger_entries`
   with **one** row for that token, and `play_purchases` with one.

**Cannot be verified in the manor either**, and this is the honest limit:
nothing above touches Google. `AURAS-0002` step 7 is the owner's, and until it
is done `GooglePlayVerifier` remains code that has never had a conversation with
the API it is written against (`TECH-DEBT #17`).

## Next

Owner verification in the manor → `009-approved` or `009-fix-*`. Missus is still
uncommitted; it gets one commit at task close, before `wts-release`.
