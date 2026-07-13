# AURAT-0008-004 — Understand

Date: 2026-07-11

## What the user wants

Implement the **BFF side of paid sessions** (AURAF-0007 items 006/007) behind
`billing_enabled`: a `sessions` module where a user books a fixed minute-block
that is debited up front (`minutes × advisor.price`) from the AURAT-0007 wallet
ledger in one transaction; a meter (BullMQ) runs the block down and finishes it
(or the user ends early, forfeiting the remainder); on start/finish the BFF
posts activity lines into the Chatwoot conversation and mirrors live session
state + accumulated paid minutes into conversation `custom_attributes` —
everything through the sealed chatwoot adapter.

## Explicit scope limit (agreed with user at dispatch)

BFF only. AURAT-0006 (app client) runs in parallel in `aura-app-manor` and is
NOT done — app-visible acceptance ("markers render in the app", "no session UI
with flag off") is recorded as **pending on AURAT-0006**, not verified here and
not blocking.

## Constraints

- No new AURA* IDs from this workspace.
- Slave-pure verification only (lint/typecheck/build/unit); live meter loop and
  Chatwoot activity lines verified in manor after merge.
- Reuse the AURAT-0007 debit path (append-only ledger, `SELECT … FOR UPDATE`);
  server is the sole authority on balance/session state.

No clarifying questions needed — spec cut (001-check) + decisions are precise.
Next: 005-context (code map).
