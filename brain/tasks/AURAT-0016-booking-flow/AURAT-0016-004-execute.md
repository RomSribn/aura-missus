# AURAT-0016-004 — Execute

Date: 2026-08-14
Slave: slave-1, `feature/AURAT-0016-booking-flow` off develop `057bac2`
Status: **code written, committed, awaiting the merge gate**
Contract: `@aura/contracts` v0.5.1 · Server: `AURAT-0018`, merged (`44418b2`)

Two commits, kept apart because they are two different changes:
`50745b8` the session model, `65929a2` the booking flow.

## 1 · One session model, and it is the server's (`50745b8`)

`entities/session` held seed constants whose `kind` read `"1:1 video"` — a
format the product has never had — and the Sessions tab rendered them. With
billing on, a user could buy a real block, watch it run in the chat, and find
the tab showing fabricated video calls and nothing about the session they paid
for. Deleted; the tab reads `GET /v1/sessions`.

The entity became real: it owns the session endpoints (they were in
`features/paid-session`, which is a feature, not a source of entity data) and
the lifecycle helpers. `sessionState` gained **`'scheduled'`** — `AURAT-0015`
left it out as unreachable and said it would arrive with the flow that could
produce it.

The tab also learned to tell **empty** from **loading** from **"we could not
ask"**. It could not before, because the data was an array that cannot fail, so
a dropped request would have read as "you have never booked anything". A past
session now shows how long it **actually ran**, not what was booked: ending
early forfeits the rest, and the record owes the user the time they got.

`features/paid-session` is now only the running session. Booking left it, so
`PickerMode`, `openPicker` and the sheet's book mode are gone. **The two
idempotency invariants moved onto extend rather than leaving with booking** —
extend charges too, and an unknown outcome must never become two debits.

## 2 · Booking a slot (`65929a2`)

Screens 20 · 21 · 22 in a stack pushed **above the tabs**: the flow is entered
from three of them, one definition beats three copies, and being above the tab
navigator is what hides the tab bar.

**No screen carries a price to the next.** Review is handed the slot and the
length and asks the server what it costs — a total that travelled through
navigation can be stale when it is charged, and the credit depends on the user,
not the slot.

Availability is read **once per advisor**, not per duration (the grid is
duration-independent server-side), with the device's IANA zone in `tz`. Taken
slots render and do not press: which of taken-or-past a slot is stays the
server's judgement.

Two states the design never drew, because a card rail cannot produce them:

- **short balance** → "Top up to book", instead of letting a confirmed tap come
  back 402;
- **slot taken while reading** → said plainly, back to a fresh grid.

## Found while writing it

1. **Request bodies were never checked against the contract.** `bffRequest`
   takes `unknown`, so `bookSession` kept compiling after the contract required
   `startsAt` — nothing would have caught it before a 400 in the user's hands.
   Bodies are parsed before they are sent, with a test.
2. **`Button`'s `icon` is a `ReactNode`, and a string is a valid one**, so
   `icon="lock"` would have rendered the word "lock" with the compiler's
   blessing.
3. **Two slot tests queried pills by their rendered clock time**, which is the
   device's zone: green here, red on a UTC machine. They now query by state.
4. The `HH:MM` formatter was about to be written a second time; promoted to
   `shared/lib` instead.

## Verification

| Gate | Result |
|---|---|
| `tsc --noEmit` | clean |
| `eslint src __tests__` | clean |
| `jest` | **44 suites / 227 tests green** (was 42 / 199 before the task) |
| Release bundle (android, `--dev false`) | built |

The server was probed directly rather than assumed: an unknown path answers
404 while `availability`, `GET /v1/sessions` and `PATCH /v1/sessions/:id` all
answer 401, so the routes exist and the container is running the merged code.
Live config is `SESSION_BLOCK_MINUTES=1,10,20,30` with the grid defaults, so
the device will show 1/10/20/30 — **not** the design's 30/45/60, which is
correct: the app renders what the server sells.

## Not verified here

Everything on a device. Booking end to end, the slot actually activating at its
time, the Sessions tab listing it, the short-balance route, and a raced slot.

## Next

Merge gate — **with `AURAT-0018`, in one window**. The server already requires
`startsAt`, so `develop` currently has an app that cannot book: the shipped
instant path is gone server-side and the new screens are on this branch.
