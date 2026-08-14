# AURAT-0025-006 — Approval

Date: 2026-08-14
Status: **approved — implementation may start in slave-1**

## What the owner approved

`005-spec.md`: confirm-before-changing as the gate, the gradient migrated to a
single shared `react-native-svg`-backed component across all six consumers,
`AURAT-0012`'s typography class fixed in the same branch, and the card gap
touched only if it reproduces with two bookings.

## The two questions, answered

1. **`AURAT-0012` folded in.** The clipped title is fixed as a class — `Text`
   derives `lineHeight` from the resolved `fontSize`, consumers audited against
   the prototype, lint rule added — not as a patch to `BookedScreen`.
   `AURAT-0012` closes with this task.
2. **`react-native-svg`**, not the `3.0.0-beta.2` line of the existing library.
   Already a dependency, already Fabric-native, already backing `AuraIcon`.

## Standing constraints carried into execution

- **Step 0 gates everything.** Prove the frames differ before restructuring. If
  `onLayout` shows the gradient and its sibling at the same width, the
  hypothesis is wrong — stop and re-diagnose. `AURAT-0011` is the precedent for
  a report whose premise did not survive contact, and an empty diff plus an
  honest finding is an acceptable outcome.
- **Two root causes, two commits.** Gradient migration and typography land
  separately so either can be reverted alone.
- No width or height pinned to make a screenshot look right.
- The five non-reported gradient surfaces (tarot sheet, chat session banner,
  gradient button) are regression-checked — they share the new component.
- Work happens **only in slave-1**; the device pass runs in manor after merge.
- Nothing merges to `develop` without explicit in-the-moment owner approval.

## Next

`007-execute.md` — written in slave-1 after the code, before the IDE review.
