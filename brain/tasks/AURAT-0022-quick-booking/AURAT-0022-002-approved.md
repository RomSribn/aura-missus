# AURAT-0022-002 — Approved

Date: 2026-08-14
Status: **done — owner-approved after a device pass**

## What the owner verified

The quick sheet from "Book now", the grid starting at the next usable time
instead of on dead morning hours, and the date card at its full width.

## Shipped

Merged into develop (`d97a937`, code `aa8fb20` + `36da946`, user-approved merge
gate) and pushed. Gates green in slave and re-verified in manor: tsc / eslint /
jest (**45 suites / 236 tests**), plus a release bundle.

## Left on the record

- The sheet says **"15:30 · in 12 min"**, never "Now" — accurate for as long as
  the grid binds the start. `AURAT-0024` is what earns the word "now", and it
  should not be used before then.
- `SESSION_SLOT_LEAD_MINUTES` is **5** on the dev BFF. It took two attempts: a
  `docker compose restart` does not re-read `.env`, and the value only landed
  after `up -d` recreated the container. Worth remembering the next time a
  config change appears not to work.
- Two of my own mistakes are recorded in `001-execute.md` rather than quietly
  fixed: the post-booking route sent the user back to the grid they had just
  booked from, and a catch block read `setFailed(… || true)`.

slave-0 released.
