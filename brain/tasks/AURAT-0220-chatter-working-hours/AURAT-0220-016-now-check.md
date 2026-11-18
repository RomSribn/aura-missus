# AURAT-0220-016 — Flag on bff-dev: «сейчас» and the block crossing the end of a shift

Date: 2026-11-18, 20:10–20:25 Europe/Madrid. The owner checked in the browser (web-dev, Alisher,
10 min); the manor read the database and the API.

## Setup (owner)

- Override for 2026-11-18 set to 09:00–23:30 on the «Расписание» page («Сохранено.»).
- Thursday added to the week: ISO 4 — 00:00–18:30. Mon, Tue, Wed and Fri stay 09:00–18:00.

## Availability (manor: `days=9`, `minutes=10`, `tz=Europe/Madrid`)

- Wed 18: 20:30–23:00 open; **23:30 closed** — the block 23:30–23:40 ends after the override's 23:30.
  This is the live case of a block crossing the end of a shift (`015` had it only in unit tests).
- Thu 19 and Thu 26: 00:00–18:00 open (37 starts); 18:30 closed for the same reason.
- Fri, Mon, Tue and Wed 25: 09:00–17:30. Sat and Sun: empty.
- The client's date strip greys exactly the days with no slots: Sat and Sun. The Thursdays are white
  because the owner added Thursday — no discrepancy.

## «Сейчас» (item 4)

- In the hours, chatter Online: `instantAvailable` = true, «Now» shown and active — ✓.
- In the hours, chatter set to **Offline** in Chatwoot (the 30 s cache allowed for): «Now» is gone, the
  slots 20:30–23:00 stay open, 23:30 stays closed — ✓ (owner's screenshots, 20:25).

## Still open

- Item 3: a booking or reschedule outside the hours → the taken-slot 409.
- Item 5: «Никто не работает» in the «Aura» tab calendar.
- Item 6: the uncovered-bookings warning on save and the backoffice list.
- Then the owner's «принято» → the approval step, one missus commit, ask before `wts-release`.
- Production: after develop goes to `main` — the bridge for account 1, then the flag once production
  chatters fill in their schedules.
