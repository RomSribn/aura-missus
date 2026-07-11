# AURAT-0005-013 — Verify: manor environment note (not a code issue)

Date: 2026-07-11

## Symptom

`POST /v1/advisors/mia/messages` → 500, Prisma **P1010** (`role "aura" does
not exist`) at `prisma-users.repository.ts:16`.

## Diagnosis

- BFF runs **natively** in the manor (`start:dev`, TS stack traces), not via
  the aura-bff compose (no aura-bff containers in `docker ps`).
- Host has Homebrew **Postgres on 5432** and **Redis on 6379**
  (user-level processes). `DATABASE_URL=postgresql://aura:aura@localhost:5432/aura_bff`
  therefore hits the host Postgres, which has no `aura` role.
- Chatwoot dev stack (`aura-cw-dev-*`) exposes only rails on host 3001; its
  Postgres/Redis are container-internal — unrelated.

## Resolution given to user

- **Option 1 (native, recommended for dev):** create role+db in host Postgres
  (`CREATE ROLE aura LOGIN PASSWORD 'aura'; CREATE DATABASE aura_bff OWNER
  aura;`), `export DATABASE_URL=…` + `npx prisma migrate deploy`, restart.
  `CHATWOOT_BASE_URL=http://localhost:3001`; inbox webhook_url must be
  `http://host.docker.internal:3000/webhooks/chatwoot` (Chatwoot is in Docker).
- **Option 2 (compose):** stop brew postgres/redis first (port clash), then
  `docker compose up --build`; `CHATWOOT_BASE_URL=http://host.docker.internal:3001`.

No slave-side code change required. Swagger body fix (a85cbd1) still pending
user confirmation together with the live loop.

Next: user re-verifies (014: approved or next fix).
