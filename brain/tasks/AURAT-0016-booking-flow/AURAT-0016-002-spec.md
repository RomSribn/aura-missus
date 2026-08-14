# AURAT-0016-002 — Spec

Date: 2026-08-14
Status: **awaiting owner approval — no code written**
Contract: `@aura/contracts` v0.5.1 (binding) · Server: `AURAT-0018` (binding)

## Goal

Book a paid session as a **scheduled slot**, per design screens 20 · 21 · 22,
paid from the wallet (`AURAD-0009`). Retire the instant block picker and the
pre-BFF seed session model with it.

## Scope

### 1 · A booking stack above the tabs

`RootStackParamList` gains `BOOKING`, a stack beside `MAIN` holding **Book →
Review → Booked**. One definition for a flow entered from three tabs, the tab
bar hidden by construction, and back returns to the tab that sent the user.
Params carry `advisorId`; Review additionally carries the chosen `startsAt` and
`minutes`, so no screen has to re-derive another's choice.

### 2 · `features/booking` (new slice)

Booking is a user interaction over an entity, not an entity: `api/booking-api`
(availability, pricing, book), `model/use-booking` (the whole selection state
machine), `lib/` for slot grouping and labels, `ui/` for `DateStrip`,
`SlotGrid`, `DurationPicker`.

`features/paid-session` keeps the **running** session — banner, countdown,
extend. Its `SessionBlockSheet` loses `book` mode and keeps `extend`; the
`'book'` `PickerMode`, `openPicker` and their tests go with it.

**Availability is read once per advisor**, not per duration — the server's grid
is duration-independent (`AURAT-0018` §2). The device's IANA zone goes in `tz`
on every read, or days land under the server's zone (contract, v0.5.1).

### 3 · Book (screen 20)

Advisor card · format card · durations **from `pricing`** · 14-day `DateStrip`
· `SlotGrid` from `availability` · sticky footer with the running total and
"Pick a time" → "Review booking".

Changing the date clears the slot. Unavailable slots are rendered and not
pressable — the design's own rule, and it is also what stops the app inventing
a lead-time rule the server owns.

### 4 · Review (screen 21)

Summary · price breakdown straight from `pricing`
(`subtotalMinor` / `creditMinor` / `costMinor` — never recomputed) · payment ·
policy note · `lock` + "Confirm & pay".

**Payment section, inverted from the design:** the balance row is live and
selected; the card row renders **disabled, marked "Soon"**, exactly as the
option the owner picked showed it.

**When the balance is short** — a state the design never drew, because there the
card always covers — the primary button becomes **"Top up to book"** and leads
to Profile → Top Up. It does not book and fail: a 402 after a confirmation tap
is a worse way to learn you have no money. The wallet is read at entry and on
focus (`AURAT-0019` made it one store, so the figure agrees with Profile).

**Confirm runs the charge before navigating**, spinner on the button, errors
inline:

| Server | What the user sees |
|---|---|
| 409 slot taken | "That time was just taken." → back to Book with availability re-read |
| 402 | the top-up route above |
| 400 | "That time is no longer bookable." → re-read |
| network / 5xx | retry with **the same idempotency key** (`AURAT-0010`'s rule — an unknown outcome must never charge twice) |

### 5 · Booked (screen 22)

Teal orb, details card, and a footer — see the open question about what that
footer may honestly say.

### 6 · Sessions tab on real data

`entities/session`'s seed constants and its `kind` are **deleted**; the tab
reads `GET /v1/sessions` and splits Upcoming (`SCHEDULED` + `ACTIVE`) from Past
(`FINISHED`). Cards follow the design; the fake **Reschedule / Join** buttons go
— reschedule arrives with `AURAT-0017`, and there is nothing to join.

Rows tap into the chat thread for now; Session detail is `AURAT-0017`.

## Out of scope

Session detail, reschedule, cancel (`AURAT-0017`) · local notifications and
add-to-calendar (`AURAF-0008-012`) · the card rail · `GET /v1/conversations`.

## Acceptance

- A slot booked in the app appears in the Sessions tab, in Chatwoot's attributes,
  and starts by itself at its time with the divider in the thread.
- Durations and every figure come from the server; nothing is recomputed.
- A slot taken between reading and confirming produces a plain message and a
  fresh grid, never a double charge.
- An unaffordable slot routes to Top Up instead of failing at the charge.
- Nothing renders with `BILLING_ENABLED` off.
- Slave gates green: tsc / eslint / jest.

## Open questions

**Q1 · The Booked screen promises a reminder this task cannot send.**
"We'll remind you 30 minutes before" and the "Add to calendar" button are
`AURAF-0008-012`. Options: (a) drop both from the copy and the footer until 012
ships; (b) keep the layout and ship 012's local notification inside this task
(scope grows, and it needs a permission prompt); (c) keep the copy and accept
that it is currently untrue.
**Recommendation: (a)** — the Upcoming card's "Reminder set · 30 min before"
goes the same way. A promise the product does not keep is worse than a plainer
confirmation screen, and 012 can add both back in one pass.

**Q2 · Does the disabled "Visa ···· 4242 — Soon" row stay on Review?**
It was in the option you picked, so it is specced in. But it advertises
something no one can use yet.
**Recommendation: keep it** — it explains why we are asking about balance at all,
and it is one line to delete if it reads as noise on device.

## Next

`003-approval.md`, then execution.
