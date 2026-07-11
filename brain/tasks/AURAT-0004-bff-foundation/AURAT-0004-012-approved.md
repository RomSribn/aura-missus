# AURAT-0004-012 — Approved

Date: 2026-07-11
Status: **done**

User verified the merged foundation in the manor (compose boot + migration,
health/readiness, Swagger UI; Chatwoot provisioning flow per available ops
setup) and accepted: "Принято".

## Task result

- aura-bff foundation on manor `develop` @ `24e6727` (feature commit
  `df32e19`, merged + pushed).
- Acceptance met: authenticated `PUT /v1/advisors/:advisorId/conversation`
  idempotently ensures Chatwoot contact + per-(user, advisor) conversation and
  returns the BFF conversation id.
- Runtime-verified twice at the HTTP surface in the slave (smoke drives, step
  009/010) + user verification in the manor.
- Tech debt recorded in `TECH-DEBT.md` (repo root); 2026 best-practices digest
  in step 009 and session memory.
- Unblocks: AURAT-0005 (messaging + delivery), AURAT-0007 (wallet, flagged).

Remaining: single missus docs commit on the feature branch, then
`wts-release slave-1`.
