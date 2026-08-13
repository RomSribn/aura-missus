# AURAT-0013-005 — Spec

Date: 2026-08-13
Status: **done** (approved 2026-08-13 — see 012)
Type: task (no `AURAF` minted — see 002)
Closes: `aura-bff/TECH-DEBT.md` **#10**

## What

Turn the BFF's two-column `advisors` price table into the real advisor catalog,
seed it with the eight advisors from `ADVISORS REAL.xlsx`, and serve it at
`GET /v1/advisors`. The app's hardcoded `ADVISORS` array — whose own comment
calls it a stand-in "until a backend exists" — stops being the source of truth.

## Data model

`advisors` is **widened in place**, not replaced: `AURAT-0008` D1 already made it
the price authority, and a second advisor table next to it would fork that.

```prisma
enum AdvisorCategory {
  LOVE
  TAROT
  PSYCHIC
}

model Advisor {
  id                  String          @id            // app slug, e.g. "olivia"
  name                String
  role                String                         // "Psychic Reader · Medium"
  category            AdvisorCategory
  tagline             String
  bio                 String
  specialties         String[]
  greeting            String                         // seeds a new thread's first message
  avatarKey           String                         // object-storage key, NOT a URL
  priceMinorPerMinute Int                            // unchanged — AURAT-0008 D1
  ratingTenths        Int                            // 49 = 4.9 (see D5)
  reviewsCount        Int
  sortOrder           Int             @default(0)
  active              Boolean         @default(true)
  createdAt           DateTime        @default(now())
  updatedAt           DateTime        @updatedAt

  @@index([active, sortOrder])
  @@map("advisors")
}
```

**No foreign key from `conversations.advisorId`** — deliberately unchanged. Free
chat must keep working for an advisor later deactivated, and must never require a
catalog row (the existing schema comment says exactly this).

`DREAMS` is absent: none of the eight reads dreams, and the user chose to drop
the category rather than invent a dream reader.

## Migration

`prisma/migrations/<stamp>_advisor_catalog/migration.sql`, hand-written per repo
convention:

1. `CREATE TYPE "AdvisorCategory"`.
2. `DELETE FROM "advisors"` — the table holds only manually-inserted dev price
   rows. Safe: no FK points at it, and `sessions.priceMinorPerMinute` is a
   booking-time **snapshot**, so past sessions keep their price. Clearing first
   is what lets the new columns be `NOT NULL` without inventing backfill values.
3. `ALTER TABLE` — add the columns above.
4. `CREATE INDEX` on `(active, sortOrder)`.

## Seed

`prisma/seed.ts`, wired via `package.json` → `prisma.seed`, **idempotent**
(`upsert` by `id`) so re-running an env is safe (build rule 6 in spirit).

The eight rows, with prices set by the owner as a $2–4/min spread ordered by
length of practice. Text fields are derived from each bio and carry a source
quote in the working data:

| id | name | category | $/min | rating | `avatarKey` |
|---|---|---|---|---|---|
| `veronica` | Gifted Veronica | TAROT | 3.80 | 4.9 | `avatar/veronica.png` |
| `labsang` | Labsang Devi | PSYCHIC | 3.40 | 4.8 | `avatar/labsang.jpeg` |
| `olivia` | Olivia Flores | PSYCHIC | 3.20 | 4.9 | `avatar/olivia.png` |
| `marta` | Marta Nebula | LOVE | 3.10 | 4.9 | `avatar/marta.jpeg` |
| `may` | May Lacosta | PSYCHIC | 2.90 | 4.7 | `avatar/may.png` |
| `sunshine` | Sunshine Hanna | PSYCHIC | 2.60 | 4.8 | `avatar/sunshine.png` |
| `alisher` | Alisher Muladhari | PSYCHIC | 2.40 | 4.7 | `avatar/alisher.jpeg` |
| `ivan` | Ivan the Fortune Teller | TAROT | 2.20 | 4.6 | `avatar/ivan.jpeg` |

Bios are **verbatim** from the spreadsheet. Slugs pass the existing
`advisorIdSchema` (`[A-Za-z0-9_-]{1,64}`).

**Retiring the old six** (`mia`, `laura`, `mijina`, `sol`, `vera`, `iris`) is
**not** in the migration or the seed. Deleting user conversations is destructive
and belongs in a reviewed, manor-only step — a documented SQL snippet run once
against the dev DB after merge, recorded in the merge step file. The user has
already said the old threads are disposable; this only keeps the deletion out of
an automatic code path.

## Module

New `src/modules/advisors/` — the catalog is not a session concern, and the whole
`sessions` module sits behind `BillingEnabledGuard`, which would 404 the catalog
in v1 free chat.

```
src/modules/advisors/
  advisors.module.ts
  advisors.controller.ts        # GET /advisors — thin
  advisors.service.ts           # list/find; composes avatarUrl from key + base
  advisors.repository.ts        # abstract — MOVED from modules/sessions/
  prisma-advisors.repository.ts # MOVED from modules/sessions/
```

`SessionsModule` imports `AdvisorsModule` and drops its own two providers;
`SessionsService` keeps its `AdvisorsRepository` dependency, only the import path
changes. `AdvisorRecord` widens — nothing that reads `priceMinorPerMinute`
breaks.

## Endpoint

`GET /v1/advisors` → `{ advisors: Advisor[] }`

- Firebase-authed like every other route (global guard, no `@Public()`).
- **Not** behind `BillingEnabledGuard`.
- Returns `active = true` only, ordered by `sortOrder`, then `id`.
- `avatarUrl` is composed at read time from `ADVISOR_ASSETS_BASE_URL` +
  `avatarKey`; the client never sees the key.

Contract in `src/contracts/advisor.ts` + an entry in `contracts/openapi.ts`,
following the local-mirror pattern. Wire enums stay **uppercase**, consistent
with `sessionStatusSchema` (`'ACTIVE' | 'FINISHED'`).

## Config

```ts
// Public base URL of the advisor-asset bucket (AURAD-0005: per-env, never
// shared). The DB stores the S3 key, not a URL, so changing bucket or putting a
// CDN in front needs no migration.
ADVISOR_ASSETS_BASE_URL: z.string().url(),
```

Required — the service must not boot able to serve a catalog of broken images
(build rule 3, fail fast). `.env` example updated.

**Bucket (supplied by the owner, verified 2026-08-13):**

```
ADVISOR_ASSETS_BASE_URL=https://amzn-s3-aura.s3.eu-north-1.amazonaws.com
```

with `avatarKey` holding the real S3 key, e.g. `avatar/alisher.jpeg`. All eight
objects were checked live: HTTP 206 on a range request, correct
`image/png` / `image/jpeg` content types. `alisher.jpeg` and `labsang.jpeg` were
byte-compared against the local files — the bucket carries the **swapped**
versions, so the river/chapan portrait is Alisher's as intended.

`eu-north-1` is Stockholm — EU, consistent with `AURAD-0005`'s EU-region rule.

Read access is public, which is right for avatars and means the app needs no
signing. Nothing else may be put in this bucket without revisiting that.

## Decisions

**D1 — widen `advisors`, don't add a table.** It is already the price authority
(AURAT-0008 D1); forking that invites two answers to "what does this advisor
cost".

**D2 — no FK from `conversations`.** Unchanged from today, and load-bearing: free
chat must not depend on the catalog.

**D3 — catalog is not billing-gated, and returns price unconditionally.**
`AdvisorRow` renders `{role} · {price}/min` with no flag check, so gating price
would blank the list subtitle in v1. Booking stays gated; D1's "no row ⇒ not
bookable" is untouched.

**D4 — `online` is not a column.** Presence is polled and pushed (AURAT-0009);
storing it would give two answers that drift. TECH-DEBT #13 unchanged.

**D5 — `ratingTenths` + `reviewsCount` ARE modelled. This reverses my earlier
call and needs the owner's explicit yes.** I told the user rating/reviews would
stay out of the schema. Then I found they render in **three** places —
`StatsCard` (profile), `AdvisorRow` (list), `TopAdvisorRow` (home) — all via a
`Stars` component. Leaving them out means the app must either strip stars from
three screens or keep local placeholder numbers, which re-forks the source of
truth we are here to unfork. Storing an owner-set rating is ordinary pre-launch
marketplace data, no more invented than the bios. Integer tenths keeps the
no-floats discipline the money columns already follow. *A real reviews system
stays out of scope — this is a display figure, not an aggregate.*

**D6 — `tint` stays app-side.** Pure design token, no business meaning.

**D7 — seed script, not INSERTs in the migration.** Data in migrations cannot be
corrected without a new migration; an idempotent seed can be re-run.

## Out of scope

Admin/registration UI · a real reviews system · per-persona presence (#13) ·
`GET /v1/conversations` (#12) · adopting `@aura/contracts` in the BFF (#11 wants
a dedicated pass) · uploading the photos to the bucket (owner does this).

## Tests (pure — slave-safe, no DB/Redis/Chatwoot)

- `advisors.service.spec.ts` — maps row → DTO; composes `avatarUrl`; drops
  inactive; orders by `sortOrder`.
- `advisor.spec.ts` (contracts) — the eight seeded rows parse against
  `advisorSchema`, mirroring the `message.spec.ts` drift stopgap.
- Existing `sessions.service.spec.ts` must stay green across the repository move.

## Acceptance

**Slave:** `lint`, `typecheck`, `build`, `test` all green.

**Manor (after merge):** `prisma migrate deploy` + `prisma db seed`;
`GET /v1/advisors` returns 8 with resolvable `avatarUrl`s; the app's old ids are
gone; with `BILLING_ENABLED=true`, booking still resolves a price.

## Follow-ups

1. **`aura-contracts` v0.4.0** — publish the `Advisor` shape + tag, so the app can
   pin it.
2. **`AURAT-0014` (app manor, "сразу следом")** — drop `ADVISORS` and the
   `Dreams` chip, read the endpoint, teach `Avatar` to render a photo (today it
   draws a monogram on `tint` and supports no image at all).
