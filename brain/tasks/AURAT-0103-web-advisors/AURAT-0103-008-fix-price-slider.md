# AURAT-0103-008 — Fix: price slider fill

Date: 2026-10-20
Owner (screenshot of the rail): the slider's coral fill drifts by a percentage and sticks out
past the thumbs on the left and right.

Cause: the fill was a `background` with a percentage `background-position` — CSS lines the
image's X% point up with the container's X% point instead of shifting it by X% — and it ignored
that a thumb's centre only travels from `thumb/2` to `width − thumb/2`.

Fix: a separate track between the centres of the extreme thumb positions, with the fill inside it
set by fractions `--low` / `--high` (0…1): `left: low·100%`, `right: (1 − high)·100%`.
