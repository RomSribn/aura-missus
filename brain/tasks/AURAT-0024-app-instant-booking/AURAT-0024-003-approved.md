# AURAT-0024-003 — Approved

Date: 2026-08-14
Status: **done — owner-approved after a device pass**

## What the owner verified

Instant booking end to end on the device: "Book now" starts a session
immediately when the advisor is free, the banner and its timer are up the
moment the sheet slides away, ending a session and reopening the sheet offers
to start another one at once, and changing the block no longer collapses the
sheet.

## Shipped

`AURAD-0009`'s second amendment, app half, on `@aura/contracts` v0.6.0.
Merged in four passes as the device pass turned up defects — `e29795b`,
`bafdae1`, `3852916`, `20d2467` — each through the merge gate and pushed.
Gates green in slave and re-verified in manor after every merge:
**46 suites / 251 tests** (was 45 / 236), plus a release bundle.

## The four defects, and the two roots under them

| Symptom | Root |
|---|---|
| The timer plate appeared only after re-entering the thread | the booking response carried the session and was thrown away instead of handed to the hook that owns it |
| "Book now" still offered the soonest slot right after a session ended | the answer was read at screen mount; its truth expires and nothing pushed the change |
| 409 said "that time was just taken" when the clash was with the user's own booking | one message for two causes the app cannot tell apart |
| The sheet emptied and its height collapsed on a block change | one flag meaning both "nothing yet" and "asking again" |

Two lessons worth carrying, both already true elsewhere in this codebase and
both re-learned here:

1. **State whose truth expires needs a trigger, and mount is not one.** The
   moment the user asks the question is the moment to ask the server.
2. **Anything re-read behind an answer already on screen keeps the answer.**
   The wallet has worked this way since `AURAT-0019`, for the same reason: a
   card that empties on refresh reads as money going missing.

## Recorded, not taken

Distinguishing "someone else booked it" from "you are already booked then"
needs a **reason code in the error body** (`slotTaken` / `userBusy`) — a
contract addition plus BFF work. Worth it only if the message should name the
conflicting booking ("you already have a session at 19:30"). Until then the
wording is true of both.

## Not verified

A slot raced away between reading and confirming (409) on a real device — it
needs two clients and is covered by unit tests on both sides.

slave-1 released.
