# AURAT-0103-009 — Execute (fix 008)

Date: 2026-10-20
Not committed — staged for review.

- `features/advisor-filters/ui/filters-body.tsx` — the slider gets its own track (`.track`)
  with the fill (`.fill`) inside; `--low` / `--high` are now fractions 0…1 instead of percentages.
- `filters-body.module.css` — `--thumb: 20px` is the single thumb size (webkit and moz,
  `box-sizing: border-box`); the track runs from `thumb/2` to `width − thumb/2`, which is exactly
  the range a thumb's centre travels; the fill is `left: low·100%`, `right: (1 − high)·100%`
  of the track; the native tracks are transparent.

Checks: lint, `tsc -b`, vitest 268/268, build — green. Visual check — in the manor (the slot has
no dev server).
