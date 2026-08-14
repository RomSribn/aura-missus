# AURAT-0024-001 — Initial

Date: 2026-08-14
Decision: `AURAD-0009`, second amendment
Blocked on: **`AURAT-0023`** (BFF) and the contract cut that follows it

## The ask

The app half of starting a session **now**.

## What changes

1. **Availability carries the duration.** `AURAT-0016`'s `useBooking` reads it
   **once per advisor** and never re-reads on a duration change — deliberately,
   because today's grid is duration-independent. Under interval occupancy a gap
   can fit ten minutes and not thirty, so the read takes `minutes` and re-runs
   when the block changes. The selected slot must be cleared when it does: a
   time that fit the old duration may not fit the new one.
2. **The quick sheet offers a real "Now".** `AURAT-0022` made a point of never
   saying "Now" for a slot half an hour out — that honesty stops being a
   constraint once the start is genuinely immediate. The sheet keeps showing
   the time and the distance for *scheduled* choices, and reads plainly as
   "start now" only when it is.
3. **The grid may keep a "Now" as its first option** when the advisor is free,
   per the owner's original sketch.
4. **The banner and the divider arrive immediately** rather than at a future
   slot — worth an explicit device check, since the whole in-thread surface
   (`AURAT-0015`) was verified against a session that started on a boundary.

## Not a rewrite

The booking screens, the charge, the idempotency handling and the Sessions tab
all stay. This is the availability read growing an argument and the sheet
gaining an honest instant path.

## Contract

`@aura/contracts` `v0.6.0` — cut **after** `AURAT-0023`'s shape is settled, not
before. Both manors build against it, so guessing it early is how the two sides
drift.
