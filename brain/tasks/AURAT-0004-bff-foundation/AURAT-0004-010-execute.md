# AURAT-0004-010 — Execute: best-practice deltas 1–3 + tech-debt register

Date: 2026-07-11
Trigger: user picked deltas 1–3 from the 009 audit; remaining items assessed
and recorded as tech debt.

## Applied

1. **Prisma 6 → 7.8** (current major):
   - `prisma`/`@prisma/client` ^7, new runtime dep `@prisma/adapter-pg`
     (driver adapters are mandatory in 7).
   - New `prisma-client` generator → client emitted into `src/generated/prisma`
     (gitignored, regenerated via `postinstall`), `moduleFormat = "cjs"`.
   - `prisma.config.ts` added (v7 CLI config); datasource URL moved out of
     `schema.prisma` (v7 rejects `url` there). Datasource block is conditional
     on `DATABASE_URL` so `prisma generate` works in DB-less envs (slave/CI) —
     the v7 CLI also no longer auto-loads `.env` (README notes this).
   - `PrismaService` now passes `new PrismaPg({ connectionString })` to the
     client; repository imports switched to the generated client.
   - Dockerfile: copies `prisma.config.ts`, runs `prisma generate` in build.
2. **`@fastify/helmet` + `@fastify/rate-limit`** registered via
   `app.register()` (CSP production-only — Swagger UI needs inline assets, and
   `/docs` is disabled in prod anyway). Global limit 120/min.
3. **Nest URI versioning**: `enableVersioning(URI, defaultVersion '1')`;
   controllers use plain paths (`advisors`), health is `VERSION_NEUTRAL`.
   URL shape unchanged (`/v1/...`, `/health`).
4. New `src/app.setup.ts` — shared `configureApp()` used by `main.ts` and test
   harnesses, so drives exercise exactly the production wiring.

## Bug found & fixed by the re-verification

**`@fastify/static` was missing** — `SwaggerModule.setup()` on Fastify
`loadPackage`s it and calls `process.exit(1)` when absent (silently, if the
Nest logger is disabled). The original changeset would have **died at real
boot in the manor**. Added `@fastify/static ^8`; `/docs` now serves Swagger UI
(verified 200 with UI HTML).

## Runtime smoke v2 (PASS, then driver deleted)

Booted real `AppModule` + real FastifyAdapter + `configureApp()`; boundaries
faked as in 009. Evidence: helmet headers present (nosniff / SAMEORIGIN /
HSTS); rate-limit headers 120/119 then **429** within the same window;
`/v1/advisors/mia/conversation` flow idempotent (same id, 0 Chatwoot calls on
repeat); unversioned `/advisors/...` and `/v2/...` → 404; `/docs` → 200.

Gates after all changes: typecheck ✓ lint ✓ tests 32/32 ✓ build ✓.

## Tech debt (items 4–6 + audit extras) — recorded in `TECH-DEBT.md` (repo root)

- terminus (LOW, pay at AURAT-0005 when checks grow) · nestjs-zod (LOW→MEDIUM
  at first request body; re-check at Nest v12 GA) · worker split-readiness
  (MEDIUM design constraint for AURAT-0005, zero code now) · OTel (LOW
  pre-launch) · prod-slim Docker (LOW, deploy task) · rate-limit tuning (LOW).

Next: re-stage both repos, user IDE review (6f gate). Still NOT committed.
