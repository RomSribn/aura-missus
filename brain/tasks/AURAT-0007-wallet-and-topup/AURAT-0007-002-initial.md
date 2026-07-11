# AURAT-0007-002 — Initial

Date: 2026-07-11
Slave: slave-2
Branch: feature/AURAT-0007-wallet-and-topup (master + missus, from develop @ 24e6727 / missus @ 7972ae5)

## User input (dispatching manor session)

> wts-task AURAT-0007 — run the full wts-task lifecycle for this task.
> Spec: missus/brain/tasks/AURAT-0007-wallet-and-topup/.
> Only dependency AURAT-0004 (bff-foundation) is done and merged — develop @
> 24e6727: NestJS 11/Fastify + Prisma 7 + BullMQ wiring, Firebase auth guard,
> sealed Chatwoot adapter. Known tech debt: aura-bff/TECH-DEBT.md.
> NOTE: AURAT-0005 (messaging-and-delivery) runs IN PARALLEL in slave-1 — both
> tasks touch schema.prisma, migrations, app.module.ts and the env schema;
> whoever merges second must rebase and regenerate their Prisma migration
> against develop. Keep wallet work behind the billing_enabled flag per
> AURAD-0002. Do not mint new AURA* IDs in this workspace.

## Notes

- Task folder already existed with `AURAT-0007-001-check.md` (spec cut by
  aura-app-manor, 2026-07-10) — numbering continues from 002.
- Slave-2 was free/detached; bootstrapped via `wts-start slave-2
  feature/AURAT-0007-wallet-and-topup`; active-work.md updated (slave-2 busy).

Next: 003 — check existing state in brain/.
