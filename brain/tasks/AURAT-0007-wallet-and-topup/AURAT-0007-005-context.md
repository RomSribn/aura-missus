# AURAT-0007-005 — Context

Date: 2026-07-11

## Sources checked

| Source | Findings |
|---|---|
| `AURAD-0002` (high) | Ledger is source of truth: balance = Σ top-ups − Σ block charges. Prepaid USD only. Non-refundable blocks (0008). Flag-gated rollout. |
| `AURAD-0004` (high) | Debit path pattern pre-ratified: `prisma.$transaction` + `SELECT … FOR UPDATE` row lock via `$queryRaw`, localized to the data layer. |
| Build rules (high) | Rule 4: money transactional + append-only, server decides balances. Rule 6: idempotency at the seams. Rule 2: transport thin. Rule 7: contracts shared. |
| `AURAT-0004` folder + TECH-DEBT.md (high) | Foundation patterns: abstract-class repositories, ZodValidationPipe, URI versioning (v1), local `src/contracts/`. Debt item 2 (nestjs-zod) not blocking — reuse the hand-rolled pipe. |
| `AURAT-0005-001-check` (high) | Parallel task in slave-1. Model sets are disjoint (messages vs wallet); conflict surface = schema.prisma, migrations/, app.module.ts, env.schema.ts. Merge-second rebases + regenerates migration. |
| `AURAT-0008-001-check` (high) | Needs `minutes × advisor.price` debits with balance pre-check → ledger entry type enum + signed amounts + lockable wallet row designed now. |
| Code @ 24e6727 (ground truth) | No wallet/billing code at all. Prisma 7 driver-adapter setup; migrations are offline-authored (init migration hand-consistent; no live DB in slaves). |

## Key design consequences

1. **Money as integer minor units (cents).** No floats, no Decimal in v1 —
   USD-only per AURAD-0002. Column names `*Minor` to make the unit explicit.
2. **Wallet row + append-only ledger.** `wallets` gives the lockable row
   (AURAD-0004 pattern) and O(1) balance reads; `ledger_entries` is the source
   of truth. Invariant enforced by writing both in one transaction:
   `wallets.balanceMinor == SUM(ledger_entries.amountMinor)` per wallet.
   Signed amounts: top-ups positive; 0008 charges negative — zero rework later.
3. **Idempotent top-up.** Client-supplied `idempotencyKey` (UUID), unique per
   wallet; replay returns the original entry, no double credit (build rule 6).
4. **Flag = env `BILLING_ENABLED`** (strict `'true'|'false'`, default false) +
   route guard that 404s when off — wallet endpoints invisible, v1 unchanged.
   Zod `z.coerce.boolean()` is a footgun ("false" → true) — custom parse.
5. **Stub top-up is credit-on-request** (no PSP). Fail-safe: refused in
   `NODE_ENV=production` (503) so the free-money endpoint can never ship live;
   PSP feature later replaces the credit source with a verified PSP event.
6. **Migration authored offline** via `prisma migrate diff
   --from-schema-datamodel <base> --to-schema-datamodel <new> --script`
   (no DB needed in the slave), mirroring the init migration style.

## Contradictions

None. The only scope ambiguity (Top Up sheet = app repo) is recorded in
004-understand and resolved by the manor topology (AURAD-0006).

Next: 006-spec.
