# AURAT-0008-008 — Execute

Date: 2026-07-11
Branch: feature/AURAT-0008-paid-sessions (slave-1). NOT committed — awaiting
IDE review.

## Master repo — created

- `prisma/migrations/20260711130000_sessions/migration.sql` — SessionStatus /
  SessionFinishReason enums, `advisors` + `sessions` tables,
  `ALTER TYPE "MessageDirection" ADD VALUE 'SYSTEM'`, hand-written partial
  unique index `sessions_one_active_per_conversation` (generated offline via
  `prisma migrate diff --from-schema <base> --to-schema <new> --script`, dummy
  DATABASE_URL per the AURAT-0007 learning).
- `src/modules/sessions/` — `sessions.module.ts`, `sessions.controller.ts`
  (pricing / active / book / extend / finish, all behind BillingEnabledGuard),
  `sessions.service.ts` (orchestration + meter/announce/sync job handlers),
  `sessions.repository.ts` (domain iface + InsufficientFunds /
  ActiveSessionExists / SessionNotActive / IdempotencyKeyReused errors),
  `prisma-sessions.repository.ts` (transactional book/extend: wallet
  `SELECT … FOR UPDATE` → replay/active/balance checks → SESSION_CHARGE ledger
  append → balance update → session write, one `$transaction`; conditional
  finish), `advisors.repository.ts` + `prisma-advisors.repository.ts` (D1
  price table).
- `src/jobs/sessions.processor.ts` (thin, dispatch by job name),
  `src/jobs/sessions.scheduler.ts` (60s sweep backstop).
- `src/contracts/session.ts` (+ index export) — Zod session shapes; booking
  request carries only `{minutes, idempotencyKey}` — no client-supplied money.
- Tests: `sessions.service.spec.ts` (20), `contracts/session.spec.ts` (8).

## Master repo — modified

- `prisma/schema.prisma` — Advisor, Session, enums, MessageDirection.SYSTEM,
  Conversation.sessions.
- `src/modules/chatwoot/` — sealed-adapter additions: client
  `createActivityMessage` (primary `message_type: 'activity'`; fallback
  private note is a one-line switch — manor-verified) +
  `setConversationCustomAttributes`; port `postActivityMessage` +
  `syncSessionState` (always re-sends `advisor_id`; keys
  `aura_session_status` / `aura_session_ends_at` / `aura_paid_minutes_total`);
  impl + spec (3 new tests).
- `src/modules/chat/` — `MessageRecord.direction` gains `'system'`;
  `ChatService.ingestSystemMarker` (store marker → fan out from stored row,
  idempotent); spec (2 new tests + mock fix).
- `src/modules/delivery/delivery.service.ts` — `pushSessionUpdate` (WS
  `session.updated`; FCM stays marker-driven via message.new ping).
- `src/modules/wallet/wallet.module.ts` — exports WalletsRepository.
- `src/contracts/message.ts` — direction `'system'`, WS union
  `session.updated`; `openapi.ts` — session fragments.
- `src/config/env.schema.ts` (+spec, `.env.example`) — `SESSION_BLOCK_MINUTES`
  CSV (default 10,20,30); prices deliberately NOT config (D1).
- `src/app.module.ts`, `src/jobs/jobs.module.ts`, `src/jobs/queues.ts` —
  sessions queue (finish/sweep/announce/sync) + module wiring.
- `README.md` (module row, endpoints, WS events), `TECH-DEBT.md` (row 10:
  manual advisor registration until the catalog feature).

## Missus — modified

- `AURAF-0007` — rows 006/007 BE ✗→✓ + AURAT-0008 context note; App column
  explicitly **pending AURAT-0006**.

## Decisions made during implementation

1. Extend prices at the session's booking-time snapshot (not the current
   advisors row) — extending mid-session can never surprise the user with a
   price change.
2. Extend replay detection via the ledger `(walletId, idempotencyKey)` unique;
   reusing the booking's own key against extend → 409 (different operation).
3. The delayed finish job id carries endsAt (`finish-<id>-<endsAtMs>`) so an
   extension's job never dedupes against the stale one; stale jobs no-op via
   the endsAt guard.
4. `finishedAt` for EXHAUSTED = the block's logical end (endsAt), not the job
   firing time.
5. Announce-job crash between the Chatwoot post and the store upsert may
   duplicate the dashboard line on retry — accepted edge (spec §5); the store
   and delivery stay idempotent regardless.

## Verification (slave-pure)

lint ✓ · typecheck ✓ · test ✓ (19 suites / 137 tests, incl. 33 new) · build ✓.
Runtime behaviour (meter loop, activity-line acceptance, custom_attributes,
402/409/404 paths against real Postgres) is manor verification after merge —
plan in 006-spec §12. App-visible acceptance (red markers, no session UI when
flag off) — **pending AURAT-0006**.

## Open issues

None blocking. `message_type: 'activity'` acceptance by the dev Chatwoot is
the one runtime unknown — fallback documented in the client, verified in the
manor step.

Next: user IDE review → commit (master only) → 009-merge.
