# AURAT-0005-008 — Execute

Date: 2026-07-11
Branch: `feature/AURAT-0005-messaging-and-delivery` (slave-1). NOT committed —
awaiting IDE review (6f gate).

## What was built (per approved spec 006)

**Prisma** (`prisma/schema.prisma` + migration
`20260711100000_add_messages_and_device_tokens`, generated via
`prisma migrate diff`, DB-less):
- `Message` — `@@unique([conversationId, chatwootMessageId])` = idempotency +
  ordering; `MessageDirection` enum USER/ADVISOR; no sender stored.
- `DeviceToken` — unique token, moves between users on re-login.
- `Conversation` + `@@index([chatwootConversationId])` (webhook resolution).

**Chatwoot module** (still sealed; new second export `ChatwootMessagingPort`):
- `chatwoot.client.ts` + `createIncomingMessage` / `listMessagesAfter`
  (paginates `after` cursor, ≤5×100 per sweep call).
- `message-normalizer.ts` — both wire dialects (REST numeric/epoch, webhook
  string/ISO — grounded by direct read of Chatwoot v4.15.1 source in
  chatwoot-manor) → one domain shape; drops activity/template/private/empty.
- `webhook-verifier.ts` — `X-Chatwoot-Timestamp` + `X-Chatwoot-Signature:
  sha256=HMAC(secret,"{ts}.{body}")` (exact `Webhooks::Trigger` format, ground
  truth — resolves 005-context gap #3), timing-safe, 300s replay window,
  optional secondary (agent-bot) secret.
- `chatwoot-webhook.controller.ts` — `POST /webhooks/chatwoot`, VERSION_NEUTRAL
  @Public, verify → normalize → filter advisor-only → enqueue (dedupe jobId)
  → 204 inside the 5s budget; enqueue failure → 500 (bot retries on 429/500).
- `chatwoot-messaging.service.ts` — port impl; our ids in, provider ids stay
  inside. `ProvisioningService.findConversation` added (history must not
  provision).

**Chat module** (new): `MessagesRepository` (+Prisma impl:
create-catch-P2002 upsert reporting `inserted`, cursor paging by our message
ids), `ChatService` (send = post→store, single `ingestResolved` path for
webhook + poll, fan-out only on fresh advisor inserts), `ReconciliationService`
(60s sweep after per-conversation watermark, per-conversation error isolation),
`ChatController` (`POST/GET /v1/advisors/:advisorId/messages`; ChatwootApiError
→ 502).

**Delivery module** (new): `ChatGateway` (plain ws `/ws?token=`, Firebase
handshake, 4401 close, per-user registry, 30s heartbeat), `DeliveryService`
(WS inline + FCM via queue, both from the stored DTO), `FcmSender` (data-only
multicast — no content in push plaintext; stale-token pruning; throw →
retry), `DevicesService/Controller` (`PUT/DELETE /v1/devices/:token`),
`DevicesRepository`.

**Jobs**: `queues.ts` (names + enqueue defaults), 3 thin processors +
`ReconciliationScheduler` (`upsertJobScheduler`, 60s, skipped in test env).
No cycles: producers register queues locally; JobsModule imports Chat+Delivery.

**Wiring**: `rawBody: true` (main.ts), `WsAdapter` (app.setup.ts), new modules
in AppModule. Env: `CHATWOOT_WEBHOOK_SECRET` now **required**,
`CHATWOOT_WEBHOOK_SECRET_SECONDARY` optional. Deps added: @nestjs/websockets,
@nestjs/platform-ws, ws (+@types/ws).

**Contracts**: `message.ts` (MessageDto, send/history/WS-event schemas),
`device.ts`. Chatwoot message ids never leave the BFF; cursors are our ids.

**Docs**: README (layout/API/delivery model), .env.example, TECH-DEBT
(#1/#2/#3/#6 updated; new #7 WS scale-out, #8 sweep enumeration).

## Verification (slave-pure)

- Gates: typecheck ✓ · lint ✓ · tests 14 suites / 82 ✓ (was 7/32) · build ✓.
- **Smoke drive** (real AppModule + FastifyAdapter + configureApp, fakes for
  Prisma/Redis/queues/Firebase/Chatwoot HTTP; driver deleted after evidence):
  16/16 — REST 401 unauth; webhook bad-sig 401 / good-sig 204 + normalized
  enqueue (sender discarded, jobId `wh-56-900`); send 201 provisions +
  posts `message_type: incoming` via the real client; WS bad token 4401;
  ingest → WS `message.new` + FCM ping; duplicate ingest → no re-delivery;
  history ordered + `after` delta; device PUT 204; FCM data-only multicast;
  sweep recovers id>watermark and fans out; unversioned 404. Pino logs showed
  `x-chatwoot-signature` absent (redaction works).

## Decisions during implementation

- Webhook enqueues **advisor messages only** (own incoming echoes skipped —
  send path stores them; poll backstops loss). Poll ingests both directions.
- Sweep recovers send-path DB failures too (same upsert key) — a nice extra
  from unifying ingestion.
- Stayed with `ZodValidationPipe` for the first request bodies (TECH-DEBT #2
  re-checked, recorded).

## Known limitations / follow-ups

- Exact live-Chatwoot verification (webhook headers on a real inbox, Agent Bot
  attach + secret, reconciliation against real API) = manor, after merge.
- Presence/typing deferred (spec decision 5).
- WS registry in-process (TECH-DEBT #7); sweep full-table (#8).

Next: stage both repos → user IDE review (6f) → commit → merge gate.
