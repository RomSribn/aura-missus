# AURAT-0008-002 — Initial

Date: 2026-07-11
Slave: slave-1, branch `feature/AURAT-0008-paid-sessions` (master from
develop @ `5919f8b`, missus from master @ `409fc4d`).

## User input

`wts-task AURAT-0008` — dispatched from a manor session with this context:

- Run the full wts-task lifecycle. Spec: `brain/tasks/AURAT-0008-paid-sessions/`.
- Dependencies state: **AURAT-0005 done** (develop @ `5919f8b` — send/history
  REST, message store, webhook ingest, reconciliation poll, WS/FCM).
  **AURAT-0007 done** (develop @ `012c18e` — wallets + append-only
  `ledger_entries` in signed cents, transactional balance with
  `SELECT … FOR UPDATE`, `GET /v1/wallet`, stubbed top-ups, all behind
  `BILLING_ENABLED`, 404 when off).
- **AURAT-0006 (app-real-chat-client) is NOT done** — runs in parallel in
  `aura-app-manor`.
- **SCOPE LIMIT agreed with the user: implement the BFF side ONLY** — sessions
  module, booking with up-front transactional debit (`minutes × advisor.price`)
  via the existing ledger, meter job, session start/finish activity lines +
  `custom_attributes` through the sealed chatwoot adapter, all behind
  `billing_enabled`.
- App-visible acceptance items (markers rendered in the app,
  no-session-UI-when-flag-off) **cannot be verified until AURAT-0006 merges** —
  note as pending in task docs instead of blocking.
- Known tech debt: `aura-bff/TECH-DEBT.md`. Do not mint new AURA* IDs here.

## Next

003 — check existing state (brain + code).
