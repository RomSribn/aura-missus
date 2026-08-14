# AURAT-0025-008 — Approved

Date: 2026-08-14
Status: **done — owner-approved after the device pass. Released.**

## What the owner checked

The device pass was run by the owner on the merged `develop` and reported good.
Per-item results are **not** on the record — only the verdict — so the checklist
in `007-execute.md` stands as what was asked for rather than as what is
evidenced. Worth knowing if any of it resurfaces: the typography change moved
45 styles across most screens, and onboarding and splash were untested
territory going in.

## What closes with it

**`AURAT-0012` — text-lineheight-inheritance.** Open since 2026-08-05, folded in
here by owner decision (`AURAT-0012-002-folded.md`), and now closed with its
scope delivered in full: `Text` derives a missing `lineHeight` from the resolved
`fontSize`, the consumers were audited mechanically against the prototype rather
than by eye, and a lint rule guards the residue. It never gets its own execution
trail; this is it.

## Shipped

Merged into aura-app `develop` (`bf2411a`, user-approved merge gate) as **three
commits**, kept separable on purpose:

- `4e31dc3` — the gradient stops being a legacy view
- `2a8b3ec` — text derives its line box from the size it is actually given
- `5dd82bd` — the item-3 gap does not reproduce (test only; belongs to neither
  root cause and has to survive a revert of either)

Gates green in slave-1 and re-verified in manor after the merge: tsc / eslint /
jest **51 suites / 286 tests** (was 49 / 276), plus a release iOS Metro bundle.
Manor's `npm install` and `pod install` were run — `BVLinearGradient` is out of
the Pods project — and its local `env.ts` `DEV_HOST_OVERRIDE` survived
untouched; this branch never went near that file.

## The one thing worth carrying forward

**The gate's own probe would have killed the diagnosis.** The spec said: log
`onLayout` on a gradient and its sibling, and if the frames match, the
hypothesis is wrong. They *do* match — the gradient's Yoga frame was never
wrong. The corruption happens after layout, when Fabric mounts a legacy view:
`RCTViewComponentView` frames the interop `contentView` at `getContentFrame()`,
the padding box, and then the children are mounted inside that inset view
carrying frames that already include the padding. Padding applied twice.

So a correct hypothesis nearly died to a probe that could not see the layer the
bug lives in. `AURAT-0011` is the standing lesson that a confident premise may
not survive contact; this is the mirror of it — **check that the test can see
the thing it is testing before letting it decide.**

## Open, recorded rather than minted

- **`Button variant="gradient"` has zero consumers.** `GradientButton` is
  reachable only through it, which is why its padding bug was never reported.
  Migrated rather than deleted, since removing a public `Button` variant is not
  a rendering fix's call — but hard rule 5 says it should go.
- **`ios/Podfile.lock` drift.** The committed lock was generated with CocoaPods
  **1.15.2**; this machine runs **1.16.2**, and a real `pod install` rewrites
  ~140 lines of React pod checksums. Both here and in manor the lock was kept
  at the committed content with only the four `BVLinearGradient` stanzas
  removed. The drift is real and lands on whichever task next runs `pod install`
  legitimately.
- **Item 3's gap.** Not reproduced at the declaration level and not changed. If
  it is ever seen again with two or more bookings on screen, it is a separate,
  cross-platform bug and this branch is not where to look.
