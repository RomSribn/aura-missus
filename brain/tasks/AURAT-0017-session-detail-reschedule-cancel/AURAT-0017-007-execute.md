# AURAT-0017-007 — Execute

Date: 2026-08-14
Slave: slave-1, `feature/AURAT-0017-session-detail-reschedule-cancel` off
develop `20d2467`
Status: **code written, staged, gates green — awaiting IDE review, not merged**

## What shipped

`AURAF-0008` rows 008–010, plus the two placeholders `AURAT-0016`/`0015`
deliberately left behind.

### 1 · Navigation — a Sessions stack

`SESSIONS_LIST` / `SESSION_DETAIL` / `RESCHEDULE` joined the shared contract as
`SessionsStackParamList`, and the Sessions **tab** became a stack
(`SessionsStackNavigator`) instead of a bare screen. Detail and Reschedule are
pushed screens that hide the tab bar, like the chat thread and the advisor
profile before them.

Both routes carry **only `sessionId`**. The session is re-read from the server
on arrival rather than travelling in params: detail is reached from three
places, and coming back from Reschedule has to show the *new* time, not the one
that was passed in before it moved.

`BOOKED` gained `sessionId` so its confirmation can open the session it just
created — both producers of that screen (Review and the quick sheet) had the
booked session in hand and were discarding its id.

### 2 · Session detail (row 008)

`screens/session-detail`. Plum hero whose eyebrow is the one element that
changes colour: gold relative day while scheduled, **teal** "In progress ·
N min left" while the meter runs, gold "Completed" when it is over — and
"Cancelled" rather than "Completed" for a `CANCELLED` session, which is `ended`
to the lifecycle and nothing like completed to the person who cancelled it.

Rows: Date · Time · Format · **Paid from balance**. No Reminder row (row 012
owns reminders, and `AURAT-0016` already refused to promise one) and no
first-session-credit row — `Session` carries no such field.

Footer is **one always-enabled button**: "Open chat", or "Open session chat ·
N min left" while live. Reschedule (soft, `repeat`) and Cancel (borderless
coral, `trash`) render only while `scheduled`, because the server refuses both
once the meter has the session.

The screen ticks once a **minute**, not once a second: it shows minutes and a
relative day. The per-second counter stays the in-chat banner's, which is the
surface that owns the live meter.

### 3 · Reschedule (row 009)

`screens/reschedule`, reusing `DateStrip`, `SlotGrid` and `useBooking` — not a
copy of them. The 4-hour cutoff is **stated and not enforced**: the screen opens
inside the window, the note names the policy, `PATCH` refuses, and the refusal
is surfaced. Hiding it on a client estimate would repeat the bug `AURAT-0022`
fixed in the slot grid.

The change preview appears only once the pick differs: old slot struck through
in ink-3 → `chev` → new slot in teal.

### 4 · Cancel sheet (row 010)

On the shared `BottomSheet`, both tiers: teal `shield` "Full refund" at ≥24h,
coral `clock` "Late cancellation" at <24h.

The rule lives in **one** named helper — `entities/session/lib/refund.ts`,
`refundEstimate` — with its own test, exactly as the owner's decision required.
It mirrors the BFF's `refundForCancellation` **including the floor**: a half
refund of an odd number of cents keeps the odd cent with the house, and
rounding the friendlier way would quote a cent that never arrives.

The figure reads as an estimate ("about $96.00", plus "We'll confirm the exact
amount once the cancellation goes through"), and what is reported *afterwards*
is `CancelSessionResponse.refundedMinor` — the server's number — in an alert
raised once the sheet's modal is provably gone. A test proves the two are not
the same code path: it answers the cancel with a `refundedMinor` deliberately
different from the preview and asserts the alert names the server's figure.

### 5 · The two placeholders, retired

- `UpcomingSessionCard` now offers **Reschedule** (soft) + **Details**
  (primary), and the card itself opens detail.
- `SessionBanner`'s tap re-points from the block sheet to Session detail, and
  its sub-line changed from "tap to extend" to "tap for details" — the design's
  own wording. Extending is unaffected: it was always also on the chat header's
  "Extend +N min", which is now its single entry point.

## Judgment calls, and why

**Propagation on the card.** The spec asked for the two buttons to stop
propagation so they cannot double-fire the card tap. React Native has no
bubbling to stop — a press goes to the innermost view that claims it, so a
nested button never fires its parent, and `stopPropagation()` on the synthetic
event would be a call that reads like a guarantee and does nothing. The
requirement is met **structurally** instead: the pressable region covers the
hero and the body, and the footer buttons are its siblings. Same behaviour,
enforced by the tree rather than by a no-op.

**The current slot is not preselected in Reschedule.** The spec said preselect
day *and* slot. The session occupies its own slot, so availability reports it
taken, and `SlotGrid` renders a taken pill greyed and unpressable — a pill
rendered both "selected" and unpressable is a lie. The **day** is preselected
as drawn; the old time is stated in the "Current time" card and again in the
change preview, which is where the design puts it.

**"Will be notified" became "sees the new time on their side."** The BFF syncs
the desk's conversation attributes on a reschedule, so the chatter does see it;
it does not send a notification. Same discipline as `AURAT-0016` dropping the
reminder promise.

**One message for three server rules.** A reschedule 409 covers *inside the
4-hour cutoff*, *slot just taken* and *you already have a session then*, and
`BffApiError` carries the status alone by design (no response bodies in errors,
no PII). So the copy is true of all three and names the cutoff first, because
it is the only one the user could see coming. Same shape for cancel, whose 409
has one reachable cause: the session started.

**An Alert for the refund.** The design ends a cancellation on the Sessions
list with no receipt. The owner's decision requires the server's figure to be
reported, so the return trip raises one alert with it. It fires from
`onClosed` — the sheet's modal provably gone — because `AURAT-0020`.

## Two things fixed on the way

**`useBooking` was recording the wrong answer.** Its `answeredFor` ref was
initialised from *whatever `minutes` happened to be* on the first render after
availability landed, on the assumption that the opening parallel read had
answered for that duration. True on Book, where `minutes` is set *from* that
response; false on Reschedule, which knows the session's block from the start
and sets it first. The result was a grid answered for the server's **shortest**
block while the screen thought it was showing the session's — the exact
over-offering `AURAT-0024` made availability duration-dependent to prevent.
`answeredFor` now records the question that was actually asked, inside the
`.then` of the read that asked it. Book is unchanged; the bug was reachable
only by a caller that chooses a duration before the first response.

**A second, narrower window from the same place**: between the shortest-block
answer arriving and the correct one landing, the grid is live and wrong for a
whole round trip. `BookingState` gained `refreshing`, true while the grid is
being re-read for a different block; Reschedule shows a spinner for it. Book
ignores it, so its duration switch behaves exactly as before. One frame of the
stale grid can still be committed before the effect runs — a window too short
to tap in, and closing it properly means `useLayoutEffect` in a shared hook,
which is not worth it here.

Also fixed while in the file: `useBooking` now accepts `advisorId: string | null`
and reads nothing until it resolves. Reschedule mounts before it knows whose
session it is moving, and `/v1/advisors//sessions/pricing` answers 404 —
indistinguishable from "this advisor is not bookable", which is a lie the
screen would then have shown.

## Deduplication done rather than deferred

Build rule 4 forbids re-implementing a formatter that already exists elsewhere,
and this task needed two that existed twice already:

- `daysUntil` / `relativeDay` / `dayNumber` / `monthShort` → **`shared/lib/dates`**.
  `dayNumber`/`monthShort` had a copy under `screens/booking` and another under
  `screens/sessions`; `screens/booking/lib/dates.ts` is deleted.
- The facts-card row (ink-3 icon · ink-2 label · bold value · hairline) →
  **`shared/ui/DetailRow`**. Review and Session detail draw the identical row.
- `localDateKey` joined `features/booking/lib/slots`, which owns the
  `YYYY-MM-DD` day-key convention. Local, not UTC: availability is requested
  with the device's `tz`, so `toISOString().slice(0,10)` would open the strip on
  the neighbouring day for anyone far enough from UTC.

`repeat` and `trash` were ported into `shared/ui/AuraIcon` from the handoff's
icon set — the design names both for these two actions, and only the icons in
use had been ported before.

## Gates (slave-1)

- `npx tsc --noEmit` — clean
- `npx eslint .` — clean
- `npx jest` — **49 suites / 276 tests** (was 46 / 251)
- release Metro bundle (`--dev false`, android) — built

New tests: `refund.test.ts` (7, including the floor and the exact-24h
boundary), `SessionDetailScreen.test.tsx` (8), `RescheduleScreen.test.tsx` (7),
plus two on `SessionsScreen` for the retired placeholders. Three existing
assertions were updated to the new behaviour rather than deleted: the banner's
sub-line, its accessibility label, and the fact that tapping it no longer opens
the block sheet — that last one rewritten to pin the *header* as the sheet's
entry point, so `AURAT-0015`'s early-end coverage survives.

## Known, recorded rather than worked around

1. **No `GET /v1/sessions/:id`.** Detail and Reschedule read the list and find
   the id. Adding a single-session read belongs to the BFF; the same shape is
   already on its debt list (#12).
2. **Availability does not exclude the user's own session.** The occupancy read
   is advisor-wide, so the session's own slot — and anything overlapping it —
   reads as taken in the reschedule grid, even though `PATCH` excludes the
   session from its own overlap check and would accept it. Effect: a user
   cannot nudge a booking by ten minutes through the grid, though the server
   would allow it. Fixing it needs an `excludeSessionId` on the availability
   query, which is BFF work.
3. **A `cancel-preview` endpoint** would delete the client-side refund rule
   entirely. Recorded in `005`/`006` as a follow-up, not minted; worth taking
   the next time the refund policy changes.
4. **The cancel sheet unmounts if the session goes live under it** (the minute
   ticker flips `scheduled` → `active` and the refund estimate with it). Correct
   in substance — cancelling has just stopped being possible — but it
   disappears rather than explaining itself. Not seen as reachable in practice:
   it needs the sheet open across the exact minute the slot arrives.
5. **`UpcomingSessionCard` gained a bottom margin.** Upcoming is a list now that
   a user can hold several bookings, and two cards were rendering flush.
   Cosmetic, unverifiable in slave, flagged for the device pass.

## Device pass (manor, after merge)

Everything below needs client `BILLING_ENABLED` on, the BFF's own flag on, and
a booked slot from a funded wallet.

- Detail opens from all three entrances: the Sessions card, the chat banner
  while a session is live, and Booked's "View session".
- Back from detail lands on the **Sessions list** in every case, including when
  it was entered from the chat.
- Eyebrow colour and wording across the three states; the footer button counts
  down while live.
- Reschedule: the strip opens on the session's day; the grid is answered for
  the session's block (a 30-minute session must not be offered a gap that only
  fits 10); confirming moves it and the Sessions list shows the new time.
- Reschedule **inside 4 hours**: the screen still opens, and the refusal is
  shown rather than swallowed.
- Cancel ≥24h and <24h: the right tier, the balance credited, the session gone
  from Upcoming, and the alert naming the **server's** figure.
- A session that starts while the detail screen is open: the two actions
  disappear on the minute tick.
- The block sheet still opens from the chat header, and early-end still works
  from inside it.
