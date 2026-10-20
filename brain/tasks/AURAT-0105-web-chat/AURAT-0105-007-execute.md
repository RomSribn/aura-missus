# AURAT-0105-007 — Execute

Date: 2026-10-20
Branch `feature/AURAT-0105-web-chat` (slave-1). Not committed — staged for review.

## Done (spec `005` + decisions `006`)

- **`shared/api/ws-client.ts`** — backoff resets only after 10 s of a stable socket (the BFF refuses
  after `open`); 4403 stops for good; 4401 → next token `getIdToken(true)`; `onClose` callback;
  `stop()` resets the backoff. **`shared/api/bff-file.ts`** — `fetchBffFile` (attachment bytes with
  the token, 401 retried once). Icon `image` (from the app's `AuraIcon.tsx`). Tokens: tarot shadow,
  plum text, fan/flip durations, chat column widths.
- **`entities/message`** — thread cache `getThread` (newest page, 50) + `getHistoryPage` +
  `postMessage`; thunks `syncThread` (after + deletedFrom, page loop ≤ 10), `syncAllThreads`,
  `refreshThread` (re-read newest page on reopening — picks made in the app), `loadOlderMessages`
  (`before`), `sendMessage` / `retryMessage` (optimistic, one key per message), `applyChatEvent`,
  `recordSpreadPick`; slice `chatLive` (presence, typing, unread-this-visit, viewing); `useChatLive`
  (socket with sign-in: start / stop / restart on another person, catch-up on open, visibility,
  online); `useConversations` (catalog advisors' threads, freshest first); attachments (lazy image
  via `IntersectionObserver` → blob URL; file download); UI: `MessageBubble`, `SystemLine`,
  `DayDivider`, `TypingBubble`, `MessagePreview`, `ConversationTime`.
  - Ported with tests: `map-message.ts` (one difference — `createdAt` instead of the hand-built
    `time`), `preview.ts` (words as i18n keys, marker flagged), `types.ts`; `ChatProvider` logic as
    pure `lib/thread.ts` with its scenarios (25 tests).
- **`entities/session`** — `SessionInviteCard` (no price / minutes, offer line, Book → `?book=1`;
  billing off → no CTA).
- **`features/send-message`** — `Composer`: growing textarea (≤ 6 lines), Enter / Shift+Enter on a
  fine pointer only, IME never sends, counter from 3800, > 4000 blocked, no paperclip.
- **`features/tarot-pick`** — `TarotPicker`: fan of 7 (handoff geometry desktop / phone), hover lift
  with neighbours (CSS `:has`), click / Enter / arrows, `POST …/pick`, flip 520 ms after the answer,
  result from the server, failure → fan back; reduced motion → result at once.
- **widgets** `conversation-list`, `chat-thread` (header, log, older pages with place kept, stick to
  bottom / «New messages», 30 s poll while visible, greeting at the start), `advisor-rail`.
- **`pages/chats`** (lazy chunk) — `/chats` and `/chats/:advisorId`: 3 columns ≥ 1181, 2 columns
  761–1180, phone list / thread; desktop `/chats` → freshest thread (`replace`); empty state; advisor
  not in the catalog → «This chat isn’t here» without a request.
- **`app`** — routes; handle `noTabBar` (thread on phones); Chats badge (signed-in, > 0); store
  `chatLive`; `useChatLive` in the account session; 8 new namespaces registered.
- **Strings** — 8 new namespaces + `app:nav.unread_*`, English + 23 languages (translated in
  parallel, checked by `tsc` and `i18n.test.ts`).
- **brain** — `AURAF-0020`: UI ✓ in 005; context line for 005; backlog rows 017–023 (BFF gaps).

## Checks

`npm run typecheck` ✓ · `npm run lint` (eslint + steiger) ✓ · `npm test` 48 files / 716 tests ✓ ·
`npm run build` ✓ · `prettier --check` ✓. New tests: ws-client (+5), thread (25), map-message (10),
preview (6), marker, when, attachment, chat-sync (12), use-chat-live (4), composer (5), tarot picker
(4), `/chats` integration (8).

Bundle: main chunk 509 → 540 kB (gzip 161 → 172); the chat page itself is a lazy 16 kB chunk.

## Notes / open

- Card names come from the server in English (`TarotCard.name` — contract); «You chose {card}» is
  translated, the name is not.
- Translators' doubts (native review welcome, not blocking): name declension in cs / sk / sl / lt /
  lv / pl / fi / hr / hu solved with «Label: {{name}}» forms; Maltese typing verb is masculine;
  «reading» wording in el / da / ro / sl; `refused.desk` rendered as «the advisor couldn’t receive
  it».
- The app's `ws-client` has the same backoff reset on `open` — backlog `AURAF-0020-021` (app task).
- Owner action: mint in `aura-app-manor` the BFF task for `AURAF-0020-017` (`exposedHeaders`).
- Verification in the manor after merge: list = app's chats; live advisor reply; a message sent in
  the app appears (≤ 30 s or on tab focus); desk deletion; `::CUPS_02::` pick + reopen;
  `::SESSION::` invite; typing; network drop and return; phone width (list / thread, no tab bar).

Next: owner review in the IDE.
