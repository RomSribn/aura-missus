# AURAT-0023-003 — Understand

Date: 2026-08-14

## What is wanted

A paid session must be startable **now**. The obstacle is the occupancy model,
not a number: a slot is held by `UNIQUE (advisorId, startsAt)` on a grid-aligned
instant, which only works while one booking fills exactly one cell — hence the
boot check that refuses a block longer than the step. So occupancy becomes an
**interval** `[startsAt, endsAt)`, "is this free" becomes "does any live session
of this advisor overlap it", and three things follow: `startsAt` stops having to
be aligned (so `now` is bookable and the session is born `ACTIVE`), the grid step
stops being tied to block length, and availability starts taking `minutes`.

## What must not move

The double-booking guarantee (advisor row `FOR UPDATE` + an overlap query inside
that lock), `balance == Σ ledger`, and the idempotency behaviour — all verified
live in the manor two hours ago, 25/25.

## Before building

The contract shape (`v0.6.0`) is agreed **first**, with the owner, because
`AURAT-0024` is blocked on it and both manors build against it. Two shapes are
open: how "start now" is expressed, and how `minutes` enters `AvailabilityQuery`.

One thing found while reading the money path is raised at the same time and is
**not** mine to decide: the first-session credit clamps to the subtotal and
cancellation restores eligibility, so a free booking cycle exists and this task
points it at *now* instead of at a future slot.

Next: 004-context.
