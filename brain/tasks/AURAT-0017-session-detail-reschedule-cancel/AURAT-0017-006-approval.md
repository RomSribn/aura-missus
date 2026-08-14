# AURAT-0017-006 — Approval

Date: 2026-08-14
Status: **approved — implementation may start in slave-1**

## What the owner approved

`005-spec.md` as written: the Sessions-stack routes, Session detail with the
state-coloured hero and a single always-enabled footer button, Reschedule reusing
`features/booking` with the 4-hour refusal left to the server, the Cancel sheet
with both refund tiers, and the two loose ends retired — `UpcomingSessionCard`
gaining Reschedule/Details, and `SessionBanner`'s `onPress` re-pointed from the
block sheet to Session detail.

## The open question, answered

**Compute the refund preview on the client.** The screen ships now rather than
waiting on a BFF preview endpoint. The server's `refundedMinor` remains
authoritative for the actual refund; the client figure is a preview and must
read as one. The rule goes in a single named helper in `entities/session/lib`
with a test, so there is one site to change when the policy does.

`GET /v1/sessions/:id/cancel-preview` is recorded as a follow-up, not minted.

## Standing constraints carried into execution

- Work happens **only in slave-1**; runtime verification waits until after the
  merge, in manor.
- Nothing merges to `develop` without explicit in-the-moment owner approval.
- Reschedule **reuses** `DateStrip` / `SlotGrid` / `use-booking` /
  `use-booking-confirm` — a second copy would drift from the UTC grid, the
  `minutes`-aware availability (`AURAT-0024`) and the server-clock past-slot
  rule (`AURAT-0022`).
- The app renders the server's numbers: live blocks are `1,10,20,30`, not the
  design's 30/45/60, and there is no first-session-credit row because `Session`
  has no such field.
- A **running** session is out of scope and stays non-refundable (`AURAD-0002`).

## Next

`007-execute.md` — written in slave-1 after the code, before the IDE review.
