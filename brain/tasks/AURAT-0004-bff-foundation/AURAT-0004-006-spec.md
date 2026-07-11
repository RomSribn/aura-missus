# AURAT-0004-006 — Implementation spec

Date: 2026-07-11
Status: draft — awaiting user approval

Scope + acceptance are fixed by `AURAT-0004-001-check.md`; this file is the
concrete build plan. No new feature file — `AURAF-0007` covers the "what".

## 1. Repo scaffold (greenfield `aura-bff`)

- **NestJS 11 + Fastify adapter**, TypeScript `strict`, Node 22 LTS
  (`engines`, `.nvmrc`, `node:22-alpine` Dockerfile).
- Tooling: ESLint (typescript-eslint) + Prettier, Jest + ts-jest for unit
  tests, `nest-cli.json`, `tsconfig.json`/`tsconfig.build.json`.
- `Dockerfile` (multi-stage build → slim runtime) and `docker-compose.yml`
  (postgres + redis + bff) — compose is **manor-only**; never run in the slave.
- `.env.example` documents every variable, no real values. `README.md` rewritten
  with service description, layout, scripts, and run instructions.

## 2. Config (`src/config/`)

- `@nestjs/config` with a **Zod** schema (`env.schema.ts`) — boot fails fast on
  missing/invalid vars (build-rule 3).
- Variables: `NODE_ENV`, `PORT`, `DATABASE_URL`, `REDIS_URL`,
  `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`,
  `CHATWOOT_BASE_URL`, `CHATWOOT_ACCOUNT_ID`, `CHATWOOT_API_ACCESS_TOKEN`
  (service-User), `CHATWOOT_INBOX_ID`, `CHATWOOT_INBOX_IDENTIFIER`,
  `CHATWOOT_WEBHOOK_SECRET` + `CHATWOOT_HMAC_TOKEN` (present in schema for
  AURAT-0005; unused now). Typed `ConfigService` wrapper per namespace.

## 3. Common layer (`src/common/`)

- **`FirebaseAuthGuard`** — global APP_GUARD. Verifies `Authorization: Bearer
  <Firebase ID token>` via Firebase Admin (`verifyIdToken`), attaches
  `{ firebaseUid, phoneE164 }` to the request. `@Public()` decorator opts out
  (health only); `@CurrentUser()` param decorator.
- **Logging**: `nestjs-pino`, request-scoped, redaction list for auth headers;
  no PII (no raw phone, no UID, no bodies) at info level (build-rule 3).
- Global `ZodValidationPipe` + exception filter mapping domain errors → HTTP.

## 4. Modules

### `modules/auth/`
- `FirebaseAdminService` — single initialized Admin app; token verification.
- `UsersService` + `UsersRepository` (interface + Prisma impl) — get-or-create
  our user row from `{ firebaseUid, phoneE164 }` (idempotent upsert).

### `modules/chatwoot/` (the sealed adapter — build-rule 1)
- `ChatwootClient` — typed HTTP client (native `fetch`/undici) speaking the
  Application API with the service-User token: contact search-by-identifier,
  contact create/update, contact-inbox ensure (get `source_id` on our inbox),
  conversation create with `custom_attributes.advisor_id`. Chatwoot payload
  types live here only; timeouts + typed errors.
- `ProvisioningService` — the domain operation
  `ensureConversation(user, advisorId) → { conversationId }`:
  1. upsert Contact (`identifier = firebaseUid`, `phone_number = E.164`),
  2. ensure ContactInbox on the env's `Channel::Api` inbox,
  3. get-or-create Conversation per (user, advisor) — **BFF-side dedupe**: read
     our map first; on miss create in Chatwoot then insert map row; unique
     constraint + retry-on-conflict makes repeat/concurrent calls converge
     (build-rule 6).
- `ConversationsRepository` (interface + Prisma impl) — the
  `(user, advisor) → conversation` map (owned here per build-rules).
- `ConversationsController` — thin transport inside the module speaking OUR
  domain only: `PUT /v1/advisors/:advisorId/conversation` → `201/200 { id,
  advisorId }` (our id; Chatwoot ids never leave the module). Idempotent PUT
  matches acceptance.

### `modules/health/`
- `@Public()` `GET /health` (liveness) and `GET /health/ready` (readiness:
  Prisma `SELECT 1` + Redis ping).

## 5. Persistence (Prisma — AURAD-0007)

`prisma/schema.prisma` + initial migration:

- `User`: `id` (cuid), `firebaseUid` **unique**, `phoneE164`, timestamps.
- `Conversation`: `id` (cuid), `userId` FK, `advisorId` (string), 
  `chatwootContactId`, `chatwootConversationId`, timestamps,
  **`@@unique([userId, advisorId])`** (AURAD-0003 dedupe).

Wallet/ledger/session tables are AURAT-0007/0008 — not created now.
Repositories behind interfaces; Prisma types never leave the data layer.

## 6. Jobs / Redis wiring

`@nestjs/bullmq` registered with `REDIS_URL`; connection healthy = readiness
input. **No queues/processors yet** — first consumers arrive with AURAT-0005.
(Wired ≠ used; keeps 0004 free of dead code: only the connection module, no
empty processors.)

## 7. API docs

`@nestjs/swagger` on the one endpoint + health; OpenAPI JSON served at
`/docs` (non-prod only).

## 8. Contracts

`src/contracts/` holds the Zod schema + inferred types for the ensure-
conversation response. Single import point, promoted to `@aura/contracts`
when the package is created (AURAT-0006 boundary work). **Open point flagged**
— creating the shared package is cross-repo and out of 0004 scope.

## 9. Testing (slave-pure)

- Unit: `ProvisioningService` (mocked client + repos — idempotency, conflict
  retry, E.164 handling), `FirebaseAuthGuard` (mocked admin SDK),
  `ChatwootClient` (mocked fetch — auth header, error mapping), config schema
  (fail-fast), `UsersService` upsert.
- `npm run lint` + `tsc --noEmit` + `nest build` green. No DB/Redis/Chatwoot in
  any test.
- Live verification (real provisioning against dev Chatwoot) = manor, post-
  merge, per workspace rules.

## 10. Out of scope (guard rails)

Webhook receiver, message send/receive, reconciliation poll, FCM/WS, agent-bot
wiring, wallet/sessions, PSP, advisor catalog. `advisorId` = opaque non-empty
string for now.

## Risks / notes

- Exact Chatwoot endpoint/payload shapes verified only at manor integration —
  unit tests mock the boundary; the client is small and isolated so fixes are
  localized.
- Firebase Admin needs service-account creds even at boot in manor; config
  validates presence, lazily initializes in tests.
