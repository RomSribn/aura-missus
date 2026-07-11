# AURAT-0005-005 — Context

Date: 2026-07-11

## Sources checked

Brain (high trust): AURAF-0007, AURAI-0002 (§2.3/2.4/5.4), AURAD-0001/0003/0005,
AURAT-0004 task folder, AURAT-0006 spec (consumer expectations). Ground truth:
full read of `slave-1/master` (develop @ 24e6727) via explore agent +
TECH-DEBT.md.

## Key findings — what the foundation already gives us

- **Sealed Chatwoot adapter**: `ChatwootClient` (contacts, contact-inboxes,
  conversation create; `api_access_token` header; 10s timeout; PII-safe
  errors). **No message send/list, no webhook code yet.**
- **ProvisioningService.ensureConversation(auth, advisorId)** — idempotent
  (user upsert + `@@unique([userId, advisorId])`, P2002 convergence). Exported
  from ChatwootModule (the only export). Orphan-conversation note at
  `provisioning.service.ts:50` defers reconciliation to this task.
- **Prisma**: only `User` + `Conversation` models. No Message, no device
  tokens. Prisma 7, generated client in `src/generated/prisma`.
- **BullMQ**: root connection only; comment reserves queues for
  webhook-processing / reconciliation / FCM fan-out. No queues registered.
- **Env schema**: `CHATWOOT_WEBHOOK_SECRET` + `CHATWOOT_HMAC_TOKEN` already
  optional-reserved for this task. `CHATWOOT_INBOX_IDENTIFIER` validated but
  unused. Pino already redacts `x-chatwoot-signature`.
- **No raw-body config** on the Fastify adapter — required for HMAC webhook
  verification (`rawBody: true` at NestFactory + `req.rawBody`).
- **No WS/FCM deps**: need `@nestjs/websockets` + `@nestjs/platform-ws` + `ws`;
  FCM comes free via installed `firebase-admin` (messaging).
- **Auth**: global FirebaseAuthGuard → `AuthUser {firebaseUid, phoneE164}`;
  `@Public()` for unauthenticated routes (webhook will need it + HMAC).
- **Tests**: colocated pure-unit specs, hand-built mocks, fetch spy pattern;
  AURAT-0004 also proved a "real AppModule + faked boundaries" smoke-drive
  pattern (steps 009/010) — reusable for the webhook/send drive here.
- **Tech debt pointed at this task**: #2 nestjs-zod trigger = first request
  body (send endpoint) — we stay with existing `ZodValidationPipe` (body
  usage), note re-check at Nest 12 GA; #3 worker split-readiness = keep
  processors thin; #6 rate-limit tuning when WS lands.

## Consumer expectations (AURAT-0006 spec)

App will need from the BFF: REST history/send, **WS live channel**, **FCM
send + device-token registration**. So the `delivery` module (FCM sender, WS
gateway, device registry) belongs to this task — matches build-rules module
map ("AURAT-0005 adds chat + delivery + jobs").

## Contradictions / gaps flagged

1. **001-check acceptance doesn't test FCM/WS** (untestable without the app),
   but build rules + AURAT-0006 require the BFF side to exist now → include
   in scope; verify by unit tests + smoke drive; end-to-end proof lands with
   AURAT-0006.
2. **Persona presence/typing** (AURAF-0007-004 BE side) is in neither
   001-check scope nor AURAT-0006's "already in place" — a scope gap between
   0005 and 0006. Recommend: defer, decide when planning 0006.
3. **Exact Chatwoot webhook timestamp header name** — AURAI-0002 gives the
   signature formula (`sha256=HMAC(secret, "{timestamp}.{body}")`) but not the
   timestamp header name; and whether the Agent Bot webhook signs with the
   same secret is unverified. Implement verifier configurably; confirm against
   live Chatwoot in the manor.
4. Concurrency: slave-2 is on AURAT-0007 (also adds Prisma models) — keep our
   schema additions append-only to ease the integration merge.

Next: spec (006).
