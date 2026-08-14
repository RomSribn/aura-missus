# AURAT-0024-002 — Execute

Date: 2026-08-14
Slave: slave-1, `feature/AURAT-0024-app-instant-booking` off develop `d97a937`
Contract: `@aura/contracts` **v0.6.0** (`fd478ba`, tagged) · Server:
`AURAT-0023`, merged **and deployed**
Status: **merged into develop (`e29795b`) — device pass open**

## Contract

`v0.6.0` was cut from `AURAT-0023-007-contract.md` — the shape both manors
agreed **before** either built against it, which is what kept the two halves
from drifting the way `tz` nearly did. Smoke-parsed all four combinations of
`startsAt` / `startNow`, including `startNow: false` alone being rejected.

## What changed

**Availability carries the duration.** It was read once per advisor because a
block could never exceed one grid cell; under interval occupancy a gap fits ten
minutes and not thirty. A duration change re-reads the grid and **drops the
chosen time** — keeping it would book a slot the user never picked for that
length.

**"Book now" starts the session now** when the advisor is free. Which of the
two paths it is comes from the server's `instantAvailable`: the app owns
neither the clock the meter runs on nor any view of other clients' bookings, so
a locally-guessed "now" is a button that 409s. When it is not instant the sheet
still spells the wait out, and the word "now" appears only when it is true.

**An instant booking returns `ACTIVE`**, so the sheet closes into the thread
instead of pushing "Session booked" — telling someone to wait for a session
that has already started would be the wrong screen.

## Found while writing it

1. **The opening read must match what the server answers by default.** It sends
   no `minutes`, so the server uses its **shortest** block — but the screen
   preselected `blocks[0]`, and pricing is not promised in order. On a
   `[30, 10]` pricing the grid would have opened offering slots the selected
   duration does not fit. Now the shortest is picked explicitly, with a test on
   deliberately unsorted pricing.
2. **`startsAt: null` is not "field absent".** The compiler caught the
   difference: the absent case now *stops* the charge rather than sending an
   empty field, so a missing slot can never be read as "now".

## Verification

tsc / eslint clean · jest **46 suites / 245 tests** (was 45 / 236) · release
bundle built. Re-verified in manor after the merge on contracts v0.6.0.

The server was checked directly rather than trusted: `btree_gist` present,
`sessions_no_overlap_per_advisor` created, the old
`sessions_one_live_per_advisor_slot` gone, migration `20260814140000_interval_occupancy`
applied, container rebuilt. Their flagged `btree_gist` risk did not bite.

## Sequencing, for the record

The app half could **not** have merged before the server deployed — not merely
degraded: `instantAvailable` is required in `v0.6.0`, so the availability parse
throws against an old server and the booking screen reads "Couldn't load the
times". The order was: their merge → their deploy → this merge.

## Not verified here

The device pass: "Book now" starting a session immediately with the banner and
divider live at once, the grid re-reading when the block changes, and the sheet
falling back to the soonest slot when the advisor is busy.

## Post-merge, from the device pass

**The timer plate did not appear until the thread was re-entered.** Two hooks
sat in the same screen and never spoke: `usePaidSession` owns the running
session and learns of one from `fetchActiveSession` — mount, advisor change,
foreground — while the quick sheet booked through `useBookingConfirm`, which
announced success as `onBooked()` and **threw the response away**. Re-entering
remounted the hook, which is exactly the workaround the symptom described.

Invisible until now on purpose: every booking used to produce a `SCHEDULED`
session, so there was nothing live to show. `ACTIVE` in the response exposed it.

Fixed by handing the session over rather than fetching it again — the rule the
balance already follows after a debit. A session that is not running clears the
state instead, so a scheduled booking cannot put a countdown on screen for
something that has not started. Three tests pin it.

**The 409 copy was blaming a stranger.** "That time was just taken" is only half
true: the server answers 409 both when another client won the slot and when the
asking user already has a session covering that window — booking 30 minutes now
against your own 19:30 booking is the reachable case. The app cannot tell them
apart, because `BffApiError` carries the status and the body is deliberately
never read. The wording is now true of both.

*Recorded, not taken:* distinguishing the two needs a **reason code in the error
body** (`slotTaken` / `userBusy`), which is a contract addition plus BFF work.
Worth it only if the message should name the conflicting booking.

Merged again (`develop` after `e29795b`), gates re-verified in manor:
**46 suites / 248 tests**.

**The sheet answered from screen mount, not from opening.** Ending a session
left "Book now" still offering the soonest free slot; the thread had to be
re-entered before it would start one now. `useQuickBooking` read pricing and
availability once, on mount — while a session ran the server had answered
`instantAvailable: false`, quite correctly, and nothing asked again. A session
ending, the user's own or the advisor's with somebody else, turns that answer
over and no push carries it.

The same shape as the banner defect and the same lesson: **state whose truth
expires needs a trigger, and mount is not one.** The sheet now re-reads when it
opens, which is the only moment its answer has to be true and the moment the
user asks the question.

Two hatches closed with it: the fallthrough to the grid was decided from the
pre-check's stale answer, so a refresh landing on "nothing free after all" now
closes the sheet and goes to the grid through the same wait-for-the-modal path;
and a duration change re-reads here too, since `instantAvailable` moves with the
block exactly as the grid does.

Merged (`develop` `3852916`), manor gates green: **46 suites / 250 tests**.
