# AURAT-0017-002 — Check existing state

Date: 2026-08-14

## Brain

No `AURAT-0017-*` folder existed — fresh task, though the ID was minted earlier
and carried on the board.

Governing artifacts:

- **`AURAD-0009`** (ratified 2026-08-14, supersedes `AURAD-0008`) — a session is
  a scheduled slot paid **from the wallet**; refunds **≥24h full / <24h half**,
  credited back to the balance, and **only before it starts**. Once running,
  `AURAD-0002`'s non-refundable rule still holds.
- **`AURAF-0008`** rows **008–010** — this task's scope.
- **`AURAT-0016`** (`002-spec.md:83`) explicitly parked the fake
  *Reschedule / Join* buttons: "reschedule arrives with `AURAT-0017`, and there
  is nothing to join". Rows tap into the chat thread "for now; Session detail is
  `AURAT-0017`".
- **`AURAT-0015`** left `SessionBanner` with an `onPress` prop pointing at the
  block sheet, on the record that it re-points here.

## Code (ground truth, slave-1 @ `20d2467`)

**The data layer is already done.** `entities/session/api/sessions-api.ts`
ships `rescheduleSession` (PATCH, "refused inside 4h of its current start") and
`cancelSession` (POST `/cancel`, returns `CancelSessionResponse`), both
contract-parsed on the way out and back. `entities/session/lib/session-state.ts`
has `sessionState` / `minsLeft` / `minsUntilStart` / `isUpcoming` / `isPast`,
including the `'scheduled'` state `AURAT-0015` deliberately omitted.

Also present and reusable: `features/booking` — `DateStrip`, `SlotGrid`,
`use-booking`, `use-booking-confirm` (owns the idempotency key, the 409 and the
short-balance route). Reschedule is the same two pickers over a different verb,
so it must reuse these, not re-cut them.

Missing, i.e. the actual work:

- No `SESSION_DETAIL` / `RESCHEDULE` route — the nav contract has only
  `BOOK_SESSION` / `BOOK_REVIEW` / `BOOKED` under `BookingStackParamList`.
- No detail, reschedule or cancel UI anywhere.
- `screens/sessions/ui/UpcomingSessionCard.tsx` has one footer button
  ("Open chat" / "Open session chat"), exactly as `AURAT-0016` left it.

## Consequence

This is a **screens-and-navigation task**, not a full-stack one. The estimate
should reflect that the endpoints, the contract parsing, the lifecycle helpers
and both slot pickers already exist.

## Next

`003-understand.md`.
