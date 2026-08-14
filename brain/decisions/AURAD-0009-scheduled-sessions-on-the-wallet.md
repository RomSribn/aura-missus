# AURAD-0009 — Sessions become scheduled slots, still paid from the wallet

Date: 2026-08-14
Status: proposed — **needs owner ratification** (direction chosen by the owner in
conversation 2026-08-14; one sub-question below is still open)

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

## Open for ratification

**Does instant booking survive alongside scheduled?** The design routes the chat
header's "Book now" *into* the booking flow, which would retire the shipped
instant block — the one `AURAD-0002` calls the growth loop, and the one
`AURAT-0010` built and verified.

Recommendation: **keep both.** Scheduling is the new capability, not a
replacement — a user who wants to talk *now* should not be made to pick a slot,
and the earliest-slot workaround is worse than the instant path that already
works. Concretely: the block picker stays for "start now", the booking flow is
reached from the same CTA as a second option, and extend keeps working on the
running session either way.

If the owner prefers the design's single path, say so and this file is amended
before any code is written — that is a cheaper edit here than in five screens.

## Why it matters

`AURAD-0008` chose to defer this whole half **because it required a PSP**. That
premise is what changed: paying the slot from the wallet removes the PSP from
the critical path entirely, and leaves it as a later addition to the Review
screen rather than a prerequisite for it.
