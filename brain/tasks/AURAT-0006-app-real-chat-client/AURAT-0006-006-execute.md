# AURAT-0006-006 — Execute

Date: 2026-07-11
Branch: `feature/AURAT-0006-app-real-chat-client` (slave-1), committed.
Contracts: `@aura/contracts` **v0.2.0** pushed (`e28bed3`, tag `v0.2.0`).

## What was built (per approved spec 004)

**Contracts (own repo)**: `chat.ts` rewritten to the BFF as-built shapes
(`Message{content, createdAt}`, `SendMessageRequest`, `HistoryQuery/Response`,
`WsServerEvent` incl. forward `presence.update`/`typing.update`,
`MessagePushData`); new `device.ts`. App consumes the git tag + `zod`.

**shared**: `config/env.ts` (dev BFF URLs per platform, LAN override const);
`api/bff/http-client.ts` (`bffRequest`: Bearer ID token, one forced-refresh
retry on 401, status-only `BffApiError`); `api/bff/ws-client.ts` (`BffSocket`:
fresh-token handshake, capped exp backoff + jitter, transport-only);
`api/firebase/messaging.service.ts` (FCM token/handlers wrapper);
`authService.getIdToken(forceRefresh?)`. All via the shared root API.

**features/chat** (sim deleted — canned replies, 1.5 s timer, sim constants,
sim exports): `api/chat-api.ts` (ensure/send/history, zod-parsed);
`lib/map-message.ts`; provider rewritten — hydrate = newest page per seed
advisor (G4), WS live events (`message.new` dedup-by-id append,
`typing.update`, `presence.update`), resync on WS open + foreground +
foreground-FCM ping, optimistic send (`pending` → stored DTO; `failed` +
`retryMessage`), `startThread` = fire-and-forget conversation ensure,
state reset on identity change, inert when signed out (tests unchanged
via `initialThreads`).

**features/push** (new slice): `api/devices-api.ts` (PUT/DELETE token);
registration hook (notifee permission → token → register; re-register on
rotation; `unregisterCurrentDevice()` wired into profile sign-out);
`message-notification.ts` (notifee channel + persona-titled notification
from the data-only ping — no content, AURAD-0001-safe);
background handler + tap funnel (cold start / background / foreground →
one `subscribeToThreadOpens`).

**app**: `navigation-ref` (deferred, auth-guarded deep link into
CHATS→CHAT_THREAD), `PushBootstrap`, root `index.js` registers headless FCM
+ notifee handlers before `AppRegistry`. Nav contract: `MAIN` now accepts
nested params (shared, not app).

**screens**: chat-thread — greeting is a UI-only intro bubble (spec §8),
`✓/✓✓` delivery meta, failed bubble = "Not delivered · Tap to resend"
(pressable, a11y-labelled); presence override in thread header + chats rows
(seed fallback). Profile sign-out unregisters the device first.

**native**: iOS `UIBackgroundModes: remote-notification`; Android
`POST_NOTIFICATIONS`. `pod install` + APNs key/entitlement = manor/owner.

## Verification (slave-pure)

- `npx tsc --noEmit` ✓ · `npm run lint` ✓ (0 warnings) · `npm test` ✓
  **21 suites / 73 tests** (was 14/44).
- New suites: http-client (bearer/401-retry/error/204), ws-client
  (connect/reconnect/token-wait/stop), chat-api (URLs/zod), map-message,
  devices-api, push notification + background handler + parse, provider
  behaviour (hydrate, dedupe, typing/presence, optimistic send/fail/retry,
  reconnect delta-sync, inert signed-out).
- Sim references: zero matches repo-wide.

## Decisions during implementation

- Greeting bubble is **always** the first rendered bubble (not only when
  empty) — it never vanishes mid-conversation and is never stored.
- Foreground FCM ping handled inside ChatProvider directly via
  `MessagePushData` (no cross-feature import from push).
- `no-void` lint: fire-and-forget promises call `.catch(() => {})`
  explicitly instead of `void`.

## Known limitations / follow-ups

- On-device e2e (live reply, push, history across reinstall) = manor after
  merge; iOS needs APNs key in Firebase console + push entitlement.
- Scroll-back pagination (`before` cursor) not surfaced in UI — newest page
  only, like the sim; follow-up when a design exists.
- Presence/typing stay seed/silent until AURAT-0009 (BFF emission).

Next: merge gate (user approval) → `wts-finish slave-1` → manor verify.
