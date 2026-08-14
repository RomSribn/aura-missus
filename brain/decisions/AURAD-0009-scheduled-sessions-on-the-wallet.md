# AURAD-0009 — Sessions become scheduled slots, still paid from the wallet

Date: 2026-08-14
Status: accepted (**owner-ratified 2026-08-14**)

**Supersedes `AURAD-0008`.** **Amends `AURAD-0002` in part.**

## Decision

A paid session becomes a **scheduled, prepaid, private chat slot**, exactly as
design handoff round 2 draws it — date strip, slot grid, review, confirmation,
detail, reschedule, cancel. The owner asked for the design as drawn.

**It is paid from the prepaid USD wallet, not by card.** The design's Review
screen defaults to a card (Visa ···· 4242) and renders "Aura balance" disabled;
that is inverted here. The card rail needs a PSP, which still does not exist, and
a Review screen that cannot be paid is a flow that can be started but never
finished. The wallet rail is shipped, metered and ledgered today (`AURAT-0007`,
`AURAT-0008`), so every screen in the round can be completed now.

That single substitution is what makes this decision buildable, and it is the
only place the implementation departs from the design.

## What changes against `AURAD-0002`

| | `AURAD-0002` (as shipped) | This decision |
|---|---|---|
| When it starts | immediately on booking | at the **booked slot** |
| Paid with | USD wallet | **USD wallet** (unchanged) |
| Refunds | none — non-refundable once started | **≥24h → full, <24h → half**, credited back to the balance, and only **before it starts**; once running, `AURAD-0002`'s rule still holds |
| Change | book another block | **reschedule free up to 4h before** |
| Discount | none | flat **−$5 first-session credit**, computed server-side |

## What survives unchanged

- The wallet is the only money source; the ledger stays append-only and
  balance = Σ credits − Σ charges.
- The session runs **inside the same durable thread** (`AURAD-0003`), chat-only
  (`Session.type` is always `'Chat'`), with no join step and no separate room.
- Boundaries are still BFF-authored system messages, which the app renders as
  the transcript dividers (`AURAT-0015`).
- Everything stays behind `billing_enabled` on both sides.
- **The app never invents a price, a block size or a discount** (`AURAT-0008`
  D1). The −$5 credit and the slot's total are server figures the app displays;
  the design's `advisor.price × mins − 5` is a prototype convenience, not the
  contract.

## Consequences

**BFF (`AURAT-0018`, executes in `aura-bff-manor`)** — the larger half:

- `Session` gains a scheduled state and a `startsAt` in the future; the meter
  transitions `SCHEDULED → ACTIVE` at that moment and posts the "started" marker.
  Today a session is created already `ACTIVE`.
- Slot availability becomes a real read; the design's deterministic stub
  (`(dayIndex*7 + slotIndex) % 5 === 0`) is a prototype device and ships nowhere.
- Reschedule (patch `startsAt`, refuse inside 4h) and cancel.
- **A credit direction in the ledger.** This is new: `AURAT-0008` deliberately
  has no refund path, because nothing was refundable. Cancellation now moves
  money back, so it needs the same locked-transaction discipline the debit has,
  and a full-vs-half figure the **server** computes.
- The clock stays the server's, per `AURAF-0008-001`.

**App (`AURAT-0016`, `AURAT-0017`)**:

- `sessionState` gains **`'scheduled'`** — deliberately left out by `AURAT-0015`
  as unreachable, with a note that it arrives "together with the flow that can
  produce it". This is that flow.
- The `SessionBanner`'s **starting-soon variant** (≤24h) becomes reachable and
  is built; same for the chats-list "Session tomorrow · 15:00" marker.
- `entities/session`'s pre-BFF seed model is retired (its `kind: "1:1 video"`
  describes a format the product does not have), and the Sessions tab renders
  real sessions — the finding recorded in `AURAT-0021-001-check.md`.
- The Sessions tab's history needs a **sessions list read**, which the BFF does
  not expose today (only `pricing` and `active`). It belongs to `AURAT-0018`.

## Resolved: instant booking does **not** survive

The owner chose the design's single path. "Book now" leads to the booking flow
and nowhere else; the instant block picker is **removed**.

Recorded plainly, because it retires working code: `AURAT-0010` built the
instant block and it was device-verified, and `AURAD-0002` called free
re-engagement plus instant blocks the growth loop. That loop now rests on free
chat alone, which stays instant and unmetered — only *paid* time becomes
scheduled.

The consequence to expect on device: the soonest a user can pay for time is the
next free slot, and by the design's own rule any slot inside the next **30
minutes** counts as past. Someone who wants paid attention immediately cannot
buy it. If that turns out to be wrong in the market, this is the line to revisit
— it is a product choice here, not a technical constraint.

**Extend is unaffected.** Adding minutes to a session that is already running is
a different act from booking one, and the block sheet keeps serving it.

## Progress

**`@aura/contracts` v0.5.0 published 2026-08-14** (`0c1b9ac`, tag `v0.5.0` on
`git@github.com:RomSribn/aura-contracts`) — the app↔BFF boundary for this
decision, so both sides build from one shape:

- `SessionStatus` gains `SCHEDULED` and `CANCELLED`.
- `Session.startsAt` (the booked slot, always present) is split from
  `startedAt` (the server's clock at the moment the meter began, **null while
  scheduled**). One field used to mean both.
- `BookSessionRequest` carries `startsAt` beside `minutes`; `ExtendSessionRequest`
  keeps its own shape without a slot, since extend is untouched by this decision.
- `RescheduleSessionRequest` patches `startsAt`; `CancelSessionResponse` answers
  with `refundedMinor` + the new balance — **the server computes the policy**,
  the app only renders it. Cancelling an already-started session must be
  refused (409), never refunded at zero.
- `AvailabilityResponse` returns whole days including full ones, so a date strip
  can show a day as taken rather than hide it. **A slot is an offer, not a
  reservation** — the server re-checks `startsAt` and `minutes` at booking,
  because a slot can be taken between the read and the tap.
- `SessionPricing.blocks` gained `subtotalMinor` / `creditMinor` / `costMinor`
  per duration: the first-session credit is flat, not proportional, so no
  block's total may be derived from another's.
- `SessionsResponse` (`GET /v1/sessions`) is the list the Sessions tab needs and
  the app has never had.
- `session.updated` needed no shape change but now also carries the
  `SCHEDULED → ACTIVE` transition the meter makes by itself.

**v0.5.1 published 2026-08-14** (`9ee43b2`, tag `v0.5.1`) — answers the open item
`AURAT-0018-005` flagged for the app manor. The availability endpoint's optional
`tz` was added after v0.5.0 was cut, so it existed only in prose: now
`AvailabilityQuery { days, tz }` types it, the way `HistoryQuery` already types
history's. **`tz` decides only which day a slot is filed under, never when it
happens** — the grid stays UTC-anchored because occupancy is global (O2) and
every client must mean the same instants. Without it a user hours from
`SESSION_SLOT_TIMEZONE` sees evening slots under the neighbouring day, so
`AURAT-0016` sends the device zone. Additive; a client that sends nothing keeps
the server defaults. **`AURAT-0018` should move its dependency to `v0.5.1`.**

### Sequencing — the two halves must land together

`AURAT-0018-005` §6 puts it plainly: `POST advisors/:id/sessions` gains
`startsAt`, and *"this is where instant booking dies"*. The consequence runs
both ways, and neither manor can fix it alone:

- BFF merges first → the app's shipped block picker sends no `startsAt` and gets
  **400**; paid booking is broken on `develop` until the app catches up.
- App merges first → the booking screens send `startsAt` to a server that does
  not understand it yet.

So `AURAT-0016` and `AURAT-0018` merge in **one window**, and the device pass is
only meaningful after both. Whoever is ready first waits at the merge gate.

## Why it matters

`AURAD-0008` chose to defer this whole half **because it required a PSP**. That
premise is what changed: paying the slot from the wallet removes the PSP from
the critical path entirely, and leaves it as a later addition to the Review
screen rather than a prerequisite for it.
