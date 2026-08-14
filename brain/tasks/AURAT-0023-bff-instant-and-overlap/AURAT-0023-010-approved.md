# AURAT-0023-010 — Approved

Date: 2026-08-14
Status: **done**

The owner verified the merged code in the manor and accepted it. `AURAT-0023`
is closed.

## What shipped

Occupancy became an interval `[startsAt, endsAt)` (`AURAD-0009`, second
amendment), so a paid session can start **now**:

- an unaligned start is legal, and the instant path takes it from the **server's**
  clock — exempt from the grid and from the lead time, created `ACTIVE` in the
  same transaction as the debit, and therefore neither cancellable nor
  reschedulable;
- the grid step is free of block length (the boot cross-check went with the
  invariant it protected);
- availability answers per duration and carries `instantAvailable`;
- the double-booking guarantee moved from `UNIQUE (advisorId, startsAt)` to an
  overlap query inside the advisor row lock, with `EXCLUDE USING gist` as the
  DB-level belt;
- two defects found on the way were fixed with it: `book` never checked the
  **caller's** own calendar (which an instant booking would have surfaced as a
  raw P2002 reported as an idempotency conflict), and `activate`'s endsAt
  recompute could run into the next booking (now clamped to it);
- the first-session credit is spent when **consumed**, closing the free
  book → cancel → book cycle — an owner decision taken during this task.

On `develop` @ **`eda5339`** (feature commit `1dd069e`), pushed. Contract shape
**v0.6.0** written up in step 007 for `aura-app-manor` to cut — additive, so
**`AURAT-0024` is unblocked rather than coupled** and needs no shared merge
window.

## Follow-ups left behind, deliberately

- **`TECH-DEBT #16`** — the exclusion violation is recognised by constraint name
  / SQLSTATE in the error text, because Prisma has no code for `23P01`.
- **Deploy** — `btree_gist` is required by the `interval_occupancy` migration;
  an environment that cannot install it should drop the constraint, not the
  lock. Recorded in `README.md`.
- **Until `AURAT-0024` sends `minutes`**, availability answers for the shortest
  block, so the manor's `1,10,20,30` makes the grid look nearly free. It
  over-offers; booking still refuses what does not fit.
