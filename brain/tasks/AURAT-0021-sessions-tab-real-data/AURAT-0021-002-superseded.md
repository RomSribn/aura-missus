# AURAT-0021-002 — Superseded

Date: 2026-08-14
Status: **closed without code — folded into `AURAT-0016` / `AURAT-0017`**

This task was scoped as the narrow, unblocked slice of `AURAT-0016`: retire the
seed session model and put real data on the Sessions tab, while the booking flow
stayed parked by `AURAD-0008`.

Hours later the owner chose to build the design's booking flow after all, and
`AURAD-0009` unparked it by paying the slot from the wallet instead of by card.
With the scheduled model adopted, this slice stops being a task of its own: the
Sessions tab's Upcoming segment gets real content, and retiring the seed model is
`AURAT-0016`'s own prerequisite again, exactly as `AURAF-0008` framed it.

## What survives from it

`001-check.md` holds three findings that shaped `AURAD-0009` and still bind the
work:

1. The BFF exposes **no sessions list** — only `pricing` and `active` per
   advisor. The history exists in Postgres and needs an endpoint (`AURAT-0018`).
2. `entities/session` is still the pre-BFF seed, and its `kind` is documented as
   `"1:1 video"` — a format the product does not have.
3. Under `AURAD-0002` the tab's Upcoming segment was empty by construction. That
   is precisely what `AURAD-0009` changes.

No branch work happened; `feature/AURAT-0021-sessions-tab-real-data` was created
and re-pointed at `AURAT-0016` before any commit.
