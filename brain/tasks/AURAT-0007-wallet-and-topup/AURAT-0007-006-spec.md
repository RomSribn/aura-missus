# AURAT-0007-006 — Spec (implementation)

Date: 2026-07-11
Status: draft — awaiting user approval
Implements: AURAF-0007 item 008 (BE side), per AURAD-0002 / AURAD-0004 / build rules

## Deliverable

A dormant-by-default `wallet` module in aura-bff: per-user prepaid USD wallet,
append-only ledger, balance API, stubbed top-up. Everything behind
`BILLING_ENABLED` (default **false**) — with the flag off the service behaves
exactly as today (wallet routes 404).

## 1. Schema (prisma/schema.prisma + one new migration)

```prisma
enum LedgerEntryType {
  TOPUP
  SESSION_CHARGE   // reserved for AURAT-0008 — no writer in this task
}

model Wallet {
  id           String        @id @default(cuid())
  userId       String        @unique
  user         User          @relation(fields: [userId], references: [id])
  currency     String        @default("USD")   // AURAD-0002: USD-only v1
  balanceMinor Int           @default(0)       // integer cents, cache of Σ ledger
  entries      LedgerEntry[]
  createdAt    DateTime      @default(now())
  updatedAt    DateTime      @updatedAt
  @@map("wallets")
}

model LedgerEntry {
  id                String          @id @default(cuid())
  walletId          String
  wallet            Wallet          @relation(fields: [walletId], references: [id])
  type              LedgerEntryType
  amountMinor       Int             // signed: TOPUP > 0; 0008 charges < 0
  balanceAfterMinor Int             // audit snapshot at write time
  idempotencyKey    String
  createdAt         DateTime        @default(now())
  // deliberately no updatedAt — rows are never updated (append-only)
  @@unique([walletId, idempotencyKey])
  @@map("ledger_entries")
}
```

- **Invariant:** `wallets.balanceMinor == SUM(ledger_entries.amountMinor)` per
  wallet — both written in one transaction, wallet row locked
  `SELECT … FOR UPDATE` via `$queryRaw` (AURAD-0004 pattern, localized in the
  Prisma repository).
- Migration authored offline (`prisma migrate diff --from-schema-datamodel
  <base> --to-schema-datamodel <new> --script`), timestamped after `_init`.
- Append-only is enforced by code shape (repository has no update/delete on
  ledger); DB-level `REVOKE UPDATE/DELETE` goes to TECH-DEBT (ops hardening).

## 2. Module `src/modules/wallet/`

| File | Role |
|---|---|
| `wallet.module.ts` | wires providers; imports AuthModule (reuse UsersService.ensureUser) |
| `wallet.controller.ts` | thin transport: 2 routes, Zod-validated, Swagger-tagged |
| `billing-enabled.guard.ts` | route guard: `BILLING_ENABLED=false` → 404 NotFound (feature invisible) |
| `wallet.service.ts` | business logic: ensure user → ensure wallet; top-up idempotency semantics |
| `wallets.repository.ts` | abstract iface + domain shapes (`WalletRecord`, `LedgerEntryRecord`) — no Prisma types outside impl |
| `prisma-wallets.repository.ts` | `getOrCreateByUserId`, `findEntryByKey`, atomic `credit()` (lock → insert entry → update balance in one `$transaction`) |

### Endpoints (URI-versioned v1, Firebase-authed, guard-gated)

- `GET /v1/wallet` → `{ balanceMinor, currency }`. Get-or-create wallet
  (idempotent) — fresh user sees `0`.
- `POST /v1/wallet/top-ups` body `{ amountMinor, idempotencyKey }` →
  `{ entryId, balanceMinor, currency }`.
  - **Stub credit** (PSP out of scope, AURAF-0007 NOT-in-scope): credits the
    requested amount directly. Replaced by PSP-verified events in the PSP
    feature.
  - **Idempotent:** same `idempotencyKey` replayed → the original entry +
    current balance, no double credit (unique `[walletId, idempotencyKey]`;
    race resolved by catching the unique violation and re-reading).
  - **Fail-safe:** refused with 503 when `NODE_ENV=production` — the
    free-money stub can never operate live even if the flag were on.
  - Validation: `amountMinor` positive int ≤ 1_000_000 ($10k sanity cap);
    `idempotencyKey` UUID. Server never trusts client state beyond this
    explicit credit request (build rule 4 note: real funding = PSP feature).

## 3. Contracts (`src/contracts/wallet.ts`, exported from index)

Zod: `walletResponseSchema`, `topUpRequestSchema`, `topUpResponseSchema`
(+ inferred types). Local contracts dir per build rule 7; promotion to
`@aura/contracts` stays with AURAT-0006.

## 4. Config

`BILLING_ENABLED` in env.schema.ts: strict `'true' | 'false'` string →
boolean, **default false** (`z.coerce.boolean()` rejected — coerces `"false"`
→ `true`). `.env.example` updated if present.

## 5. Tests (pure — no DB/Redis/Chatwoot, per slave rules)

- `wallet.service.spec.ts` — fresh wallet balance 0; top-up credits and
  returns entry; replayed key returns original entry, credit called once;
  production refusal; amount validation boundaries.
- `billing-enabled.guard.spec.ts` — flag off → NotFound; on → passes.
- `env.schema.spec.ts` — extend: BILLING_ENABLED default false, `'true'` →
  true, `'yes'` rejected.

## 6. Docs sync (post-execute)

- `AURAF-0007` scope row 008: BE ✗ → ✓ (app column stays ✗ — sheet wiring is
  app-manor work).
- `TECH-DEBT.md`: add DB-level append-only enforcement row.
- aura-bff `README.md`: endpoints + flag note, if it lists endpoints.

## 7. Out of scope

PSP integration; ledger history endpoint; session charges/debits (AURAT-0008);
Top Up sheet wiring (app manor, consumes this API); feature-flag discovery
endpoint for the app (AURAT-0006 decides how the app learns the flag).

## 8. Parallel-merge coordination (AURAT-0005 in slave-1)

Disjoint models, shared files: `schema.prisma`, `prisma/migrations/`,
`app.module.ts`, `env.schema.ts`. Whichever task merges **second** rebases
onto develop and regenerates its migration (re-diff, new timestamp) before
`wts-finish`. Noted in active-work.md.

## 9. Manor verification plan (post-merge)

1. Stack up with `BILLING_ENABLED=false` → `GET /v1/wallet` = 404; nothing
   else changed.
2. Flag on → `GET /v1/wallet` = `{ balanceMinor: 0, currency: "USD" }`.
3. `POST /v1/wallet/top-ups` twice with the same `idempotencyKey` → one ledger
   row, balance credited once; response identical.
4. DB: `SELECT w.balanceMinor, SUM(e.amountMinor) FROM wallets w JOIN
   ledger_entries e … GROUP BY w.id` — invariant holds.
