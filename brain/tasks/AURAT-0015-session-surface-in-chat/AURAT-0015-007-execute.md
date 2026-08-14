# AURAT-0015-007 — Execute

Date: 2026-08-14
Slave: slave-1, `feature/AURAT-0015-session-surface-in-chat` off develop `80a37be`
Status: **code written, staged, awaiting IDE review — nothing committed, nothing merged**

Scope executed: `AURAF-0008` rows **001–005** exactly as approved in `005-spec.md`
/ `006-approval.md`. Rows 006–012 untouched; no booking flow, no payment rail,
no refund logic.

## What was built

### Row 001 · Server clock + lifecycle helpers

New `shared/api/bff/server-clock.ts`: a module-level offset, folded from the
`Date` header of **every** BFF response (failures included — a 404 dates the
same reply a 200 would), and `serverNow()`. The offset is estimated from the
midpoint of the request window, so half the round trip is not charged to it;
the header's one-second resolution is immaterial against a minute-scale meter
and far better than a device clock that can be hours out. No clock endpoint, no
extra round trip, no timer. Until the first response lands the offset is zero,
i.e. exactly the behaviour that shipped before.

Both `Date.now()` call sites in `use-paid-session.ts` (the initial `now`, and
the countdown tick) now read `serverNow()`. `lib/remaining.ts` keeps its
injected-`now` signature and stays pure, so its existing tests were unaffected.

`sessionState(session, now) → 'active' | 'ended'` and `minsLeft(session, now)`
added next to `remainingSeconds`. **`'scheduled'` is not in the union**, per the
spec — under `AURAD-0002` nothing can produce it; it arrives with `AURAT-0016`.

### Row 002 · SessionBanner

New `features/paid-session/ui/SessionBanner.tsx` — live variant only. Plum→plum-dark
gradient, 34px gold `clock` tile, 7px teal dot pulsing on the design's 1.6s
`orb-pulse`, "PAID SESSION LIVE" in gold, the counter in display 20/800 white
with `fontVariant: ['tabular-nums']`, "LEFT", and the 3px teal progress bar
tracking **elapsed** against total booked minutes (so an extension measures
against its new total, not its first block).

The screen renders it conditionally, so it **unmounts** when the block ends
rather than greying out — its disappearance is the signal the meter stopped.

**Deviation from the design, deliberate:** the prototype's banner owns a 1s
interval because nothing else in the prototype ticks. Here `usePaidSession`
already ticks every second and recomputes the remainder from `endsAt` on the
server clock. A second interval could only decrement locally — precisely the
drift `AURAT-0010` designed out — so the counter is a pure render of what the
hook resolved. The 1s cadence the spec asks for is met; the second timer is not
built.

Sub-line reads "N min booked · tap to extend", not the design's "tap for
details": Session detail is parked (`AURAD-0008`), and the tap opens the block
sheet. Copy follows the actual destination. Re-point at Session detail in
`AURAT-0017`.

### Row 003 · Transcript dividers

`SessionMarker` restyled: teal rules + label at the start, ink-3 at the end,
11/700/uppercase, letter-spacing `0.66` (= the spec's `.06em` at 11px).
`ChatMessage` gained an optional `tone`, mapped in `lib/map-message.ts`.

**The label text is still the server's, verbatim** — the owner's resolution 1.
Only the colour changed.

### Row 004 · Chats list

`useActiveSessions(advisorIds)` (new, in `features/paid-session/model/`) →
advisorId → minutes left, live sessions only. Rows carry a teal `Pill` with a
dot reading "Session live · N min left", the `· online` suffix is suppressed
while a block runs (one status per row), a `system` last message previews as
`— {text}`, and threads with a running block sort to the top (stable sort, so
nothing else reshuffles).

### Row 005 · Header swap

`ChatThreadHeader` swaps "Book now" (primary) → "Extend +N min" (soft) while
live, through a 150ms opacity cross-fade (`theme.animations.durations.fast`).

**N is the server's smallest block**, via new `smallestBlockMinutes(pricing)` —
never the design's literal 15. A live session quietly loads pricing in the
background (the picker would have loaded it anyway); if that fails or returns no
blocks, `extendLabel` stays null and the header keeps "Book now" rather than
offering a block the BFF would refuse. The background failure is deliberately
silent and never poisons the picker's error state.

## The one judgment call, owner-approved mid-task

`SessionBanner` lands in the exact slot the shipped `SessionBar` occupied — both
pin under the chat header, both are the live meter. Two stacked meters would
also break the spec's own rule that the banner's *disappearance* is the signal.
Put to the owner via `AskUserQuestion`; the chosen option:

- **`SessionBar` deleted** (component + its test).
- Its near-end state survives as a coral tint on the banner's counter and
  progress fill, so `nearEnd` keeps a consumer and the urgency cue is not lost.
  The near-end *extend prompt* is superseded by the header's persistent
  "Extend +N min", which is strictly better than an offer that only appears in
  the last two minutes.
- **"End session early" moved into `SessionBlockSheet`** (shown only in
  `extend` mode, which by definition means a block is running). `endEarly` and
  its non-refundable confirmation are **unchanged** — only the entry point
  moved. `AURAT-0010`'s device-verified forfeit flow stays reachable for the
  whole session, not just its last two minutes.

## Findings worth recording

1. **The BFF has no machine-readable marker kind.** `direction: 'system'` is all
   the contract carries, and the two markers differ only in the server's English
   ("Your session has started" / "…has finished", `sessions.service.ts`
   `MARKER_CONTENT`). Colouring the two ends therefore means matching the
   server's own wording. It is isolated in one helper, and anything unrecognised
   takes the quiet tone — **a reworded line loses a colour, never the divider**.
   *BFF debt: a marker subtype would retire this. Not minted; flagged here.*
2. **No sessions-list endpoint.** The BFF exposes only
   `GET /v1/advisors/:id/sessions/active` (routes verified in
   `sessions.controller.ts`), so row 004 fans out one request per thread — the
   same shape the chat history sync already uses for the same missing-endpoint
   reason (BFF `TECH-DEBT #12`). The gate in `006-approval.md` is therefore
   **met, not narrowed**: every pill is a session the server confirmed, none is
   inferred client-side. A list read would make it one request instead of N.
   Expiry costs no traffic at all — a block ends at its own `endsAt`, so the
   local 30s tick drops it on the server's clock.
3. **`ws-client` recurses under jest when a socket is actually closed**
   (`onerror` → `close` → `onerror`). Only surfaced because the new screen tests
   unmount their trees, which no earlier test did. Stubbed `BffSocket` in those
   two files; not a production path (nothing closes a live socket that way), so
   not fixed here.
4. The prototype tints only the divider's *label* and leaves the hairlines at
   `--line`; `005-spec.md` says "teal **rules** + label". The approved spec was
   followed — it is also the smaller diff, since the rules were already tinted
   (coral).
5. **Divider rules moved from `height` to `borderTopWidth`** (raised at IDE
   review by an editor inspection on `height: StyleSheet.hairlineWidth`). The
   line was pre-existing — `AURAT-0010`, device-verified on Android — so this is
   not a defect fix, but a sub-pixel *height* is a layout value subject to
   Yoga's pixel-grid rounding where a border width is drawn as one, and 8 of the
   app's 9 `hairlineWidth` usages were already `border*Width`. `SessionMarker`
   was the lone outlier; it no longer is. Visually identical, tests unchanged.

## Verification (slave gates only — the stack is never started here)

| Gate | Result |
|---|---|
| `tsc --noEmit` | clean |
| `eslint src` | clean |
| `jest` | **39 suites / 182 tests green** (was 34 / 142) |
| Release bundle (`react-native bundle`, android, `--dev false`) | built, 19 assets copied |

New/changed tests, and what each pins:

- `server-clock.test.ts` — fast device, slow device, half-round-trip, and a
  missing/unparseable header keeping the last good offset.
- `http-client.test.ts` — every response re-syncs the clock; a response with no
  `Date` header is not an error.
- `use-paid-session.test.tsx` — **the acceptance criterion**: with the device
  clock five minutes fast, the countdown still reads `10:00`. Plus the extend
  label taking the server's smallest block, and staying null with no pricing.
- `remaining.test.ts` — `sessionState` flips exactly at `endsAt`, a
  `FINISHED` session is ended inside its window, `minsLeft` rounds up.
- `blocks.test.ts` — smallest block regardless of server order; **null, never 15,
  when there are no blocks**.
- `map-message.test.ts` — both tones, an unknown line falling back to quiet, and
  a real message containing "started" staying untinted.
- `SessionBanner.test.tsx` — progress tracks elapsed (incl. after an extend),
  tabular figures, near-end coral, whole card is one target.
- `SessionMarker.test.tsx` — teal/ink-3 ends, and that the app has **not**
  substituted the designed wording.
- `ChatThreadScreen.session.test.tsx` (new file, billing on) — banner appears
  for a running block, header reads "Extend +10 min" and not "Book now", no
  banner without a session, banner tap opens the sheet with the end action.
- `ChatsScreen.session.test.tsx` / `ChatListRow.test.tsx` — live pill, sort to
  top, presence suppressed while live, `— {text}` preview.
- `format-countdown.test.ts` — zero-padded `mm:ss`, `h:mm:ss` past the hour,
  fixed width across the 9:59→10:00 boundary.

`formatCountdown` was extended rather than duplicated (spec's instruction), so
its output changed `7:32` → `07:32`; the two affected expectations in
`use-paid-session.test.tsx` were updated. That is the only behavioural change to
existing code outside the rows above.

**Everything stays invisible when `BILLING_ENABLED` is off** — the pre-existing
"with billing off there is no session UI at all" test still passes untouched,
and `useActiveSessions` issues zero requests in that state.

## Not verified here (needs manor, after merge)

Device pass: the banner's gradient/pulse/tabular digits on a real screen, the
countdown against a deliberately skewed device clock end to end, dividers in
scroll-back, the chats-list pill and re-sort, and the header cross-fade.

## Next

IDE review of the staged diff → commit → merge gate (explicit owner approval
required; nothing is merged or pushed).
