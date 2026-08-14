# AURAT-0015-002 — Check existing state

Date: 2026-08-14

## Brain

- **`AURAF-0008`** (minted today) — the round-2 feature spec, 12 rows. This task
  owns rows **001–005**.
- **`AURAD-0008`** (ratified today, option B) — the reason 006–012 are parked.
- **`AURAD-0002`** (in force) — instant blocks, wallet-prepaid, non-refundable.
  Everything this task builds must stay true under it.
- **`AURAD-0001`** — advisor is a persona, presence/typing are persona-level.
  The banner shows session state, never a chatter identity.
- `AURAT-0010` (app paid sessions) and `AURAT-0008` (BFF) are the shipped
  ancestors of this surface — read both before touching `features/paid-session`.

No prior task folder covers the banner, the dividers' restyle, or chats-list
session markers. Fresh work.

## Code (ground truth, read in slave-1)

Already exists, and is **not** to be rebuilt:

- `features/paid-session/` — `use-paid-session.ts` (session state, `nearEnd`,
  extend, early end), `lib/remaining.ts` (seconds from `endsAt`),
  `lib/format-countdown.ts`, `ui/SessionBar.tsx`, `ui/SessionBlockSheet.tsx`.
  The countdown is already derived from `endsAt` rather than decremented — the
  invariant AURAT-0010 verified across a BFF restart and an app kill.
- `screens/chat-thread/ui/SessionMarker.tsx` — **already** hairline — label —
  hairline. Currently `theme.colors.accent` (coral) for both rules and label,
  and it renders the server's own line verbatim ("Your session has started").
- `features/chat/model/types.ts` — `MessageAuthor` is already
  `'me' | 'advisor' | 'system'`; `ChatMessage` carries no tone.
- `screens/chats/ui/ChatListRow.tsx` + `model/use-chats.ts` — the list rows and
  their ordering.
- `screens/chat-thread/ui/ChatThreadHeader.tsx` — where "Book now" lives.

## Consequences for the spec

Rows 002 and 004 are new components. Row 003 is a **restyle plus a tone field**,
not new plumbing — the markers already arrive from the BFF as stored
`direction:'system'` messages and already render in order and survive scroll-back.
Row 001 partly exists as `lib/remaining.ts`; the gap is the *server clock* and the
scheduled/active/ended vocabulary.

## Next

`003-understand.md`.
