# AURAT-0004-009 — Runtime smoke verification + 2026 best-practices audit

Date: 2026-07-11
Trigger: user asked to verify workability and research current NestJS best
practices before approving the 008 changeset.

## 1. Runtime smoke drive (slave-pure)

Method: booted the REAL `AppModule` on a REAL `FastifyAdapter` via
`@nestjs/testing`, drove HTTP through `app.inject()`. Only the four external
boundaries were faked: Prisma (in-memory), Redis client (stub), Firebase
`verifyIdToken` (token table), Chatwoot (fake `fetch` recording calls). Driver
script was temporary and deleted after the run (runtime verification proper is
manor-scope per workspace rules).

Recipe for reuse: set required env vars, `Test.createTestingModule({imports:
[AppModule]})` + `overrideProvider(PrismaService / REDIS_CLIENT /
FirebaseAdminService)`, then `app.init()` + `await
app.getHttpAdapter().getInstance().ready()` before `app.inject()`.

Results (verdict: PASS, 13 drives):

- `GET /health` → 200 `{"status":"ok"}`; `GET /health/ready` → 200 both checks.
- No auth → 401 "Missing bearer token"; bad token → 401 "Invalid or expired
  token"; `Basic` header → 401.
- First `PUT /v1/advisors/mia/conversation` (valid token) → 200
  `{"id":"conv-2","advisorId":"mia"}`; fake Chatwoot received exactly
  filter → create contact → contact_inboxes → conversations.
- Repeat call → same id, **0** Chatwoot calls (idempotency holds at the surface).
- Second advisor (`zara`) → new conversation, only `POST /conversations`
  (contact identity correctly cached on the user).
- `bad*id` advisor → 400 with the Zod message; wrong method → 404; unknown
  route → 404.
- pino request logs confirmed: `authorization` header is redacted (absent from
  logged headers), no UID/phone in logs.
- `GET /docs` → 404 in the injected app — expected: Swagger is wired in
  `main.ts` bootstrap, which the Test harness bypasses. Verify in manor.

## 2. Best-practices research (July 2026)

Web-researched digest (primary sources; saved to session memory as
`nestjs-best-practices-2026`). Version snapshot: **NestJS 11.1.x stable, v12
imminent** (ESM-first, Standard Schema/Zod native in route decorators);
**Prisma major is 7** (Rust-free, driver adapters mandatory, `prisma.config.ts`,
client emitted into src/, `moduleFormat = "cjs"` needed for CJS apps); Node 22
LTS floor confirmed.

### Where the scaffold already matches 2026 consensus

Ports-and-adapters Chatwoot module; thin controllers; repositories behind
interfaces; Zod env validation with boot-time fail-fast; global `APP_GUARD` +
`@Public()`; no `Scope.REQUEST` providers; nestjs-pino; `enableShutdownHooks()`;
`0.0.0.0` bind; single BullMQ `forRoot` connection; `app.inject()` + `.ready()`
e2e pattern; CJS on Nest 11 is correct (don't force ESM before v12).

### Deltas found (proposed, NOT applied — user decides)

| # | Delta | Size | Recommendation |
|---|-------|------|----------------|
| 1 | Prisma pinned ^6, current major is 7 (driver adapters, prisma.config.ts, src/ client, cjs flag) | medium | Do now while greenfield — avoids a real migration later |
| 2 | No `@fastify/helmet` / `@fastify/rate-limit` registered | small | Add now (register(), not middleware) |
| 3 | `/v1` as path literal vs `enableVersioning(URI)` + `@Version('1')` | small | Do before first release freezes URL shape (URL stays `/v1/...`) |
| 4 | Hand-rolled health vs `@nestjs/terminus` | small | Optional; our liveness/readiness split already matches practice |
| 5 | Hand-rolled Zod pipe vs `nestjs-zod` | small | Keep ours for one param; adopt nestjs-zod when request bodies appear (AURAT-0005); re-evaluate at v12 GA |
| 6 | Worker split-readiness (separate entrypoint for BullMQ workers) | note | Structure decision for AURAT-0005, nothing to change now |

Next: user picks which deltas to apply pre-commit (new execute step), or
approves the changeset as-is and deltas become follow-ups.
