# AURAT-0009-004 — Spec: BFF persona presence + typing

Date: 2026-08-05
Status: **approved** (owner-ratified 2026-08-05 — see `005-approval`)
Closes: `AURAF-0007-004` BE column (the last v1 free-chat gap)
Depends on: `AURAT-0005` (HMAC receiver, WS gateway) ✓, `@aura/contracts` v0.3.0 ✓
Grounded in: `AURAD-0001`, `AURAD-0005`, `AURAD-0006`, Chatwoot v4.15.1 source
(see `003-context` — every Chatwoot claim is a direct source read)

## 1. Goal

The BFF starts emitting the two persona-level WS events the app already
consumes and currently never receives:

- `typing.update { advisorId, typing }` — driven by Chatwoot
  `conversation_typing_on` / `conversation_typing_off`.
- `presence.update { advisorId, online }` — driven by Chatwoot agent
  availability.

No app changes (`003-context` C6). The individual chatter's identity never
leaves the adapter — not to the app, not to the store, not to the logs.

## 2. Decisions

### D1 — Transport path: webhook → dedicated `presence` queue → service

The receiver keeps enqueuing rather than calling a service directly. This is
not ceremony: `ChatwootModule` must not depend on a domain module, and `jobs/`
is the established seam that breaks that cycle (`003-context` C8). A **new,
dedicated `presence` queue** rather than reuse of `chatwoot-webhook`:

| | `chatwoot-webhook` | `presence` (new) |
|---|---|---|
| attempts | 5, exponential | **1** — a retried typing event is stale noise, not lost data |
| ordering | retries can reorder | concurrency 1, no retries ⇒ FIFO on/off preserved |
| retention | 1 000 / 5 000 | 100 / 100 — ephemeral signal |

Belt-and-braces: the job carries `receivedAt` (server clock at receipt) and the
service ignores an event older than the one it last applied for that
conversation, plus drops anything older than the TTL outright.

### D2 — Typing TTL: **45 s**, not 10 s (`TYPING_TTL_SECONDS`, env-tunable)

001-check proposed ~10 s. That rests on `typing_on` repeating while the chatter
types. **It does not** — Chatwoot fires it **once per burst** and never
refreshes it (`003-context` C2, source-verified). A 10 s TTL therefore hides the
indicator *while the chatter is still writing*, and it cannot return until they
pause ≥4 s and resume. That is a visibly broken indicator, and it would fail the
owner's own acceptance ("гаснет по стопу или по таймауту" — not "гаснет пока
чаттер печатает").

The TTL is only ever a **safety net for a lost `typing_off`**, because the real
clears all already exist and are fast:

- `typing_off` ≈4 s after the last keystroke (idle timer),
- `typing_off` on editor blur,
- `typing_off` ≈4 s after send (send is a keystroke),
- the app clears its own indicator on `message.new` for that advisor.

So the only cost of a longer TTL is a stale "typing…" after a chatter abandons a
draft *and* the webhook is lost — and even that is wiped by their next reply.
**45 s** covers a normal composition burst with margin. Tunable via
`TYPING_TTL_SECONDS` so the manor can retune without a code change.

> Owner call available: 30 s (tighter, small risk of cutting a long burst) or
> 45 s (recommended). 10 s is not recommended and I would rather not ship it.

### D3 — Debounce = emit on state change only; no per-agent refcount

State is kept per conversation: `{ typing: boolean, expiresAt }`. A
`typing.update` goes out **only on a transition** (off→on, on→off), so repeated
or overlapping events never flap the socket. `typing_on` re-arms the TTL.

Two chatters typing on the same conversation are *not* refcounted — last event
wins. Refcounting would mean retaining Chatwoot agent ids in BFF memory, and
`AURAD-0001` says the chatter identity is **discarded at our backend**; the
normalizer therefore never reads `user` at all. The failure mode (chatter A
stops, indicator clears while B still types) is rare — one thread is worked by
one chatter — and self-limiting.

### D4 — Presence source: **Chatwoot agent availability for our inbox**, polled

Rejected: **advisor-catalog flag.** The `advisors` table holds prices only, rows
exist solely for bookable advisors and are registered manually (`TECH-DEBT #10`),
and the value would be static — the event would carry nothing the app's seed
flag does not already have. It would satisfy the letter of the task and none of
its point.

Chosen: **Chatwoot agent availability**, which is live, honest, and demonstrable
in the manor by toggling availability in the dashboard.

- Read: `GET /api/v1/accounts/{id}/assignable_agents?inbox_ids[]={inboxId}` —
  scoped to our inbox, renders the `_agent` partial with `availability_status`.
  Fallbacks if the service token is refused, in order, manor-verified:
  `/inboxes/{inboxId}/assignable_agents`, then `/agents`. (Same
  primary-plus-documented-fallback pattern `AURAT-0008` used for
  `message_type: 'activity'`.)
- `online = ∃ agent : availability_status === 'online'`. **`busy` counts as
  offline** — a chatter marked busy is deliberately not taking work.
- **The service User is excluded.** Our own token owner is an account user and
  would otherwise pin the persona permanently online. Its id is resolved once via
  `GET /api/v1/profile` and cached; `CHATWOOT_SERVICE_AGENT_ID` is an optional
  override. Note `/profile` sits outside the `/accounts/{id}` prefix and its body
  contains `access_token` — the client reads `id` only and the body is never
  logged.
- Poll every `PRESENCE_POLL_SECONDS` (default **30 s**) — Chatwoot has no
  availability webhook (`003-context` C3). Repeatable BullMQ job, same
  `upsertJobScheduler` pattern as the reconciliation sweep, skipped under
  `NODE_ENV=test`.
- On read failure: keep the last known value, log a rate-limited warning, emit
  nothing. Presence degrades to the app's seed flag rather than flapping.

**v1 is inbox-scoped, so every persona gets the same value.** `AURAD-0001` wants
per-persona *team* availability, but teams are not deployed (`003-context` C4)
and the inbox is one pool answering every persona — which is exactly the
"one 'Advisors' team" shape `AURAD-0001` names as the alternative. So the value
is accurate for what is actually running. Per-team refinement is recorded as
follow-up, not faked now.

### D5 — Which advisors get a `presence.update`, and when

The BFF has **no advisor catalog** — by contract, personas are app-side data
(`003-context` C5). The only enumerable set is the advisors a user actually has
a conversation with. So:

- **On WS connect** — emit the current value for that user's advisors, so a
  freshly opened app gets its dots immediately instead of waiting up to 30 s.
- **On change** — when a poll flips the value, emit to every connected user for
  each of their advisors.

Known limit, stated plainly: **an advisor the user has never messaged keeps its
seed dot** (the app's `presence[advisorId] ?? seedAdvisor.online`). That is the
graceful degradation `AURAT-0006` designed. Lifting it needs an advisor catalog
(`TECH-DEBT #10`), not this task.

Mechanics: `ChatGateway` grows `onUserConnected(listener)` and
`connectedUserIds()`; `PresenceService` subscribes at module init. Dependency
runs presence → delivery only, so no cycle.

### D6 — `GET /v1/conversations`: **not in this task** (only its internal half)

Recommendation: **defer the public endpoint, pay the internal capability.**

- Its response shape (last message? unread count? ordering? empty threads?) is a
  product decision that must be co-designed with the app's Chats tab, and it
  needs a `@aura/contracts` release plus an app task before it does anything for
  a user.
- Shipping it here would land an endpoint no client calls — build rule 8, "no
  unreachable endpoints", forbids exactly that.
- What presence genuinely needs is only `ConversationsRepository.listAdvisorIdsByUser(userId)`
  — which is also the whole backbone of the future endpoint. That gets built
  here, so the follow-up is a controller and a DTO, not a design.

Follow-up to mint in `aura-app-manor` (no IDs minted here): *app conversations
list endpoint* — `GET /v1/conversations` + contracts bump + Chats-tab adoption,
retiring the per-seed-advisor delta-sync (`AURAT-0006` G4).

### D7 — `@aura/contracts` migration: **not in this task**

Recommendation: **defer.** v0.3.0 exports no `EnsureConversationResponse`, so
adoption today would be *partial* and would need a contracts release first; the
package's naming (`Message` as both schema and type) differs from the BFF's
(`messageSchema` + `MessageDto`), so adoption rewrites imports across ~15 files;
and `src/contracts/openapi.ts` has no counterpart there (`003-context` C7). That
is a mechanical, zero-behaviour refactor with real regression surface, and
bundling it into the task that must prove a live typing indicator makes both
harder to review.

Instead: add the two events to `src/contracts/message.ts` **mirroring v0.3.0
field-for-field**, and lock it with a unit test asserting the exact emitted
payload shapes. This matters more than usual because the app's
`WsServerEvent.safeParse` **silently drops** a mismatched event — a typo would
be invisible, not loud (`003-context` C6).

Recorded as a `TECH-DEBT` row: migrate to `@aura/contracts` once the package
carries the BFF-only shapes.

### D8 — Widened accepted-event set (scope item 3)

A single `normalizeWebhookEvent(body)` in the adapter becomes the one explicit
table of accepted events, returning a discriminated union:

```ts
type NormalizedWebhookEvent =
  | { kind: 'message'; chatwootConversationId: number; message: ChatwootMessage }
  | { kind: 'typing';  chatwootConversationId: number; typing: boolean };
```

- `message_created` → existing path, unchanged behaviour.
- `conversation_typing_on` / `_off` → new path.
- **`is_private: true` is dropped** — a chatter typing a private note is not
  replying to the user.
- `user` (id / name / **email**) is never read — the field does not appear
  anywhere in the code path, so it cannot leak to the app or the logs
  (`AURAD-0001`, build rule 3).
- Everything else → 204, as today.

No Chatwoot configuration change is required: the api-inbox webhook already
delivers typing events unconditionally and signs them with the secret the
receiver already verifies (`003-context` C1).

## 3. Flow

```
chatter types in dashboard
  → Chatwoot conversation_typing_on  (api-inbox webhook, HMAC-signed)
  → ChatwootWebhookController: verify → normalizeWebhookEvent → kind 'typing'
  → queue `presence` job 'typing' { chatwootConversationId, typing, receivedAt }
  → PresenceProcessor (thin)
  → TypingService: resolve conversation → transition? → arm 45 s TTL
  → DeliveryService.pushTyping → ChatGateway.emitToUser
  → app: typing.update → persona indicator

clears on: typing_off (≈4 s idle / blur / after send) · TTL expiry · message.new

presence poll (30 s)                    WS connect
  → PresenceService.refresh()             → PresenceService.onUserConnected(userId)
  → adapter: assignable_agents            → emit cached value for that
     → availability only, no PII             user's advisors
  → changed? → emit to all connected
```

`presence.update` and `typing.update` are **WS-only** — no FCM, no store. They
are live-foreground signals with no meaning once stale, so build rule 5
("delivery fed from the same stored message") does not apply; the precedent is
`DeliveryService.pushSessionUpdate` (`AURAT-0008`).

## 4. Files

**master**

| File | Change |
|---|---|
| `src/contracts/message.ts` | + `presence.update` / `typing.update` in `wsServerEventSchema` (mirror v0.3.0) |
| `src/config/env.schema.ts` | + `TYPING_TTL_SECONDS` (45), `PRESENCE_POLL_SECONDS` (30), `CHATWOOT_SERVICE_AGENT_ID` (optional) |
| `src/modules/chatwoot/chatwoot.types.ts` | + typing/agent wire shapes + domain `AgentAvailability` |
| `src/modules/chatwoot/webhook-events.ts` **(new)** | `normalizeWebhookEvent` — the accepted-event table |
| `src/modules/chatwoot/chatwoot-webhook.controller.ts` | dispatch on event kind; stays thin |
| `src/modules/chatwoot/chatwoot.client.ts` | + `listInboxAgentAvailability()`, `getServiceUserId()` |
| `src/modules/chatwoot/chatwoot-messaging.port.ts` | + `AgentDeskTypingEvent`, `fetchInboxAvailability()`, `listAdvisorIdsForUser()` |
| `src/modules/chatwoot/chatwoot-messaging.service.ts` | implement the above |
| `src/modules/chatwoot/conversations.repository.ts` + `prisma-conversations.repository.ts` | + `listAdvisorIdsByUser(userId)` (D6 internal half) |
| `src/modules/chatwoot/chatwoot.module.ts` | register the `presence` queue (producer side) |
| `src/modules/delivery/chat.gateway.ts` | + `onUserConnected(listener)`, `connectedUserIds()` |
| `src/modules/delivery/delivery.service.ts` | + `pushTyping()`, `pushPresence()` |
| `src/modules/presence/` **(new)** | `presence.module.ts`, `typing.service.ts`, `presence.service.ts` |
| `src/jobs/queues.ts` | + `PRESENCE_QUEUE`, job names, options, payload types |
| `src/jobs/presence.processor.ts`, `presence.scheduler.ts` **(new)** | thin delegate + repeatable poll |
| `src/jobs/jobs.module.ts`, `src/app.module.ts` | wire `PresenceModule` |
| `README.md`, `TECH-DEBT.md` | env table + new debt rows |

New module `presence` = persona liveness (typing + online), deliberately
separate from `chat` (the message store) and `delivery` (transport). It imports
`ChatwootModule` + `DeliveryModule`; neither imports it — no cycle.

**missus:** step files; `AURAF-0007` row 004 BE ✗→✓ + context line; follow-up
notes for D6/D7.

## 5. Tests (pure — slave-legal)

- `webhook-events.spec.ts` — typing on/off normalize; `is_private: true`
  dropped; unknown event → null; missing conversation id → null; **`user` never
  appears in the normalized output**.
- `typing.service.spec.ts` (fake timers) — on ⇒ one emit; repeated on ⇒ no
  re-emit, TTL re-armed; off ⇒ emit false; TTL expiry ⇒ emit false; stale
  `receivedAt` ignored; unknown conversation ⇒ no emit.
- `presence.service.spec.ts` — `online` iff some non-service agent is `online`;
  `busy` ⇒ offline; service user excluded; emit only on change; emit per advisor
  on connect; read failure ⇒ last value kept, nothing emitted.
- `chatwoot.client.spec.ts` — agent payload maps to availability only (no name,
  no email in the domain shape).
- `chatwoot-webhook.controller.spec.ts` — typing enqueues on `presence`; message
  path unchanged; other events still 204.
- Contract-shape test on the two new events (D7 drift guard).

Then `lint`, `typecheck`, `build`, `test`.

## 6. Not in scope

`GET /v1/conversations` endpoint (D6) · `@aura/contracts` migration (D7) ·
per-persona team availability (D4) · presence for advisors with no conversation
(D5) · user→advisor typing (the app does not send it; the gateway stays
server→client only) · Redis-backed cross-instance state (`TECH-DEBT #8`;
single instance per `AURAD-0005`) · any app change.

## 7. Acceptance

**Slave (here):** lint + typecheck + build + unit tests green; no Chatwoot type,
header, or agent identity outside `src/modules/chatwoot/`.

**Manor (after merge — the real proof):**

1. Chatter types in the dashboard → persona typing indicator appears live in the
   app; stops typing → clears within ~4–6 s; kill the webhook mid-burst →
   clears at the TTL.
2. Chatter types a **private note** → **no** indicator.
3. Toggle the agent's availability Online → Busy → Offline in the dashboard →
   the persona dot follows within one poll; the service User alone online ⇒ dot
   stays off.
4. Logs contain no agent name, email, or id — and no message content.
5. Two personas, one user: both dots track the same inbox availability; neither
   ever names a chatter.

## 8. Owner decisions requested

1. **Typing TTL — 45 s (recommended) or 30 s?** 10 s is source-disproven (D2).
2. **`GET /v1/conversations` — defer (recommended, D6)?** Confirm the follow-up
   gets minted in `aura-app-manor`.
3. **`@aura/contracts` migration — defer (recommended, D7)?**
4. **Presence scope — inbox-wide for every persona (D4/D5)?** Confirms that
   advisors never messaged keep their seed dot in v1.
