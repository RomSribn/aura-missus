# AURAT-0009-003 — Context

Date: 2026-08-05

Sources: `AURAD-0001`, `AURAD-0005`, `AURAD-0006`, `AURAF-0007`,
`AURAT-0005` (006-spec, 015-approved), `AURAT-0006` (003-context G4,
004-spec, 010-approved), `AURAT-0010` (009-approved), BFF code at
`slave-1/master`, the installed `@aura/contracts` v0.3.0, and the **Chatwoot
v4.15.1 source** in `chatwoot-manor/project/manor/master/chatwoot`
(ground truth — every Chatwoot claim below is a direct source read, not
documentation).

## C1 — Chatwoot really does send typing to our webhook (verified)

`app/models/webhook.rb:32` — `ALLOWED_WEBHOOK_EVENTS` includes
`conversation_typing_on` / `conversation_typing_off`.

`app/listeners/webhook_listener.rb` — both route through
`handle_typing_status` → `deliver_webhook_payloads(payload, inbox)` →
`deliver_api_inbox_webhooks`, which posts to **`inbox.channel.webhook_url`
signed with the inbox `channel.secret`** — i.e. **exactly the endpoint and
exactly the secret the BFF receiver already verifies**. The api-inbox leg is
*unconditional*: only account-type webhooks filter on `subscriptions`.

**Consequence: the BFF is already receiving typing events today and silently
204s them.** No Chatwoot config change is needed — only code. (Payload never
reaches the agent-bot webhook: `AgentBotListener` is a separate path.)

Payload (source-exact):

```
{ event: "conversation_typing_on" | "conversation_typing_off",
  user: { id, name, email, type: "user" },   # ← real chatter, PII
  conversation: <Conversations::EventDataPresenter#webhook_data>,
  is_private: <bool> }
```

- `conversation.id` is `display_id` (`app/presenters/conversations/event_data_presenter.rb`
  → `push_data`: `id: display_id`) — the same key the message webhook uses, so
  the existing `chatwootConversationId` → conversation lookup applies unchanged.
- `is_private: true` = the chatter is typing a **private note**, not a reply.
  Must not raise the user-facing indicator.
- `user` is the real Chatwoot agent **including their email**. `AURAD-0001`
  forbids it reaching the app; build rule 3 forbids it reaching the logs.

## C2 — Chatwoot emits `typing_on` ONCE per burst (this breaks the 10s number)

`@chatwoot/utils` `createTypingIndicator` (dist read) + `Editor.vue`:

```js
start() { if (!timer) onStartTyping();  reset(); }   // keyup
stop()  { if (timer)  { clear; onStopTyping(); } }   // blur, or idle timeout
reset() { timer = setTimeout(stop, idleTime) }       // TYPING_INDICATOR_IDLE_TIME = 4000
```

`typingIndicator.start()` fires on **keyup**, but `onStartTyping` only runs when
no timer is armed. So a chatter typing continuously for 60 s produces **one**
`typing_on` at t≈0 and one `typing_off` ≈4 s after the last keystroke. There is
**no keepalive**.

This directly contradicts the assumption behind 001-check's "~10 s" auto-clear:
a 10 s TTL would hide the indicator while the chatter is still writing, and it
would only come back if they paused ≥4 s and resumed. Consequences worked
through in the spec (D2).

Natural clears that do exist: `typing_off` on 4 s idle, `typing_off` on editor
blur, and — because sending is a keystroke — a `typing_off` ≈4 s after send.
The app additionally clears its indicator on `message.new` for that advisor.

## C3 — No availability webhook; availability must be polled

`ALLOWED_WEBHOOK_EVENTS` has no agent/availability event. Availability is only
readable:

- `GET /api/v1/accounts/{id}/inboxes/{inboxId}/assignable_agents` →
  `payload[]` rendered by `app/views/api/v1/models/_agent.json.jbuilder`:
  `{ id, availability_status, auto_offline, email, name, role, … }`.
  `Inbox#assignable_agents` = inbox members **+ all account administrators**.
  `InboxPolicy#assignable_agents? → true`.
  Carries a stale `# Deprecated: removed in 2.7.0` comment — still present and
  routed in 4.15.1.
- `GET /api/v1/accounts/{id}/agents` — account-wide equivalent, authorization
  path not verifiable without the live instance.

`availability_status` ∈ `online | offline | busy` (`User`/`AccountUser`
`enum availability: { online: 0, offline: 1, busy: 2 }`), and
`AvailabilityStatusable#user_availability_status` resolves it through
`OnlineStatusTracker` (Redis presence) when `auto_offline` is set — so it
reflects a genuinely connected agent, not just a manual toggle. Good: it is
demonstrable in the manor by toggling availability in the dashboard.

Both responses carry agent **name + email** — PII that must die at the adapter.

## C4 — Per-persona teams are a plan, not a deployment

`AURAD-0001` describes persona → Chatwoot **team** routing ("or one 'Advisors'
team + assignment rules"). Nothing in the BFF config, env schema, or Prisma
schema knows about teams; `TECH-DEBT #10` records that `advisors` rows are
registered manually with no catalog. So per-team availability is not
implementable today without new ops config. Whatever v1 does must degrade to
the "one pool answers every persona" shape that is actually deployed.

## C5 — The BFF has no advisor catalog, by design

`@aura/contracts` v0.3.0 states it outright: *"the BFF has no advisor catalog
endpoint (personas are app-side data per AURAD-0001; the BFF's `advisors` table
holds prices only)"*. The only advisor sets the BFF can enumerate are
(a) the `conversations` rows of a given user and (b) the partial `advisors`
price table. This bounds which personas presence can be emitted for.

## C6 — App side is fully plumbed; no app changes needed (verified in the app repo)

`aura-app/src/features/chat/model/ChatProvider.tsx` already handles all four
events; `WsServerEvent.safeParse` **silently drops** anything that does not
match, so an emitted payload that is one field name off is invisible rather
than loud.

- `typing.update` → `setTypingAdvisorId(...)`; also cleared on `message.new`
  for the same advisor. Consumed by `screens/chat-thread` (`isTyping`).
- `presence.update` → `setPresence(prev => ({...prev, [advisorId]: online}))`.
  Consumed by `screens/chat-thread` and `screens/chats` as
  `presence[advisorId] ?? seedAdvisor.online` — **absence falls back to the seed
  flag in `entities/advisor/config/advisors.ts`.** Advisors the BFF says nothing
  about keep their seed dot; this is the graceful degradation `AURAT-0006`
  designed, and it is also the escape hatch for C5.
- Tests already exist app-side (`ChatProvider.test.tsx`: "typing.update drives
  the typing indicator", "presence.update overrides persona presence").

## C7 — Contracts: v0.3.0 has the events; the BFF's local copy does not

Installed `@aura/contracts@0.3.0` `WsServerEvent` union (source-exact):

```
{ type: 'message.new',     advisorId: AdvisorId, message: Message }
{ type: 'session.updated', advisorId: AdvisorId, session: Session }
{ type: 'presence.update', advisorId: AdvisorId, online:  boolean }
{ type: 'typing.update',   advisorId: AdvisorId, typing:  boolean }
```

`AdvisorId = z.string().min(1)`.

The BFF's `src/contracts/message.ts` `wsServerEventSchema` has only the first
two. Migration friction found while checking whether to just adopt the package:

- v0.3.0 exports **no** `EnsureConversationResponse` — the BFF's
  `PUT /v1/advisors/:id/conversation` response shape exists only locally, so
  adoption today would be partial and would need a contracts release first.
- Naming diverges: package `Message` / `HistoryResponse` (schema *and* type share
  a name) vs BFF `messageSchema` + `MessageDto`. Adoption rewrites imports in
  ~15 files.
- The BFF also carries `src/contracts/openapi.ts` (hand-written Swagger schemas)
  which has no counterpart in the package.

## C8 — BFF wiring the task must fit into

- `chatwoot-webhook.controller.ts` — verifies HMAC, calls
  `normalizeWebhookMessage`, drops everything that is not an advisor message,
  enqueues to `chatwoot-webhook`, returns 204. Thin by rule.
- The controller enqueues rather than calling a service **because
  `ChatwootModule` must not depend on `ChatModule`** — `jobs/` imports both and
  is the established seam that breaks the cycle. Any new inbound path has the
  same constraint.
- `ChatGateway` — in-process `Map<userId, Set<WebSocket>>`, `emitToUser(userId,
  WsServerEvent)`, Firebase-authed handshake, server→client only, no
  `@SubscribeMessage`. Single instance by `AURAD-0005`; scale-out is
  `TECH-DEBT #8`.
- `DeliveryService` — `fanOut` (WS + FCM queue) and `pushSessionUpdate` (WS
  only, inline). Precedent for a WS-only, non-stored live event.
- `DeliveryModule` does **not** import `ChatwootModule` → a new module may
  depend on both without a cycle.
- `ChatwootMessagingPort` — the domain boundary (`resolveConversation`,
  `listConversations`, …). `ConversationsRepository` has `findByUserAndAdvisor`
  / `findById` / `findByChatwootConversationId` / `listAll` / `create` — no
  per-user listing yet.
- `ReconciliationScheduler` — `upsertJobScheduler(id, { every: 60_000 })`,
  skipped when `NODE_ENV === 'test'`. The pattern any new poll should copy.
- `queues.ts` — per-queue `defaultJobOptions`; `reconciliation` already uses
  `attempts: 1` with the comment "a failed run just waits for the next".
- Logging is pino with `x-chatwoot-signature` and `authorization` redacted;
  bodies are never logged.

## Contradictions / corrections

| Claim | Reality |
|---|---|
| 001-check: "contracts v0.2.0" | **v0.3.0**; the app is on it, and both events are already in its `WsServerEvent`. |
| 001-check: "auto-clear ~10 s" | Rests on typing_on repeating. It does not (C2) — 10 s would hide the indicator mid-composition. Spec D2. |
| 001-check: "extend the accepted-event set" implies config work | No Chatwoot config needed — the api-inbox webhook already delivers typing (C1). Code only. |
| `AURAD-0001`: presence = "a chatter available for that persona's **team**" | Teams are not deployed (C4). v1 must approximate at inbox scope and say so. |
