# AURAT-0008-001 — Check

Date: 2026-07-10

Implements paid sessions of `AURAF-0007` (items 006/007), **behind the
`billing_enabled` flag**. Obeys `AURAD-0002` (fixed non-refundable minute
blocks, red markers) and `AURAD-0003` (a session is a window inside the durable
conversation).

Already in place: AURAT-0005 (messaging), AURAT-0006 (app thread), AURAT-0007
(wallet + ledger).

## Scope

- **"Book now"** → pick a fixed block (e.g. 10 / 20 / 30 min); pre-check
  balance ≥ cost, **debit `minutes × advisor.price` up front** (ledger).
- Meter run-down; **non-refundable** early end (forfeit remaining minutes);
  **extend / book another block** prompt near the end.
- Post **"Your session has started / finished"** as activity lines into the
  conversation — app renders the red markers; both app and chatter dashboard see
  the boundary.
- Push live session state + accumulated paid minutes to the Chatwoot conversation
  **`custom_attributes`** so chatters see the meter; per-shift paid-minute
  reporting hook.
- All gated by `billing_enabled`.

## Acceptance

With the flag **on**: a user books a block, balance debits up front, the meter
runs, markers show in both app + dashboard, early end forfeits remaining minutes,
extend works; with the flag **off**, no session UI.

## Dependencies

AURAT-0005, AURAT-0006, AURAT-0007. Closes `AURAF-0007` P1 scope (items
006–008).

Next: none — feature complete once approved (PSP + O5/O6 remain separate).
