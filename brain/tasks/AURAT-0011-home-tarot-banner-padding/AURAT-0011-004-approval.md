# AURAT-0011-004 — Approval

Date: 2026-08-05
Approved by: owner, in session.

## Decisions

1. **R1 as specified** — revert the `cardWrapper` re-parenting (copy + fan back
   to being direct children of the gradient), extend the fan comment with *why*
   it is anchored to the banner, add the `TarotBanner` regression test, **and**
   swap the two bare `20`s for `theme.spacing.xl` (identical value, no pixel
   change).
2. **R2 included in this task** — explicit line heights for the three copy lines
   (eyebrow 14, title 26, subtitle 20) so the copy block is ~70pt instead of
   82pt and lands where design 07 puts it. The systemic version of the same
   pattern (`Text` overriding `fontSize` without `lineHeight`, app-wide) stays
   out and is to be minted as its own AURAT.
3. **R3 not taken** — the comment carries the intent; no extra node.

## Device question — answered

The edit was made from reading the code, **not from a running app**. So there is
no unexplained device symptom to chase: no Android clipping bug, no
`transformOrigin` problem. R1 + R2 closes the task, and the manor device pass is
ordinary verification rather than a hunt.

## Next

`AURAT-0011-005-execute.md`.
