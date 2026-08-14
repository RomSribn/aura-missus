# AURAT-0018-001 — Initial input

Date: 2026-08-14
Slave: slave-1 (`aura-bff-manor`)
Branch: `feature/AURAT-0018-bff-scheduled-sessions` (master + missus)
Base: aura-bff `develop` @ `b0ee16a`, aura-missus `master` @ `df5bc61`

## What the user asked

> AURAT-0018

Handed over with manor-session context (reference, does not replace the specs):

- Task: **bff-scheduled-sessions**. Governing decision is **AURAD-0009**
  (owner-ratified 2026-08-14) — read first:
  `missus/brain/decisions/AURAD-0009-scheduled-sessions-on-the-wallet.md`.
  It supersedes `AURAD-0008` and partly amends `AURAD-0002`.
  Feature: `missus/brain/features/AURAF-0008-scheduled-sessions-booking/`.
- Dependency state: aura-bff `develop` @ `b0ee16a` (AURAT-0013 advisor-catalog),
  in sync with origin. aura-missus `master` @ `df5bc61`, 0/0 vs origin, AURAD-0009 /
  AURAF-0008 / AURAT-0015/0019/0020 entries already local.
  `@aura/contracts` v0.4.0 (separate repo); the BFF still keeps its own copy of the
  contract in `src/contracts/` — TECH-DEBT #11, the two can drift.
- **Parallel work in the other manor:** `aura-app-manor` slave-1 is doing
  AURAT-0016 (booking-flow) right now and is **waiting on the contract from this
  task**. No git conflict (different repos), but the Session/slot shape is a shared
  contract — publish the contract shape early and explicitly.

## Ground truth handed over (verified in the manor, not from docs)

- `prisma/schema.prisma`: `enum SessionStatus = ACTIVE | FINISHED` — no `SCHEDULED`.
- `model Session`: has `startedAt` / `endsAt`, no `startsAt`; a partial unique index
  enforces "one ACTIVE per conversation" — with `SCHEDULED` that has to be
  revisited (several future slots + one running session must coexist).
- `enum LedgerEntryType = TOPUP | SESSION_CHARGE`. **No credit/refund direction at
  all** — AURAT-0008 deliberately shipped without a refund path. This is the
  riskiest part of the task: the refund must run under the same locked-transaction
  and `SELECT … FOR UPDATE` discipline as the debit, the ledger stays append-only
  (no `UPDATE`), and `balance == Σ ledger` must keep holding.
- `src/modules/sessions/sessions.controller.ts` exposes only: `GET
  advisors/:id/sessions/pricing`, `GET advisors/:id/sessions/active`, `POST
  advisors/:id/sessions`, `POST sessions/:id/extend`, `POST sessions/:id/finish`.
  No list, no reschedule, no cancel, no available-slot read.

## Scope per AURAD-0009 (BFF half), as handed over

1. `SCHEDULED` state + future `startsAt`; the meter itself does `SCHEDULED → ACTIVE`
   at the slot moment and posts the started marker. Today a session is created
   already `ACTIVE`.
2. Real available-slot read. The design's deterministic stub
   (`(dayIndex*7 + slotIndex) % 5 === 0`) is a prototype device and ships nowhere.
3. Reschedule (patch `startsAt`, refuse inside 4h) and cancel.
4. Credit direction in the ledger: ≥24h full refund, <24h half, **server**-computed.
   Only **before** start — a running block stays non-refundable (`AURAD-0002`).
5. Server-side totals, including the flat **−$5 first-session credit**. The app never
   computes price or discount itself (`AURAT-0008` D1).
6. Sessions list read for the Sessions tab.

Clock is the server's (`AURAF-0008-001`). Everything behind `billing_enabled`.
Paid from the wallet, not by card — PSP does not exist; conscious substitution in
AURAD-0009. Instant booking is removed — the `AURAT-0010` block picker retires.

## Slave constraints (restated)

Code / lint / typecheck / build / **pure** unit tests only. No stack: docker compose,
Postgres, Redis, Chatwoot are manor-only, after merge. Running the migration and
live verification of refunds is manor work — plan it for after the merge.

## Next

Step 002 — check existing state in the shared brain.
