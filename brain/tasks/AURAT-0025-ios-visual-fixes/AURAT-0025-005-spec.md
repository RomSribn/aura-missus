# AURAT-0025-005 — Spec

Date: 2026-08-14
Slave: slave-1, `feature/AURAT-0025-ios-visual-fixes` off aura-app `develop`
Status: **awaiting owner approval — no code written**

## Goal

Make the four reported screens render on iOS as they already do on Android, by
fixing the causes rather than the screenshots.

## Scope

### 0 · Confirm before changing (gate on everything below)

Reproduce each item on the device and prove the mechanism:

- Log `onLayout` for a gradient and its sibling card on Home. If the gradient's
  frame is narrower than the sibling's, finding 1 is confirmed and the fix is
  structural. If the frames match, the hypothesis is **wrong** — stop, write it
  down, and re-diagnose rather than proceeding.
- Book **two** sessions and look at the gap before touching `marginBottom`.

`AURAT-0011` is the precedent: a confident visual report whose premise was
false, where the delivered fix was an empty diff plus the one real defect found
on the way. The same outcome is acceptable here.

### 1 · The gradient (items 1, 2, 3-top)

Introduce **one shared gradient component** in `shared/ui`, backed by
`react-native-svg` — already a dependency at 15.15.5, already Fabric-native
(`codegenConfig` present), already used by `AuraIcon`. Migrate all **six**
consumers: `TarotBanner`, `TarotSheet`, `SessionHero`, `UpcomingSessionCard`,
`SessionBanner`, `GradientButton`.

The component takes the two colours and the direction the theme already
expresses; call sites keep their own padding and radius. Do **not** pin widths
or heights to make a screenshot look right — a mis-measured container hidden
behind magic numbers is a worse bug than the visible one.

`react-native-linear-gradient` leaves `package.json` once nothing imports it.

### 2 · The clipped title — `AURAT-0012` folded in (owner's call, 2026-08-14)

Fix the **class**, not the site. Per `AURAT-0012`'s own scope:

- Make `Text` derive `lineHeight` from the **resolved** `fontSize` so a local
  style that overrides the size cannot keep the variant's box. `theme.typography.
  lineHeights` already carries `tight / normal / relaxed` — the ratios exist,
  they are just unreachable once a consumer sets a raw size.
- Audit consumers for a local `fontSize` with no `lineHeight` and measure the
  affected screens against `prototype/`, not by eye. `HoroscopeCard.signName` is
  a confirmed second case beyond `BookedScreen`.
- Add the lint rule that flags `fontSize` without `lineHeight` in StyleSheet
  blocks fed to `Text`, so the class cannot come back.

`AURAT-0012` closes with this task; its folder gets a pointer here rather than
its own execution steps.

Beware: this changes type metrics across many screens at once. That is the
reason its device pass matters more than the gradient's.

### 3 · The card gap (item 3-gap)

Only if step 0 reproduces it. Fix where the cause is — list container or card —
and note that this one is cross-platform, unlike the rest of the task.

## Out of scope

Restyling anything that is not broken. New screens. Any change to session
semantics, money or navigation.

## Acceptance

- Home, Session detail and Sessions render at the same width and with no
  clipped content on iOS, matching Android — verified on the device, not in a
  simulator screenshot.
- No `LinearGradient` import from `react-native-linear-gradient` remains.
- The five other gradient surfaces (tarot sheet, chat session banner, gradient
  button) are checked for regressions — they share the component now.
- Slave gates green: tsc / eslint / jest.
- Device pass in manor after merge, since this is a rendering task and the
  slave may not start the stack.

## Resolved by the owner (2026-08-14)

1. **`AURAT-0012` is folded into this branch** — the lineHeight class is fixed
   properly here rather than run separately (§2). One device pass, and a task
   open since 2026-08-05 closes with it.
2. **The gradient is replaced with `react-native-svg`** (§1), not with
   `react-native-linear-gradient@3.0.0-beta.2`. No pre-release in production,
   and no new dependency — svg is already in the tree, already Fabric-native and
   already the backing for `AuraIcon`.

This makes the branch carry **two** root causes, which was the argued cost of
folding. Keep them separable in review: land the gradient migration and the
typography change as **distinct commits**, so either can be reverted without the
other if the device pass turns up trouble.
