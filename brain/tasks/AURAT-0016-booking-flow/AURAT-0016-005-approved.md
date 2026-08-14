# AURAT-0016-005 — Approved

Date: 2026-08-14
Status: **done — owner-approved after a device pass**

## What the owner verified

Booking a scheduled slot on the device, against the merged `AURAT-0018`: the
Book screen with its durations, date strip and time grid, Review with the
server's price breakdown, the charge, and the session landing in the Sessions
tab. Reported working.

## Shipped

`AURAF-0008` rows 006–007. Merged into develop (`51555bc`, code `50745b8` +
`65929a2`, user-approved merge gate) and pushed, **in one window with
`AURAT-0018`** — the server had already made `startsAt` required, so either
half alone leaves `develop` unable to sell a session. Gates green in slave and
re-verified in manor: tsc / eslint / jest (**44 suites / 227 tests**, was
42 / 199), plus a release bundle.

## Known limitation, not a defect

The soonest bookable slot is the next grid boundary, so the wait floats between
zero and thirty minutes depending on where the clock sits in the half hour. The
lead time only trims the last minutes before a slot; the grid is what binds.
`AURAD-0009`'s second amendment takes this on — occupancy becomes an interval so
`startsAt = now` is valid — as **`AURAT-0023`** (BFF, running) and
**`AURAT-0024`** (app, blocked on it).

## Left on the record

- The device shows durations **1/10/20/30**, not the design's 30/45/60: the
  server's `SESSION_BLOCK_MINUTES`, rendered as-is. Correct by `AURAT-0008` D1 —
  the app never invents a block it cannot sell.
- The Booked screen makes **no reminder promise**; the copy and the calendar
  button return with `AURAF-0008-012`.
- The disabled "Visa ···· 4242 — Soon" row stays on Review, pointing at
  **`AURAF-0009`**.
- Not separately exercised on device: a slot raced away between reading and
  confirming (409), and the short-balance route to Top Up. Both are covered by
  unit tests.

slave-1 released.
