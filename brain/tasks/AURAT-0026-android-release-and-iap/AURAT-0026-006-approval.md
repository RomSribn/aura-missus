# AURAT-0026 — 006 approval

Date: 2026-08-17

**Approved** — owner: "апрувлю, приступай".

Covers `005-spec` in full, and ratifies **`AURAD-0010`** (Google Play Billing
is the Android top-up rail; the SKU defines the credit; only the BFF credits
the wallet; idempotency keys on the `purchaseToken`; refunds are negative
ledger entries and the balance may go below zero). `AURAF-0010` moves to
`in-progress`.

Two things inside the approved plan still need their own in-the-moment go, as
the spec said, and were **not** granted by this approval:

1. Creating the Android app + SHA registration in Firebase (a write to an
   external service).
2. Committing and pushing tag `v0.7.0` of `@aura/contracts`.

Both are asked for when reached. The merge gate is untouched and separate.

## Next

`007-execute`.
