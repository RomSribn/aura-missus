# AURAT-0008-005 — Context

Date: 2026-07-11
Sources: brain (AURAD-0002/0003, AURAF-0007, AURAT-0005/0007 docs) — high;
aura-bff code @ develop 5919f8b — ground truth (full sweep).

## What exists to reuse (code, ground truth)

- **Ledger is debit-ready:** `LedgerEntryType.SESSION_CHARGE` already exists in
  schema + the applied `20260711100000_wallet` migration, commented "reserved
  for AURAT-0008; no writer yet". Signed `amountMinor` (charges negative),
  `balanceAfterMinor` audit, `@@unique([walletId, idempotencyKey])`.
- **Transactional template:** `prisma-wallets.repository.ts:60-99` —
  `$transaction` + `SELECT … FOR UPDATE` via `$queryRaw` → insert entry →
  update `balanceMinor`; P2002 → `DuplicateLedgerEntryError`. `credit()` is
  TOPUP-only and positive-only; **no debit method exists anywhere**.
- **Flag gate:** `BillingEnabledGuard` (flag off → `NotFoundException`) —
  controller-wide on wallet; reuse as-is on sessions controller.
- **Conversation map:** `ProvisioningService.ensureConversation` /
  `findConversation` per (user, advisor); `Conversation` has compound unique
  `[userId, advisorId]`.
- **Jobs:** BullMQ pattern — queue consts + per-queue options in
  `src/jobs/queues.ts`, consumer registration in `jobs.module.ts`, producer
  registers same options in its module; thin `WorkerHost` processors delegate
  to services (TECH-DEBT #3); `upsertJobScheduler({every})` repeatable
  template in `reconciliation.scheduler.ts` (test-env skipped). No `delay:`
  job exists yet — BullMQ 5 supports it on `queue.add`.
- **Delivery:** `DeliveryService.fanOut` = WS `message.new` + FCM data-only
  ping, always fed from the stored message. `WsServerEvent` is a Zod
  discriminated union (`src/contracts/message.ts`) with one variant — add new
  variants there. `ChatGateway.emitToUser(userId, event)`.
- **Message store:** `Message` with `@@unique([conversationId,
  chatwootMessageId])`, `MessageDirection` enum `USER | ADVISOR` only;
  `ChatService.ingestResolved` upserts + fans out advisor messages.
- **Patterns:** Zod contracts in `src/contracts/` + per-route
  `ZodValidationPipe`; hand-written OpenAPI fragments in
  `contracts/openapi.ts`; URI v1 default; co-located pure `.spec.ts` with
  hand-mocked deps (no TestingModule); `envBool` helper for strict flags.

## Gaps this task must fill

1. **No advisor price anywhere** — `advisorId` is an opaque validated string
   (`/^[A-Za-z0-9_-]{1,64}$/`); no model/config/map has a price. Decision
   needed (spec D1).
2. **Sealed adapter has no activity-post and no custom-attributes update** —
   `custom_attributes: { advisor_id }` is written only at conversation
   creation; only `message_type: 'incoming'` is ever posted. Normalizer
   deliberately drops `activity` messages (no webhook echo risk). New
   `ChatwootClient` + `ChatwootMessagingPort` methods needed.
3. **No Session model**, no meter queue, no session WS event variant.
4. **AURAI-0002 never established** whether the Application API accepts
   `message_type: 'activity'` — needs manor verification; fallback = private
   note (both echo-safe: normalizer drops activity, receiver filters private).

## Constraints carried forward

- TECH-DEBT #7: DB-level append-only on `ledger_entries` is ops-gated
  **before enabling billing in staging/prod** — named trigger is this task /
  PSP; stays tech debt, not in scope here.
- TECH-DEBT #3: meter processor must stay a thin delegate.
- Parallel-merge coordination from 0005/0007 (schema.prisma, migrations,
  app.module.ts, env.schema.ts are contention files) — no parallel BFF task
  is running now; AURAT-0006 is app-manor, different repo. Low risk.
- Postgres `ALTER TYPE … ADD VALUE` (for a `SYSTEM` message direction) is
  transaction-safe on PG ≥ 12 as long as the same migration doesn't insert
  rows with the new value (compose runs modern PG).

Next: 006-spec.
