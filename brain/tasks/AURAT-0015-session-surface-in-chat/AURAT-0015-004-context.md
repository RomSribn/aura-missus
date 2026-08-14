# AURAT-0015-004 — Context

Date: 2026-08-14
Sources: `AURAF-0008`, `AURAD-0008`, `AURAD-0002`, `AURAT-0010`, the handoff
`SESSIONS_BOOKING.md` §5b + §8 + §9, and the slave-1 working tree.

## Findings that shape the spec

**1 · The countdown is already correct; the clock behind it is not.**
`features/paid-session/lib/remaining.ts` recomputes from the server's `endsAt`
and never decrements — deliberately, and AURAT-0010 verified it across a BFF
restart and an app kill. But it is compared against `Date.now()`
(`use-paid-session.ts:67,142`), i.e. the **device** clock. A phone with a skewed
clock therefore shows a wrong "N min left" against a correct server `endsAt`.
This is exactly what the handoff means by *"drive `sessionState` off the server
clock, not the device"* — the fix is a server-time offset, not a new timer.

**2 · The divider is a restyle, not new plumbing.** `SessionMarker.tsx` is
already hairline — label — hairline, already `React.memo`, and already fed by
BFF-stored `direction:'system'` messages that arrive in order and survive
scroll-back. What differs from the handoff: it is **coral for both start and
end**, where the design wants **teal** at start ("PAID SESSION STARTED · N MIN")
and **ink-3** at end ("SESSION ENDED"); and it renders the server's own sentence
rather than the designed label.

That last point is the trap. The label text is written by the **BFF**
(`AURAT-0008` stores it as a SYSTEM message and the chatter sees the same line in
Chatwoot). The app must not silently rewrite server copy — but it also cannot
show the designed label without it. See the open question in `005`.

**3 · `MessageAuthor` already has `'system'`;** `ChatMessage` has no `tone`.
Row 003's model change is one optional field, not a new message kind.

**4 · Presence is persona-level (`AURAD-0001`).** The chats-list rule "suppress
the `· online` suffix while a session is live" is a display rule on top of
existing persona presence — no new data.

**5 · Sorting has a hidden cost.** "Threads with a session sort to the top"
requires knowing the session state of **every** advisor in the list, not just the
open thread. `use-paid-session` is per-thread today. The app also has no
`GET /v1/conversations` (BFF `TECH-DEBT #12`), so the chats list is already
assembled from a per-advisor hydrate. Whether a sessions-for-all-threads read
exists must be checked against the BFF before row 004 is estimated.

## Contradictions logged

- Handoff vocabulary is **scheduled** (`'scheduled'` state, ≤24h "starting soon"
  banner, "UNTIL START"); `AURAD-0002` makes sessions **instant**, so that state
  is unreachable in this product today. Resolved in `005`.
- Handoff §5b says the banner's live variant shows *"30 min booked · tap for
  details"* and taps through to **Session detail** — a screen `AURAD-0008`
  parked. The tap target needs a decision (`005`).

## Next

`005-spec.md`.
