# AURAT-0005-003 — Check existing state

Date: 2026-07-11

## Task folder

Pre-existed with only `001-check.md` (spec cut by app manor 2026-07-10). No
prior execution — this is the first implementation session. Numbering
continues 002 (initial), 003 (this).

## Related brain artifacts (all read)

- `AURAF-0007` (feature, in-progress): AURAT-0005 = BE side of items 001/002/003.
- `AURAI-0002` (investigation): §2.3 Application API + trust tiers, §2.4
  webhook delivery + reliability caveats (5s / no-retry / no-order →
  reconciliation poll mandatory; order by message `id`), §5.4 message flow.
- `AURAD-0003`: one durable conversation per (user, advisor); BFF owns the map
  (already built in AURAT-0004).
- `AURAD-0005`: Agent Bot on the inbox for the retrying webhook; provisioning
  stays on service-User token. Per-env inbox `secret` signs
  `X-Chatwoot-Signature`.
- `AURAT-0004` (done, develop @ 24e6727): foundation — auth guard, Prisma 7,
  BullMQ wiring, sealed Chatwoot adapter, idempotent contact/conversation
  provisioning. Tech debt in `aura-bff/TECH-DEBT.md` (terminus, nestjs-zod,
  worker split-readiness flagged as MEDIUM design constraint **for this task**).

## Concurrency note

`active-work.md`: slave-2 is concurrently on AURAT-0007 (wallet-and-topup).
Both tasks add Prisma models → expect a `schema.prisma` merge conflict at
manor integration; keep our model additions append-only and self-contained.

Next: understand (004).
