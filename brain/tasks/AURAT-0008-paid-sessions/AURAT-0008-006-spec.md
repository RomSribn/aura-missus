# AURAT-0008-006 — Spec (implementation)

Date: 2026-07-11
Status: approved 2026-07-11 (D1 = advisors table + pricing endpoint — see 007-approval)
Implements: AURAF-0007 items 006/007 (BFF side only), per AURAD-0002 /
AURAD-0003 / build rules. App side = AURAT-0006 (parallel, app-manor).

## Deliverable

A dormant-by-default `sessions` module in aura-bff: book a fixed minute-block
prepaid from the AURAT-0007 wallet (up-front transactional debit
`minutes × advisor.price`), meter runs the block down, early end forfeits the
remainder, extend books more minutes into the same window; on start/finish the
BFF posts activity lines into the Chatwoot conversation and mirrors live
session state + accumulated paid minutes into conversation
`custom_attributes` — all through the sealed chatwoot adapter, all behind
`BILLING_ENABLED` (routes 404 when off).

## D1 — advisor price source (DECIDED 2026-07-11: DB `advisors` table)

No advisor entity/price existed anywhere in the BFF (advisorId is an opaque
string on `conversations`). **User decision:** the price lives in a new
`advisors` table — the first real advisor entity in the BFF and the seam for
future advisor registration / catalog / admin (that feature gets its own
AURAD, minted in aura-app-manor). Price changes are `UPDATE`s, no redeploy.

- Sessions still **snapshot** `priceMinorPerMinute` at booking (audit — a
  later price change never rewrites what a past session cost).
- **No `advisors` row → booking (and pricing) refused with 404** ("advisor
  not bookable"). No silent fallback to a default price — charging an
  unregistered advisor at some default is a money bug, not a convenience.
- **No FK from `conversations`** — free chat must work for any advisorId and
  with billing off; registration is required only to sell sessions.
- Population is manual for now (SQL insert; dev advisors seeded during manor
  verification) — tracked in TECH-DEBT until the catalog feature.

Config-map and Chatwoot-attributes alternatives were considered and
rejected (ops burden / Chatwoot must not hold billing truth per AURAD-0002).

## 1. Schema (`prisma/schema.prisma` + one migration `<ts>_sessions`)

```prisma
model Advisor {
  id                  String   @id      // the app's advisorId slug (validated /^[A-Za-z0-9_-]{1,64}$/)
  priceMinorPerMinute Int               // integer cents per minute — server-side price authority
  createdAt           DateTime @default(now())
  updatedAt           DateTime @updatedAt
  @@map("advisors")
}

enum SessionStatus { ACTIVE FINISHED }

enum SessionFinishReason {
  EXHAUSTED     // meter ran the block down
  ENDED_EARLY   // user ended early — remainder forfeited (AURAD-0002)
}

model Session {
  id                  String               @id @default(cuid())
  conversationId      String
  conversation        Conversation         @relation(fields: [conversationId], references: [id])
  status              SessionStatus        @default(ACTIVE)
  bookedMinutes       Int                  // total incl. extensions
  priceMinorPerMinute Int                  // snapshot at booking
  costMinor           Int                  // total charged (= Σ its ledger charges)
  idempotencyKey      String               // booking key
  startedAt           DateTime             @default(now())
  endsAt              DateTime             // startedAt + bookedMinutes (moves on extend)
  finishedAt          DateTime?
  finishReason        SessionFinishReason?
  createdAt           DateTime             @default(now())
  updatedAt           DateTime             @updatedAt
  @@unique([conversationId, idempotencyKey])
  @@index([conversationId])
  @@map("sessions")
}
```

- Raw SQL in the migration (Prisma can't model it): **partial unique index**
  `CREATE UNIQUE INDEX "sessions_one_active_per_conversation" ON "sessions"
  ("conversationId") WHERE "status" = 'ACTIVE'` — DB-level guarantee of at
  most one active session per conversation (race-proof double-book guard).
- `ALTER TYPE "MessageDirection" ADD VALUE 'SYSTEM'` — session markers are
  stored messages (see §5). Safe on PG ≥ 12 while the migration inserts no
  rows using it.
- **No ledger migration needed** — `SESSION_CHARGE` already exists in the DB
  enum (reserved by AURAT-0007).

## 2. Money — booking debit (reuses AURAT-0007 discipline)

`PrismaSessionsRepository` owns the atomic units (wallet + ledger + session
must commit together; a cross-repository transaction would leak Prisma tx
types through the domain interfaces, so the unit lives in one repo — same
`SELECT … FOR UPDATE` template as `prisma-wallets.repository.ts:60-99`):

- **`book({walletId, conversationId, minutes, priceMinorPerMinute,
  idempotencyKey})`** — one `$transaction`: lock wallet row FOR UPDATE →
  `cost = minutes × price`; `balance < cost` → `InsufficientFundsError` →
  insert `ledger_entries` (SESSION_CHARGE, `−cost`, `balanceAfterMinor`) →
  update `wallets.balanceMinor` → create `sessions` row. P2002 on the partial
  index → `ActiveSessionExistsError`; P2002 on either idempotency unique →
  replay → re-read and return the existing session (no double debit).
- **`extend({sessionId, walletId, minutes, priceMinorPerMinute,
  idempotencyKey})`** — same transaction shape; session must be `ACTIVE` with
  `endsAt > now` (else `SessionNotActiveError`); debits a new SESSION_CHARGE
  entry, then `bookedMinutes += minutes`, `costMinor += cost`,
  `endsAt += minutes`. Ledger-key replay → rollback → return current session.
- **`finish(sessionId, reason)`** — `updateMany WHERE id AND status='ACTIVE'`;
  0 rows = already finished (idempotent no-op). `finishedAt` = `endsAt` for
  EXHAUSTED, `now` for ENDED_EARLY.

Ledger stays append-only; every charge is an individual auditable entry
(booking + each extension). Wallet invariant `balanceMinor == Σ ledger`
untouched. The server alone computes cost — client sends only `minutes` +
`idempotencyKey` (build rule 4).

## 3. Module `src/modules/sessions/`

| File | Role |
|---|---|
| `sessions.module.ts` | imports Auth, Chat, Chatwoot, Delivery, Wallet modules + registers sessions queue (producer) |
| `sessions.controller.ts` | thin transport, `@UseGuards(BillingEnabledGuard)`, Zod pipes, Swagger |
| `sessions.service.ts` | business logic: pricing, booking/extend/finish orchestration, meter handlers, announce handler |
| `sessions.repository.ts` | abstract iface + domain records + domain errors (no Prisma types) |
| `prisma-sessions.repository.ts` | transactional units from §2 + lookups |
| `advisors.repository.ts` | abstract iface: `findById(advisorId) → {id, priceMinorPerMinute} \| null` |
| `prisma-advisors.repository.ts` | Prisma impl over the `advisors` table |

`WalletModule` adds `exports: [WalletsRepository]` (sessions needs
`getOrCreateByUserId` for the walletId). `BillingEnabledGuard` reused as-is.

### Endpoints (URI v1, Firebase-authed, 404 when flag off)

- `GET /v1/advisors/:advisorId/sessions/pricing` →
  `{priceMinorPerMinute, blocks: [{minutes, costMinor}]}` — display-only
  pricing from the `advisors` table, so the app shows exactly what the server
  will charge; **404** for an unregistered advisor.
- `POST /v1/advisors/:advisorId/sessions` body `{minutes, idempotencyKey}` →
  `{session, balanceMinor}`. Resolves price from `advisors` (**404** if
  unregistered), ensures conversation
  (`ProvisioningService.ensureConversation`), books, schedules
  meter jobs, enqueues `announce-started`, emits WS `session.updated`.
  Errors: **402** insufficient funds, **409** active session exists,
  400 minutes not in allowed blocks. Idempotent replay → existing session.
- `POST /v1/sessions/:sessionId/extend` body `{minutes, idempotencyKey}` →
  `{session, balanceMinor}`. Ownership via session→conversation.userId
  (else 404). Reschedules the finish job, enqueues attrs sync, WS event.
  Errors: 402, **409** session not active/expired.
- `POST /v1/sessions/:sessionId/finish` → `{session}` — early end, remainder
  forfeited (AURAD-0002); idempotent (already finished → current state, 200).
  Enqueues `announce-finished`, WS event.
- `GET /v1/advisors/:advisorId/sessions/active` → `{session: SessionDto | null}`.

`SessionDto`: `{id, advisorId, status, bookedMinutes, priceMinorPerMinute,
costMinor, startedAt, endsAt, finishedAt?, finishReason?}` — app derives the
countdown and the near-end "extend" prompt locally from `endsAt` (no
server-side warning push needed).

## 4. Meter (BullMQ, queue `sessions` in `src/jobs/queues.ts`)

- **Delayed finish**: on book/extend, `queue.add('finish', {sessionId},
  {delay: endsAt − now, jobId: 'finish-<sessionId>-<endsAtMs>'})` (jobId
  carries endsAt so an extension's new job never dedupes against the stale
  one). Handler → `sessionsService.finishIfDue(sessionId)`: not ACTIVE →
  no-op; `endsAt > now` (extended) → no-op (newer job exists); else
  `finish(EXHAUSTED)` + `announce-finished` + WS.
- **Sweep backstop**: `upsertJobScheduler('session-meter-sweep',
  {every: 60_000})` (skipped in test env, per reconciliation template) —
  finishes any ACTIVE session with `endsAt <= now`; covers lost/flushed
  delayed jobs. Stale finish jobs firing after an extension are harmless
  no-ops (guard above).
- **Announce jobs** (`announce`, `{sessionId, kind: 'started'|'finished'}`,
  jobId `announce-<kind>-<sessionId>`, 5 attempts exp backoff): post the
  activity line via the port → store it as a SYSTEM message → fan out →
  sync custom attributes (§5, §6). Extend enqueues a `sync` job (attrs only —
  markers bracket the session per AURAD-0002; extensions don't add lines).
- `SessionsProcessor` in `src/jobs/` stays a thin delegate (TECH-DEBT #3),
  dispatching by job name to service methods; queue registered in
  `jobs.module.ts` (consumer) + `sessions.module.ts` (producer).

## 5. Markers — "Your session has started / finished"

The announce handler, via the sealed port:

1. `postActivityMessage(conversationId, content)` → Chatwoot message id.
2. `ChatService.ingestSystemMarker(conversation, {chatwootMessageId, content,
   chatwootCreatedAt})` (new method) — upserts a `Message` row with
   `direction: SYSTEM` (idempotent by `[conversationId, chatwootMessageId]`)
   and fans out through the existing `DeliveryService.fanOut` (WS
   `message.new` + FCM data ping). Markers therefore appear **in the app's
   history feed, id-ordered with chat messages, fed from the stored row**
   (hard rule 5) — the dashboard sees the same line natively in Chatwoot.
3. Echo-safety: activity messages are dropped by the webhook normalizer and
   the private fallback is filtered by the receiver — no duplicate ingestion
   either way.

Chatwoot API fact to verify in manor (AURAI-0002 gap): whether the
Application API accepts `message_type: 'activity'`. Primary = activity;
fallback = **private note** (chatter-visible, echo-safe) — a one-line switch
inside `ChatwootClient`, recorded at verification. Known accepted edge: a
crash between the Chatwoot post and the store upsert makes the retry re-post
the line (duplicate line in dashboard, cosmetic, retries-only).

## 6. Chatwoot adapter additions (sealed — port + client only)

- `ChatwootClient.createActivityMessage({conversationDisplayId, content})` →
  `{id, createdAt}` (returns raw id — bypasses the normalizer's activity
  drop).
- `ChatwootClient.setConversationCustomAttributes({conversationDisplayId,
  attributes})` → `POST …/conversations/:id/custom_attributes`. Always
  re-sends `advisor_id` alongside session keys (defends against
  replace-not-merge semantics).
- Port (`ChatwootMessagingPort`): `postActivityMessage(conversationId,
  content)` and `syncSessionState(conversationId, state)` where state =
  `{status: 'active'|'none', endsAt?: ISO, paidMinutesTotal: number}` —
  domain shapes in, wire shapes sealed inside the adapter.
- Attribute keys: `aura_session_status`, `aura_session_ends_at`,
  `aura_paid_minutes_total` (accumulated booked minutes over the
  conversation's life — booked = paid, blocks are non-refundable). Updated on
  start / extend / finish — transitions only, no per-minute ticks.

## 7. Contracts + WS

- `src/contracts/session.ts` (Zod, + `index.ts` re-export):
  `sessionDtoSchema`, `bookSessionRequestSchema` (`minutes` positive int in
  allowed blocks — set validated in service since blocks are config,
  `idempotencyKey` uuid), `extendSessionRequestSchema`,
  `bookSessionResponseSchema`, `activeSessionResponseSchema`,
  `sessionPricingResponseSchema`.
- `src/contracts/message.ts`: `direction` union gains `'system'`;
  `wsServerEventSchema` gains `{type: 'session.updated', advisorId,
  session: SessionDto}` (emitted inline post-commit on book/extend/finish via
  a new `DeliveryService.pushSessionUpdate` → `ChatGateway.emitToUser`; FCM
  unchanged — the marker's `message.new` ping already wakes the app).
- `contracts/openapi.ts`: hand-written fragments for the new schemas.
- Promotion to `@aura/contracts` remains with AURAT-0006 (as for wallet).

## 8. Config (`env.schema.ts` + `.env.example`)

- `SESSION_BLOCK_MINUTES` — CSV of allowed blocks, default `"10,20,30"`
  (AURAD-0002 "e.g."); manor verification can add `1` for a fast live meter
  test. Prices are NOT config — they live in the `advisors` table (D1).

## 9. Tests (pure — no DB/Redis/Chatwoot)

- `sessions.service.spec.ts`: price resolution from `AdvisorsRepository`
  (found / unregistered → 404-mapped error); pricing endpoint payload
  (blocks × price); block validation; book happy path (debit args, jobs
  scheduled, WS emitted); insufficient funds → 402-mapped error;
  active-conflict → 409; idempotent replay returns existing without re-debit;
  extend happy / not-active / replay; early finish forfeits + idempotent
  re-finish; `finishIfDue` exhausted / already-finished / extended-stale
  no-ops; announce handler (port call order, marker ingest, attrs sync).
- `contracts/session.spec.ts`; `env.schema.spec.ts` additions
  (`SESSION_BLOCK_MINUTES` default + malformed CSV rejected).
- Existing suites untouched and green.

## 10. Docs sync (post-execute)

- `AURAF-0007` rows 006/007: **BE ✗ → ✓**; App column stays ✗ — markers in
  the app + no-session-UI-when-flag-off are **pending AURAT-0006** (recorded,
  not blocking, per dispatch scope limit).
- aura-bff `README.md`: sessions module row, endpoints, env vars.
- `TECH-DEBT.md`: new row — `advisors` rows are registered manually (SQL)
  pending an advisor catalog / registration feature (AURAD to mint in
  aura-app-manor); #7 (DB append-only before enabling billing) unchanged,
  still gates prod billing.

## 11. Out of scope

PSP / real top-ups; per-shift paid-minute reporting endpoint (the
sessions + ledger tables are the reporting source; Chatwoot-ops feature);
scheduling sessions for later (AURAD-0002 assumption: blocks start
immediately); app UI / AURAT-0006; presence/typing; advisor catalog; identity
edge cases (O5) / chatter provisioning (O6).

## 12. Manor verification plan (post-merge)

1. Flag **off**: every sessions route 404; nothing else changed.
2. Flag **on**, blocks incl. `1`: seed a dev advisor
   (`INSERT INTO advisors (id, "priceMinorPerMinute", …) VALUES …`);
   `GET …/sessions/pricing` returns table price × blocks; an unseeded
   advisorId → 404 on pricing and booking. Top up (stub) → book 1-min block →
   wallet debited exactly `1 × price`, SESSION_CHARGE ledger row, invariant
   `balance == Σ ledger` holds; activity line ("started") in dashboard;
   `custom_attributes` show active + ends_at + paid minutes; history returns
   the SYSTEM marker.
3. Meter: after ~60–120s the session flips FINISHED/EXHAUSTED, "finished"
   line + attrs `none`; WS `session.updated` observed.
4. Early end: book, finish immediately → remainder forfeited (no refund
   entry), attrs/lines correct; repeat finish → idempotent.
5. Extend: book, extend → second SESSION_CHARGE, `endsAt` moved, stale finish
   job no-ops, no extra marker lines.
6. Replays: same booking/extend `idempotencyKey` twice → one ledger row each.
7. `message_type: 'activity'` acceptance — record result; flip to private
   note if rejected.
8. **Pending AURAT-0006** (recorded, not verified here): markers render red
   in the app; no session UI when flag off.
