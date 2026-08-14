# AURAT-0025-003 — Understand

Date: 2026-08-14

## What the owner wants

The screens to look on iOS the way they already look on Android. Four reported
defects; the work is to fix what is actually broken, not to restyle.

## What the four reports resolve to

- **Items 1, 2, 3-top** — one cause. Every misbehaving element is a
  `react-native-linear-gradient`, and the symptoms are container-shaped: wrong
  width, wrong height, content clipped by the container's own edge. Nothing
  about the styles is wrong; the view is not being measured.
- **Item 4** — a different cause: a local `fontSize` with no `lineHeight`,
  which is `AURAT-0012`'s subject.
- **Item 3-gap** — unconfirmed. The margin the report says is missing is
  present in the source, and the screenshot shows a single booking, so there is
  no second card for a gap to appear between. Reproduce with two before
  touching anything.

## Why iOS only

Both confirmed causes are places where iOS is strict and Android is not: text
clipping to the line box, and the Fabric interop path for a legacy native
component. That the owner sees Android as clean is consistent with the diagnosis
rather than evidence against it.

## The prior that applies

`AURAT-0011` was the same shape — a confident visual report whose stated premise
was wrong, where the real defect was an inherited `lineHeight`. So: reproduce
each item, measure, and only then change. An "obvious" padding fix that makes a
screenshot look right while the container is still mis-measured would hide the
bug rather than fix it.

## Next

`004-context.md`.
