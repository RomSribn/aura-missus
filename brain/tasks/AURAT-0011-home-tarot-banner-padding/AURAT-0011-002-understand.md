# AURAT-0011-002 — Understand

Date: 2026-08-05
Slave: slave-1, branch `feature/AURAT-0011-home-tarot-banner-padding` (from
`develop` @ `15a5704`). The edit found in the manor tree was carried here as a
diff and reverted in manor — it now exists only in this worktree.

## The edit as found (unchanged, verified)

`src/screens/home/ui/TarotBanner.tsx`:

- `paddingHorizontal: 20` removed from `styles.banner` (the `LinearGradient`),
- everything inside the gradient — the three copy lines **and the fanned deck** —
  wrapped in a new `<View style={styles.cardWrapper}>` carrying
  `paddingHorizontal: 20`.

Stated rationale (from `001-check`): *"the gradient keeps the full card width
while only the text and the fanned deck are inset — the fan is no longer
squeezed by the container's padding."*

## Finding 1 — the rationale does not hold; padding never touched either one

The deck anchor is `styles.fan` = `position:'absolute', right:18, bottom:-26`.
Yoga positions an absolutely-positioned child **with insets defined** against the
containing node's *padding box* — border is subtracted, **padding is not**. Read
from the shipped engine, not from memory:

`node_modules/react-native/ReactCommon/yoga/yoga/algorithm/AbsoluteLayout.cpp`,
`positionAbsoluteChild()` (l. 164-224) — the inset branch (l. 200-217) computes

```
containingNode.measuredDimension - child.measuredDimension
  - containingNode.computeInlineEndBorder(...)   ← border only
  - child.computeInlineEndMargin(...)
  - child.computeInlineEndPosition(...)          ← our `right: 18`
```

Padding appears in this file only on the *no-insets* (static-position) paths
(l. 24-78), gated by `Errata::AbsolutePositionWithoutInsetsExcludesPadding` —
not our case. This is also plain CSS behaviour, which matters because the design
source is a browser prototype (below).

So before the edit, `right: 18` already measured 18pt from the banner's **visible
right edge**; the banner's `paddingHorizontal: 20` did nothing to the deck.

The "gradient keeps the full width" half is refuted twice over:

- padding never clips a background — the gradient paints the whole padding box;
- on Android `<LinearGradient>` is not even a native container. It renders a
  plain RN `View` with the native `BVLinearGradient` as an **inset-0 absolutely
  positioned sibling** of the children
  (`node_modules/react-native-linear-gradient/index.android.js`, l. 84-95). It
  is the same class of node as the fan — if padding shrank inset-positioned
  children, the gradient would already have been inset by 20pt on both sides,
  which is not what the screen shows.

## Finding 2 — the design's own markup has the deck anchored to the banner

`.claude/design_handoff_aura/prototype/screens.jsx`, l. 26-46 — the authoritative
source for screen 07:

```jsx
<div style={{ position:'relative', borderRadius:24, overflow:'hidden',
              background:'linear-gradient(...)', padding:'20px 20px 0', height:148 }}>
  <div className="eyebrow">Daily ritual</div>
  <div className="title-l">Draw your card</div>
  <div className="body">One free pull every day</div>
  <div style={{ position:'absolute', right:18, bottom:-26 }}>…cards…</div>   ← direct child
</div>
```

The banner carries the padding; the deck is a **direct child of the banner** and
hangs 26px below it, clipped by `overflow:hidden`. `screens/07-home.png` confirms
it: the deck sits in the bottom-right corner and is **cut off by the banner's
bottom edge** — roughly the top 46pt of a 72pt card is visible.

The pre-edit RN component is a faithful transcription of exactly this.

## Finding 3 — the edit is a regression, ~46pt of it

The wrapper re-parents the deck: its containing block is no longer the banner
(fixed `height: 148`) but `cardWrapper`, whose height is its *text content*.

Measured from the actual render tree (probe against `react-test-renderer`, since
`StyleSheet.create` returns plain objects here): all three copy lines inherit
`lineHeight: 24` from the shared `Text` `body` variant — the local styles
override `fontSize` only. So

```
cardWrapper height = 24 + (6 + 24) + (4 + 24) = 82pt,   top at 20 (banner paddingTop)
```

| | deck anchor (`bottom:-26`) | card box (72pt tall) | vs banner (148pt) |
|---|---|---|---|
| before | 148 + 26 = **174** | y 102 → 174 | bleeds, clipped at 148 → 46pt visible |
| after  | (20+82) + 26 = **128** | y 56 → 128 | fully inside, 20pt of empty banner below |

Horizontally nothing moves (the wrapper stretches to the banner's full width, and
per Finding 1 its own padding does not shift the deck either).

Net: the deck rides **46pt up** and stops bleeding past the bottom edge — the one
thing design 07 is unambiguous about. The edit changes nothing else.

The re-parenting is also fragile beyond this bug: pinning a decoration to a text
block makes its position depend on font metrics and on OS font scaling
(`allowFontScaling` is on by default), so the deck would move whenever the copy
reflows.

## Finding 4 (incidental) — the copy block itself sits low vs the design

The same `lineHeight: 24` leak is a real, pre-existing fidelity gap, independent
of the edit. The prototype gives the eyebrow/title their font's natural line box
(~13 / ~26pt) and the subtitle `line-height:1.5` (19.5pt) → copy block ≈ 69pt;
RN renders 82pt, so the title/subtitle sit up to ~11pt lower than design 07 and
the banner reads more cramped. Not caused by this branch, and it is a
codebase-wide pattern (any `Text` that overrides `fontSize` without
`lineHeight` — e.g. `HoroscopeCard.signName`). Options in `003-spec`.

## Gates — baseline on this branch (with the found edit in the tree)

`npx tsc --noEmit` clean · `npx eslint .` clean · `npx jest` 30 suites / 126
tests pass. Nothing here catches the regression: no test asserts the banner's
structure, and there is no `TarotBanner` test at all.

## Next

`AURAT-0011-003-spec.md` — proposal for owner approval. No code written yet.
