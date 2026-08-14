# AURAT-0011-005 — Execute

Date: 2026-08-05
Slave: slave-1, branch `feature/AURAT-0011-home-tarot-banner-padding`.
Status: code applied, gates green, **uncommitted — awaiting IDE review**.

## What was done

Per `004-approval`: R1 as specified + R2.

### `src/screens/home/ui/TarotBanner.tsx`

- **Reverted the `cardWrapper` re-parenting.** The copy lines and `styles.fan`
  are direct children of the `LinearGradient` again, so the deck's containing
  block is the fixed-height clipping banner and it bleeds 26pt past the bottom
  edge (design 07). `styles.cardWrapper` deleted. **The JSX diff against
  `develop` is now empty** — the file's markup is back to the shipped shape;
  only styles and comments changed.
- **Comment on `CARD_ROTATIONS`** now records *why* the deck is parented to the
  banner and that padding does not inset it (Yoga measures insets from the
  padding box, like CSS) — the exact reasoning error this task cleaned up.
- **`paddingTop` / `paddingHorizontal` → `theme.spacing.xl`** (= 20; no pixel
  change). The rest of the banner geometry (148 / 24 / 18 / -26 / 46×72) stays
  raw: one-off design constants with no token, matching `HoroscopeCard` and
  `ContinueChatCard`.
- **R2 — explicit line heights**: eyebrow 14, title 26, subtitle 20, with a
  comment naming the cause (the shared `Text` `body` variant ships
  `lineHeight: 24`, and overriding only `fontSize` leaves it in place). Copy
  block 82pt → 70pt (prototype ≈69pt); the title/subtitle move up to ~11pt up,
  and clearance to the top of the deck goes 0 → ~32pt. Banner height is fixed,
  so nothing below reflows.

### `src/screens/home/ui/__tests__/TarotBanner.test.tsx` (new)

Three cases; the component had no test before.

1. copy renders in order and `onPress` fires from the accessible banner;
2. **the invariant** — the deck anchor (absolute, negative `bottom`) is a direct
   child of a node with a fixed numeric `height` and `overflow: 'hidden'`;
3. five cards, exactly one white centre, every card carrying `rotate` +
   `translateX`, locking `CARD_ROTATIONS` / `CENTER_CARD` / `cardCenter`.

The literal design numbers (148 / 18 / -26) are deliberately **not** asserted —
the test pins the relationship, so design tweaks stay cheap.

**Proven to catch the regression**: run against the found edit *before* the fix,
case 2 failed (`typeof style.height` → `"undefined"`, parent was `cardWrapper`)
while 1 and 3 passed; after the fix all three pass.

## Gates (slave)

| gate | result |
|---|---|
| `npx tsc --noEmit` | clean (exit 0) |
| `npx eslint .` | clean (exit 0) |
| `npx jest` | **31 suites / 129 tests** pass (was 30 / 126) |

## Not done here (slave rules)

Device verification. On merge into `develop`, check in manor on Home:

- the deck sits bottom-right and is **cut off by the banner's bottom edge**, not
  floating inside it;
- the gradient reaches both card edges, copy inset 20pt;
- the copy sits higher/tighter than before (R2) and still clears the deck;
- the banner still opens the tarot sheet (designs 18/19).

## Next

Owner reviews the diff in the IDE → commit → merge gate for `develop`.
