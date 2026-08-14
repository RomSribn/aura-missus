# AURAT-0022-001 — Execute

Date: 2026-08-14
Slave: slave-0, `feature/AURAT-0022-quick-booking` off develop `51555bc`
Decision: `AURAD-0009`, amended the same day
Status: **merged into develop (`d97a937`) — device pass open**

Asked for by the owner after seeing `AURAT-0016` on the device: a grid that
does not spend its space on hours already gone, and a "Book now" that books in
one tap again.

## What changed

**The grid drops slots that have already started.** The server returns whole
days, so today opened on a column of dead morning hours. A slot that is merely
*unavailable* stays — a booked afternoon must read as booked, not as a day that
never existed. Past is decided on the **server's** clock; from the device's, a
skewed phone would hide slots the server is still selling.

**"Book now" opens a sheet on the soonest free slot** — length, price, balance,
one button — with "Another time" through to the full grid, and it falls through
to that grid by itself when nothing is free.

**It is not the instant block returning.** The session is still a scheduled
slot the server starts. The amendment only takes the lead time to zero, which
is BFF config and no code. The grid stays anchored to half hours, so the
soonest slot can be nearly a step away — hence the sheet always reads
*"15:30 · in 12 min"* and never "Now".

**The sheet is a shortcut, not a second implementation.** It charges through
the same `useBookingConfirm` the Review screen uses, so the idempotency key,
the 409 and the short-balance route keep one home. The hook learned to take a
slot that is not chosen yet and pricing the caller already loaded, so the
shortcut costs one request rather than two. Leaving the sheet waits for the
modal to be gone (`AURAT-0020`).

**The date card got its full 58px.** The design has `width: 58` with
`padding: 11px 0 10px` under a border-box reset — vertical only. Ours added
10px of side padding *inside* the same 58, leaving 38px of content, which is
what made "Today" look cramped.

## Found in my own code

- The post-booking route sent the user back to the slot grid they had just
  booked from; it now lands on the same confirmation the full flow ends on.
- A catch block read `setFailed(… || true)` — a condition that means nothing.

## Verification

tsc / eslint clean · jest **45 suites / 236 tests** · release bundle built.

## Live config, worth knowing before the device pass

The owner intended `SESSION_SLOT_LEAD_MINUTES=5`, but the value never landed:
`aura-bff/.env` and the running container both read **0**, and no file in the
BFF manor contains a 5. Nothing is broken by this — at 0 the sheet is simply as
fast as the grid allows — but a chatter gets no warning at all that someone is
about to arrive, which is the reason 5 was chosen.

## Not verified here

The device pass: the sheet's slot and its countdown, "Another time", the
fallthrough when nothing is free, and the grid starting at the next usable
time.
