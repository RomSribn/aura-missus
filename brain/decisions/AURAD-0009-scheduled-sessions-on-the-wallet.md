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

### Amended 2026-08-14 — a fast path comes back, as the *nearest slot*

Seeing the flow, the owner asked for "Book now" to be quick again: a sheet that
books the soonest free time in one tap, with a way through to the full grid, and
the grid itself starting at the next usable hour instead of spending its space
on the morning that has already passed.

This walks back part of the resolution above, and the reason it can be walked
back cheaply is that it is **not** the instant block returning. Nothing about
the model changes: the session is still a scheduled slot, still paid from the
wallet, still started by the server's meter. What changes is how far away the
soonest slot is allowed to be.

- **`SESSION_SLOT_LEAD_MINUTES` moves to 0** — a config value, no server code
  (`AURAT-0018`'s env schema already allows it). The soonest bookable slot
  becomes the next grid point rather than one a half-hour out.
- **The label stays honest.** Even at lead 0 the grid is anchored to 30-minute
  UTC boundaries, so "the soonest" can still be 29 minutes away. The sheet says
  *"15:30 · in 12 min"*, never "Now" — a button that says now and means later is
  the failure this whole decision was written to avoid.
- **A true start-this-second is still server work** and is not being taken:
  bookings are validated as on-grid, and advisor occupancy is a unique index on
  the aligned `startsAt`, so an unaligned session would need occupancy by
  overlap instead of by equality. If the market says a half-hour wait is too
  long, that is the task to mint.
- The lead time is what gives a chatter warning that someone is coming. At 0
  there is none; 5 minutes is the obvious compromise if that turns out to
  matter operationally.

App side: `AURAT-0022`.

### Amended again 2026-08-14 — a session may start *now*, and occupancy becomes an interval

The first amendment bought a shorter wait and said a true start-this-second was
server work "not being taken". The owner has now taken it: **starting now is
what the product needs**, and half an hour of dead time before a paid
conversation is the wrong thing to ask of someone who came to talk.

The blocker was never the lead time. It is that occupancy is an **equality**:
`UNIQUE (advisorId, startsAt)` on a grid-aligned instant, which is only sound
while one booking fills exactly one cell — hence the boot check refusing any
block longer than the step. A 10-minute grid with 30-minute sessions is not a
tuning mistake under that model, it is an unsound grid, and the service is
right to refuse it.

**So occupancy becomes an interval.** A session is `[startsAt, endsAt)`, and
"is this free" becomes "does anything of this advisor's overlap it". Three
things follow, and they are the whole change:

1. **`startsAt` no longer has to be aligned**, so `startsAt = now` is a valid
   booking and "Book now" starts a session immediately — the instant block, but
   inside the scheduled model rather than beside it.
2. **The grid step stops being tied to block length.** Whatever step the "pick a
   time" screen uses is a display choice; 10 or 15 minutes become possible with
   30-minute sessions.
3. **Availability becomes duration-dependent.** A gap can fit ten minutes and
   not thirty, so the read must be told how long the session is.

What must not be lost is the **double-booking guarantee**, which is the most
safety-critical thing the BFF owns. It does not rest on the index alone: every
booking transaction already takes `SELECT … FOR UPDATE` on the advisor row,
precisely so two clients racing one slot are serialized. An overlap query
inside that lock is as sound as the equality was; the DB-level belt, if wanted,
is an `EXCLUDE USING gist` constraint rather than a unique index.

**A trap worth naming before it is built:** the lead time currently rejects any
start inside `now + SESSION_SLOT_LEAD_MINUTES`, which would reject `now` itself.
The lead protects a chatter from a slot appearing under them with no warning —
that reasoning applies to *picking a future slot*, not to a user saying "I am
here, start it". The instant path has to be exempt, or the lead has to be zero,
and the first is the honest reading.

Tasks: **`AURAT-0023`** (BFF, executes in `aura-bff-manor`) and
**`AURAT-0024`** (app). `AURAT-0018`'s grid tests are written against equality
and will need rewriting against intervals — that, not the query, is the bulk of
the work.

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

**v0.6.0 — shape agreed 2026-08-14 (`AURAT-0023`), not yet cut.** The second
amendment's contract, owner-approved before either side built, so the two manors
cannot drift while `AURAT-0024` waits. The package is minted in `aura-app-manor`;
the BFF implements the same shape in its mirror (`TECH-DEBT #11`) and pins it in
`session.spec.ts`. Full write-up:
`tasks/AURAT-0023-bff-instant-and-overlap/AURAT-0023-007-contract.md`.

- `BookSessionRequest` gains **`startNow`** and makes `startsAt` optional —
  **exactly one of the two**, both or neither is a 400. "Now" travels as an
  intent, never as a client timestamp: the server compares a slot to its own
  clock when it processes the request, so a client-sent `now` is already in the
  past on arrival (watched failing in the manor at `lead = 0`). A missing
  `startsAt` is deliberately not read as "now" — that would turn a forgotten
  field into a charged, running session. The instant path is exempt from grid
  alignment and from the lead time, and answers `status: 'ACTIVE'`, so it is
  neither cancellable nor reschedulable.
- `AvailabilityQuery` gains **`minutes`** (optional; the server answers for its
  shortest block when omitted): under interval occupancy a gap can fit ten
  minutes and not thirty, so the read must be re-run when the duration changes
  and the selected slot cleared with it.
- `AvailabilityResponse` gains **`instantAvailable`** — whether a session of
  that duration could start this second. The app owns neither the clock
  (`AURAF-0008-001`) nor any view of other clients' bookings, so without it the
  quick sheet offers a "Now" that 409s, which is the failure the first amendment
  refused to ship.
- Everything else is byte-identical to v0.5.1; additive throughout, so a v0.5.x
  client keeps working and the two halves can merge in one window.

**One behaviour change with no shape change:** the flat first-session credit is
now spent when it is **consumed**, not when a session is completed — cancelling a
first booking no longer hands it back (owner decision, `AURAT-0023`). The credit
clamps to the subtotal, so a block cheaper than $5 is free, and eligibility used
to return with a cancellation: book free → cancel → book free was unbounded, and
took an advisor's time for nothing. Money never leaked (the credit is a discount
on the charge, never a ledger credit), but instant booking would have pointed
that cycle at **now** instead of at a future slot.

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
