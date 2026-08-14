# AURAT-0025-002 — Check existing state

Date: 2026-08-14

## Brain

- **`AURAT-0012`** — text-lineheight-inheritance, minted 2026-08-05, **still
  open and never started**. It exists for exactly the class of bug item 4 is:
  the shared `Text` sets `lineHeight` per variant, so a consumer overriding
  `fontSize` in a local style without also overriding `lineHeight` silently
  keeps the variant's. Its check file is explicit that the fix belongs there and
  that the codebase is **not to be patched site-by-site**.
- **`AURAT-0011`** — the precedent for this kind of report: a plausible visual
  premise that turned out to be wrong, where the real defect was a `lineHeight`
  the local style never overrode. Read it before assuming.
- No prior task covers the gradient.

## Code (ground truth, manor `develop`)

Six `LinearGradient` consumers, and all three misbehaving screens are among
them: `screens/home/ui/TarotBanner.tsx`, `screens/session-detail/ui/SessionHero.tsx`,
`screens/sessions/ui/UpcomingSessionCard.tsx`, plus `TarotSheet`,
`features/paid-session/ui/SessionBanner` and `shared/ui/button/GradientButton`.

`UpcomingSessionCard` already carries **`marginBottom: 14`** on `card`, with a
comment saying it exists precisely so a second card does not sit flush. So item
3's missing gap is **not** a missing style — it needs reproducing with two or
more bookings before anything is changed.

`BookedScreen.tsx:111-114` sets `title: { fontSize: 28 }` with **no
`lineHeight`**. `shared/ui/Text.tsx` defaults to `variant='body'`, whose
`lineHeight` is `sizes.md × lineHeights.normal`. A 28pt glyph in a ~24pt line
box clips — and iOS clips to the line box where Android is forgiving, which is
exactly the platform split the owner reports.

## Consequence

Two distinct root causes, not four bugs; item 3's gap is a third, unconfirmed.
Detail in `004-context.md`.

## Next

`003-understand.md`.
