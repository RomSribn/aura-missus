# AURAF-0008 — Sessions & booking, design handoff round 2
Type: product
Status: in-progress (rows 001–005) — rows 006–012 **parked per `AURAD-0008` option B**
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
| AURAF-0008-006 | spec | ✓ | ✓ | ✗ | ✗ |   | Book a session: advisor card, static chat-format card, duration, `DateStrip` (14 d), `SlotGrid`, sticky total |
| AURAF-0008-007 | spec | ✓ | ✓ | ✗ | ✗ |   | Review + payment + "Booked" confirmation (`lock` CTA, first-session credit, card vs balance rows) |
| AURAF-0008-008 | spec | ✓ | ✓ | ✗ | ✗ |   | Session detail: state-coloured hero eyebrow, detail rows, one always-enabled "Open chat" footer |
| AURAF-0008-009 | spec | ✓ | ✓ | ✗ | ✗ |   | Reschedule with the change preview + the 4-hour policy |
| AURAF-0008-010 | spec | ✓ | ✓ | ✗ | ✗ |   | Cancel sheet, both refund variants driven by `hoursUntil` — **mirrored server-side** |
| AURAF-0008-011 | spec | ✓ | ✓ | ✗ | — |   | Real availability + pricing API replaces the deterministic slot stub |
| AURAF-0008-012 | spec | ✓ | ✓ | ✗ | — |   | Local notification 30 min before + "Add to calendar" |

`Own` = owned by this feature. `UI`/`BE` track what is actually built; all rows
start `✗`. `—` = not applicable to that side.

## NOT in scope

- **Voice / video.** Removed from the product entirely — `Session.type` is always
  `'Chat'`; the `video` and `mic` icons ship unused. This *confirms* `AURAD-0001`.
- **A separate session room or a join step.** The thread is the session surface;
  entry is never gated. The old disabled "Chat opens 5 min before" button is gone.
- **PSP integration.** Still the `AURAF-0007` boundary — but note that under
  `AURAD-0008` option A the Review screen cannot function without one.

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
- `@aura/contracts` is on **v0.4.0**.

## Open questions

1. **`AURAD-0008`** — scheduled+card+refundable, or instant+wallet+non-refundable?
   Everything below 006 depends on it.
2. Does the −$5.00 first-session credit come from the wallet ledger (a real
   ledger direction) or is it a display-only discount on the charge?
3. The handoff prices in **`advisor.price × mins`** with no mention of the BFF's
   `advisors.priceMinorPerMinute` authority (`AURAT-0008` D1: no row = not
   bookable, no default). Confirm the pricing endpoint stays the source.
4. `nextFor`/`activeFor` need the **whole** session list per advisor; the app has
   no `GET /v1/conversations` yet (BFF `TECH-DEBT #12`) — check whether a
   sessions-list endpoint is a separate gap.
