# AURAT-0023-001 — Initial

Date: 2026-08-14
Executes in: **`aura-bff-manor`** (ID minted here per `AURAD-0006`)
Decision: `AURAD-0009`, second amendment
Depends on: `AURAT-0018` (merged, `44418b2`)

## The ask

A paid session must be startable **now**. Today the soonest is the next grid
boundary — up to a full step away — and a user who came to talk is asked to
wait half an hour.

## Why the lead time is not the answer

`SESSION_SLOT_LEAD_MINUTES` only trims the last minutes before a slot. The
binding constraint is the grid itself, and the grid cannot simply shrink:
`envSchema` refuses to boot when any block exceeds the step, with a comment
that says exactly why —

> *One booking must occupy exactly one grid slot. That single invariant is what
> lets availability ignore duration and lets a plain partial unique index be the
> double-book guard instead of a range-exclusion constraint — so a block longer
> than the step is not a tuning mistake, it is an unsound grid.*

That reasoning is correct. It is the model that has to change, not the numbers.

## The change

**Occupancy becomes an interval.** `[startsAt, endsAt)` per advisor; "is this
free" becomes "does any live session of this advisor overlap it". From that:

- `startsAt` need not align to the grid → **`startsAt = now` is bookable**, and
  the session is created **`ACTIVE`** rather than `SCHEDULED` with a delayed
  activation job.
- The grid step stops being tied to block length; the boot cross-check goes.
- **Availability takes `minutes`**: a gap that fits 10 does not fit 30.

## What must not regress

**The double-booking guarantee.** It does not rest on
`sessions_one_live_per_advisor_slot` alone — every booking transaction already
takes `SELECT … FOR UPDATE` on the advisor row so that two clients racing one
slot are serialized. An overlap query **inside that lock** is as sound as the
equality was. If a DB-level belt is wanted in place of the unique index, it is
`EXCLUDE USING gist (advisorId WITH =, tsrange(startsAt, endsAt) WITH &&)`,
which needs `btree_gist`.

`balance == Σ ledger` and the idempotency behaviour are untouched by this and
must stay untouched.

## Traps worth naming before building

1. **The lead time would reject `now` itself.** It exists so a chatter is not
   ambushed by a slot appearing with no warning — that applies to *picking a
   future slot*, not to a user saying "I am here". The instant path needs an
   exemption, or the lead has to be 0; the exemption is the honest reading.
2. **Activation is now two paths.** A scheduled session still transitions by
   job; an instant one is `ACTIVE` at creation, so the marker, the
   `session.updated` push and the finish job all have to fire inline. The
   existing activation code is the thing to reuse, not to duplicate.
3. **Extend's "must not overrun the next session" check becomes natural** under
   overlap — and must keep working.
4. **The grid tests are written against equality** (`AURAT-0018` §10). Rewriting
   them against intervals — races into the same gap, back-to-back bookings,
   overlap at the exact boundary, a booking that straddles a taken one — is the
   bulk of this task, not the query.

## App side

**`AURAT-0024`**: availability starts carrying `minutes` and is re-read when the
duration changes (`AURAT-0016` reads it once per advisor precisely because the
grid is duration-independent today), and the quick sheet offers a genuine
"Now" instead of the soonest boundary.

Contract: expect a `v0.6.0` — `AvailabilityQuery` gains `minutes`, and booking
needs to express "start now" (an explicit flag, or simply an unaligned
`startsAt` the server accepts). The app manor cuts it once this task's shape is
settled; **agree the shape before either side builds against it**.
