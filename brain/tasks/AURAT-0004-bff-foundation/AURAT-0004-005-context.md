# AURAT-0004-005 — Context

Date: 2026-07-11

## Sources checked

- `AURAF-0007` (feature, high): scope table rows 001–005 = v1 free chat; 0004
  is the BE foundation slice. Task chain 0004 → 0005 → 0006.
- `AURAD-0004` (high): NestJS + Fastify, TS strict, Postgres, Redis/BullMQ,
  Firebase Admin for identity, FCM + WS later, Docker co-located with Chatwoot.
- `AURAD-0005` (high): one `Channel::Api` inbox per env, each with own
  `identifier`/`hmac_token`/`secret`/`webhook_url`; **service-User** access
  token (not a human agent's); Agent Bot wiring is a later delivery concern.
- `AURAD-0007` (high): Prisma over Postgres; repositories behind interfaces so
  Prisma never leaks into services; `prisma migrate` owns migrations. 0004 only
  needs users + conversation-map tables (wallet is AURAT-0007).
- `AURAD-0003` (high): one durable conversation per (user, advisor), tagged
  `custom_attributes.advisor_id`; `lock_to_single_conversation` OFF — dedupe is
  BFF-side (unique constraint + idempotent get-or-create).
- `AURAI-0002` (high, grounded in Chatwoot v4.15.1 source): Application API on
  a `Channel::Api` inbox; User token can create/patch contacts (`identifier`,
  `phone_number` settable) and conversations; contact dedupe priority
  identifier → email → phone; `phone_number` must be strict E.164 or silently
  dropped. Webhook/delivery facts matter for 0005, not here.
- `aura-bff-build-rules.md` (workspace, high): layer discipline table, module
  layout (`auth` + `chatwoot` for 0004), hard rules 1–8.
- Code ground truth: `aura-bff` @ `60874dc` = README + .gitignore only.

## Key implications

- Exact Application-API endpoint shapes (contact search/create, contact-inbox
  create, conversation create) are best-known from AURAI-0002 + docs; final
  verification happens in the manor against the dev Chatwoot instance — unit
  tests mock the client (advisory → verify at integration).
- `@aura/contracts` package does not exist yet; 0004's device-facing surface is
  one endpoint. Plan: local Zod schemas in `src/contracts/` as the single
  import point, promoted to the shared package when the app client lands
  (AURAT-0006). Flagged in spec as an open point.
- Advisor catalog is app-side today; BFF treats `advisorId` as an opaque
  validated string in 0004.

No contradictions between sources.

Next: 006-spec.
