# AURAT-0008-010 — Approved

Date: 2026-07-13
Status: **done**

User verified the manor checklist from 009-merge (flag gate, pricing +
unseeded-advisor 404, booking with exact up-front debit and ledger invariant,
activity lines in the dashboard — `message_type: 'activity'` accepted by the
dev Chatwoot, no fallback needed — custom attributes, system marker in
history, meter EXHAUSTED flip, early finish forfeit + idempotency, extend,
key replays / 409 / 402) and accepted the result.

## Outcome

- BFF side of AURAF-0007 items 006/007 is live on manor develop @ `61f66f9`
  (code commit `0fe722d`), dormant behind `BILLING_ENABLED`.
- AURAF-0007 P1 scope (006–008) is now BE-complete; the feature closes fully
  when AURAT-0006 (app client) lands.
- **Pending on AURAT-0006 (app manor):** red markers rendered in the app;
  no session UI when the flag is off. Recorded, not blocking this task.
- Follow-ups already registered: advisor catalog / registration (TECH-DEBT
  row 10 + future AURAD in aura-app-manor), PSP feature replaces the stub
  top-up and brings top-up products, DB-level append-only before enabling
  billing in staging/prod (TECH-DEBT #7).

Task complete. Missus docs committed on the feature branch; slave released
via `wts-release slave-1`.
