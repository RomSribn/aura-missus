# AURAT-0007-008 — Execute

Date: 2026-07-11
Branch: feature/AURAT-0007-wallet-and-topup (slave-2). NOT committed — awaiting IDE review.

## Master repo — created

- `prisma/migrations/20260711100000_wallet/migration.sql` — wallets +
  ledger_entries + LedgerEntryType enum; generated offline via
  `prisma migrate diff --from-schema <base> --to-schema <new> --script`.
- `src/modules/wallet/` — `wallet.module.ts`, `wallet.controller.ts`
  (GET /v1/wallet, POST /v1/wallet/top-ups), `billing-enabled.guard.ts`
  (flag off → 404), `wallet.service.ts` (idempotency semantics, prod refusal),
  `wallets.repository.ts` (domain iface + DuplicateLedgerEntryError),
  `prisma-wallets.repository.ts` (atomic credit: `$transaction` +
  `SELECT … FOR UPDATE` via `$queryRaw`, P2002 → domain error).
- `src/contracts/wallet.ts` (+ index export) — Zod wallet/top-up shapes.
- Tests: `wallet.service.spec.ts` (6), `billing-enabled.guard.spec.ts` (2),
  `contracts/wallet.spec.ts` (6 asserts via it.each).

## Master repo — modified

- `prisma/schema.prisma` — User.wallet, Wallet, LedgerEntry, LedgerEntryType.
- `src/config/env.schema.ts` — `BILLING_ENABLED` strict `'true'|'false'`
  (default false) via `envBool` helper; `.env.example` documented.
- `src/app.module.ts` — WalletModule import.
- `src/config/env.schema.spec.ts` — flag parsing cases.
- `README.md` — wallet endpoints + module in layout; `TECH-DEBT.md` — row 7
  (DB-level append-only enforcement deferred to ops).

## Missus — modified

- `AURAF-0007` — row 008 BE ✗→✓ + context note (App column = sheet wiring,
  stays app-manor).

## Decisions made during implementation

1. Replay of a used idempotencyKey with a **different amount** → 409 Conflict
   (key reuse is a client bug; silent success would hide it).
2. `prisma migrate diff`: Prisma 7.8 renamed `--from-schema-datamodel` →
   `--from-schema`; the conditional datasource in prisma.config.ts makes the
   CLI silently emit nothing without DATABASE_URL — a dummy URL
   (`postgresql://dummy…`) is required (datamodel diffs never connect).
3. Guard order note: with the flag off, an unauthenticated request gets 401
   (global Firebase guard) before the 404 — trivial existence leak, accepted.

## Verification (slave-pure)

lint ✓ · typecheck ✓ · test ✓ (9 suites / 47 tests, incl. 14 new) · build ✓.
Runtime behaviour (404 gate, idempotent credit, ledger invariant) is manor
verification after merge — plan in 006-spec §9.

## Open issues

None blocking. Parallel AURAT-0005 (slave-1): if it merges first, rebase +
regenerate this migration timestamp against develop before wts-finish.

Next: user IDE review → commit (master only) → 009-merge.
