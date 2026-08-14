# AURAT-0018-007 — Execute

Date: 2026-08-14
Branch: `feature/AURAT-0018-bff-scheduled-sessions` off develop `b0ee16a`
Gates: **lint ✓ · typecheck ✓ · build ✓ · jest 294/294 ✓** (was 274 — 20 new)
Committed: **no** — awaiting IDE review

## What landed

### Schema + migrations (2 files, deliberately)

`prisma/schema.prisma`: `SessionStatus` gains `SCHEDULED` (now the default) and
`CANCELLED`; `LedgerEntryType` gains `SESSION_REFUND`. `Session` gains
`advisorId` (denormalized, no FK — same reasoning as `conversations.advisorId`),
`startsAt`, `creditMinor`, `cancelledAt`, `refundedMinor`, and `startedAt` becomes
**nullable**.

Two migrations, because Postgres refuses to *use* an enum value added in the same
transaction and Prisma wraps each file in one:

1. `20260814120000_scheduled_sessions_enums` — enum values only.
2. `20260814120100_scheduled_sessions` — columns, backfill
   (`startsAt := startedAt`, `advisorId` from the conversation join — old rows were
   instant blocks, so their start *is* their slot), then indexes:
   `sessions_status_startsAt_idx`, `sessions_advisorId_startsAt_idx`, and the
   hand-written partial unique **`sessions_one_live_per_advisor_slot`**
   (`(advisorId, startsAt) WHERE status IN ('SCHEDULED','ACTIVE')`) — the DB-level
   answer to owner decision O2.

### The lock that actually enforces O2

`book` / `extend` / `reschedule` now take `SELECT … FROM advisors … FOR UPDATE`
**before** the wallet lock. Two clients racing for one slot hold two different
wallets, so the existing wallet lock could never serialize them; the advisor row
can, and does. Same order everywhere, so the paths cannot deadlock. The unique
index stays as the guarantee that outlives a bug in the lock.

### The credit direction

`cancel` runs the debit's transactional shape in reverse: wallet `FOR UPDATE` →
conditional `SCHEDULED → CANCELLED` → append a **positive** `SESSION_REFUND` →
update the cached balance. Nothing is ever `UPDATE`d in the ledger. Idempotency has
two layers — the conditional transition, and the server-derived key
`session-refund:{sessionId}` on the ledger's unique index. A zero refund writes no
entry; a `P2002` converges on the committed state instead of paying twice.

### First-session credit — a discount, not money

`costMinor = max(0, subtotal − 500)`, one `SESSION_CHARGE` for the discounted
amount, `creditMinor` stored on the row as the audit trail. Eligibility (no session
in `SCHEDULED`/`ACTIVE`/`FINISHED`) is decided **inside** the booking transaction,
so two simultaneous first bookings cannot both claim it. A fully-credited block
writes **no** ledger row at all — the ledger records movements, and nothing moved.

The alternative (a real ledger credit) was rejected in the spec and the reason is
in the code: it would let book → cancel → refund mint $5 of withdrawable balance
per cycle.

### Availability

New pure module `slot-grid.ts` (+ `session-policy.ts` for the money/timing rules).
24/7 grid, instants anchored to **UTC** midnight, days labelled in a timezone —
`SESSION_SLOT_TIMEZONE`, overridable per request with `?tz=`. A slot is offerable
only if it is past the lead time, not taken **by anyone** with that advisor, and not
overlapping a session the caller already has with *any* advisor.

Day bucketing scans ±2 days around the window and files each instant under the day
its own formatted label says, which is how the DST cases come out right without any
midnight arithmetic — the 25-hour Madrid day genuinely returns 50 half-hour slots,
and there is a test that says so.

### Endpoints

`GET advisors/:id/sessions/availability` (new), `GET sessions` (new),
`PATCH sessions/:id` (new), `POST sessions/:id/cancel` (new); `pricing` is now
per-user with the `subtotalMinor`/`creditMinor`/`costMinor` breakdown; `book` takes
`startsAt` — **which is where instant booking dies**; `extend` refuses to run past
the advisor's next booking; `finish` and `active` unchanged. All still behind
`BillingEnabledGuard`.

### The meter starts sessions by itself

New `activate` job (delayed to `startsAt`, job id carries the slot so a reschedule's
job never dedupes against the stale one) plus the same 60s sweep, which now finishes
spent blocks **first** and then activates due ones — that order is what keeps
back-to-back slots from colliding on `sessions_one_active_per_conversation`.
Activation recomputes `endsAt` from the meter's own `startedAt`, so a late sweep
never shortens a paid block.

### Contract

`src/contracts/session.ts` mirrors `@aura/contracts` **v0.5.0** by hand
(TECH-DEBT #11); `contracts/session.spec.ts` grew from 2 to 18 assertions pinning
every field, because that spec file is the only thing between a mistyped mirror and
a silent `safeParse` failure in the app.

### Chatwoot mirror

`ConversationSessionState` gains `'scheduled'` + `startsAt` →
`aura_session_starts_at`. Booking, rescheduling and cancelling post **no** marker —
the transcript's dividers stay the real boundaries of a session (`AURAT-0015`) — so
the attributes are the only thing the desk sees ahead of time. `syncState` now
derives from the *conversation* (running → upcoming → none), not from whichever
session triggered the job, so a cancelled booking cannot report "none" while another
slot waits.

## Decisions taken during implementation

1. **One booking occupies exactly one slot**, enforced at boot: every
   `SESSION_BLOCK_MINUTES` value must be ≤ `SESSION_SLOT_STEP_MINUTES`. That one
   invariant is what lets availability ignore duration and lets a plain partial
   unique index be the double-book guard instead of a `btree_gist` exclusion
   constraint. A longer block is not a tuning mistake, it is an unsound grid.
2. **Policy numbers are constants, not env** (`session-policy.ts`): 24h/half refund,
   4h reschedule cutoff, $5 credit. Grid mechanics are deployment config; ratified
   product policy is not, or staging and production could disagree about what a
   cancellation is worth.
3. **Cancel is refused once `startsAt` has passed**, not just once the status is
   `ACTIVE` — a slot whose moment arrived is about to be flipped by the meter, and
   "before it starts" should mean the clock, not the worker's luck.
4. **Half-refunds floor** (`Math.floor`), so a refund can never exceed what was paid
   and the odd cent lands somewhere deterministic.
5. **`sumBookedMinutes` now excludes `CANCELLED`** — counting them would tell the
   chatter desk about minutes nobody ever spent.
6. **`GET /v1/sessions` is capped at 100** (v0.5.0 has no cursor) → TECH-DEBT #14
   rather than a silent truncation.
7. **`ActiveSessionExistsError` was deleted.** Booking a future slot while a session
   runs is legitimate now, so nothing could throw it — and an unreachable error path
   is dead code (build rule 8).

## Files

**Created (6):** `prisma/migrations/20260814120000_scheduled_sessions_enums/`,
`prisma/migrations/20260814120100_scheduled_sessions/`,
`src/modules/sessions/{slot-grid,slot-grid.spec,session-policy,session-policy.spec}.ts`

**Modified (21):** `prisma/schema.prisma` · `src/config/env.schema{,.spec}.ts` ·
`src/contracts/{session,session.spec,openapi}.ts` ·
`src/jobs/{queues,sessions.processor}.ts` ·
`src/modules/sessions/{sessions.service,sessions.service.spec,sessions.repository,prisma-sessions.repository,sessions.controller}.ts` ·
`src/modules/chatwoot/{chatwoot-messaging.port,chatwoot-messaging.service,chatwoot-messaging.service.spec}.ts` ·
`src/modules/wallet/{wallets.repository,prisma-wallets.repository}.ts` ·
`README.md` · `TECH-DEBT.md` · `.env.example`

**Missus:** `AURAF-0008` — status, the superseded-split section, BE column ✓ for rows
006–011, contracts bumped to v0.5.0, open questions 1–4 moved to resolved. Note: row
011's BE was marked `—`; it is the row this whole task implements, so it is now `✓`
and the correction is called out in the table.

## Known gaps / for the manor

- **Nothing transactional is proven here.** Locks, races, the `balance == Σ ledger`
  invariant and both migrations need a real Postgres — `011` in the spec lists the
  six checks.
- **Activation latency edge:** recomputing `endsAt` from a late `startedAt` can
  overrun the next slot by the sweep's own lag (seconds). Bounded, and preferable to
  charging for minutes not delivered — but it is a real, deliberate overrun.
- **The `tz` param is BFF-only** (TECH-DEBT #15). Until `AURAT-0016` sends it, a user
  far east or west sees days grouped by `SESSION_SLOT_TIMEZONE`. **Worth one message
  to the app manor.**
- **Deploy note:** the four new `SESSION_SLOT_*` / `SESSION_BOOKING_*` vars all have
  defaults, so nothing new is *required* at boot — but the block-vs-step cross-check
  will refuse to start an environment whose `SESSION_BLOCK_MINUTES` exceeds the step.

## Next

Review in the IDE (step 6f), then the merge gate.
