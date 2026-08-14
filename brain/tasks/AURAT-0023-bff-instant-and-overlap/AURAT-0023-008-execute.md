# AURAT-0023-008 — Execute

Date: 2026-08-14
Slave: `slave-2`, branch `feature/AURAT-0023-bff-instant-and-overlap`
(from `develop` @ `44418b2`, missus from `master` @ `de296d9`)

## Verification (slave-legal only)

`323/323 jest`, `eslint` clean, `tsc --noEmit` clean, `nest build` clean,
`prettier` clean on every file this task touched. No stack was started — the
transactional and constraint behaviour is manor work (§Manor list below).

## Master — code

**Contracts (`src/contracts/`)** — the v0.6.0 mirror, shape per `007-contract`:

- `session.ts` — `bookSessionRequestSchema` gains `startNow`, makes `startsAt`
  optional and refines to **exactly one of the two**; `availabilityQuerySchema`
  gains optional `minutes`; `availabilityResponseSchema` gains
  `instantAvailable`. `sessionSlotSchema.available` now means "a block of
  `minutes` fits here".
- `openapi.ts` — the same three, plus the 400/409 descriptions that changed.
- `session.spec.ts` — pins raised to v0.6.0: the instant form accepted, both
  refused, neither refused (a forgotten field must not read as "now"), `minutes`
  coerced and optional, `instantAvailable` required. **29 tests.**

**Grid (`slot-grid.ts`)** — `markAvailability` stops taking a set of taken slot
starts and a step, and takes the advisor's **busy intervals** and the **booked
duration**. New exported primitive `fitsInterval` — one definition of "free",
used by the day grid and by the instant answer, so the two cannot disagree.

**Repository (`sessions.repository.ts`, `prisma-sessions.repository.ts`)**

- `listBookedSlots → listAdvisorBusyWindows` (intervals, overlap predicate).
- `hasCommittedSession → hasSpentFirstSessionCredit` (`creditMinor > 0`) — D4.
- `book` gains `startNow`: creates the row **`ACTIVE`** with `startedAt` in the
  same transaction as the debit; equality slot check → overlap check; **new**
  caller-overlap check under the caller's own wallet lock → `UserBusyError`
  (409). Without it an instant booking made while a session runs would have hit
  `sessions_one_active_per_conversation` as a raw P2002 and been reported as an
  idempotency conflict.
- `reschedule` / `convergeBookRace` — same equality → overlap change.
- `extend` — "the next booking starts before my new end" became a plain overlap
  against the widened window, which also catches a session that began *before*
  this one and runs long. Wrapped so a constraint violation maps to the same
  409 the check gives.
- `activate` — now takes the advisor lock and **clamps** the recomputed `endsAt`
  to the advisor's next live session. The recompute exists so a late sweep does
  not shorten a paid block; under intervals it can no longer eat minutes that
  belong to the next client (and the constraint would have rejected the
  transition outright). A block that starts late against a back-to-back
  neighbour is short by exactly the lateness.
- `isOverlapViolation` — maps Postgres `23P01` to the domain errors. Prisma has
  no code for it, so it matches the constraint name / SQLSTATE (recorded as
  **TECH-DEBT #16**).

**Service (`sessions.service.ts`)**

- `getAvailability` — resolves `minutes` (query, else the shortest block),
  validates it like booking's, reads both sides as intervals, and answers
  `instantAvailable` from the same two reads. `gridWindow`'s far end reaches one
  *block* past the last slot (a later session can still overlap it) and its near
  end never starts after `now`.
- `book` — branches on `startNow`: the start is the **server's** clock, exempt
  from grid alignment and the lead time, and the response is a running session.
- Two new privates, both extractions rather than new behaviour: `afterActivated`
  (arm the run-down, announce "started", push — used by the meter's transition
  *and* the instant booking) and `closeSpentSession` (release the
  one-ACTIVE-per-conversation slot held by a block whose finish job has not
  landed).
- `UserBusyError → 409`.

**Config (`env.schema.ts`)** — the boot cross-check refusing a block longer than
the step is gone with the invariant it protected; both knobs' comments now say
what they actually govern (grid spacing; how soon a *scheduled* slot may be
picked).

**Migration (`20260814140000_interval_occupancy`)** — repairs any live window
that a late activation pushed past the next booking, drops
`sessions_one_live_per_advisor_slot`, and adds
`sessions_no_overlap_per_advisor` (`EXCLUDE USING gist`, needs `btree_gist`).
`prisma/schema.prisma` records where the guard lives, since Prisma can model
neither exclusion constraints nor partial indexes.

## Master — tests (the bulk, as the spec said)

- `slot-grid.spec.ts` **26** — the five equality cases rewritten as intervals,
  plus a whole `fitsInterval` suite: a gap that fits ten and not thirty,
  back-to-back in both directions, one minute of overlap on either boundary, a
  booking that straddles a taken one, a session that began before the window,
  the caller's own window.
- `sessions.service.spec.ts` **71** — availability answering differently per
  duration, the shortest-block default, an unknown duration refused, and
  `instantAvailable` across four cases (both free / advisor busy / caller busy /
  lead time closing the grid but not the instant path). A new `book — startNow`
  suite: the server's clock, exemption from grid+lead, the run-down armed and
  "started" announced with **no** `activate` job, the spent session closed
  first, a replay that announces nothing, and blocks still validated. Plus
  `UserBusyError → 409` and a request carrying neither start form.
- `env.schema.spec.ts` **17** — the boot-refusal test became its opposite: a
  45-minute block on a 30-minute step is now an ordinary configuration.

## Docs

`README.md` (the endpoint prose, the interval model, and a **deploy note** on
`btree_gist`), `TECH-DEBT.md` (**#16**), `AURAD-0009` §Progress (the v0.6.0 shape
and the credit change, for the app manor), `AURAF-0008` (BE column on rows
006/007/011 and a line saying which task shipped what).

## Known and deliberate

1. **Until `AURAT-0024` ships, the app sends no `minutes`**, so availability
   answers for the shortest block — in the manor's `.env` that is **1 minute**,
   which is close to "everything is free". Booking still refuses what does not
   fit (409), so this over-offers rather than mis-sells. It disappears the
   moment the app sends the duration.
2. **`btree_gist` is the one thing that can fail at migrate time**, not at test
   time. If an environment cannot install it, drop the constraint, not the lock.
3. A session that starts late against a back-to-back neighbour is now **short**
   by the lateness, where before it silently overlapped. That is the honest
   reading of O2, and it is visible in `endsAt`.

## Manor verification list (after merge)

1. Migration on the populated manor DB: `btree_gist` installs, the repair UPDATE
   touches what it should, the constraint is created.
2. Instant booking at `minutes=1`: 201 `ACTIVE`, started divider in the live
   thread, `session.updated` on the socket, self-finishing a minute later.
3. Two clients into the same gap — one 201, one 409.
4. Back-to-back (`[14:00,14:10)` then `[14:10,14:20)`) — both accepted; a
   straddling booking refused; `extend` into the next booking still 409.
5. Instant booking while the caller is already in a session → 409, not 500.
6. `balance == Σ ledger` after the run, and `AURAT-0018`'s 25 checks unbroken.
7. The credit is spent once: book free → cancel → the next booking is **not**
   free.

Next: user review in the IDE, then the merge gate.
