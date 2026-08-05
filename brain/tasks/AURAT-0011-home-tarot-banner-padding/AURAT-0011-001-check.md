# AURAT-0011-001 — Check

Date: 2026-08-04
Status: minted, not started (no slave assigned)

## Why this exists

A layout fix to `src/screens/home/ui/TarotBanner.tsx` was found **uncommitted
in the manor working tree** during the AURAT-0010 merge (2026-08-04), owned by
no task. Manor rules forbid feature development there, so rather than
committing it straight onto `develop` unreviewed, it is minted as its own task
and goes through a slave like any other change.

The edit itself was left in place in the manor tree — it is the starting point,
not something to redo from scratch.

## The change as found

The Home "Daily ritual" banner (design screen 07) moves its content into a new
`cardWrapper` `View` that carries `paddingHorizontal: 20`, and drops that
padding from the `banner` (gradient) style itself.

Effect: the gradient keeps the full card width while only the text and the
fanned tarot deck are inset — the fan (`right: index * -2` plus a `translateX`
per card) is no longer squeezed by the container's padding.

## Scope

- Take the manor's working-tree edit as the baseline, verify it against design
  screen 07 (banner geometry, the fan's right-edge bleed) and finish it
  properly: the wrapper style follows the theme spacing tokens rather than a
  bare `20`, and formatting matches the surrounding file.
- Confirm nothing else on Home shifts (the banner is also the tarot-sheet
  entry point, designs 18/19).

## Acceptance

The daily-ritual banner matches design 07 on device — the fanned deck reads as
intended at the card's right edge, text inset unchanged — and Home renders
identically otherwise. Slave gates green (tsc / eslint / jest).

## Notes

- Trivial in size, but it is UI work: it belongs in a slave, not the manor.
- Pair it with any other small Home polish before spending a merge cycle on it.
