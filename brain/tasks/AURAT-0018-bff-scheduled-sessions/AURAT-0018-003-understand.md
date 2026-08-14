# AURAT-0018-003 — Understand

Date: 2026-08-14

## What the user wants

Build the BFF half of `AURAD-0009`: a paid session stops being an instant block
and becomes a **scheduled slot** — booked and prepaid from the wallet for a future
time, started by the server's own meter when the slot arrives, changeable
(reschedule, free up to 4h before), cancellable **with a real refund** (≥24h full,
<24h half, server-computed, before the start only), priced with a flat −$5
first-session credit the server applies, offered from a **real** availability read,
and listable so the app's Sessions tab has history at all.

It must land against the already-published `@aura/contracts` **v0.5.0** shape, keep
everything behind `billing_enabled`, and keep the money discipline `AURAT-0007/0008`
established: locked wallet row, append-only ledger, `balance == Σ ledger`, server
as the only authority on price and state.

## What that actually is, in one line

The riskiest part is not the calendar — it is that **money has to move backwards
for the first time**, in a codebase whose ledger has only ever had a debit
direction.

## Boundaries

- Slave: code, lint, typecheck, build, pure unit tests. No stack.
- The migration run and live refund verification are **manor work after the merge**.
- Instant booking retires; `extend` on a running session is untouched by
  `AURAD-0009` and stays.

## Next

Step 004 — context.
