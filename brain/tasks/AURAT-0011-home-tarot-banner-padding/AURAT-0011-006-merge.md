# AURAT-0011-006 — Merge

Date: 2026-08-05
Merge gate: **owner-approved in session** (merge + push + release).

## Commit

`b918f4b` — *fix(AURAT-0011): keep the tarot deck anchored to the banner*
on `feature/AURAT-0011-home-tarot-banner-padding`. Two files:
`src/screens/home/ui/TarotBanner.tsx` (+14/−3) and the new
`src/screens/home/ui/__tests__/TarotBanner.test.tsx` (+102).

## Merge

`wts-finish slave-1` → `develop` `15a5704` → **`ebb6a67`** (`--no-ff`), pushed to
`git@github.com:RomSribn/aura-app.git`: `15a5704..ebb6a67 develop -> develop`.
**origin/develop stays fully in sync** — the push debt closed on 2026-08-05 was
not re-opened. slave-0 refreshed to the new develop.

The manor's local uncommitted `src/shared/config/env.ts` (the `DEV_HOST_OVERRIDE`
LAN IP, deliberately local since AURAT-0010) survived the merge untouched — this
branch never went near that file, so no stash was needed this time.

## Gates in manor (post-merge)

| gate | result |
|---|---|
| `npx tsc --noEmit` | clean (exit 0) |
| `npx jest` | **31 suites / 129 tests** pass |

Matches the slave exactly (was 30 / 126 before this task).

## Device check — still open, belongs to manor

Not runnable from a slave, and not yet done here. On Home:

1. the deck sits bottom-right and is **cut off by the banner's bottom edge** —
   not floating fully visible inside it (this is the regression that was
   reverted, and the one thing design 07 is unambiguous about);
2. the gradient reaches both card edges; copy inset 20pt;
3. the copy block sits ~11pt higher and tighter than before (R2) and still
   clears the top of the deck;
4. the banner still opens the tarot sheet (designs 18/19).

## Next

`wts-release slave-1`, then the device pass above → `007-approved.md` closes the
task. The brain files in this folder are still **uncommitted in the manor missus
clone** — manor commits them on closure, per the task's own instruction.
