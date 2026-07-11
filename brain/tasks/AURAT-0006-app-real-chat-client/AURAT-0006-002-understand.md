# AURAT-0006-002 — Understand

Date: 2026-07-11
Slave: slave-1, branch `feature/AURAT-0006-app-real-chat-client`

## What the task is

App side of AURAF-0007 items 001–005: replace the in-memory chat sim in
`features/chat` with a real client for the live dev BFF (AURAT-0004/0005,
merged + verified), add FCM background delivery, keep the persona rendering
(AURAD-0001) and the one-durable-thread-per-advisor model (AURAD-0003).

## App today (ground truth, `df0906f`)

- `features/chat` = `ChatProvider` (React context): `threads:
  Record<advisorId, ChatMessage[]>`, `typingAdvisorId`, `startThread`
  (seeds `advisor.greeting` locally), `sendMessage` (canned reply after a
  1.5 s timer from `config/constants.ts`). View model `ChatMessage {id,
  from: 'me'|'advisor', text, time: 'HH:MM'}`.
- Consumers: `screens/chat-thread` (bubbles + typing + send),
  `screens/chats` (list = one row per thread, last message preview),
  `screens/home` (continue-your-chat card), `screens/advisor-profile`
  (Start free chat → `startThread` + jump), `screens/sessions` (Join →
  same), `app/index.tsx` (provider mount). Tests seed via `initialThreads`.
- Firebase: only `app` + `auth` installed (v24.1.1, namespaced API);
  `authService` singleton in `shared/api/firebase`. Jest mocks auth with
  `currentUser: null`.
- No HTTP client, no env config, no zod, no push libs. Babel `@ → ./src`
  alias; TS strict; eslint bans deep/cross-slice imports.

## BFF as-built (ground truth, aura-bff `develop`, live-verified in 0005)

- REST v1 (Bearer = Firebase ID token): `PUT /v1/advisors/:id/conversation`
  (idempotent ensure), `POST /v1/advisors/:id/messages` `{content}` →
  stored MessageDto (creates conversation on first use),
  `GET /v1/advisors/:id/messages?before|after|limit` — ascending pages;
  **no cursor = newest page** (tail); `after` = delta sync, `before` =
  scroll-back. History never provisions. `PUT/DELETE /v1/devices/:token`
  `{platform?}` — FCM token registry.
- WS `wss …/ws?token=<Firebase ID token>`, server→client only, 4401 close
  on bad token, 30 s heartbeat (server pings). Events: `{type:
  'message.new', advisorId, message: MessageDto}`.
- FCM: **data-only** ping `{type: 'message.new', advisorId}` (no content —
  PII), `android.priority=high`, apns `content-available: 1` — BFF comment
  says explicitly: *the app wakes, delta-syncs over REST, renders the
  persona notification locally from advisorId*.
- `MessageDto = {id, advisorId, direction: 'user'|'advisor', content,
  createdAt}` — BFF ids, already ordered; Chatwoot ids never leave the BFF.

## Verdict

The BFF surface covers send/history/live/push completely. Four gaps need
decisions before spec — see 003-context.
