# AURAT-0023-009 — Merge

Date: 2026-08-14
Approved in the moment by the owner ("принято" on the review, then "Да, мёрж").

## What landed

- Feature branch: `feature/AURAT-0023-bff-instant-and-overlap`
- Feature commit: `1dd069e`
- Manor `develop`: `44418b2` → **`eda5339`** (merge commit), pushed to origin —
  `## develop...origin/develop` clean, 0/0.
- 16 files, +919 / −223, including the new
  `prisma/migrations/20260814140000_interval_occupancy/`.
- Idle slaves 3/4/5 refreshed to the new master by `wts-finish`.

**Missus is still uncommitted** — as the lifecycle requires; the step files, the
`AURAD-0009` progress note and the `AURAF-0008` scope update are committed once,
at task close. `wts-finish` reporting "Already up to date" for missus (and
warning on its push) is therefore expected, not a failure: manor missus is on
`de296d9`, in sync with origin.

## Why this could merge without the app

`AURAD-0009` §Sequencing made `AURAT-0016`/`AURAT-0018` merge in one window,
because `startsAt` became **required** and a shipped client would have got 400s.
That does not apply here — v0.6.0 is additive in every direction:

- a v0.5.x client sends `startsAt` and no `startNow`, which is exactly the
  scheduled form the refinement accepts;
- `minutes` is optional on the availability query;
- `instantAvailable` is an extra response field, which the app's non-strict
  `safeParse` strips.

So `AURAT-0024` is unblocked rather than coupled: it can take the contract cut
and ship on its own schedule.

## Live verification is manor work (nothing of it ran in the slave)

Ordered so a failure stops the cheapest thing first:

1. **Migration on the populated DB** — `btree_gist` installs, the repair UPDATE
   touches only windows a late activation had overrun, the constraint is
   created. This is the one step that can fail at migrate time.
2. **Instant booking at `minutes=1`** — 201 with `status: ACTIVE`, the started
   divider in the live thread, `session.updated` on the socket, the block
   finishing by itself a minute later.
3. **Two clients into one gap** — one 201, one 409.
4. **Back-to-back** `[14:00,14:10)` then `[14:10,14:20)` — both accepted; a
   straddling booking refused; `extend` into the next booking still 409.
5. **Instant booking while the caller is already in a session** → 409, not 500.
6. **`balance == Σ ledger`** after the run, and `AURAT-0018`'s 25 checks
   unbroken.
7. **The credit is spent once** — book free → cancel → the next booking is *not*
   free.

Note for step 2: the manor `.env` has `SESSION_BLOCK_MINUTES=1,10,20,30`, and
until `AURAT-0024` sends `minutes` the availability read answers for the
shortest block — 1 minute — so the grid will look almost entirely free. That
over-offers; booking still refuses what does not fit.

Next: owner verifies in the manor → `010-approved.md` or `010-fix-*.md`.
