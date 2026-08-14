# AURAT-0025-004 — Context

Date: 2026-08-14
Sources: the four device screenshots, manor `develop`, `node_modules`, npm,
`AURAT-0011`/`AURAT-0012` docs.

## Finding 1 — the gradient is a legacy Paper component on the New Architecture

`react-native-linear-gradient` is pinned at **2.8.3**. Its package has **no
`codegenConfig`** and none of its sources call `codegenNativeComponent` — it is
a pre-Fabric native component.

The app runs the **New Architecture**: `newArchEnabled=true` in
`android/gradle.properties`, and the iOS build compiles with
`-D RCT_NEW_ARCH_ENABLED=1` (seen in the `xcodebuild` invocation during the
`AURAT-0015`-era iOS build repair). So every `LinearGradient` renders through
Fabric's **interop layer for legacy view managers**, whose iOS implementation
mis-measures such views. That is the mechanism behind an inset width, a short
height, and children clipped at the container's edge — three symptoms of one
container that never received its correct frame.

**Marked as the leading hypothesis, not as fact.** It explains all three
symptoms and the platform split, but it has not been proven on the device. The
first job in the slave is to confirm it — e.g. by logging `onLayout` on a
gradient and its sibling card, which will show whether the frames differ.

### Fix options

| Option | Cost |
|---|---|
| **`react-native-svg` gradient** — already a dependency (**15.15.5**), **has `codegenConfig`**, already Fabric-native and already used by `AuraIcon` | One shared wrapper; six call sites migrate; no new dependency, no beta |
| **Upgrade to `react-native-linear-gradient` 3.x** | The only Fabric-ready line is **`3.0.0-beta.2`** — `latest` on npm is still 2.8.3, so this means shipping a pre-release |
| **Pin the frame by hand** (explicit width/height per gradient) | Cheapest, and wrong — it hides a mis-measured container behind magic numbers on six call sites and breaks on the next screen size |

Recommendation: **svg**, behind a single `shared/ui` gradient component so the
six consumers stop depending on the library directly and a future swap is one
file. That also satisfies the standing rule that a visual value needed twice
becomes a shared component before the second copy merges.

## Finding 2 — item 4 is `AURAT-0012`, exactly

`BookedScreen.tsx:111` — `title: { fontSize: 28 }`, no `lineHeight`.
`shared/ui/Text.tsx` defaults `variant='body'`, which sets
`lineHeight: sizes.md × lineHeights.normal`. The local style overrides the size
and not the box, so a 28pt title renders in a ~24pt line and iOS clips it.

`AURAT-0012` is minted, open, and explicitly says this class is **not** to be
patched site-by-site — the audit and the decision on whether `Text` should
derive `lineHeight` from the resolved `fontSize` belong to it. So this task
either pulls `AURAT-0012` in or hands item 4 to it. That is the owner's call
(`005-spec.md`).

## Finding 3 — the missing card gap is not reproduced

`UpcomingSessionCard.styles.card` already has `marginBottom: 14`, with a comment
explaining why. The screenshot shows one booking. Book two before changing
anything; if the gap is genuinely absent with two cards, the cause is in the
list container, not the card.

## Contradiction logged

The owner reports the gap missing on **Android too**, while items 1–2 and 4 are
iOS-only. If finding 3 reproduces, it is a third, cross-platform bug and should
be treated as its own fix rather than folded into the iOS work.

## Next

`005-spec.md`.
