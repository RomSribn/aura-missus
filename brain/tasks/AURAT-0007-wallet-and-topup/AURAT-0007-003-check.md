# AURAT-0007-003 — Check existing state

Date: 2026-07-11

## Task folder

- `AURAT-0007-001-check.md` — spec cut by aura-app-manor (2026-07-10). Scope:
  wallet + append-only ledger + balance API, `billing_enabled` flag (off by
  default), stubbed top-up (PSP out of scope), no paid consumption (AURAT-0008).
- `AURAT-0007-002-initial.md` — this run's dispatch brief.
- No spec/approval/execute files — implementation has not started anywhere.

## Related brain artifacts

- `AURAF-0007` (features/) — row 008 = this task ("Top up and see the USD
  wallet balance"), BE column ✗. Rows 006–008 behind `billing_enabled`.
- `AURAD-0002` — prepaid USD wallet, append-only ledger (balance = Σ top-ups −
  Σ charges), `billing_enabled` gate. Ratified.
- `AURAD-0004` — stack; names the wallet debit path pattern:
  `prisma.$transaction` + `SELECT … FOR UPDATE` via `$queryRaw`, localized.
- `AURAD-0007` — Prisma is the ORM.
- `AURAT-0005-001-check.md` (parallel, slave-1) — messaging/delivery; will add
  its own Prisma models + migration; no wallet overlap in models, but shared
  files: schema.prisma, migrations dir, app.module.ts, env.schema.ts.
- `AURAT-0008-001-check.md` (downstream) — paid sessions will consume the
  ledger (block charges, `minutes × advisor.price` debit). Schema must leave
  room for charge entries (signed amounts / entry type enum) without migration
  rework.

## Code ground truth (develop @ 24e6727, branch base)

- Modules: auth (Firebase guard + users upsert), chatwoot (sealed adapter +
  provisioning), health. No wallet module, no billing flag, nothing money.
- prisma/schema.prisma: `User`, `Conversation` only. One migration
  `20260711000000_init`.
- env.schema.ts: no boolean flags yet; optional Chatwoot webhook secrets
  reserved for AURAT-0005.
- Repository pattern established: abstract class interface + Prisma impl,
  domain shapes in the interface file, Prisma types never reach services.
- Contracts: local `src/contracts/` re-export point (Zod), promotion to
  `@aura/contracts` deferred to AURAT-0006.

Fresh implementation, nothing to resume. Next: 004-understand.
