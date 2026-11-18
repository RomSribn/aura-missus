# AURAT-0220-018 — Approved

Date: 2026-11-18. Owner (relayed by the manor): «принято, закрывай 0220».

## Checked live on bff-dev (`012`–`017`)

- **Bridge.** In Aura Dev the «Расписание» item sits in the menu list under Settings (after the fix
  `6e252a8`). The «Aura» tab in production works as before. No item in the production account.
- **Schedule page and backoffice.** Hours save and survive a reload; the backoffice «Расписания» tab
  shows them.
- **Availability.** It equals the pool's hours, for 10- and 30-minute blocks. Before the flag all 48
  slots were open.
- **A block past the end of a shift is closed:**
  - 23:30 under an override that ends at 23:30;
  - 18:30 under a Thursday that ends at 18:30.
- **«Сейчас».** In the hours, with a chatter Online — available. With the chatter Offline, «Now» is gone
  and the other slots stay open.
- **Booking outside the hours** — the taken-slot 409, nothing charged:
  - Saturday;
  - 23:30 past the override;
  - `startNow` while Offline.
  - The control slot in the hours passes the check and gets the money refusal: 402.

## Left to unit tests

- A reschedule outside the hours — there was no SCHEDULED booking more than 4 h ahead.
- The uncovered-bookings warning on save and the backoffice list.
- The «Никто не работает» blocks in the «Aura» tab calendar.
- The seam between two shifts — the dev pool has one chatter.

## After the task

Production, after develop is released to `main`:

1. the bridge with `AGENT_DESK_ACCOUNTS=1=https://bff.aura-app.cc,2=https://bff-dev.aura-app.cc`;
2. `SESSION_WORKING_HOURS_ENABLED=true` once the production chatters fill in their schedules — the
   owner's decision.

State is recorded in `AURAD-0025` («Состояние (2026-11-18)»).

`wts-release` is done by the manor, with the owner's approval.
