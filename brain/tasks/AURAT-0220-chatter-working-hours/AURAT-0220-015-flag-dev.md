# AURAT-0220-015 — Flag on bff-dev: live check of the slot grid

Date: 2026-11-18, about 20:05 Europe/Madrid. Checked by the manor (manor-8e).

The owner set `SESSION_WORKING_HOURS_ENABLED=true` on bff-dev and redeployed. Container
`…-20261118T190229` runs `ffb3c58` with the flag in env; `/health` is ok. Migrations
`20261118150000_consents` and `20261118160000_chatter_working_hours` are applied on bff-dev.

**Dev pool** (database, read only): one chatter, agent 1, Europe/Madrid. Week: ISO days 1, 2, 3 and 5,
09:00–18:00. Override for 2026-11-18: 09:00–15:30.

## Item 2 — availability

Checked on the public `GET /v1/advisors/olivia/sessions/availability?days=7&tz=Europe/Madrid`, for
`minutes=10` and `minutes=30`.

- Wed 18 is closed: the override ends at 15:30 and it is now 20:05. Thu 19, Sat 21 and Sun 22 are
  closed. Fri 20, Mon 23 and Tue 24 open with starts from 09:00 to 17:30.
- No difference from the union of the hours, for either 10 or 30 minutes. Before the flag (the old
  container) all 48 slots were open.
- Two cases can't be reproduced live; unit tests cover them:
  - **A block crossing the end of a shift.** Blocks are 10, 20 or 30 minutes (`minutes=60` → 400),
    and the grid and the schedule step are 30 minutes, so no block can cross an edge.
  - **The seam between two shifts.** The dev pool has one chatter.

## Item 4 — «сейчас»

`instantAvailable` = false now (outside the hours) — ✓.

Not checked yet: "in the hours, nobody online" and "in the hours, someone online" need hours covering the
present moment. The manor will suggest the owner an override for today.

## Still open

- The owner's browser checks:
  - item 1 — `enforced: true`, the "does not close slots yet" line is gone;
  - item 3 — 409 on a booking or reschedule outside the hours;
  - item 5 — «Никто не работает» in the «Aura» tab calendar;
  - item 6 — the uncovered-bookings warning and the backoffice list.
- Item 4 inside the hours, once the override is set.
- Then the owner's «принято» → the approval step, one missus commit, ask before `wts-release`.
- Production: after develop goes to `main` — the bridge for account 1, then the flag once production
  chatters fill in their schedules.
