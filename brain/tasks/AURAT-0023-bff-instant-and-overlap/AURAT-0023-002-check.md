# AURAT-0023-002 — Check

Date: 2026-08-14
Slave: `slave-2`, branch `feature/AURAT-0023-bff-instant-and-overlap`
(master @ `44418b2`, missus @ `de296d9` — exactly the dependency the spec names)

## Existing state

- **This task folder** already carried `001-initial.md`, written in the manor.
  It is the spec; nothing else existed. Last file was 001, so this continues at
  002 rather than resuming mid-flight.
- **`AURAD-0009`** carries the second amendment verbatim (§"Amended again
  2026-08-14"): occupancy becomes an interval, `startsAt` need not align,
  availability becomes duration-dependent, the double-booking guarantee rests on
  the advisor row lock, `EXCLUDE USING gist` is the DB-level belt if wanted.
- **`AURAT-0018`** has **no task folder in this brain** — its record lives in the
  code (`44418b2`, feature commit `de32959`) and in `AURAD-0009` §Progress. The
  grid tests the spec calls "written against equality" are
  `src/modules/sessions/slot-grid.spec.ts` and `sessions.service.spec.ts`; both
  were read directly rather than via a step file.
- **`AURAT-0024`** (app half) exists as `001-initial.md` and is explicitly
  **blocked on this task and the contract cut that follows it**.
- **`AURAF-0008`** rows 006–011 are the feature this sits under; its scope table
  is where the BE column moves when this lands.

## Nothing is being redone

No prior work on instant booking or interval occupancy exists in this repo. The
first amendment's fast path (`AURAT-0022`, app-side) is the *nearest slot*, not
this; nothing of it is touched.

Next: 003-understand.
