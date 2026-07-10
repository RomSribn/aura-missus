# AURAT-0007-001 — Check

Date: 2026-07-10

Implements the wallet of `AURAF-0007` (item 008), **behind the `billing_enabled`
flag**. Obeys `AURAD-0002` (prepaid USD wallet, append-only ledger, flag).

Already in place: AURAT-0004 (BFF foundation + user identity). App has a Profile
→ Top Up sheet (design) not wired to anything.

## Scope

- Postgres **wallet** (per user) + **append-only ledger** (top-ups, block
  charges); balance API.
- **`billing_enabled`** feature flag (off by default).
- Wire the existing **Top Up sheet** to show the real balance and initiate a
  top-up flow. **PSP integration is out of scope** (`AURAF-0007` NOT-in-scope) —
  stub / mock the credit for now.
- No paid consumption yet (that is AURAT-0008).

## Acceptance

With the flag **on**, the app shows the real wallet balance and a (stubbed)
top-up increments ledger + balance; with the flag **off**, wallet UI is hidden
and nothing changes.

## Dependencies

AURAT-0004. Blocks AURAT-0008. Real payments wait on a separate PSP feature.

Next: AURAT-0008 (paid sessions).
