# AURAT-0005-006 — Spec

Date: 2026-07-11
Status: draft — awaiting user approval

Implements the BE side of AURAF-0007 items 001/002/003 on the AURAT-0004
foundation. Everything below obeys the build rules (sealed Chatwoot module,
thin transport, shared contracts, idempotent seams, store-first delivery).

## 1. Data model (Prisma — append-only additions)

```prisma
enum MessageDirection { USER ADVISOR }   // USER = app→advisor (Chatwoot "incoming")

model Message {
  id                String           @id @default(cuid())
  conversationId    String
  conversation      Conversation     @relation(fields: [conversationId], references: [id])
  chatwootMessageId Int              // single ordering key (AURAI-0002 §2.4)
  direction         MessageDirection
  content           String
  chatwootCreatedAt DateTime         // Chatwoot's created_at, informational
  createdAt         DateTime         @default(now())

  @@unique([conversationId, chatwootMessageId])  // idempotency + ordering index
  @@map("messages")
}

model DeviceToken {
  id        String   @id @default(cuid())
  userId    String
  user      User     @relation(fields: [userId], references: [id])
  token     String   @unique          // FCM registration token
  platform  String?                   // 'ios' | 'android'
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@index([userId])
  @@map("device_tokens")
}
```

- No `sender` field ever stored — the webhook's Chatwoot agent identity is
  discarded at ingestion (AURAD-0001); direction + the conversation's
  `advisorId` are all the app needs to render the persona.
- Ordering = `chatwootMessageId` ascending. User messages get their id from
  the Application-API create response, agent messages from webhook/poll — one
  ordering domain.
- Idempotency: every write path (send response, webhook, poll) upserts on
  `(conversationId, chatwootMessageId)` — repeat webhook / poll overlap / retry
  ⇒ no duplicates (hard rule 6).
- Attachments: out of scope (v1 text only).
- One migration: `add_messages_and_device_tokens`.

## 2. Chatwoot adapter additions (all inside `modules/chatwoot/`)

**Client methods** (same request core, PII-safe errors):
- `createIncomingMessage({ conversationDisplayId, content })` →
  `POST /conversations/:display_id/messages` `{ content, message_type: 'incoming' }`;
  returns domain `ChatwootMessage`.
- `listMessagesAfter({ conversationDisplayId, afterId })` →
  `GET /conversations/:display_id/messages?after=…`; returns `ChatwootMessage[]`.

**Domain shape** `ChatwootMessage { id, content, kind: 'incoming'|'outgoing',
isPrivate, createdAt }` — wire types stay sealed in `chatwoot.types.ts`.

**Webhook receiver** `chatwoot-webhook.controller.ts`:
- `POST /webhooks/chatwoot`, `VERSION_NEUTRAL`, `@Public()` + HMAC guard.
- `ChatwootWebhookVerifier` (provider): timing-safe compare of
  `X-Chatwoot-Signature` against `sha256=HMAC(CHATWOOT_WEBHOOK_SECRET,
  "{timestamp}.{rawBody}")` per AURAI-0002 §2.4, with a replay-tolerance
  window. Timestamp header name confirmed against live Chatwoot in the manor
  (verifier takes header names via config-in-code, single place to fix).
- On verified `message_created`: translate wire → domain event
  `{ conversationDisplayId, message: ChatwootMessage }`, enqueue
  `chatwoot-webhook` job, return 200 immediately (5s Chatwoot timeout).
  Invalid signature → 401, no body parsing. Non-message events → 204 ignore.
- Requires `rawBody: true` on NestFactory + verifier reads `req.rawBody`.

**Module boundary**: ChatwootModule newly exports `ChatwootMessagingPort` — a
small BFF-domain interface (`postUserMessage`, `fetchMessagesAfter`) backed by
the client, so `chat` never sees Chatwoot types. Existing
`ProvisioningService` export unchanged. Env: `CHATWOOT_WEBHOOK_SECRET`
optional → **required** (boot-validated, fail fast).

## 3. `chat` module (new) — store + orchestration

- `MessagesRepository` (abstract + Prisma impl): `upsertByChatwootId`,
  `listPage(conversationId, {before?, after?, limit})`,
  `maxChatwootMessageId(conversationId)`.
- `ChatService`:
  - `sendMessage(auth, advisorId, content)` — ensureConversation (existing,
    idempotent) → `ChatwootMessagingPort.postUserMessage` → upsert stored
    message → return DTO. Chatwoot-down ⇒ 502; Chatwoot-ok-but-DB-fail ⇒
    recovered later by the poll (same upsert key).
  - `getHistory(auth, advisorId, {before?, after?, limit=50})` — page ordered
    by `chatwootMessageId` asc; `after` = delta sync on app resume, `before` =
    scroll-back.
  - `ingestAgentMessage(event)` (called by processors): filter
    `kind=='outgoing' && !isPrivate` (drop our own `incoming` echoes), resolve
    conversation by `chatwootConversationId`, discard sender, upsert; **only
    if the upsert actually inserted** → hand to `delivery` fan-out.
- `ChatController` (thin): `POST /v1/advisors/:advisorId/messages` (body
  `{content}` via `ZodValidationPipe(sendMessageSchema)`),
  `GET /v1/advisors/:advisorId/messages` (query via zod). Both `@ApiBearerAuth`.

## 4. `delivery` module (new) — FCM + WS from the same stored message

- `DevicesController` (thin): `PUT /v1/devices/:token` (body `{platform?}`) —
  idempotent upsert bound to the authed user; `DELETE /v1/devices/:token`
  (logout). `DevicesRepository` behind an abstract class.
- `DeliveryService.fanOut(storedMessage, {userId, advisorId})`:
  - **WS (inline)**: emit `message.new { advisorId, message }` to the user's
    live sockets.
  - **FCM (queued)**: enqueue `fcm-fanout` job → processor → `FcmSender`
    (`firebase-admin/messaging`, `sendEachForMulticast` to the user's tokens;
    prune tokens on `unregistered` errors). Notification payload: persona-level
    title (advisor display name is app-side → send `advisorId` + generic
    body-preview-free data payload; **no message content in the push** — PII
    stays out of FCM plaintext; app fetches via delta sync).
- `ChatGateway` (`@nestjs/platform-ws`, path `/ws`): handshake authenticates
  the Firebase ID token (`?token=` query → FirebaseAdminService.verifyIdToken;
  close 4401 on failure); one connection registry keyed by `firebaseUid`
  (in-process `Map` — single instance per AURAD-0005; Redis pub/sub only when
  we scale out, noted as debt). Heartbeat ping/pong; no client→server commands
  in v1 (send stays REST).
- Deps added: `@nestjs/websockets`, `@nestjs/platform-ws`, `ws` (+types).

## 5. `jobs` — BullMQ queues + processors (thin, worker-split-ready)

| Queue | Producer | Processor delegates to | Retry |
|---|---|---|---|
| `chatwoot-webhook` | webhook controller | `ChatService.ingestAgentMessage` | 5× exp backoff |
| `reconciliation` | repeatable job (every 60s) + on-demand | `ReconciliationService.sweep` | non-overlapping (jobId dedupe) |
| `fcm-fanout` | `DeliveryService` | `FcmSender` | 3× exp backoff |

- `ReconciliationService.sweep()`: for conversations with activity in the last
  N days (start: all — table is small; revisit at scale), compute
  `maxChatwootMessageId`, `fetchMessagesAfter`, run each through
  `ingestAgentMessage` (same filter/upsert/fan-out path — poll-recovered
  messages still push). Closes the webhook's 5s/no-retry/no-order gap
  (AURAI-0002 §2.4) **and** covers send-path DB failures.
- Processors contain zero business logic (tech-debt #3 constraint honored).

## 6. Contracts (`src/contracts/`)

`message.ts`: `messageSchema` (`{id, advisorId, direction: 'user'|'advisor',
content, createdAt}` — exposes cuid as id, `chatwootMessageId` never leaves
the BFF), `sendMessageRequestSchema` (`content: 1..4000` trimmed),
`historyQuerySchema`, `historyResponseSchema`. `device.ts`:
`registerDeviceSchema`. WS event envelope `wsEventSchema` (`message.new`).
All re-exported from `contracts/index.ts`; Swagger updated from the same
shapes.

## 7. Agent Bot (ops, manor-side)

BFF code is bot-agnostic: the receiver verifies whatever hits
`/webhooks/chatwoot`. Attaching the Agent Bot (retrying webhook, AURAD-0005)
+ setting the inbox `webhook_url` is Chatwoot-side configuration done at
manor verification time; if the bot signs with a different secret, the
verifier already supports a secondary secret via env (documented in
`.env.example`).

## 8. Testing (slave = pure unit; no DB/Redis/Chatwoot)

- Verifier: known HMAC vectors, tampered body, stale timestamp, timing-safe.
- ChatService: send happy path, Chatwoot 5xx ⇒ 502 + no store, idempotent
  re-ingest (dup webhook), incoming-echo filtered, private filtered, sender
  discarded, fan-out only on fresh insert.
- ReconciliationService: gap recovery, watermark math, no-op sweep.
- FcmSender: multicast batching, token pruning on unregistered.
- Gateway: handshake accept/reject, registry add/remove, emit targeting.
- Client methods: fetch-spy URL/headers/body, error PII-safety.
- Smoke drive (AURAT-0004 009/010 pattern): real AppModule + configureApp +
  faked boundaries — webhook 401/200, send→store→WS flow, history paging,
  device upsert. Deleted after evidence, like 0004 did.
- Gates: lint, typecheck, build, full test suite.

## 9. Out of scope (explicit)

- Persona presence/typing (gap flagged in 005-context — decide at AURAT-0006
  planning; likely small BFF follow-up).
- Attachments, read receipts, message edits/deletes.
- Redis-backed WS fan-out across instances (single-instance per AURAD-0005).
- PSP/top-ups (AURAT-0007, slave-2) — schema kept append-only for clean merge.
- Live-stack verification (manor after merge: real webhook from dev Chatwoot,
  Agent Bot attach, reconciliation against real API).

## 10. Acceptance mapping (from 001-check)

| Acceptance | Covered by |
|---|---|
| App-sent message appears in Chatwoot dashboard | §3 send → §2 `createIncomingMessage` (manor-verified) |
| Reply stored within seconds via webhook | §2 receiver → §5 `chatwoot-webhook` queue → §3 ingest |
| Recovered by poll if webhook dropped | §5 reconciliation sweep |
| Correct order | single `chatwootMessageId` key + history paging |

## Decisions for approval

1. **Delivery module in scope now** (FCM + WS + device registry) — required by
   AURAT-0006's "already in place" and the build-rules module map, even though
   001-check acceptance can't e2e-test it. Recommended: yes.
2. **Plain WebSocket** (`@nestjs/platform-ws` + `ws`), not socket.io — lighter
   RN client, no protocol lock-in; auth via Firebase token on handshake.
3. **No message content in FCM payloads** (data-only push + delta sync) — PII
   never transits FCM plaintext. App UX shows generic "New message from
   <persona>" built app-side from `advisorId`.
4. **`CHATWOOT_WEBHOOK_SECRET` becomes required** (boot fail-fast).
5. **Presence/typing deferred** to AURAT-0006 planning.
