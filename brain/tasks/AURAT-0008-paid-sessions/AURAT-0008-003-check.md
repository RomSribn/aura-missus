# AURAT-0008-003 — Check existing state

Date: 2026-07-11

## Task folder

`brain/tasks/AURAT-0008-paid-sessions/` exists with `001-check.md` — the spec
cut from `aura-app-manor` (2026-07-10). No execution steps yet; this session
continues from 002.

## Related brain artifacts

- `AURAF-0007` (in-progress) — rows 006/007 are this task's scope; BE column
  currently ✗ for both. Row 008 BE ✓ (AURAT-0007). Dependency chain confirms:
  {0005, 0006, 0007} → 0008.
- `AURAD-0002` — paid session = prepaid fixed minute-block inside the thread,
  non-refundable once started, extend = book another block, markers as
  activity lines, custom_attributes for chatter visibility, ledger append-only,
  all behind `billing_enabled`.
- `AURAD-0003` — one durable conversation per (user, advisor); sessions are
  windows inside it; BFF owns the map.
- `AURAT-0007` docs — wallet + ledger implementation (signed cents,
  `SELECT … FOR UPDATE`, `BILLING_ENABLED` 404 gating) — the debit path this
  task must reuse.
- `AURAT-0005` docs — messaging/delivery infrastructure (webhook, poll,
  WS/FCM) — the conversation plumbing sessions attach to.

## Code state

Branch cut from develop @ `5919f8b` (includes AURAT-0004/0005/0007). Detailed
code map gathered in 005-context.

## Status

Fresh execution, no prior AURAT-0008 work. Next: 004-understand.
