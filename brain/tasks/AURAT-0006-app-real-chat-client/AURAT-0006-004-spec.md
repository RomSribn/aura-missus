# AURAT-0006-004 — Spec

Date: 2026-07-11
Status: draft — awaiting user approval
Branch: `feature/AURAT-0006-app-real-chat-client` (slave-1)

Implements AURAF-0007 001–005 app-side against the live BFF (AURAT-0004/0005).
Everything obeys the FSD hard rules (public APIs, `@/` alias, model/lib split,
render-only screen ui, theme tokens, memoized rows).

## 1. `@aura/contracts` 0.2.0 (own repo, prerequisite)

Replace the v0 `chat.ts` guesswork with the BFF **as-built** schemas
(`aura-bff/src/contracts` is ground truth): `messageSchema` (`content`,
BFF ids, ISO `createdAt`), `sendMessageRequestSchema` (`content` 1..4000),
`historyQuerySchema` / `historyResponseSchema`, `deviceTokenSchema` +
`registerDeviceRequestSchema`, and `wsServerEventSchema` as a discriminated
union of `message.new` **plus forward contracts** `presence.update`
`{advisorId, online}` and `typing.update` `{advisorId, typing}` (G3 —
BFF emits them later, AURAT-0009). Keep money/advisor/session/wallet as-is.
Bump 0.2.0, tag `v0.2.0`, push `main`. BFF migrates its imports to the
package later (BFF-side follow-up, out of scope here).

App consumes it as a git dependency pinned to the tag
(`git+ssh://git@github.com/RomSribn/aura-contracts.git#v0.2.0`) + `zod`
(peer, ^3.24 to match the BFF).

## 2. New deps (app)

- `@aura/contracts` (git tag) + `zod` — contract + runtime parsing.
- `@react-native-firebase/messaging@^24.1.1` — FCM (matches app/auth).
- `@notifee/react-native` — local notification for the data-only ping +
  tap events (G2; exactly what the BFF design expects).
No other new libs: WS = RN's built-in `WebSocket`, HTTP = `fetch`.

## 3. `shared` additions

- `config/env.ts` — `BFF_HTTP_URL` / `BFF_WS_URL`: `__DEV__` defaults
  `http://localhost:3000` (iOS sim) / `http://10.0.2.2:3000` (Android emu),
  one obvious override const for LAN-device testing; production placeholder
  until hosting exists (AURAD-0005 O7 follow-through).
- `api/bff/http-client.ts` — `bffRequest(path, init)`: Bearer from
  `authService.getIdToken()`, JSON in/out, one forced-refresh retry on 401,
  `BffApiError {status}` (no PII in messages).
- `api/bff/ws-client.ts` — `BffSocket`: token-per-connect (fresh ID token),
  `onEvent`/`onOpen`/`onClose`, exponential backoff + jitter (1 s → 30 s),
  explicit `close()`; transport only — no chat knowledge.
- `api/firebase/auth.service.ts` — add `getIdToken(forceRefresh?)`.
- `api/firebase/messaging.service.ts` — thin RNFB-messaging wrapper
  (modular API): `requestPermission`, `getToken`, `onTokenRefresh`,
  `onMessage`, `setBackgroundMessageHandler`.
- All exported through the shared root public API.

## 4. `features/chat` — the real client (sim deleted)

- `api/chat-api.ts` — `ensureConversation`, `sendMessage`, `fetchHistory`
  (zod-parsed responses via `@aura/contracts`).
- `lib/map-message.ts` — `MessageDto → ChatMessage`; `lib/format-time.ts`
  stays (used by the mapper).
- `model/types.ts` — `ChatMessage` gains `status?: 'pending' | 'failed'`;
  the `{id, from, text, time}` view model survives so screen UI churn is
  minimal.
- `model/ChatProvider.tsx` — same context surface (`threads`,
  `typingAdvisorId`, `startThread`, `sendMessage` + new `retryMessage`):
  - **Hydrate** (on Firebase user present): fetch newest history page per
    seed advisor in parallel (G4 workaround), threads = non-empty results.
  - **Live**: WS connect while authed + app active; `message.new` →
    dedupe-by-id append; `typing.update` → `typingAdvisorId`;
    `presence.update` → per-advisor online override (falls back to seed).
  - **Resync**: on WS open (incl. reconnects) and on foreground
    (`AppState`), delta sync every thread (`after` = last id); FCM
    foreground ping = extra sync trigger for the pinged advisor.
  - **Send**: optimistic `pending` bubble → `POST` → replace with stored
    DTO; failure → `failed` + `retryMessage` re-posts. No user echo comes
    over WS (BFF fans out advisor messages only) — no race.
  - **startThread** → fire-and-forget `ensureConversation` (send also
    creates on first use, so failure is benign).
  - `initialThreads` prop kept; signed-out (tests) = fully inert.
- `config/constants.ts` — canned replies + delay **deleted**; page size +
  resync constants instead. Public API re-exports updated.

## 5. `features/push` — new slice (FCM registration + notification)

- `api/devices-api.ts` — `registerDevice(token, platform)` /
  `unregisterDevice(token)` (`PUT/DELETE /v1/devices/:token`).
- `model/push-registration.ts` — when authed: request permission
  (Android 13+ POST_NOTIFICATIONS / iOS alert), `getToken` → register;
  `onTokenRefresh` → re-register; expose `unregisterCurrentDevice()` for
  sign-out (wired into `use-profile`'s signOut before `authService.signOut`).
- `lib/message-notification.ts` — notifee: channel setup + "New message"
  notification titled with the persona name from `entities/advisor`
  (`advisorId` from the ping's data payload; body generic — content never
  reaches FCM), `data.advisorId` for tap routing.
- `model/background-handler.ts` — shared handler: `message.new` ping →
  display notification (background/quit path).
- `model/notification-taps.ts` — notifee foreground/background press
  events + `getInitialNotification` (cold start) funneled into one
  `subscribeToThreadOpens(cb)` for the app layer.

## 6. `app` wiring

- `app/index.tsx` — ChatProvider stays; add a `PushBootstrap` (app-layer
  hook component): runs push registration, subscribes to thread-open taps →
  `navigationRef` navigate CHATS → CHAT_THREAD(advisorId).
- `app/navigation/navigation-ref.ts` — `createNavigationContainerRef`,
  attached in RootNavigator (nav types from the shared contract, as today).
- Root `index.js` — register FCM background handler + notifee background
  event **before** `AppRegistry` (headless requirement).

## 7. Native config (build-only in slave; device verify = manor)

- iOS `Info.plist`: `UIBackgroundModes: [remote-notification]`.
  (`pod install`, APNs key/entitlement in the Apple/Firebase consoles =
  manor/owner step — noted for verification.)
- Android: `google-services.json` already present; add
  `POST_NOTIFICATIONS` to the manifest (runtime ask via notifee).

## 8. Greeting & lists (sim behaviours, resolved honestly)

- `advisor.greeting` is **UI-only**: intro bubble rendered in an empty
  thread (chat-thread ui, from the advisor entity), never stored/sent.
- Chats list & Home "continue" card list only threads with ≥1 real
  message (empty ensured conversations stay invisible — consistent across
  devices).

## 9. Tests (slave-pure; no network/native)

- jest.setup: mocks for `@react-native-firebase/messaging` + notifee
  (+ transformIgnorePatterns `@notifee`).
- Unit: http-client (auth header, 401 retry, error mapping), ws-client
  (reconnect/backoff, event parse), chat-api (URLs/bodies/zod), map-message,
  devices-api, message-notification (persona title), background-handler.
- ChatProvider behaviour suite: hydrate, live append + dedupe, optimistic
  send / fail / retry, typing + presence events, resync on reconnect,
  inert when signed out.
- Existing screen tests keep passing unchanged (signed-out provider +
  `initialThreads`).
- Gates: `npm run lint`, `npx tsc --noEmit`, `npm test`.

## 10. Out of scope (explicit)

- BFF changes of any kind. Presence/typing emission = **AURAT-0009**
  (proposed, BFF manor). `GET /v1/conversations` = recorded BFF tech-debt.
- Local message persistence/offline queue (BFF is the store; v1 refetches).
- Paid sessions / wallet (AURAT-0007/0008), attachments, read receipts.
- On-device end-to-end (manor, after merge: real send → chatter reply →
  live + push; history across reinstall; APNs setup).

## Acceptance mapping (from 001-check)

| Acceptance | Covered by |
|---|---|
| Send → real chatter | §4 send path → BFF POST (live loop verified in 0005) |
| Reply live in foreground | §4 WS `message.new` + resync |
| Reply as push in background | §5 FCM ping → notifee → tap opens thread |
| History across restart/devices | §4 hydrate + delta sync (BFF store) |
| Persona, not agent | DTO has direction only; persona from `entities/advisor` |
| No canned replies remain | §4 sim deletion (config + timers + exports) |

## Decisions for approval

1. **Contracts**: update `@aura/contracts` to BFF as-built + forward
   presence/typing events; tag v0.2.0; app consumes via git tag. (G1)
2. **Push UX**: add `@notifee/react-native`; app renders persona
   notification from the data-only ping. (G2)
3. **Presence/typing**: app plumbs WS `presence.update`/`typing.update`
   now; mint **AURAT-0009 bff-presence-typing** (BFF manor) to emit them.
   Until then: online dot = seed data, typing indicator silent. (G3)
4. **Thread list**: v1 rebuilds the Chats list by delta-syncing the seed
   advisors; `GET /v1/conversations` recorded as BFF tech-debt. (G4)
5. **Greeting**: UI-only intro bubble; threads listed only once a real
   message exists. (§8)
