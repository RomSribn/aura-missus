# AURAT-0025-007 — Execute

Date: 2026-08-14
Slave: slave-1, `feature/AURAT-0025-ios-visual-fixes` off aura-app `develop` @ `734f987`
Status: **written, gates green, staged — awaiting IDE review. Nothing committed,
nothing merged.**

## Step 0 first: the gate, and why its own probe would have lied

The spec gated everything on proving the frames differ before restructuring, and
named the probe: log `onLayout` on a gradient and its sibling card, and if the
frames match, **stop — the hypothesis is wrong**.

Two things about that.

**A slave cannot run it.** The device pass is manor work; slave rules forbid
starting the stack. So the gate had to be met another way or not at all.

**And it would have produced a false negative.** `onLayout` reports the node's
own Yoga frame, and the gradient's Yoga frame was never wrong — it is full
width, exactly like its sibling card. The corruption happens *after* layout, in
how Fabric mounts a legacy view. The probe would have shown two matching frames,
and the spec's own instruction would then have retired a correct diagnosis.
Recording that plainly because it is the sort of thing `AURAT-0011` exists to
catch, pointed the other way: the premise survived, the *test of the premise*
did not.

What replaced it is a derivation from the shipped sources — every link checked
in this checkout's `node_modules`, not from memory:

1. `react-native-linear-gradient@2.8.3` has **no `codegenConfig`** and calls
   `codegenNativeComponent` **nowhere** (`common.js` is
   `requireNativeComponent('BVLinearGradient')`). It is a pre-Fabric view
   manager. Its `BVLinearGradientManager` uses a bare `RCT_EXPORT_MODULE()`, so
   its module name is `BVLinearGradient`.
2. RN is **0.85.3**, New Architecture — the only architecture 0.85 has.
   `RCTLegacyViewManagerInteropComponentView +isSupported:` matches
   `BVLinearGradient` at step 3, the scan of registered module classes
   (`RCTLegacyViewManagerInteropComponentView.mm:120-146`). So every gradient
   mounts through the interop layer.
3. That view sets `self.contentView = _adapter.paperView` — the real
   `BVLinearGradient` — and `RCTViewComponentView` frames its `contentView` at
   `_layoutMetrics.getContentFrame()`
   (`RCTViewComponentView.mm:94` and `:580`).
4. `getContentFrame()` is the frame **inset by `contentInsets`**
   (`LayoutMetrics.h:51-58`), and `contentInsets` is **border + padding**
   (`components/view/conversions.h:158-162`).
   → **the gradient is painted inset by its own padding.**
5. Children are mounted with
   `[_adapter.paperView insertReactSubview:childComponentView atIndex:index]`
   (`RCTLegacyViewManagerInteropComponentView.mm:173-201`), so they become
   subviews of that already-inset view — while Fabric has given each child a
   frame whose origin is relative to the **container**, padding offset
   included.
   → **the padding is applied twice**, and the last/rightmost child falls out
   of the shortened box.

Two independent checks that this is the right story rather than a plausible one:

- **The platform split falls out of it.** `index.ios.js` renders the native
  view *as the layout container*; `index.android.js` renders a plain RN `View`
  with the native gradient as an absolutely-filled sibling. Android never puts
  an interop view in the layout path, which is why Android is clean.
- **It predicts which surfaces the owner reported and which they did not.**
  The three broken ones are exactly the three that put padding **on the
  gradient**: TarotBanner (20), SessionHero (18), UpcomingSessionCard header
  (16). The three nobody reported have effectively none: SessionBanner pads its
  inner row instead (0), TarotSheet's card has only a 2px border, GradientButton
  is unreachable (below). That correlation is not something a wrong hypothesis
  gets for free.

So: hypothesis confirmed, mechanism named, and the fix is structural. **The
pixel confirmation is still owed** — it is the first item of the device pass.

## What was built

Two root causes, **two commits**, as approved, so either can be reverted alone.

### Commit 1 — the gradient stops being a legacy view

New `shared/ui/gradient/Gradient.tsx`, backed by `react-native-svg` (already a
dependency at 15.15.5, `codegenConfig: rnsvg`, already behind `AuraIcon`).

It reproduces **the Android shape, which was never wrong**: an ordinary `View`
that lays out its children, with the paint as an absolutely-filled sibling
*behind* them. Padding, radius and absolutely-positioned children therefore
behave as they do on any other `View` — no measurement, no pinned width or
height anywhere in the change.

Two details worth knowing:

- The paint is a unit-square `viewBox` stretched with
  `preserveAspectRatio="none"`, so no coordinate inside the SVG needs the box's
  real size. `start`/`end` stay fractions of the box, as before.
- The layer carries the call site's **border radius** and clips itself. Two
  call sites round their corners without `overflow: 'hidden'` (the tarot card,
  the gradient button), and an absolutely-filled child is only clipped by a
  parent that sets it. This is what the old library did on Android with its
  `borderRadii` prop.

All six consumers migrated: `TarotBanner`, `TarotSheet`, `SessionHero`,
`UpcomingSessionCard`, `SessionBanner`, `GradientButton`.
`react-native-linear-gradient` is gone from `package.json`, `package-lock.json`,
the jest `transformIgnorePatterns`, and `ios/Podfile.lock`.

Five of the six were repeating the same three values, so the plum wash became
**`theme.gradients.plum`** (rule 3: a visual value needed twice is a token
before the second copy merges). That is why `theme.ts` shows a large diff — the
palette had to become a named `const` for the gradient tokens to reference it;
the reindentation is the whole of it, no value changed.

New `Gradient.test.tsx` pins the invariant that actually broke: **the paint
never parents the children**, plus the fill, the radius and the stop spread.

### Commit 2 — `Text` derives its line box (`AURAT-0012`, folded in)

`Text` now derives a missing `lineHeight` from the **resolved** `fontSize`,
using the variant's ratio from `theme.typography.lineHeights` — the ratios were
always there, just unreachable once a consumer set a raw size. A style naming
both is left exactly as written.

That alone fixes `HoroscopeCard.signName` (14pt in a 24pt box → 21, and the
prototype's `.body` is 1.5). It is **not** enough for a heading, and that is the
audit's finding:

> No call site passes `variant`. A style that switches to the display font is
> still measured with `body`'s ratio, so the derivation would give a 28pt title
> a 42pt line where the prototype's 28px display heading carries no
> `line-height` at all and lands near 34.

So the audit was run mechanically rather than by eye — every `StyleSheet` block
with a `fontSize` and no `lineHeight`, split by whether it resolves to the
display font — and **37 display-font headings** were given an explicit tight box
(`round(fontSize × 1.2)`, the `tight` ratio, which is what `tokens.css` gives
`.title-l` / `.title-m` / the 28px sheet title by leaving `line-height` unset).
`BookedScreen.title` 28 → 34 is the reported defect; `UpcomingSessionCard`'s
header is two more of them, which is the other half of item 3.

Eight more were set by hand because a ratio is wrong for them:

- the splash wordmark, 48 → **50**: the prototype sets display leading
  explicitly only at this size (`.display` 1.02, `.title-xl` 1.04), not the 1.2
  the smaller headings inherit;
- seven decorative glyphs (the onboarding moon/sparkles/stars, the splash ✦):
  single characters in fixed-size absolutely-positioned boxes, where `body`'s
  1.5 would have blown the box out — a 40pt emoji would have asked for a 60pt
  line inside a 46pt container. They sit at 1.2 too. *They were clipped before
  this change and nobody had reported it*, so give onboarding a look on device.

The remaining **111 body-font styles keep no explicit `lineHeight`** and take
the derivation's 1.5, which is the prototype's `.body` ratio. Restating it at
111 sites would have been a mass restyle the spec puts out of scope, would make
every future size change a two-line edit, and would have pushed a `lineHeight`
onto three `TextInput` styles where it is a known Android centring hazard.

New `Text.test.tsx` covers the derivation, the untouched explicit case, the
variant default, both ratios and a composed style array.

### The lint rule — narrowed, deliberately

The spec asked for a rule flagging `fontSize` without `lineHeight` in
StyleSheet blocks fed to `Text`. **Shipped narrower than that**, and the owner
should overrule if they disagree:

`no-restricted-syntax` errors on a style that sets the **display font** and a
`fontSize` but no `lineHeight`. Verified both ways — clean across `src`, and it
fires on a deliberate violation while leaving a correct block and a body block
alone.

The reason for the narrowing: once `Text` derives the box, the literal rule
would flag 111 sites that are now *correct*, and the only class it could still
catch is the one it does catch — the heading whose resolved font the derivation
cannot see. That is also exactly the class that has now come back twice
(`AURAT-0011`'s tarot title, `AURAT-0025`'s Booked title).

## Item 3's missing gap — not reproduced

`UpcomingSessionCard` has carried `marginBottom: 14` since `AURAT-0017`, with a
comment saying why. The owner's screenshot held one booking, so the spec said
book two before touching anything.

A slave cannot book, but it can render: `SessionsScreen.test.tsx` gained a case
that serves **two** scheduled sessions and reads the result — two card surfaces,
each with a positive bottom margin, rendered as **adjacent siblings**
(`SessionsSegmentBody` returns its children in a fragment, so nothing re-parents
them). Passing. **Nothing changed for item 3.**

That is not a pixel check and does not close the item; it does mean there is no
declaration-level cause, so if the gap is genuinely absent on device the cause
is somewhere this branch has not looked. Cross-platform, unlike the rest — the
owner reports it on Android too.

## Gates

Green in slave-1: `tsc` · `eslint` · `jest` **51 suites / 286 tests** (was
49 / 276) · release iOS Metro bundle.

`npm uninstall` was run, so **manor needs `npm install`** — and, because
`Podfile.lock` changed, **`pod install`** before the next iOS build.

## Two things left on the record rather than fixed

- **`Button variant="gradient"` has zero consumers.** `GradientButton` is
  reachable only through it, so the whole path is dead code — which is why its
  padding bug was never reported. Migrated rather than deleted, because the
  spec named six consumers and deleting a public `Button` variant is the
  owner's call, not a visual fix's. Hard rule 5 says it should go.
- **`ios/Podfile.lock` was hand-edited.** A real `pod install` here rewrites
  142 further lines: this machine has **CocoaPods 1.16.2** and the committed
  lock was generated with **1.15.2**, so every React pod checksum churns.
  Bundling a toolchain bump inside a rendering fix would be wrong, so only the
  four `BVLinearGradient` stanzas were removed. The drift is real and will
  surface in whichever task next runs `pod install` legitimately.

## Device pass (manor, after merge) — the typography half matters most

The gradient change is structural and its failure mode is obvious. The
typography change moves type metrics on **45 styles across most screens**, and
that is where a regression would hide.

1. **The four reported defects**, on iOS *and* Android: Home banner full width;
   session detail hero full width with `20:30` whole; the Upcoming card's top
   block correct and its title not truncated; the Booked title not clipped.
2. **The three unreported gradients**, which now share the component: the tarot
   sheet card (gold border, `shadows.xl` — check the shadow survived a
   transparent container), the in-chat session banner (`shadows.md`, plum
   shadow colour, and the 3px progress track still clipped by the card's
   radius), and — only if it is ever wired up — the gradient button.
3. **Type sweep**: Booked, Sessions, Home, both booking screens, reschedule,
   session detail, profile and its three sheets, phone auth, verify OTP, chats,
   advisors. Nothing clipped, nothing newly loose.
4. **Onboarding and splash**, whose decorative glyphs changed and which nobody
   has looked at: the moon, the card sparkles, the orb sparkles, the wordmark.
5. **The gap**: book **two** sessions and look. If it is really missing, it is
   a separate, cross-platform bug that this branch did not find.

## Next

IDE review, then two commits. No merge to `develop` without explicit
in-the-moment owner approval.
