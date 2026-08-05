# AURAT-0012-001 — Check

Date: 2026-08-05
Status: minted, not started (no slave assigned)

## Why this exists

Found while doing AURAT-0011 (`AURAT-0011-002-understand.md`, Finding 4), and
deliberately left out of that branch so the banner fix stayed reviewable.

`shared/ui/Text.tsx` applies `lineHeight` per variant:

```ts
body:    { fontSize: 16, lineHeight: 16 * 1.5 },   // = 24
caption: { fontSize: 14, lineHeight: 21 },
title:   { fontSize: 24, lineHeight: 28.8 },
```

Consumers routinely override `fontSize` in a local `StyleSheet` while leaving
`lineHeight` alone. Because the local style is merged *after* the variant, the
override lands on `fontSize` only and the variant's `lineHeight` survives — an
11pt eyebrow gets a 24pt line box. The result is silent: nothing errors, the text
just sits lower and looser than the design.

Measured case: the Home tarot banner's copy block rendered **82pt against the
design prototype's ~69pt**, pushing the title and subtitle up to ~11pt low inside
a 148pt banner. Fixed locally in AURAT-0011 with three explicit line heights.

## Scope

- Audit `Text` consumers for a local `fontSize` with no `lineHeight`
  (`HoroscopeCard.signName` is a confirmed second case; `ContinueChatCard`,
  `TopAdvisorRow`, the chat and advisor slices are all candidates), and measure
  each against the prototype in `.claude/design_handoff_aura/prototype/` rather
  than by eye.
- Decide the shared fix and take it, rather than patching call sites forever.
  Options to weigh: derive `lineHeight` from the resolved `fontSize` inside
  `Text`; expose sizes as named props so `fontSize` is never set raw; or keep the
  variants and add a lint rule that flags `fontSize` without `lineHeight` in
  StyleSheet blocks fed to `Text`.
- Whatever lands, the theme already carries `typography.lineHeights`
  (`tight 1.2 / normal 1.5 / relaxed 1.75`) — the ratios exist, they are just
  not reachable once a consumer overrides the size.

## Acceptance

No `Text` consumer silently inherits a line box that does not match its font
size; the affected screens match their design screens on device; slave gates
green (tsc / eslint / jest).

## Notes

- Purely a fidelity/typography task — no behaviour, no navigation, no backend.
- Touches many screens at once, so it wants its own device pass in manor.
