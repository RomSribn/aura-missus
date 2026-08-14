# AURAT-0024-002 — Execute

Date: 2026-08-14
Slave: slave-1, `feature/AURAT-0024-app-instant-booking` off develop `d97a937`
Contract: `@aura/contracts` **v0.6.0** (`fd478ba`, tagged) · Server:
`AURAT-0023`, merged **and deployed**
Status: **merged into develop (`e29795b`) — device pass open**

## Contract

`v0.6.0` was cut from `AURAT-0023-007-contract.md` — the shape both manors
agreed **before** either built against it, which is what kept the two halves
from drifting the way `tz` nearly did. Smoke-parsed all four combinations of
`startsAt` / `startNow`, including `startNow: false` alone being rejected.

## What changed

**Availability carries the duration.** It was read once per advisor because a
block could never exceed one grid cell; under interval occupancy a gap fits ten
minutes and not thirty. A duration change re-reads the grid and **drops the
chosen time** — keeping it would book a slot the user never picked for that
length.

**"Book now" starts the session now** when the advisor is free. Which of the
two paths it is comes from the server's `instantAvailable`: the app owns
neither the clock the meter runs on nor any view of other clients' bookings, so
a locally-guessed "now" is a button that 409s. When it is not instant the sheet
still spells the wait out, and the word "now" appears only when it is true.

**An instant booking returns `ACTIVE`**, so the sheet closes into the thread
instead of pushing "Session booked" — telling someone to wait for a session
that has already started would be the wrong screen.

## Found while writing it

1. **The opening read must match what the server answers by default.** It sends
   no `minutes`, so the server uses its **shortest** block — but the screen
   preselected `blocks[0]`, and pricing is not promised in order. On a
   `[30, 10]` pricing the grid would have opened offering slots the selected
   duration does not fit. Now the shortest is picked explicitly, with a test on
   deliberately unsorted pricing.
2. **`startsAt: null` is not "field absent".** The compiler caught the
   difference: the absent case now *stops* the charge rather than sending an
   empty field, so a missing slot can never be read as "now".

## Verification

tsc / eslint clean · jest **46 suites / 245 tests** (was 45 / 236) · release
bundle built. Re-verified in manor after the merge on contracts v0.6.0.

The server was checked directly rather than trusted: `btree_gist` present,
`sessions_no_overlap_per_advisor` created, the old
`sessions_one_live_per_advisor_slot` gone, migration `20260814140000_interval_occupancy`
applied, container rebuilt. Their flagged `btree_gist` risk did not bite.

## Sequencing, for the record

The app half could **not** have merged before the server deployed — not merely
degraded: `instantAvailable` is required in `v0.6.0`, so the availability parse
throws against an old server and the booking screen reads "Couldn't load the
times". The order was: their merge → their deploy → this merge.

## Not verified here

The device pass: "Book now" starting a session immediately with the banner and
divider live at once, the grid re-reading when the block changes, and the sheet
falling back to the soonest slot when the advisor is busy.
