# AURAT-0014 — 001 check

**Date:** 2026-08-13 · **Slot:** slave-1 · **Branch:** `feature/AURAT-0014-app-advisor-catalog`

## Ask

Delete the hardcoded advisors from the app and read them from the backend.

## Why now

`AURAT-0013` landed the catalog in the BFF: `GET /v1/advisors` on aura-bff
`develop` @ `b0ee16a` serves the eight real personas in display order behind a
Firebase token, and `@aura/contracts` **v0.4.0** publishes the shape. The app
still ships `src/entities/advisor/config/advisors.ts` — six personas
(`mia, laura, mijina, sol, vera, iris`) that no longer exist anywhere but the
bundle, whose threads have been deleted on dev.

## Scope

- Retire the seed list and its `getAdvisor` snapshot lookup.
- Take `Advisor` / `AdvisorCategory` / `AdvisorsResponse` from `@aura/contracts`
  v0.4.0 — the shape is **not** re-declared app-side (AURAD-0006).
- Rework every consumer for the field changes:
  `price → priceMinorPerMinute`, `rating → ratingTenths` (integer tenths),
  `reviews → reviewsCount`, `cat → category` (uppercase enum).
- `tint` and `online` are **gone** from the shape. `avatarUrl` is new and the
  monogram `Avatar` has to render it.
- Drop the `Dreams` chip — the category does not exist any more.

## Acceptance

1. No advisor persona data in the bundle; the list on screen is what the BFF
   returned, in the order it returned it.
2. Catalog failure is visible and retryable, never a silently empty list
   (BFF TECH-DEBT #11: the package's `AdvisorId` is looser than the BFF guard,
   and a `safeParse` would swallow the mismatch).
3. Presence keeps working: the online dot / pill / "Online" segment read the
   WS `presence.update` map (AURAT-0009), not a catalog field.
4. Advisor photos render, with the monogram as the fallback.
5. A push notification still names the persona from a cold background start.
6. tsc / eslint / jest green in slave.

## Out of scope

- The real fix for TECH-DEBT #11 (aligning `AdvisorId` charset across package
  and BFF) — noted, not touched here.
- `GET /v1/conversations` (BFF TECH-DEBT #12): the thread list is still rebuilt
  by delta-syncing every advisor in the catalog.
- Per-persona presence (BFF TECH-DEBT #13): presence stays inbox-wide.
