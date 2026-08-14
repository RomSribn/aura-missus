# AURAT-0015-003 — Understand

Date: 2026-08-14

## What the user wants

Make a running paid session **legible inside the chat thread**, per design
handoff round 2, without touching how a session is bought or refunded.

Today a session is only visible as a `SessionBar` plus coral markers. The round
adds four things that together answer, at a glance, *"am I being charged right
now, and for how much longer?"*: a banner pinned under the chat header with a
1-second counter and a progress bar, restyled dividers that bracket the paid
window in the transcript, markers and re-sorting in the chats list so a session
is visible before you open the thread, and a header action that becomes "Extend"
while live instead of offering a second booking.

## What it explicitly is not

- Not the booking flow. `AURAD-0008` option B parked Book / Review / Booked /
  Reschedule / Cancel until a PSP exists.
- Not a change to the payment rail, the refund rules, or when a session starts —
  `AURAD-0002` stands: instant, wallet-prepaid, non-refundable once started.
- Not a separate session screen or a join step. The thread *is* the surface.

## The one thing that needs care

The handoff writes the session in a **scheduled** vocabulary —
`sessionState → 'scheduled' | 'active' | 'ended'`, a "starting soon (≤24h)"
banner variant, "SESSION SCHEDULED", "UNTIL START". Under `AURAD-0002` a session
**cannot be scheduled**: it starts the moment it is booked. So the
starting-soon variant has no reachable state in this product today.

Building it anyway would ship dead UI. Leaving the vocabulary out entirely would
mean rewriting the helpers when the booking flow lands. Resolution is in the
spec (`005`).

## Next

`004-context.md`.
