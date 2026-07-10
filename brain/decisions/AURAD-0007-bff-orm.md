# AURAD-0007 — The BFF data layer is Prisma over PostgreSQL

Date: 2026-07-10
Status: accepted (owner-ratified 2026-07-10)

## Decision

The Aura BFF uses **Prisma** as its ORM / data-access layer over the PostgreSQL
datastore (`AURAD-0004`). Closes the ORM open item flagged in the BFF build rules
(`aura-bff-manor/.claude/aura-bff-build-rules.md` → Open decisions).

## How it works

- **Schema + migrations:** a Prisma schema (`prisma/schema.prisma`) generates the
  type-safe client; **`prisma migrate`** owns per-env migrations (dev/staging/prod
  — `AURAD-0005`). Turnkey, reproducible.
- **Money integrity (`AURAD-0002`):** the wallet/session **debit path** runs inside
  an interactive **`prisma.$transaction`**; the anti-double-spend **row lock** uses
  `SELECT … FOR UPDATE` via **`$queryRaw` inside that transaction** (Prisma has no
  first-class `FOR UPDATE` in its fluent API). This raw-SQL-for-locks step is
  **deliberate and localized** to the wallet/session debit path — everything else
  uses the fluent client. The **ledger is append-only** (insert-only; no updates/
  deletes). Amounts are **integer cents** (`@aura/contracts` `Money`) — no floats.
- **Layering (build-rules discipline):** services depend on **repository
  interfaces**; the Prisma-backed implementation sits behind them. So persistence
  is swappable, unit tests mock the repo, and Prisma never leaks into services or
  transport.

## Why

- **v1 has no money.** `AURAT-0004..0006` (contact/conversation mapping + messaging)
  carry zero billing; Prisma's DX + turnkey migrations ship them fastest with the
  fewest footguns. Velocity to v1 is the dominant factor now (`AURAF-0007` — free
  chat first).
- **The P1 money path is well-trodden.** A row-locked debit via `FOR UPDATE` inside
  `$transaction` is a standard, localized pattern — not pervasive raw SQL.
- **Lowest risk.** Largest ecosystem/docs → least onboarding + maintenance cost for
  a small team.

Assumption / caveat: a few advanced ledger queries (row locks, some CTEs) drop to
`$queryRaw` where the fluent API doesn't reach — **acceptable and contained**. If
the money layer later needs *pervasive* SQL control, revisit vs Drizzle (which
would supersede this decision). TypeORM was rejected (weaker type-safety and a
rougher migration/maintenance track record).

Informed by `AURAD-0002`, `AURAD-0004`, `AURAD-0006`. Unblocks the persistence
slice of `AURAT-0004` (the `(user, advisor) → conversation` mapping table) and
`AURAT-0007` / `AURAT-0008` (wallet / ledger / sessions).
