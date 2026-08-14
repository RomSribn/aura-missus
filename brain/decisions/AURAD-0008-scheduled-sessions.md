# AURAD-0008 — Are paid sessions scheduled slots paid by card, or instant blocks prepaid from the wallet?

Date: 2026-08-14
Status: **superseded by `AURAD-0009` (2026-08-14)** — was accepted, owner-ratified, option B

> Superseded the same day. Option B deferred the booking flow **because it
> required a PSP**; `AURAD-0009` removes that premise by paying the scheduled
> slot from the wallet instead of by card, so rows 006–012 became buildable
> without one. The conflict analysis below still stands and is why the
> replacement decision exists.

## Decision

**Option B — `AURAD-0002` holds; the handoff's booking flow is deferred.**

Design handoff round 2 (`SESSIONS_BOOKING.md`, committed `a88cbb5`) specifies a
paid session that contradicts `AURAD-0002`, ratified 2026-07-09 and **already
built and shipped** on both the BFF (`AURAT-0008`) and the app (`AURAT-0010`).
The owner chose to keep the shipped monetization model and take only the half of
the round that does not touch it.

**Adopted now:** the in-thread session surface — lifecycle helpers, the
`SessionBanner`, transcript system dividers, chats-list markers and sorting, and
the "Book now" → "Extend +15 min" header swap (`AURAF-0008` rows 001–005). None
of these depend on when a session starts or how it was paid for; they describe a
session that is *running*, which is true under either model.

**Deferred, not rejected:** scheduled slots, the card rail, the −$5 first-session
credit, refunds, reschedule and the 30-minute reminder (rows 006–012, screens
20–25/27). They land as one piece once a PSP exists, since the Review screen
cannot be paid without one.

Sessions remain **instant blocks prepaid from the USD wallet, non-refundable once
started**, per `AURAD-0002`.

## The conflict

| | `AURAD-0002` (ratified, **built**) | Handoff round 2 (**designed**) |
|---|---|---|
| When it starts | **Immediately** on booking | **Scheduled** — 14-day date strip + time slot |
| Paid with | **USD wallet**, debited up front | **Card** (Visa ···· 4242 default); *"Aura balance · not enough"* is rendered **disabled** |
| Refunds | **Non-refundable once started** — ending early forfeits the rest | **≥ 24 h → full refund**, **< 24 h → half kept**, back to balance |
| Discounts | none | flat **−$5.00 "First-session credit"** |
| Change | extend by booking another block | **Reschedule free up to 4 h before** |
| Reminder | none | local notification **30 min before** |
| Cancel | n/a | cancel sheet, two variants |

`AURAF-0007` also lists **"Scheduling a session for later — sessions start
immediately only (`AURAD-0002/0003`)"** under *NOT in scope*, so the handoff
reverses an explicit exclusion, not merely an unstated assumption.

What is **not** in conflict, and holds either way: the session is chat-only
(`type: 'Chat'`, no voice/video — this only *confirms* `AURAD-0001/0003`); it runs
**inside the same durable thread** with no separate room and no join gating; and
it is bracketed by system dividers in the transcript.

## Options

**A — Handoff wins; `AURAD-0002` is superseded in part.** Sessions become
scheduled, card-paid and refundable. Cost: the wallet stops being the session
rail (`entities/wallet` keeps only Top Up / balance display), the BFF gains slot
availability, reschedule, cancel + a refund ledger direction, and a PSP becomes a
**hard prerequisite** rather than the deferred stub it is today — nothing in the
Review screen can be paid without one. `AURAT-0008`'s non-refundable invariant
and its up-front debit are rewritten.

**B — `AURAD-0002` holds; the handoff's booking flow is deferred.** Ship only the
parts that do not touch monetization: `SessionBanner`, the transcript dividers,
chats-list markers + sorting, the header action swap, and the lifecycle helpers.
Screens 20–25/27 (Book, Review, Booked, Reschedule, Cancel) wait for a PSP. The
app keeps instant wallet-paid blocks; the design set carries screens the product
does not implement yet.

**C — Both, flagged.** Scheduled+card behind a second flag alongside
`billing_enabled`, instant+wallet stays the shipped path. Highest cost: two
monetization models alive in one codebase and one BFF.

## Recommendation (as put to the owner — B was chosen)

**B now, A next.** The handoff's screens are a real product direction, but the
refund policy, the −$5 credit and the card rail all require a PSP that
`AURAF-0007` deliberately left out of scope and that still does not exist —
option A cannot be finished, only started. Option B delivers the whole
chat-surface half of the round (which contradicts nothing, is the half the user
actually sees every session, and is where the design's new thinking is), and
leaves the booking flow to land in one piece once payments are real.

## Consequences

- `AURAD-0002` stays `accepted` and gains a pointer here recording that the
  scheduled variant is designed but not adopted.
- `AURAF-0008` rows 001–005 are unblocked (`AURAT-0015`); rows 006–012 are parked.
- The design set now carries screens (20–25, 27) the product does not implement.
  That gap is deliberate — anyone reading `SESSIONS_BOOKING.md` as a build order
  must read this decision first.
- Revisit when a PSP lands: option A becomes buildable, and this file should then
  be superseded rather than edited.

## Why it matters

`entities/session` still models the pre-BFF seed data and its `kind` field is
documented as `"1:1 video"` — a format the product no longer has. Sessions are
currently described by two unrelated shapes in the app (that seed entity, and
`Session` from `@aura/contracts`). Any of the three options has to collapse them
into one; picking the target model is what unblocks that.
