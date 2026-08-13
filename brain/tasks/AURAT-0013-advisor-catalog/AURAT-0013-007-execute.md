# AURAT-0013-007 — Execute

Date: 2026-08-13
Branch: `feature/AURAT-0013-advisor-catalog` (slave-1)
Status: **implemented, uncommitted — awaiting IDE review**

## Green in the slave

`lint` ✓ · `tsc --noEmit` ✓ · `jest` **210 passed / 25 suites** (was 190) · `nest build` ✓

## Files

**Schema + data**
- `prisma/schema.prisma` — `AdvisorCategory` enum (`LOVE`/`TAROT`/`PSYCHIC`, no
  `DREAMS`); `Advisor` widened with name/role/category/tagline/bio/specialties/
  greeting/avatarKey/ratingTenths/reviewsCount/sortOrder/active + an
  `(active, sortOrder)` index.
- `prisma/migrations/20260813120000_advisor_catalog/migration.sql` — create enum,
  `DELETE FROM "advisors"`, add columns, create index.
- `src/modules/advisors/advisor-seed.data.ts` — the eight rows. **Generated from
  the extraction artefacts, not retyped**, so the bios are byte-for-byte the
  owner's. Lives under `src/` so it is linted, type-checked and spec-covered.
- `prisma/seed.ts` + `prisma.config.ts` (`migrations.seed`) + `npm run prisma:seed`.

**Contract**
- `src/contracts/advisor.ts` (new), exported from `contracts/index.ts`;
  `advisorOpenApi` / `advisorsResponseOpenApi` in `contracts/openapi.ts`.

**Module** — `src/modules/advisors/`: module, controller (`GET /v1/advisors`),
service (composes `avatarUrl`), `advisors.repository.ts` +
`prisma-advisors.repository.ts` **moved out of `sessions/`**.

**Rewiring** — `app.module.ts` registers `AdvisorsModule`; `sessions.module.ts`
imports it and drops its two providers; `sessions.service.ts` import path only.

**Config** — `ADVISOR_ASSETS_BASE_URL` (required, URL, trailing slashes trimmed)
in `env.schema.ts` and `.env.example`.

**Docs** — README layout + a `GET /v1/advisors` entry; `TECH-DEBT.md` #10
rewritten to what actually remains (no admin surface), #13's stale "the BFF has
no advisor catalog" parenthetical corrected.

**Tests** — `advisors.service.spec.ts` (7: URL composition, leading-slash join,
key never leaked, price returned, order preserved, empty catalog),
`contracts/advisor.spec.ts` (11: the seed parses as wire DTOs, unique slugs and
sortOrders, every advisor priced, keys are not URLs, `DREAMS` rejected, rating
bounds, storage-only fields stripped), plus 2 env cases.

## Decisions taken while implementing

**`active` does not block booking.** `findById` still returns a row regardless of
`active`; only the catalog list filters. Whether hiding an advisor should also
stop new bookings is a product question the spec did not answer, so the
AURAT-0008 booking path keeps the behaviour it shipped with. Documented on the
abstract method.

**`toRecord` is an explicit projection, not a spread** — so a column added to the
table later cannot reach the client just by existing.

**Prettier was reverted on 26 unrelated files.** `prettier --write "src/**/*.ts"`
reformatted files this task never touched — the repo was not prettier-clean.
Reverted them all: unrelated churn does not belong in this diff. Worth a separate
pass, or a format check in CI.

## Noticed, not acted on

`@fastify/static` is a dependency (`package.json`) and is registered nowhere in
`src/`. Dead since it was added. Out of scope here — flagging it rather than
deleting a dependency inside a feature task.

## Manor-only cleanup (deliberately NOT automated)

The migration clears `advisors`, and the seed repopulates it — but conversations
with the retired slugs survive, because deleting user threads must be a reviewed
act, not a side effect of `migrate deploy`. After merge, in the manor:

```sql
-- Retired personas from the app's placeholder catalog (AURAT-0013).
DELETE FROM messages
 WHERE "conversationId" IN (
   SELECT id FROM conversations
    WHERE "advisorId" IN ('mia','laura','mijina','sol','vera','iris'));
DELETE FROM sessions
 WHERE "conversationId" IN (
   SELECT id FROM conversations
    WHERE "advisorId" IN ('mia','laura','mijina','sol','vera','iris'));
DELETE FROM conversations
 WHERE "advisorId" IN ('mia','laura','mijina','sol','vera','iris');
```

Owner already confirmed these threads are disposable ("пофиг на старые треды").

## Not done here — follow-ups

1. **`aura-contracts` v0.4.0** — the `Advisor` shape + tag, so the app can pin it.
   Separate repo; the BFF keeps its local mirror per TECH-DEBT #11.
2. **App task (next, "сразу следом")** — drop `ADVISORS` and the `Dreams` chip,
   read the endpoint, teach `Avatar` to render a photo.

## Next

User reviews the diff in the IDE. Nothing is committed.
