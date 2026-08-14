# AURAT-0016-001 — Check existing state

Date: 2026-08-14
Slave: slave-1, `feature/AURAT-0016-booking-flow` off develop `057bac2`
Decision: `AURAD-0009` · Feature: `AURAF-0008` rows 006–007 (app half)
Contract: `@aura/contracts` **v0.5.1** (`9ee43b2`, tagged) — binding
Server half: `AURAT-0018`, in flight in `aura-bff-manor`; its `005-spec` is read
and binding on the app where it decides behaviour.

## What exists

- **`features/paid-session`** — the instant flow: `SessionBlockSheet` (book +
  extend modes), `usePaidSession`, the banner, the countdown from `endsAt`.
  `AURAD-0009` **removes booking from it** and leaves extend untouched.
- **`entities/session`** — still the pre-BFF seed (`UPCOMING_SESSIONS`,
  `PAST_SESSIONS`, `kind: "1:1 video"`). To be retired.
- **`screens/sessions`** — renders those constants through a `SegmentedControl`.
- **Navigation** — the root stack holds `SPLASH / ONBOARDING / AUTH / MAIN`;
  per-tab stacks live under `MAIN`. There is no place for a pushed flow above
  the tabs yet.

## What the design needs (screens 20 · 21 · 22)

Book (advisor card, format card, 3 durations, 14-day `DateStrip`, `SlotGrid`,
sticky total) → Review (summary, price breakdown, payment, policy note) →
Booked (teal orb, details card, add-to-calendar + view-session).

## Findings that shape the spec

**1 · The flow is reachable from three different tabs.** Advisor profile
(Advisors stack), chat header (Chats stack) and the Sessions tab all lead into
it. Duplicating three screens into three stacks triples the route table for one
flow. The design says these are *pushed screens with the tab bar hidden*, which
is exactly a **root-level stack beside `MAIN`** — one definition, and back
returns to whichever tab sent the user.

**2 · Durations come from the server, and they are not the design's.**
`AURAT-0018` keeps `SESSION_BLOCK_MINUTES` at 10/20/30 under a boot check that
every block ≤ the 30-minute slot step; the design draws 30/45/60. The screen
must render whatever `pricing` returns (`AURAT-0008` D1), so this is not an app
bug — but the mock will not match the device, and a 60-minute block requires the
*server's* grid step to grow, which halves slot density. Owner's call, not
this task's.

**3 · Two promises the design makes that this task cannot keep.** The Booked
screen says "We'll remind you 30 minutes before" and offers "Add to calendar";
the Upcoming card says "Reminder set · 30 min before". Local notifications and
calendar are **`AURAF-0008-012`**, out of scope here. Shipping the copy without
the mechanism tells the user something untrue. Raised in `002-spec.md`.

**4 · The payment section inverts.** The design defaults to a card and renders
"Aura balance · not enough" disabled. `AURAD-0009` makes the wallet the rail, so
the balance row is the live one. What happens when the balance *is* short is a
real flow the design never drew, because in it the card always covers.

**5 · Booking gains a failure the instant flow never had: 409 slot taken.**
Availability is an offer, not a reservation (`AURAT-0018` §1–2), so the slot can
go between reading it and confirming. The app must re-read and say so, not
retry blindly.

**6 · Sequencing is fixed and mutual.** `AURAT-0018` §6 kills instant booking
server-side (`POST advisors/:id/sessions` requires `startsAt`). Whichever half
merges first breaks paid booking on `develop`, so the two merge in one window —
recorded in `AURAD-0009`.

## Next

`002-spec.md`.
