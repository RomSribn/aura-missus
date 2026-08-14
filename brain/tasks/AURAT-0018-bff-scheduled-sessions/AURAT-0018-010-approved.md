# AURAT-0018-010 — Approved

Date: 2026-08-14
Status: **done**

## Owner verdict

Verified in the manor on `develop` @ `44418b2`: *«проверил в маноре, все ок»* —
approved, no changes requested. The six checks from `009-merge.md` (both migrations
on the populated DB, the `balance == Σ ledger` invariant across both refund tiers,
double-cancel idempotency, the two-client slot race, timed activation with its
marker and push, and the Chatwoot attribute walk) are the owner's own observation;
they were not run from this slave and no output is recorded here.

## What shipped

The BFF half of `AURAD-0009`. A paid session is now a **scheduled slot**: booked for
a future time, prepaid from the wallet at a server-computed total (flat $5
first-session credit applied as a discount, never as balance), started by the
server's own meter, reschedulable free up to 4h before, and cancellable with a real
refund — ≥24h full, under that half, floored, and only before it starts. Instant
booking is gone: `POST advisors/:id/sessions` requires a slot.

New endpoints: availability, sessions list, reschedule (`PATCH`), cancel. Pricing
became per-user with a `subtotalMinor`/`creditMinor`/`costMinor` breakdown. Implements
`@aura/contracts` **v0.5.1** exactly.

The three things that carry the design:

- **The advisor row lock.** Two clients racing one slot hold two different wallets,
  so the existing wallet lock could never serialize them. `book`/`extend`/`reschedule`
  take `advisors … FOR UPDATE` first, always in the same order, with a partial unique
  index on `(advisorId, startsAt)` as the guarantee that outlives a bug in the lock.
- **The ledger's first credit direction.** `SESSION_REFUND`, appended in the debit's
  exact transactional shape, never an `UPDATE`, idempotent through both a conditional
  status transition and a server-derived key.
- **Blocks ≤ slot step, enforced at boot.** One booking occupies exactly one slot,
  which is what lets availability ignore duration and lets a plain partial index be
  the double-book guard.

294 unit tests (20 new). `AURAF-0008` rows 006–011 are `✓` on the BE side.

## Left behind, deliberately

- **`TECH-DEBT #14`** — `GET /v1/sessions` caps at 100; v0.5.1 has no cursor.
- **`TECH-DEBT #15`** — the booking horizon now lives in two places: the contract's
  `max(14)` literal and `SESSION_BOOKING_HORIZON_DAYS`. They agree at 14 today;
  whichever moves first breaks the other, which is why the service still checks its
  own config instead of trusting the pipe.
- **`TECH-DEBT #7` is sharper** — with a credit direction in the ledger, a bad
  hand-fix can now create money, not only destroy it. DB-level append-only
  enforcement matters more before billing is switched on anywhere.
- **Activation latency edge** — `endsAt` is recomputed from the meter's own
  `startedAt`, so a late sweep never shortens a paid block, at the cost of a bounded
  overrun into the next slot equal to that lag.
- **`AURAF-0008-012`** (30-minute reminder, add-to-calendar) untouched: the BFF sends
  no session reminders, and whether they are local or pushed is still open.

## For the app manor

`AURAT-0016`/`AURAT-0017` can build against the live server now. Availability takes
`?days=` and `?tz=` — **send the device's zone**, or a user hours from
`SESSION_SLOT_TIMEZONE` sees evening slots filed under the neighbouring day. The
`session.updated` WS event now also carries the `SCHEDULED → ACTIVE` transition the
meter makes on its own, which can arrive while the user is anywhere in the app.

## Next

Commit the task's missus docs, then release the slave.
