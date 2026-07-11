# AURAT-0005-002 — Initial input

Date: 2026-07-11

## User input

`wts-task AURAT-0005` — dispatched from the manor session with context:

> Run the full wts-task lifecycle for this task. Spec:
> `missus/brain/tasks/AURAT-0005-messaging-and-delivery/`. Its dependency
> AURAT-0004 (bff-foundation) is done and merged — develop @ `24e6727`:
> NestJS 11/Fastify + Prisma 7 + BullMQ wiring, Firebase auth guard, sealed
> Chatwoot adapter with idempotent contact/conversation provisioning. Known
> tech debt is listed in `aura-bff/TECH-DEBT.md`. Do not mint new AURA* IDs
> in this workspace.

## Slave / branch context

- Slave: `slave-1` (was idle, detached at develop `24e6727` / missus `7972ae5`).
- Bootstrapped via `wts-start slave-1 feature/AURAT-0005-messaging-and-delivery`
  (paired branches in master + missus).
- Task folder pre-existed with `001-check.md` (spec cut by app manor,
  2026-07-10) — numbering continues from 002.

Next: check existing state (003).
