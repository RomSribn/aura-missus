# AURAT-0011-003 — Spec (for owner approval)

Date: 2026-08-05
Status: **awaiting approval** — no code written.
Grounding: `AURAT-0011-002-understand.md`.

## Summary

The edit found in the manor tree is not a fix — it is a 46pt regression, and the
problem it claims to solve does not exist (Yoga never applied the banner's
padding to the deck; the gradient was never narrowed). Design 07 wants the deck
anchored to the banner and clipped by its bottom edge, which is what the code did
**before** the edit.

So the proposal is: **drop the wrapper, keep the deck anchored, and leave behind
the test + comment that were missing when this trap was walked into.**

## R1 — Core (recommended)

**R1.1 — Revert the `cardWrapper` re-parenting.** `styles.banner` gets its
`paddingHorizontal` back; the copy lines and `styles.fan` go back to being direct
children of the `LinearGradient`. Result is the pre-edit render: deck in the
bottom-right corner, bleeding 26pt below the banner and clipped by
`overflow:'hidden'` — design 07.

**R1.2 — Leave a comment where the trap is.** The existing comment explains what
the fan is, not why it is parented where it is. Extend it so the next reader does
not repeat this:

```tsx
// Decorative fan bottom-right: five cards rotated around their base.
// Anchored to the banner itself (not to the copy) — it must hang past the
// bottom edge and be clipped. The banner's padding does not move it: Yoga
// measures insets from the padding box, exactly like CSS.
```

**R1.3 — Regression test** — new `src/screens/home/ui/__tests__/TarotBanner.test.tsx`
(the component has none today, and none of the 126 existing tests notice this
change). Three cases, all structural/behavioural rather than snapshot:

1. renders the three copy lines and calls `onPress` (accessible name
   `"Draw your card"`);
2. **the invariant**: the deck anchor (the node with `position:'absolute'` and a
   negative `bottom`) is a direct child of a node that has a fixed numeric
   `height` and `overflow:'hidden'` — i.e. its containing block is the clipping
   banner, so it bleeds. Under the found edit the parent is `cardWrapper`
   (`{paddingHorizontal:20}`) and this fails on both counts, which is the whole
   point;
3. five cards, exactly one centre card (white fill + `sparkle`), each carrying a
   `rotate` + `translateX` transform — locks `CARD_ROTATIONS` / `CENTER_CARD` /
   `cardCenter` against a careless refactor.

Deliberately **not** asserted: the literal values 148 / 18 / -26. The test pins
the relationship, not the design numbers, so genuine design tweaks stay cheap.
It will be run against the found edit first (must fail), then against the fix.

**R1.4 — Token for the padding** (cosmetic, answers `001-check`'s ask).
`paddingTop: 20, paddingHorizontal: 20` → `theme.spacing.xl` (which *is* 20, so
zero pixel change). The rest of the banner's geometry (148 / 24 / 18 / -26 /
46×72) stays raw — those are one-off design constants with no token, and the
file's neighbours (`HoroscopeCard`, `ContinueChatCard`) do the same. Say the word
and I drop this item; it is the only part of R1 that touches style values.

## R2 — Copy vertical rhythm (recommended, separable)

Independent of the edit, and the one thing on this banner that genuinely does not
match design 07 (Finding 4): all three copy lines silently inherit
`lineHeight: 24` from the shared `Text` `body` variant because the local styles
override `fontSize` only. The copy block renders 82pt instead of the prototype's
~69pt, so title and subtitle sit up to ~11pt low and the banner reads cramped.

Fix = three explicit line heights, no structural change:

| line | now | proposed | design |
|---|---|---|---|
| eyebrow (11pt) | 24 | **14** | font-natural, ~13 |
| title (22pt) | 24 | **26** | font-natural, ~26 |
| subtitle (13pt) | 24 | **20** | `line-height:1.5` → 19.5 |

Banner height is fixed at 148, so nothing below reflows; only the copy moves up.
Clearance between the subtitle and the top of the deck returns (0pt → ~32pt).

**Take it or leave it:** including it makes "matches design 07" true for the
whole banner in one merge cycle; excluding it keeps this branch a pure revert +
test. Either way I would flag the systemic version — `Text` with an overridden
`fontSize` and no `lineHeight` happens across the app (e.g.
`HoroscopeCard.signName`) — as a **new AURAT** rather than fixing it ad hoc here.

## R3 — Alternative structure (available, not recommended)

If you want the padding *visibly* scoped rather than explained by a comment: keep
a wrapper around the copy only, and leave the fan a direct child of the banner.

```tsx
<LinearGradient style={styles.banner}>      {/* no padding */}
  <View style={styles.copy}>…three Texts…</View>   {/* paddingTop + paddingHorizontal */}
  <View style={styles.fan}>…cards…</View>          {/* direct child — unchanged */}
</LinearGradient>
```

Pixel-identical to R1, honours the instinct behind the found edit, costs one
extra node and a larger diff. R1.2's comment buys the same protection for free,
so R1 is my recommendation — but this is a preference call, not a correctness
one.

## One question I cannot answer from the slave

**What did you actually see on the device that prompted the edit?** Everything
above is verified against the design source and the shipped Yoga engine, but I
cannot run the app here (slave rules), so I cannot see your screen. If the deck
really did render wrong on device, the cause is elsewhere and R1 alone will not
help — the candidates to check in manor after merge would be Android clipping of
the rounded gradient container, `transformOrigin` support for the rotated cards,
and OS font scaling. If it was "it looked a bit off, let me try something", R1+R2
is the answer.

## Acceptance

- Home renders exactly as design 07: deck in the bottom-right, **cut off by the
  banner's bottom edge**; copy inset 20pt; gradient full-bleed to the card edges.
- Nothing else on Home moves; the tarot sheet (designs 18/19) still opens from
  the banner.
- Slave gates green: `npx tsc --noEmit`, `npx eslint .`, `npx jest`
  (30 suites / 126 tests today → 31 / 129 with the new file).
- Device verification in manor after merge, per slave rules.

## Out of scope

- The systemic `lineHeight` pattern beyond this file (follow-up AURAT).
- Any other Home polish — `001-check` suggested pairing this with one, but there
  is nothing else outstanding on the screen.

## Plan on approval

1. Apply R1 (+ R2 if approved) — one file, plus the new test file.
2. Run the new test against the found edit to prove it catches the regression,
   then against the fix.
3. Gates → `004-execute.md` → your review in the IDE → commit → merge gate.
