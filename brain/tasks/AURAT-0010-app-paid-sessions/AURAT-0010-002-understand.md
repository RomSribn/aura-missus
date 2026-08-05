# AURAT-0010-002 — Understand

Date: 2026-08-04
Slave: slave-1, branch `feature/AURAT-0010-app-paid-sessions`

## App today (ground truth, aura-app `0244a3b`)

- **`features/chat`** — real BFF client. `ChatProvider` holds
  `threads: Record<advisorId, ChatMessage[]>`, `typingAdvisorId`,
  `presence`, and `startThread` / `sendMessage` / `retryMessage`. Hydrate =
  newest history page per seed advisor; live = one `BffSocket`; resync on
  WS open, on foreground, and on an FCM ping. View model
  `ChatMessage {id, from: 'me' | 'advisor', text, time, status?}`.
- **`shared/api/bff`** — `bffRequest` (Bearer ID token, one 401 refresh
  retry, `BffApiError {status}`) and `BffSocket` (transport only, backoff,
  `onEvent`/`onOpen`). `shared/config/env.ts` holds the BFF URLs; there is
  **no flag of any kind** in it yet.
- **`screens/chat-thread`** — header with avatar/status and a **`Book now`**
  button that today navigates to the advisor profile; message FlatList
  (memoized bubbles) + typing indicator + input bar. Model hook
  `use-chat-thread.ts` owns all orchestration.
- **`screens/profile`** — `ProfileCard` shows `balanceLabel`, hardcoded
  `formatUsd(0)` ("display-only until payments exist"), and a `TopUpSheet`
  whose Pay button just closes the sheet.
- **`entities/session`** — Sessions-tab seed data: `UpcomingSession`
  (`kind: '1:1 video'`, day/month/time/reminder) and `PastSession`
  (date/duration). Consumed only by `screens/sessions`. **Nothing to do
  with a paid chat session.**
- **`entities/advisor`** — seed catalog with a `price` in **dollars**
  (1.99…2.99). The BFF prices in **integer cents** from its own `advisors`
  table; the seed price is display-only design data.
- Discipline: `@/` alias + eslint bans on deep/cross-slice imports, TS
  strict, jest 21 suites / 73 tests green.

## BFF as-built (aura-bff `develop`, `AURAT-0008` approved)

All routes are URI-versioned (`/v1`), Firebase-authed, and sit behind
`BillingEnabledGuard` — **with `BILLING_ENABLED` off every one of them
404s**, indistinguishable from a route that does not exist.

| Method | Path | Shape |
|---|---|---|
| GET | `/v1/advisors/:advisorId/sessions/pricing` | `{priceMinorPerMinute, blocks: [{minutes, costMinor}]}` — 404 if the advisor has no `advisors` row ("not bookable", no default price) |
| GET | `/v1/advisors/:advisorId/sessions/active` | `{session: SessionDto \| null}` — no advisor check, `null` when there is no conversation |
| POST | `/v1/advisors/:advisorId/sessions` | body `{minutes, idempotencyKey: uuid}` → `{session, balanceMinor}`; **402** insufficient funds, **409** active session exists, **400** minutes not an allowed block, **404** not bookable; replaying the key returns the existing session without a second debit |
| POST | `/v1/sessions/:sessionId/extend` | same body/response; **409** if not active; ownership failures are **404** |
| POST | `/v1/sessions/:sessionId/finish` | `{session}` — early end, remainder forfeited, idempotent |
| GET | `/v1/wallet` | `{balanceMinor, currency: 'USD'}` (creates the wallet on first read) |
| POST | `/v1/wallet/top-ups` | `{amountMinor, idempotencyKey}` → `{entryId, balanceMinor, currency}` — **stub credit, refused in production** until a PSP exists |

`SessionDto = {id, advisorId, status: 'ACTIVE'|'FINISHED', bookedMinutes,
priceMinorPerMinute, costMinor, startedAt, endsAt, finishedAt: string|null,
finishReason: 'EXHAUSTED'|'ENDED_EARLY'|null}` — ISO strings; the app is
expected to derive the countdown and the near-end prompt **locally from
`endsAt`** (spec §3: "no server-side warning push needed").

Session markers are **not** a separate endpoint: on start/finish the BFF
posts an activity line to Chatwoot, stores it as a message with
`direction: 'system'` and fans it out through the normal path — so a marker
arrives in `GET …/messages` history and over WS `message.new` exactly like
any other message. Blocks are `SESSION_BLOCK_MINUTES` (default `10,20,30`).
WS additionally carries `{type: 'session.updated', advisorId, session}`.

## The contract drift (why this blocks, not just annoys)

`@aura/contracts` v0.2.0 — what the app runs on — declares
`MessageDirection = ['user','advisor']` and a `WsServerEvent` union of
`message.new` / `presence.update` / `typing.update`.

Consequences the moment billing is switched on, **before any UI exists**:

1. `HistoryResponse.parse` **throws** on a page containing a SYSTEM marker.
   `ChatProvider.syncThread` swallows it — so the thread silently stops
   syncing forever once a session has ever been booked.
2. `WsServerEvent.safeParse` **fails** for a `message.new` carrying a marker
   and for `session.updated` — both events are dropped.
3. After the union gains `session.updated`, `ChatProvider`'s event handler
   is wrong in the other direction: its final `else` assumes
   `presence.update` and would write `presence[advisorId] = undefined`.

So the contracts bump is a prerequisite of the UI, and this task must land
before `BILLING_ENABLED` is turned on anywhere.

`wallet.ts` in the package drifted identically (`Wallet {balance: Money}`
vs the as-built `{balanceMinor, currency}` + top-up shapes); `session.ts` is
still the v0 placeholder. Neither has an app consumer today — the app only
imports `Message`, `HistoryResponse`, `MessagePushData`, `WsServerEvent` —
so rewriting them is not a breaking change for any shipped code.

## Verdict

The BFF surface covers the whole P1 flow; nothing is missing server-side.
Five app-side questions need decisions before the spec — see 003-context.
