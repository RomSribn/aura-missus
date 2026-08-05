# AURAT-0009-006 — Execute

Date: 2026-08-05
Branch: `feature/AURAT-0009-bff-presence-typing` (slave-1, master + missus)
Status: implemented, **staged, not committed** — awaiting IDE review.

## Verification (slave-legal only)

```
npm run typecheck   ✓
npm run lint        ✓
npm run build       ✓
npm test            ✓  23 suites, 190 tests (was 183)
```

No stack started, no DB/Redis/Chatwoot touched. Runtime proof is manor-only.

## What landed

**Contracts** — `src/contracts/message.ts`: `presence.update {advisorId, online}`
and `typing.update {advisorId, typing}` added to `wsServerEventSchema`, mirroring
`@aura/contracts@0.3.0` field-for-field. `src/contracts/message.spec.ts` (new)
pins the shape, including the near-miss names a hand-copied contract drifts into
(`isOnline`, `isTyping`, `online: 'true'`) — necessary because the app's
`WsServerEvent.safeParse` drops a mismatch **silently**.

**Adapter (`modules/chatwoot`)**

- `webhook-events.ts` (new) — `normalizeWebhookEvent` is now the single table of
  accepted events, returning `{kind:'message'|'typing', …}`. Drops private-note
  typing and anything without a numeric conversation id. `user` is not declared
  in `CwWebhookTypingWire` at all, so the chatter cannot be read, forwarded or
  logged — what is not declared cannot leak.
- `chatwoot-webhook.controller.ts` — dispatches on kind: messages to the
  `chatwoot-webhook` queue as before, typing to the new `presence` queue with a
  `receivedAt` stamp. Still thin; still 204s everything else.
- `chatwoot.client.ts` — `fetchInboxAvailability()` reads
  `GET /accounts/{id}/assignable_agents?inbox_ids[]={inboxId}` and returns
  `{ onlineAgentCount }` — a count, never a roster. The service User is excluded,
  its id resolved once from `GET /api/v1/profile` (outside the `/accounts/{id}`
  prefix — hence the new `requestAbsolute` split) and cached, or taken from
  `CHATWOOT_SERVICE_AGENT_ID`. `busy` is not counted as online.
- `chatwoot-messaging.port.ts` / `.service.ts` — `AgentDeskTypingEvent`,
  `listAdvisorIdsForUser`, `fetchInboxAvailability`.
- `conversations.repository.ts` / `prisma-…` — `listAdvisorIdsByUser` (the
  internal half of the deferred `GET /v1/conversations`).

**`modules/presence` (new)**

- `typing.service.ts` — per-conversation state machine. Emits only on a
  transition, re-arms the TTL on a repeated `typing_on`, ignores events that
  arrive behind a newer one or older than the TTL, and unrefs its timers.
  Deliberately no per-agent refcount: it would mean retaining chatter ids, which
  `AURAD-0001` says are discarded at the backend.
- `presence.service.ts` — polls availability, emits on change plus a snapshot on
  WS connect; keeps the last known value on a read failure (rate-limited warning)
  so a flaky agent desk cannot flap the dot; stays silent until the first
  successful read so the app keeps its seed flag rather than a guess.
- `presence.module.ts` — imports chatwoot + delivery; nothing imports it, which
  is also why the receiver reaches `TypingService` through the queue.

**Delivery** — `chat.gateway.ts`: `onUserConnected(listener)` (best-effort, a
throwing listener cannot take the socket down) and `connectedUserIds()`.
`delivery.service.ts`: `pushTyping` / `pushPresence`, WS-only.

**Jobs** — `presence` queue (`attempts: 1`, small retention — a retried typing
event is stale noise, and no-retry + concurrency 1 keeps an on/off pair FIFO),
`presence.processor.ts` (thin, dispatches by job name), `presence.scheduler.ts`
(repeatable poll, same `upsertJobScheduler` pattern as reconciliation, skipped
under `NODE_ENV=test`). Wired into `jobs.module.ts` and `app.module.ts`.

**Config** — `TYPING_TTL_SECONDS` (45, 5–300), `PRESENCE_POLL_SECONDS` (30,
10–600), `CHATWOOT_SERVICE_AGENT_ID` (optional). `.env.example` documents all
three with the reasoning.

**Docs** — `README.md` (module layout, WS event list, accepted webhook events, a
delivery-model section for the WS-only liveness pair), `TECH-DEBT.md` #8 extended
+ new #11 (contracts copy), #12 (`GET /v1/conversations`), #13 (inbox-wide
presence). Missus: `AURAF-0007` row 004 BE ✗→✓ plus an AURAT-0009 context entry.

## Decisions made while implementing

1. **`normalizeWebhookEvent` replaced the controller's ad-hoc filtering** rather
   than sitting beside it. The accepted-event set is now one table in the
   adapter, which is what scope item 3 was really asking for.
2. **Split `request` into `request` / `requestAbsolute`** — `/api/v1/profile` is
   not account-scoped. Its body also contains the owner's `access_token`; only
   `id` is read and the body is never logged.
3. **`presence` is its own queue, not a job name on `chatwoot-webhook`** — the
   two need opposite retry semantics (recover a lost message / never replay a
   stale signal), and retries would reorder an on/off pair.
4. **Existing mocks widened** in four specs for the new port/repository members
   (`chat.service`, `provisioning.service`, `chatwoot-messaging.service`,
   `chatwoot-webhook.controller`) — no behavioural change to those tests.

## Known limits (recorded, not hidden)

- Presence is one inbox-wide value; advisors a user never messaged get no event
  and keep the app's seed dot (TECH-DEBT #13, #10).
- Typing has no per-agent refcount — two chatters on one thread, and the first
  `typing_off` clears the indicator (rare; one thread is worked by one chatter).
- Typing state and the cached presence value are process-local, like the socket
  registry they feed (TECH-DEBT #8).
- The primary availability endpoint is `assignable_agents`; if the service token
  is refused there, the documented fallbacks (`/inboxes/{id}/assignable_agents`,
  then `/agents`) are a one-line change — resolvable only against the live
  instance, i.e. in the manor.

## Next

IDE review of the staged diff → commit (master only) → merge gate.
