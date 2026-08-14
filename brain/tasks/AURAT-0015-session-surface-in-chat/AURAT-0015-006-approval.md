# AURAT-0015-006 — Approval

Date: 2026-08-14
Status: **approved — implementation may start in slave-1**

## What the owner approved

The `005-spec.md` scope as written: server clock + `sessionState`/`minsLeft`,
the live-only `SessionBanner`, the divider restyle, chats-list markers and
sorting, and the header action swap. Rows 006–012 of `AURAF-0008` stay parked
per `AURAD-0008`.

## The two open questions, answered

1. **Divider copy stays the BFF's.** Only the styling changes (teal at start,
   ink-3 at end); the designed wording is not adopted and no BFF copy task is
   minted. Keeps the app and the Chatwoot dashboard telling the same story.
2. **Extend takes the server's smallest block**, not the design's hardcoded 15.
   Label is built from the pricing endpoint; with no options loaded the header
   stays "Book now" rather than offering a block the BFF would refuse.

Both answers were the recommended options, so `005-spec.md` needed no scope
change — the questions section was replaced with the resolutions.

## Standing constraints carried into execution

- Work happens **only in slave-1**. Manor is štab; the stack is not started from
  a slave, so runtime verification waits until after the merge.
- Nothing merges to `develop` without explicit in-the-moment owner approval.
- `'scheduled'` state and the ≤24h banner variant are **not** built — unreachable
  under `AURAD-0002`, and they arrive with `AURAT-0016`.
- Row 004's sorting is bounded by whether the BFF can report session state for
  every listed advisor. Check before implementing; if it cannot, ship the
  narrower behaviour and log BFF debt rather than faking it client-side.

## Next

`007-execute.md` — written in slave-1 after the code, before the IDE review.
