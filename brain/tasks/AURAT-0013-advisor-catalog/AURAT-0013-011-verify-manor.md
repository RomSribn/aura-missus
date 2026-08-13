# AURAT-0013-011 — Manor verification: all six checks from step 008

Date: 2026-08-13
Ran from: manor, `develop` @ `b0ee16a`, full stack via `docker compose up -d --build`
Result: **all six pass.** Three environment defects found on the way, one of which
would have stopped the service from booting.

## Blocker found before check 1 — the service could not have started

The manor `.env` (assembled 2026-08-05) was missing `ADVISOR_ASSETS_BASE_URL`,
which this task added as **required** (`z.string().url()`, no default). Boot
validation fails fast, so the stack would not have come up at all. Diffed the key
sets of `.env` against `.env.example` and found five missing keys; only this one
is required — `TYPING_TTL_SECONDS`, `PRESENCE_POLL_SECONDS`,
`CHATWOOT_SERVICE_AGENT_ID`, `CHATWOOT_WEBHOOK_SECRET_SECONDARY` all carry
`.default()` or `.optional()`.

Added it to the manor `.env` (backup: `.env.bak-before-0013`). **This generalises:
any environment moving to this commit must add the variable first**, or the deploy
fails on boot rather than degrading. Worth stating in the release note for staging
and prod.

## 1. `prisma migrate deploy` on a populated DB — ✓

The DB was genuinely populated first (7 conversations, 54 messages, 5 sessions,
2 users), so this was not a fresh-database run. `20260813120000_advisor_catalog`
applied cleanly during container start; `_prisma_migrations` shows it finished.
Table widened with all twelve columns, `advisors_active_sortOrder_idx` created,
`advisors` left at 0 rows by the deliberate `DELETE FROM "advisors"`.

## 2. `prisma db seed` — ✓, but the path needed two fixes to run at all

This is the step that had never once been executed, and it failed twice before
passing:

1. **`TSError: 'specialties' does not exist in type AdvisorCreateInput`.** The
   generated Prisma client in `src/generated/prisma` was stale — the merge changed
   the schema and nothing regenerated it. `npx prisma generate` fixed it. A fresh
   checkout runs `prisma generate` via `postinstall`, so this bites the
   *upgrade-in-place* case: pulling this commit into an existing working copy
   requires a regenerate before the seed will compile.
2. **`P1010 DatabaseAccessDenied`.** The documented `npm run prisma:seed` from the
   host hit **a different Postgres**: a local one (PID 3898) binds `127.0.0.1:5432`
   and `[::1]:5432` and shadows the container's published port, which Docker binds
   as `*:5432`. `role "aura" does not exist` there. Ran the seed against the host's
   LAN address instead (`192.168.31.55:5432`), which reaches Docker's listener and
   not the local server. Nothing was written to the wrong database — the failure
   was at connect.

With those cleared: **`seeded 8 advisors`**. Re-ran it — still 8, no error, which
is the upsert-by-slug idempotency the seed claims. Rows carry the right categories
(no `DREAMS`), prices 220–380, ratings 46–49, `sortOrder` 10…80.

## 3. Live `GET /v1/advisors` through Firebase auth — ✓

Minted an ID token for uid `manor-verify-0013` with `secrets/mint-id-token.cjs`.
The Web API key is not in the manor `.env`; rather than block, fetched it from the
Firebase Management API with the existing service account.

- Without a token → **401**. With one → **200**, eight advisors.
- Order is `sortOrder`: olivia, sunshine, veronica, may, labsang, alisher, marta, ivan.
- Body keys are exactly the wire DTO. **`avatarKey`, `sortOrder` and `active` are
  absent** — the explicit projection in `toRecord` holds, storage detail does not
  reach the client.

## 4. `avatarUrl` resolves — ✓

Checked twice, and the second one is the one that counts: first by composing from
DB keys, then by taking the `avatarUrl` values **out of the live response** and
requesting them. All eight return `200` with content types matching their
extensions (`.png` → `image/png`, `.jpeg` → `image/jpeg`). The bucket contents and
the seed's keys agree.

## 5. Booking after the repository moved modules — ✓ (with one substitution)

`BILLING_ENABLED=true` was already set in the manor `.env`, and `NODE_ENV` is
`development`, so the stub top-up was available.

- `GET /advisors/olivia/sessions/pricing` → `320`/min with all four blocks — the
  price came through `AdvisorsModule` after the move.
- `GET /advisors/mia/sessions/pricing` → **404**. `mia` is retired and has no
  catalog row, so it is not bookable: AURAT-0008 D1 ("no row = not bookable")
  still holds after the table was rewritten.
- Top-up 10000 → booking olivia ×10 min → **201**, `costMinor 3200` at
  `priceMinorPerMinute 320`, balance 10000 → 6800.
- Replaying the same `idempotencyKey` returned the *same* session and did **not**
  debit again.
- Ledger: `TOPUP +10000`, `SESSION_CHARGE -3200`, and `balance == Σ ledger` — the
  invariant holds.
- Finishing early kept the balance at 6800 (`ENDED_EARLY`) — non-refundable.

**The substitution, stated plainly:** a booking cannot reach Chatwoot here, so the
first attempt returned **500** from `ProvisioningService.ensureChatwootIdentity`
(`fetch failed` — `CHATWOOT_BASE_URL=http://localhost:3001` is not running, and
from inside the container `localhost` is the container itself, so a host-side
Chatwoot would be unreachable regardless). Since `ensureConversation` short-circuits
on an existing map row, I inserted one fixture conversation to bypass provisioning
and booked through it. This does not weaken the check: `requireAdvisor` resolves
the price *before* `ensureConversation` runs, so the moved repository was exercised
either way — and the 404 on `mia` proves resolution is live, not cached. What
remains unverified is Chatwoot-side provisioning and the session activity markers,
neither of which this task changed.

## 6. Retired-advisor cleanup SQL — ✓

Ran step 007's script verbatim, in a transaction: **52 messages, 5 sessions,
6 conversations** deleted.

**One row it does not cover:** a conversation on advisor `advisoor-test-1` (note
the typo — an old manual test row, 2 messages) survives, because it is not in the
retirement list. It now references an advisor with no catalog row, i.e. an orphan.
Harmless on dev and deliberately left alone — deleting rows beyond the approved
script is not mine to decide — but flagged so it is not mistaken for real data.

Fixture cleanup: my own test conversation and session rows were removed afterwards.
The `manor-verify-0013` user, wallet and its two ledger entries were **left in
place** — the ledger is append-only by rule, and hand-deleting money rows to tidy a
test is exactly what that rule forbids.

## State after the run

`advisors` = 8, `conversations` = 1 (the orphan), `sessions` = 0. The stack is
still up. Nothing in `src/` was changed by this verification — the only edit was
the manor `.env`, which is not in the repo.

## Next

Task-close bookkeeping: `NNN-approved.md`, the single missus commit, then
`wts-release slave-1`, then `active-work.md`. Open follow-up worth its own task —
TECH-DEBT #11: with contracts v0.4.0 the advisor shape now exists in two places
and `AdvisorId` already differs between them.
