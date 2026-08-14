# AURAT-0012-002 — Folded into AURAT-0025

Date: 2026-08-14
Status: **closed without its own execution — scope moved, not dropped**

The owner's iOS device pass after `AURAT-0017` surfaced this class again: the
Booked confirmation's title sets `fontSize: 28` with no `lineHeight`, inherits
the `body` variant's ~24pt box from `shared/ui/Text.tsx`, and iOS clips it where
Android does not.

Rather than patch that one site — which `001-check.md` explicitly forbids — the
owner folded this task into **AURAT-0025**, which was already opening the same
screens for the gradient defect. The full scope travels intact: derive
`lineHeight` from the resolved `fontSize` in `Text`, audit consumers against the
prototype (`HoroscopeCard.signName` is the confirmed second case), and add the
lint rule that stops the class recurring.

Execution and acceptance live in the **AURAT-0025-ios-visual-fixes** task folder.
