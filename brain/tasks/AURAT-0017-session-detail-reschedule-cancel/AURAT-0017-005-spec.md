# AURAT-0017-005 — Spec

Date: 2026-08-14
Feature: `AURAF-0008` rows 008–010
Slave: slave-1, `feature/AURAT-0017-session-detail-reschedule-cancel` off
develop `20d2467`
Status: **awaiting owner approval — no code written**

## Goal

Give a booked session a screen, and from it the two things possible before it
starts: move it, or cancel it for a refund.

## Scope

### 1 · Navigation (prerequisite)

Add `SESSION_DETAIL` (`{ sessionId }`) and `RESCHEDULE` (`{ sessionId }`) to the
shared nav contract. **Put them in the Sessions stack, not the booking stack** —
detail is reached from the Sessions tab and the chat banner far more often than
from a fresh booking, and back from detail should land on the Sessions list, not
inside a booking flow the user already finished. The Booked screen's
"View session" jumps across to it, which is what the handoff draws anyway.

### 2 · Session detail (row 008)

New `screens/session-detail`. Plum hero, eyebrow carrying the state from
`sessionState`: gold relative day when `scheduled`, teal
"IN PROGRESS · N MIN LEFT" when `active`, gold "COMPLETED" when `ended`. Advisor
row with ringed avatar, start time large, end time after it.

Detail rows: Date · Time (with duration) · Format ("Private chat") · **Paid**.
Paid renders `costMinor` and says it came from the balance — `AURAD-0009` pays
from the wallet, so the design's card wording does not apply. No
first-session-credit row: it is not in `Session`, and inventing it would be the
same error `AURAT-0016` avoided with the duration picker.

Footer: **one** always-enabled button — "Open chat", or "Open session chat ·
N min left" while live. No join gating, no second Message button.

Reschedule (soft, `repeat` icon) and Cancel (borderless coral, `trash`) show
only while the session is `scheduled`; an `active` or `ended` session offers
neither, since both are refused server-side.

### 3 · Reschedule (row 009)

New `screens/reschedule`, **reusing `features/booking`'s `DateStrip`, `SlotGrid`
and `use-booking`** — not a second copy. Preselect the session's current day and
slot. Availability is queried with the session's own `bookedMinutes`, because
under interval occupancy the answer moves with the block (`AURAT-0024`).

Change preview appears only once the pick differs: old slot struck through in
ink-3 → `chev` → new slot in teal.

The **4-hour rule is the server's**. Show it as the note the design specifies;
do not hide or disable the entry on a client-side estimate — let `PATCH` refuse
and surface that refusal. A 409 (slot taken) reuses the message path
`use-booking-confirm` already owns.

### 4 · Cancel sheet (row 010)

On the existing shared `BottomSheet`. Two tiers driven by hours until start:
teal `shield` "Full refund" at ≥24h, coral `clock` "Late cancellation" at <24h.

**The figure shown before confirming is a display-only preview** computed from
`costMinor` and the documented rule (full, or half rounded the server's way),
clearly derived from data the app already has. The **server's `refundedMinor`
is authoritative** and is what gets reported after the call; if the two differ,
the server's wins and the difference is a bug to file, not to paper over.

This is the one place the app touches refund arithmetic, and it does so only to
render a preview the contract has no endpoint for. Recorded as a follow-up:
a BFF cancel-preview would remove the duplication entirely — see open question.

Confirming cancels, credits the balance, pops to the Sessions list. A session
that started is refused (409) — surface it rather than pretending.

### 5 · Wiring up the loose ends `AURAT-0016`/`0015` left

- `UpcomingSessionCard` gains **Reschedule** (soft) + **Details** (primary),
  both stopping propagation so they do not double-fire the card tap; the card
  itself opens detail.
- `SessionBanner`'s `onPress` re-points from the block sheet to Session detail,
  as `AURAT-0015` recorded it would.

## Out of scope

Reminders / add-to-calendar (row 012), the card rail (`AURAF-0009`), anything
about a **running** session's money — early end stays `finishSession` and stays
non-refundable per `AURAD-0002`.

## Acceptance

- A scheduled session opens from the Sessions card, the chat banner and Booked.
- Reschedule moves a slot and the Sessions list shows the new time; inside 4h
  the server refuses and the user is told why.
- Cancel shows the right tier for the time remaining, credits the balance, and
  the session leaves Upcoming.
- A started session offers neither action and refuses if forced.
- Everything stays invisible with `BILLING_ENABLED` off.
- Slave gates green: tsc / eslint / jest.

## Resolved by the owner (2026-08-14)

**The refund preview is computed on the client**, as specified in §4 above: the
sheet derives the figure from `costMinor` and the documented ≥24h / <24h rule so
the screen ships now, and the server's `refundedMinor` stays authoritative for
what actually happened. No BFF preview endpoint is minted.

Two things this obliges:

1. The rule lives in **one** place — a named helper in `entities/session/lib`
   beside `session-state.ts`, not inline in the sheet — so the day the server's
   policy changes there is a single site to fix and a test that names it.
2. The preview must be **visibly a preview**. If the server's `refundedMinor`
   comes back different, the app reports the server's number; it never shows the
   estimate as the outcome. A mismatch is a defect to file, not to smooth over.

Recorded as a follow-up, not minted: `GET /v1/sessions/:id/cancel-preview` would
delete this duplication, and should be considered when the refund policy next
changes.
