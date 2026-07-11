# AURAT-0004-008 — Execute

Date: 2026-07-11

## What was built (aura-bff @ feature/AURAT-0004-bff-foundation)

Full NestJS foundation per `006-spec`:

- **Scaffold**: NestJS 11 + Fastify, TS strict (incl. `noUncheckedIndexedAccess`),
  Node 22 (`.nvmrc`, engines), ESLint 9 flat + Prettier, Jest/ts-jest,
  `Dockerfile` (multi-stage, dev-grade), `docker-compose.yml` (manor-only),
  `.env.example`, rewritten `README.md`.
- **Config**: `src/config/env.schema.ts` — Zod schema, `validateEnv` fails fast
  at boot; AURAT-0005 secrets (`CHATWOOT_WEBHOOK_SECRET`, `CHATWOOT_HMAC_TOKEN`)
  optional until consumed.
- **Common**: global `FirebaseAuthGuard` (APP_GUARD) + `@Public()` /
  `@CurrentUser()`, `ZodValidationPipe`, pino logging with auth-header
  redaction (no PII), global Prisma + Redis providers.
- **auth module**: `FirebaseAdminService` (lazy init, modular API),
  `UsersService` + `UsersRepository` (interface) + Prisma impl — idempotent
  upsert by Firebase UID.
- **chatwoot module (sealed)**: typed `ChatwootClient` (fetch, 10s timeout,
  errors carry status+path only — no body/PII), `ProvisioningService`
  (contact upsert → contact-inbox ensure → conversation get-or-create,
  BFF-side dedupe, race convergence via unique constraint),
  `ConversationsRepository` + Prisma impl (P2002 → domain error),
  `ConversationsController` — `PUT /v1/advisors/:advisorId/conversation`.
- **health module**: `GET /health`, `GET /health/ready` (Prisma + Redis probes,
  2s timeout each).
- **jobs**: BullMQ root wiring from `REDIS_URL`; no queues yet (AURAT-0005).
- **contracts**: `src/contracts/` Zod schemas (advisorId, ensure-conversation
  response) — local until `@aura/contracts` exists (flagged, AURAT-0006).
- **prisma**: `schema.prisma` (users, conversations w/
  `@@unique([userId, advisorId])`), initial migration SQL generated **offline**
  via `prisma migrate diff` (no DB in slave); manor runs `migrate deploy`.

## Verification (slave-pure)

`npm run typecheck` ✓ · `npm run lint` ✓ · `npm test` ✓ (6 suites, 32 tests) ·
`npm run build` ✓. No DB/Redis/Chatwoot touched.

## Deviations from 006-spec (all minor)

1. Chatwoot contact identity (`chatwootContactId`, `chatwootSourceId`) cached on
   `users`, not `conversations` — contact is per-user; avoids denormalized copies.
2. Typed config = direct `ConfigService<Env, true>`, no per-namespace wrappers.
3. Zod validation as per-param pipe (no request bodies exist yet), not global.
4. BullMQ connection from `REDIS_URL` options (BullMQ bundles its own ioredis;
   sharing the instance mistypes), readiness uses the common Redis client.

## Open issues

- Chatwoot endpoint/payload shapes need live verification in manor (dev
  instance) — client normalizes defensively and is isolated for cheap fixes.
- Race loser orphans one Chatwoot conversation (harmless; reconciliation lands
  with AURAT-0005).

Next: stage both repos, user IDE review (6f gate). NOT committed.
