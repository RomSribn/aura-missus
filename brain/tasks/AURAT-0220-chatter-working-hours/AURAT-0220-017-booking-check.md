# AURAT-0220-017 — Flag on bff-dev: a booking outside the hours, through the API

Date: 2026-11-18, about 20:35 Europe/Madrid. Done by the manor at the owner's request («пусть манор
проверит бронь вне часов через API»). The owner gave the token of his web-dev user; the manor deleted
the token file after the check.

## Setup

- Balance 2200 (USD minor); advisor `alisher`, 10 min = 2400.
- Agent 1 is Offline, so `instantAvailable` = false.
- Every request: `POST /v1/advisors/alisher/sessions`, a new `idempotencyKey`, consent `booking-v1` /
  `now-v1` (`en`), no Origin.

## Results

| # | Request | Answer | Balance |
|---|---|---|---|
| 1 | Sat 21, 12:00 Madrid (`2026-11-21T11:00Z`) — a day off; 10 min | 409 «That slot has just been taken — pick another one» | 2200 |
| 2 | Today, 23:30 Madrid (`2026-11-18T22:30Z`) — the block ends after the override's 23:30; 10 min | 409, the same text | 2200 |
| 3 | Control: Fri 20, 10:00 Madrid (`2026-11-20T09:00Z`) — in the hours; 10 min | 402 «Insufficient wallet balance: cost 2400, balance 2200». The hours check passed; the refusal is about money. No booking | 2200 |
| 5 | `startNow`, in the hours (override until 23:30), agent Offline | 409, the same text | 2200 |

- Outside the hours the answer is the taken-slot 409. It comes before the wallet, so nothing is
  charged — ✓.
- **Reschedule (`PATCH /v1/sessions/:id`) is not checked live.** The user has no SCHEDULED booking
  starting more than 4 h ahead (16 sessions, all CANCELLED or FINISHED). It stays covered by unit tests
  (`sessions.service.spec`, «working hours»); live only if the owner makes a booking.
- On the side, for AURAT-0216: the `consents` table on bff-dev has 0 rows — the refused requests
  wrote nothing.

## Still open

- Item 5: «Никто не работает» in the «Aura» tab calendar.
- Item 6: the uncovered-bookings warning on save and the backoffice list. It needs a SCHEDULED booking,
  so the reschedule can be checked on the same booking.
- Then the owner's «принято» → the approval step, one missus commit, ask before `wts-release`.
- Production: after develop goes to `main` — the bridge for account 1, then the flag once production
  chatters fill in their schedules.
