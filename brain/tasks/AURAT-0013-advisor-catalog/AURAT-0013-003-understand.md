# AURAT-0013-003 — Understanding

Date: 2026-08-13

## What the user wants

Move the advisor catalog from a hardcoded array in the app into the BFF's
Postgres, and populate it with the eight real advisors from
`ADVISORS REAL.xlsx` instead of the six invented placeholders. The BFF must
serve that catalog over an endpoint so the app stops shipping personas in its
bundle.

## Why it is the right shape

The app's own comment calls its array a stand-in "until a backend exists". The
backend now exists — it has held `advisors` since AURAT-0008, but only as two
columns (`id`, `priceMinorPerMinute`) because that is all the paid-session debit
path needed. Widening that table is the smallest change that makes the DB the
source of truth the user asked for, and it keeps the existing price authority
(`AURAT-0008` D1: no row ⇒ not bookable, no default price) intact rather than
introducing a second advisor record next to it.

## Boundaries

**In scope (this task, BFF):** widen the `Advisor` model + migration, seed the
eight advisors, `GET /v1/advisors`, the `Advisor` contract in `@aura/contracts`
(0.3.0 → 0.4.0), retire the six old ids and their dev-DB threads.

**Next task (app manor, `AURAT-0014`, "сразу следом"):** the app drops its
`ADVISORS` array and `AdvisorCategory` `Dreams`, reads the endpoint, and renders
photo avatars — its `Avatar` draws monogram-on-tint today and supports no image
at all.

**Not in scope:** admin/registration UI, a reviews system, per-persona presence
(TECH-DEBT #13), `GET /v1/conversations` (#12).

## The one open dependency

The bucket exists but its public base URL is not yet known to me. The design
puts an `avatarKey` in the DB and the base URL in validated config, so the code
is complete without it and only the env value is outstanding — no migration
later, and dev/prod can point at different storage per `AURAD-0005`.

## Next

Step 004 — gather context from code and decisions.
