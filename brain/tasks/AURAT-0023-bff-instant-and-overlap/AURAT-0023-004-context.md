# AURAT-0023-004 — Context

Date: 2026-08-14

## Sources

| Source | Trust | What it gave |
|---|---|---|
| `AURAT-0023-001-initial.md` | high (owner-approved spec) | the change, the four traps, the app-side coupling |
| `AURAD-0009` §"Amended again" | high (ratified) | the same, plus the `EXCLUDE USING gist` belt and the naming of the lead-time trap |
| `AURAT-0024-001-initial.md` | high | the app is blocked on the shape, not on the code |
| manor's live check of `AURAT-0018` (14 Aug) | **ground truth** | lead=0 does not work; the free-booking cycle |
| `src/modules/sessions/**`, `src/config/env.schema.ts`, `prisma/` | **ground truth** | everything below |

## The blast radius is small and exact

Interval occupancy touches **seven** places, and nothing outside the sessions
module reads any of them:

- `slot-grid.ts` — `markAvailability` takes `advisorTakenMs: Set<number>` (epoch
  equality) and a `stepMinutes` span. Both go; the span becomes the *booked
  duration* and the advisor side becomes intervals. `alignsToGrid`,
  `buildSlotGrid`, `zonedDayKeys`, `zonedDateKey` are untouched.
- `sessions.repository.ts` — `listBookedSlots(advisorId, from, to): Date[]`
  becomes a busy-window read. It has exactly **one** caller
  (`getAvailability`), and `BusyWindow` already exists for the user side.
- `prisma-sessions.repository.ts` — three equality checks:
  `book` (`startsAt: input.startsAt`), `reschedule` (same), `convergeBookRace`
  (same); plus `extend`'s "next booking" read, which is already a half-interval
  check and becomes a plain overlap.
- `sessions.service.ts` — `requireBookableSlot` (alignment + lead + horizon),
  `gridWindow` (its `to` must widen from one step to the booked duration), and
  `book`'s post-commit fan-out.
- `env.schema.ts` — the `superRefine` cross-check, which exists only to keep one
  booking inside one cell.
- `prisma/migrations/…_scheduled_sessions/migration.sql` — the partial unique
  index `sessions_one_live_per_advisor_slot`.
- The tests: `slot-grid.spec.ts` §`markAvailability` (5 cases against equality)
  and `sessions.service.spec.ts` §`book` / §`getAvailability`.

## Facts that change the design

1. **The lead-time trap is worse than the spec's wording.** `requireBookableSlot`
   compares the slot to the *server's* clock at processing time; at `lead = 0`
   the condition degenerates to `slot < now`, so a client-sent `startsAt = now`
   is already in the past by the time it lands. Verified live in the manor. The
   instant path needs an **exemption**, and "or set the lead to 0" is not a
   second option — it does not work.
2. **An instant session collides with `sessions_one_active_per_conversation`.**
   Born `ACTIVE`, an instant booking made while another session of the same
   conversation is running hits that partial unique index as a raw P2002, which
   `convergeBookRace` currently interprets as an idempotency-key conflict — the
   wrong 409, with the wrong message. So the booking transaction has to refuse an
   overlap **with the user's own live sessions** too, not only with the advisor's.
   The user's wallet row is already locked in that transaction, which is exactly
   what serializes one user's concurrent bookings, so the check is sound where it
   sits. (Today `book` checks nothing user-side; availability marks it but
   booking does not enforce it — a pre-existing hole that instant booking turns
   from theoretical into a double-tap.)
3. **`extend`'s overrun check becomes natural.** It reads "the advisor's next
   booking with `startsAt > mine`, does it start before my new end" — under
   intervals it is "does any other live session of this advisor overlap
   `[my startsAt, my new endsAt)`", which also covers a session that started
   *before* mine and runs long. Strictly stronger, same error.
4. **The credit is a discount, not a balance** (`session-policy.ts` says why in
   prose): `creditForBooking` clamps to the subtotal, so a block cheaper than
   $5 costs **0**. Eligibility is `!hasCommittedSession`, and
   `COMMITTED_STATUSES = SCHEDULED|ACTIVE|FINISHED` — **`CANCELLED` is absent, so
   cancelling gives the credit back**. Book-free → cancel → book-free is
   unbounded, verified live in the manor on a fresh account. No money leaks (the
   ledger never sees it), but advisor time does — and this task moves the target
   of that cycle from a future slot to **now**. Product decision, raised in the
   spec, not taken here.
5. **The manor's `.env` runs `SESSION_BLOCK_MINUTES=1,10,20,30` with
   `SESSION_SLOT_STEP_MINUTES=30`** and `SESSION_SLOT_LEAD_MINUTES=5`. The
   1-minute block is what makes (4) cheap to reproduce and is also the fastest
   way to verify the instant path after merge.
6. **Contracts are a hand-kept mirror** (`TECH-DEBT #11`): `src/contracts/` is
   this repo's copy of `@aura/contracts`, and the package itself is cut in
   `aura-app-manor`. So this task writes the shape and pins it in
   `session.spec.ts`; it cannot publish `v0.6.0`.

## No contradictions found

The spec, `AURAD-0009` and the code agree. The only correction is to the spec's
own hedge in trap 1, which the manor's live check settles.

Next: 005-spec.
