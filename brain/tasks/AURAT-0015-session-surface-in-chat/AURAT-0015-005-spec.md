# AURAT-0015-005 — Spec

Date: 2026-08-14
Feature: `AURAF-0008` rows 001–005
Slave: slave-1, `feature/AURAT-0015-session-surface-in-chat` off develop `80a37be`
Status: **awaiting owner approval — no code written**

## Goal

Make a running paid session legible inside the chat thread, per handoff §5b,
without touching how a session is bought, priced or refunded.

## Scope

### 1 · Server clock (row 001)

Add a server-time offset to `shared/api/bff` — captured from the BFF response
(`Date` header or an explicit field) and applied as `serverNow()`. Replace the
two `Date.now()` call sites in `use-paid-session.ts`. `remaining.ts` keeps its
injected-`now` signature and stays pure, so its tests are unaffected.

Add `sessionState(s) → 'active' | 'ended'` and `minsLeft(s)` next to
`remainingSeconds`. **`'scheduled'` is deliberately omitted** — under
`AURAD-0002` a session starts when booked, so the state is unreachable, and a
union member no code path can produce is a lie the compiler will happily keep.
It gets added by `AURAT-0016` together with the flow that can produce it.

### 2 · SessionBanner (row 002)

New `features/paid-session/ui/SessionBanner.tsx`, pinned under the chat header
(margin `10/16/0`, radius 18). **Live variant only**, per the state decision
above: plum→plum-2 gradient, 34px gold `clock` tile, teal pulsing dot with
"PAID SESSION LIVE" in gold, `mm:ss` (→ `h:mm:ss` past an hour) in Bricolage
20/800 white with **tabular figures**, "LEFT" label, and a 3px teal progress bar
= elapsed %.

Ticks **1s**, owned by the banner. Hidden when no session is live — *its
disappearance is the signal the meter stopped*, so it must unmount, not grey out.

**Tap target:** Session detail is parked, so the banner taps to the existing
`SessionBlockSheet` (which already shows the running block and the extend
action). Re-point at Session detail in `AURAT-0017`.

Reuse `format-countdown.ts` if it already produces the required format; extend
it rather than writing a second formatter.

### 3 · Transcript dividers (row 003)

Restyle `SessionMarker`: **teal** rules + label at session start, **ink-3** at
end, 11px/700/uppercase, letter-spacing `0.06em`. Add an optional `tone` to
`ChatMessage` and map it in `lib/map-message.ts`.

**Label text stays the server's.** The BFF authors the line and the chatter sees
the same one in Chatwoot; having the app substitute "PAID SESSION STARTED · 30
MIN" would make the two surfaces disagree about what happened. If the owner wants
the designed wording, it changes in the BFF (`AURAT-0008`'s system message) and
is a separate task — flagged, not silently taken.

### 4 · Chats list (row 004)

Session marker per row — teal `Pill` + live dot "Session live · N min left" when
active — plus sorting active-session threads to the top, and `· online`
suppressed on those rows so a row carries one status, not two. A `system`
message previews as `— {text}`.

**Bounded by a real dependency:** this needs session state for *every* listed
advisor. If the BFF has no such read, this row ships as "sort + marker for the
advisor whose session is known" and the gap is logged as BFF debt rather than
faked client-side. Check first, implement second.

The scheduled variant ("Session tomorrow · 15:00") is **out** — same reason as
the banner's.

### 5 · Header swap (row 005)

`ChatThreadHeader`: "Book now" (primary) → "Extend +15 min" (soft) while live,
150ms cross-fade. The extend path already exists in `use-paid-session`
(`openExtend`), so this is a label/variant swap driven by session state, not new
behaviour. `+15 min` must come from the server's block options, not a literal —
`AURAT-0008` D1 is explicit that the app never invents pricing or block sizes.

## Out of scope

Booking flow (`AURAT-0016/0017`), the scheduled state and its banner variant, the
BFF's marker copy, Session detail, the 30-min reminder, add-to-calendar.

## Acceptance

- Banner appears on session start, counts down in `mm:ss` with non-jittering
  digits, progress bar tracks elapsed, and **unmounts** at zero.
- Countdown agrees with the BFF meter on a device whose clock is deliberately
  skewed — the concrete proof the server clock landed.
- Dividers bracket the paid window teal→ink-3 and survive scroll-back.
- Chats list floats an active-session thread to the top with the teal pill and
  no doubled status.
- Header shows Extend only while live.
- Everything stays invisible when `BILLING_ENABLED` is off.
- Slave gates green: tsc / eslint / jest.

## Resolved by the owner (2026-08-14)

1. **Divider copy — keep the BFF's sentence.** The app renders what the server
   authored; it never substitutes the designed label. App and Chatwoot therefore
   always agree on what happened in the thread. The handoff's
   "PAID SESSION STARTED · 30 MIN" wording is **not** adopted — only its
   *styling* (teal at start, ink-3 at end) is. No BFF copy task is minted.
2. **"Extend +N min" takes the server's smallest block**, not the design's
   literal 15. The label is built from the pricing endpoint's block options, so
   the button can never offer a block the BFF would refuse to sell
   (`AURAT-0008` D1 — the app never invents prices or block sizes). If the
   options list is empty or unloaded, the header keeps "Book now" rather than
   rendering an Extend button with no block behind it.
