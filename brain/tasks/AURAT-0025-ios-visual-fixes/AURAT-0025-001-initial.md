# AURAT-0025-001 — Initial

Date: 2026-08-14
Context: raised from **manor** after the owner's iOS device pass following the
`AURAT-0017` release. Execution slave is **slave-1**,
`feature/AURAT-0025-ios-visual-fixes`, off aura-app `develop`.

## What the owner reported

Four visual defects, **iOS only** except where noted, with four screenshots:

1. **Home** — the card is not full width (fine on Android).
2. **Session detail** — the same, and the hero's big start time is cut off.
3. **Sessions tab** — the Upcoming card's top block renders incorrectly, and
   there is **no gap between cards** — the gap is missing **on Android too**.
4. **Booked confirmation** — the title is slightly clipped (fine on Android).

> «карточка на странице home и session details не на всю ширину (на андроиде
> норм), карточка на скрине сессий отображается некорректно в плане топ инфы и
> так же нет отступа между карточками (отступ отсутсвует и на андроиде) и на
> подтверждающем бронировании скрине тайтл обрезается слегка (на андроид всё
> норм)»

## First read of the screenshots

In all three of 1–3 the element that misbehaves is a **plum gradient**: on Home
the Daily-ritual banner sits inset from the screen padding its sibling cards
respect; on Session detail the hero is inset the same way *and* clips "20:30" at
its bottom edge; on Sessions the plum header is inset inside its own white card
and clips "Reading with Olivia Fl…".

Item 4 is a different shape of bug — a text baseline, not a container.

## Next

`002-check.md` — brain and code state.
