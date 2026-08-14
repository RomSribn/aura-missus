# AURAT-0018-004 — Context

Date: 2026-08-14

## Sources checked

| Source | Trust | What it gave |
|---|---|---|
| `AURAD-0009` | high (ratified) | The whole scope; wallet-not-card; refund tiers; 4h reschedule; −$5 credit; instant booking retired |
| `AURAD-0002` | high | Survives for a *running* block: prepaid, non-refundable once started |
| `AURAD-0003` / `AURAD-0001` | high | Session lives in the one durable thread; the chatter is never surfaced |
| `AURAD-0004` / `AURAD-0007` | high | Money path = `$transaction` + `SELECT … FOR UPDATE` on the wallet row; Prisma migrations own the schema |
| `AURAF-0008` | high but **stale** | Scope rows 006–012 still marked parked under `AURAD-0008` |
| `AURAT-0021-001-check` | high | The missing sessions-list read, and *why* the tab's two segments were meaningless under the instant model |
| `AURAT-0015-005-spec` | high | The app deliberately has no `'scheduled'` state yet; divider copy stays the server's |
| `@aura/contracts` v0.5.0 (`aura-contracts` @ `0c1b9ac`, tagged) | **binding** | The exact wire shape — see `002-check.md` |
| `aura-bff` source @ `b0ee16a` | **ground truth** | Below |

## Ground truth in the code

Confirmed by reading, not by docs:

- `prisma/schema.prisma` — `enum SessionStatus { ACTIVE, FINISHED }`; `model Session`
  has `startedAt` (non-null) / `endsAt`, **no `startsAt`**, no `advisorId` (it hangs
  off `conversation`), no cancellation or refund columns.
- `prisma/migrations/20260711130000_sessions/migration.sql` — the one-active guard is
  a **hand-written partial unique index**
  `sessions_one_active_per_conversation … WHERE "status" = 'ACTIVE'`. It survives
  a `SCHEDULED` world unchanged (it only constrains `ACTIVE`), so several future
  slots plus one running session already coexist under it. What it does *not* give
  is any guard against two users taking the same advisor slot — there is nothing
  advisor-scoped in the schema to hang one on.
- `enum LedgerEntryType { TOPUP, SESSION_CHARGE }` — **no credit direction**.
  `PrismaWalletsRepository.credit()` exists but **hardcodes `type: 'TOPUP'`**, so it
  is the top-up path, not a reusable refund primitive.
- `PrismaSessionsRepository.book()/extend()` are the pattern to copy: one
  `$transaction`, `lockWallet()` via `$queryRaw … FOR UPDATE`, replay check, balance
  check, ledger append, cached-balance update, session write — plus a
  `convergeBookRace()` fallback on `P2002`.
- `SessionsService` creates the session `ACTIVE` at `now`, schedules the delayed
  `finish` job from `endsAt`, and posts the `started` marker immediately.
- `getPricing(advisorId)` takes **no user** — with a per-user `creditMinor` in
  v0.5.0 it must.
- `sessions.controller.ts` — the five routes named in the brief, all behind
  `BillingEnabledGuard`. No list / reschedule / cancel / availability.
- `ChatwootMessagingPort.syncSessionState` mirrors `status: 'active' | 'none'` +
  `endsAt` + `paidMinutesTotal` into `custom_attributes` — there is no `scheduled`
  value for the chatter desk today.
- `jobs/queues.ts` — one `sessions` queue, jobs `finish` / `sweep` / `announce` /
  `sync`, `attempts: 5`; the meter sweep is a 60s repeatable backstop
  (`SessionsScheduler`).
- `delivery.service.pushSessionUpdate` — WS-only `session.updated`, already the
  right vehicle for the meter's own `SCHEDULED → ACTIVE` push.
- `env.schema.ts` — `BILLING_ENABLED` (default false, routes 404 when off) and
  `SESSION_BLOCK_MINUTES` (CSV, default `10,20,30`). **No scheduling config exists**:
  no timezone, no opening hours, no lead time, no horizon.
- `src/contracts/session.ts` — the local hand-copy, still the `AURAT-0008` shape
  (`ACTIVE|FINISHED`, `costMinor` positive, no `startsAt`).

## Contradictions / stale material found

1. **`AURAF-0008` still says rows 006–012 are parked** under `AURAD-0008`. Superseded
   by `AURAD-0009` — the feature file must be corrected as part of this task.
2. **`AURAT-0008`'s contract says `costMinor` is positive**; v0.5.0 widens it to
   nonnegative for a fully-credited block. The BFF copy must follow the package.
3. **TECH-DEBT #11 (contracts copy) is directly in the blast radius**: v0.5.0 is a
   *breaking* shape change and the BFF mirrors it by hand. Anything mistyped here
   fails silently at the app's `safeParse`.
4. **TECH-DEBT #7 (DB-level append-only on `ledger_entries`) gets sharper**: adding a
   credit direction means a bug or a bad hand-fix can now *create* money, not just
   destroy it. Still code-discipline-only.

## The gap the specs do not fill

`AURAD-0009` says availability "becomes a real read" and the contract fixes its
*shape* — but **nothing anywhere defines what makes a slot bookable**: there is no
schedule, no working hours, no timezone and no advisor-capacity notion in the
system, and Chatwoot's agent availability is live presence (`AURAT-0009`), not a
calendar. That, plus whether a taken slot is taken for *everyone*, is the one thing
this task cannot derive from existing decisions — it goes to the owner before the
spec.

## Next

Two owner questions, then step 005 — spec.
