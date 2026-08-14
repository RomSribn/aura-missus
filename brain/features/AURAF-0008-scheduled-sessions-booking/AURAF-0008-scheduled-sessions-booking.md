# AURAF-0008 — Sessions & booking, design handoff round 2
Type: product
Status: in-progress — rows 001–005 shipped (`AURAT-0015`); rows 006–011 un-parked by
`AURAD-0009`, **server half shipped** (`AURAT-0018`, widened by `AURAT-0023`), app
half in flight (`AURAT-0016`/`AURAT-0017`/`AURAT-0022`/`AURAT-0024`); row 012 still
open
Priority: P1
Source spec: `.claude/design_handoff_aura/SESSIONS_BOOKING.md` (workspace, committed `a88cbb5`)

## What

Round 2 of the design handoff reworks the paid session end to end: it becomes a
**scheduled, prepaid, private chat slot** with its own booking flow (date strip →
slot grid → review → pay → confirmation), a detail screen with reschedule and
cancel, and — the half that changes what the user sees every session — a set of
**in-thread affordances** that make a running paid window legible: a live banner
under the chat header, system dividers in the transcript, session markers and
sorting in the chats list, and a header action that swaps to "Extend".

> **Superseded split.** `AURAD-0008` parked rows 006–012 for want of a PSP;
> `AURAD-0009` (ratified the same day) unparked them by paying the slot from the
> **wallet** instead of by card. Rows 006–007 are `AURAT-0016` (app, in flight)
> and `AURAT-0018` (BFF, shipped); 008–010 are `AURAT-0017`. The card rail became
> its own feature, `AURAF-0009`. The section below is kept as the record of why
> the split existed.

## Split by AURAD-0008 (owner-ratified 2026-08-14, option B)

Rows 006–012 assume scheduled, card-paid, refundable sessions, which **contradict
the ratified and already-shipped `AURAD-0002`** (instant blocks, prepaid from the
wallet, non-refundable once started). The owner kept `AURAD-0002` and **parked
those rows until a PSP exists** — the Review screen cannot be paid without one.

Rows 001–005 describe a session that is *running*, which is true under either
model, so they are independent of the conflict and are being built now as
**`AURAT-0015`**. Do not start 006–012 without a new decision.

## Scope

| # | Src | Own | App | UI | BE | Del | Item |
|---|-----|-----|-----|----|----|-----|------|
| AURAF-0008-001 | spec | ✓ | ✓ | ✗ | — |   | Session lifecycle helpers: `sessionState`/`minsLeft`/`activeFor`/`nextFor`, driven by the **server clock**, not the device |
| AURAF-0008-002 | spec | ✓ | ✓ | ✗ | — |   | `SessionBanner` under the chat header — live (plum, gold clock, mm:ss, teal progress bar) and starting-soon (≤ 24 h) variants, 1 s tick, tabular figures, tap → detail |
| AURAF-0008-003 | spec | ✓ | ✓ | ✗ | ✗ |   | System dividers in the transcript: `from:'sys'` (+ `tone:'teal'`), "PAID SESSION STARTED · N MIN" / "SESSION ENDED", persisting in scroll-back |
| AURAF-0008-004 | spec | ✓ | ✓ | ✗ | — |   | Chats list: session markers (teal live pill / quiet scheduled line), threads with a session sort to the top, `sys` preview renders as "— {text}" |
| AURAF-0008-005 | spec | ✓ | ✓ | ✗ | — |   | Chat header action swaps "Book now" → "Extend +15 min" while live |
| AURAF-0008-006 | spec | ✓ | ✓ | ✗ | ✓ |   | Book a session: advisor card, static chat-format card, duration, `DateStrip` (14 d), `SlotGrid`, sticky total |
| AURAF-0008-007 | spec | ✓ | ✓ | ✗ | ✓ |   | Review + payment + "Booked" confirmation (`lock` CTA, first-session credit, card vs balance rows) |
| AURAF-0008-008 | spec | ✓ | ✓ | ✗ | ✗ |   | Session detail: state-coloured hero eyebrow, detail rows, one always-enabled "Open chat" footer |
| AURAF-0008-009 | spec | ✓ | ✓ | ✗ | ✗ |   | Reschedule with the change preview + the 4-hour policy |
| AURAF-0008-010 | spec | ✓ | ✓ | ✗ | ✗ |   | Cancel sheet, both refund variants driven by `hoursUntil` — **mirrored server-side** |
| AURAF-0008-011 | spec | ✓ | ✓ | ✗ | ✓ |   | Real availability + pricing API replaces the deterministic slot stub |
| AURAF-0008-012 | spec | ✓ | ✓ | ✗ | — |   | Local notification 30 min before + "Add to calendar" — **also owns the copy `AURAT-0016` removed**: the Booked screen's "We'll remind you 30 minutes before" + its calendar button, and the Upcoming card's "Reminder set · 30 min before". They were promises with no mechanism behind them, so they come back with this row |

`Own` = owned by this feature. `UI`/`BE` track what is actually built; all rows
start `✗`. `—` = not applicable to that side.

`BE` on rows 006 / 007 / 011 is the BFF half shipped by **`AURAT-0018`**
(availability, pricing, booking with an up-front wallet debit, reschedule,
cancel with refund tiers, sessions list) and widened by **`AURAT-0023`**
(occupancy became an interval, so a session can start **now** and availability
answers per duration — `AURAD-0009`, second amendment). The app halves of 006 /
007 are `AURAT-0016` / `AURAT-0022`, and the instant path's app half is
`AURAT-0024`.

## NOT in scope

- **Voice / video.** Removed from the product entirely — `Session.type` is always
  `'Chat'`; the `video` and `mic` icons ship unused. This *confirms* `AURAD-0001`.
- **A separate session room or a join step.** The thread is the session surface;
  entry is never gated. The old disabled "Chat opens 5 min before" button is gone.
- **PSP integration.** Still the `AURAF-0007` boundary. `AURAD-0009` took it off the
  critical path entirely: the slot is paid from the wallet, so the Review screen
  works today and the card rail becomes a later addition to it — its own feature,
  `AURAF-0009`, rather than a prerequisite for this one.

## Context found

- **Ground truth — the app already ships paid sessions** (`AURAT-0010`):
  `features/paid-session` (block picker, wallet pre-check, `idempotencyKey`,
  countdown from `endsAt`, extend prompt, early finish with a forfeit warning),
  `entities/wallet`, red markers from `direction:'system'`, all behind a client
  `BILLING_ENABLED` flag. The BFF half is `AURAT-0008`.
- **Two session shapes exist in the app right now.** `entities/session` still
  holds the pre-BFF seed model — `UpcomingSession.kind` is documented as
  `"1:1 video"`, a format the product no longer has — while the live flow uses
  `Session` from `@aura/contracts`. `screens/sessions` (`AURAF-0006`) renders the
  seed one. Collapsing these is a prerequisite for rows 006–010.
- **The dividers are half-built.** `AURAT-0010` already renders red markers from
  BFF-stored `direction:'system'` messages; row 003 is a restyle to the handoff's
  hairline/label/hairline form plus the teal tone, not new plumbing.
- `@aura/contracts` is on **v0.6.0**, cut in three steps as the server was built:
  v0.5.0 the `AURAD-0009` boundary (`SCHEDULED`/`CANCELLED`, `startsAt` beside a
  nullable `startedAt`, reschedule/cancel/list/availability, the per-duration
  pricing breakdown), v0.5.1 the typed availability query with the `tz` param
  `AURAT-0018` had flagged, v0.6.0 the instant path and availability that knows the
  duration (`AURAT-0023`). The BFF mirrors it by hand (`TECH-DEBT #11`).

## Resolved questions

1. **`AURAD-0008`** — resolved by **`AURAD-0009`**: scheduled + **wallet** +
   refundable-before-start; the card rail waits for a PSP as `AURAF-0009`.
   `AURAD-0009`'s **second amendment** (`AURAT-0023`) then brought the instant path
   back: occupancy is an interval, so a session may start *now* — unaligned, exempt
   from the lead time, created `ACTIVE`, and therefore neither cancellable nor
   reschedulable. Scheduled and instant now coexist; only the `AURAT-0010` block
   picker stayed retired.
2. **The −$5.00 first-session credit is a discount on the charge**, not a ledger
   credit (`AURAT-0018`). If it were money in the wallet, book → cancel → refund
   would hand the user $5 of real balance per cycle; as a discount, a refund can
   only ever return what was actually taken. `SessionPricing` carries
   `subtotalMinor` / `creditMinor` / `costMinor` per duration, and the session row
   keeps `creditMinor` as the audit trail of a discount that leaves no ledger row.
   **`AURAT-0023` closed the remaining loop**: the credit is spent when *consumed*,
   not merely when booked, so cancelling no longer hands it back (owner decision).
3. **The pricing endpoint stays the source.** `advisors.priceMinorPerMinute` is the
   only price authority (`AURAT-0008` D1); the handoff's `advisor.price × mins` is a
   prototype convenience and the app never recomputes a total.
4. **The sessions-list gap was real and is closed**: `GET /v1/sessions` returns every
   session of the caller, newest slot first, all advisors, all statuses
   (`AURAT-0018`). It is a different gap from `GET /v1/conversations`
   (BFF `TECH-DEBT #12`), which stays open.

## Open questions

1. Row 012 (30-minute reminder + add-to-calendar) is untouched: local notification
   only, or a server-side push? The BFF sends no session reminders today.
2. The booking horizon exists twice — a literal `max(14)` in the contract's
   availability query, and `SESSION_BOOKING_HORIZON_DAYS` on the server. They agree
   at 14 today; whichever one moves first breaks the other (BFF `TECH-DEBT #15`).
