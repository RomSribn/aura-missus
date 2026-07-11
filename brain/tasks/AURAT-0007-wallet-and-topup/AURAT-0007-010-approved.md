# AURAT-0007-010 — Approved

Date: 2026-07-11

User accepted the task and ordered the release. Status: **done**.

Manor verification (develop @ 012c18e, then 5919f8b after AURAT-0005 merged):
Swagger-driven checks of the wallet flow. Findings during verification were all
environment, not code: manor clone lacked node_modules (npm ci), no manor
`.env` (assembled from .env.example + AURAS-0001 dev-Chatwoot creds + Firebase
service-account JSON → env vars; JSON moved to `<manor>/secrets/`, chmod 600),
and a not-running dev server misread as "CORS". Tooling added for future
verifications: `<manor>/secrets/mint-id-token.cjs` (custom token → ID token
for Swagger auth). No code defects surfaced; no fix iterations needed.

Delivered (recap): wallets + append-only ledger_entries (+ migration),
GET /v1/wallet, idempotent stubbed POST /v1/wallet/top-ups (503 in
production), BILLING_ENABLED gate (404 when off), contracts, 14 unit tests;
merged to develop @ 012c18e, pushed.

Downstream: AURAT-0008 consumes the ledger (SESSION_CHARGE reserved); PSP
feature replaces the stub credit source (needs an AURAD, minted in
aura-app-manor). AURAT-0005 merged second and took the migration-rebase duty
— develop now @ 5919f8b with both tasks.

Next: single missus docs commit → sync missus with origin/master (AURAT-0005
docs touched AURAF-0007 too) → wts-release slave-2.
