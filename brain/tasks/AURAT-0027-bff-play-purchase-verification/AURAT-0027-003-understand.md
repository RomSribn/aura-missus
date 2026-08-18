# AURAT-0027 — 003 understand

Date: 2026-08-17

## What the owner wants

The server half of the Google Play top-up rail, built now rather than parked
behind the Play service account that does not exist yet.

Three things, in this order:

1. **`purchaseAccountId` on `GET /v1/wallet` first.** Not third. The app treats
   its absence as "the rail is not configured" and keeps the whole thing
   switched off, so until this ships nothing else can be exercised at all.
2. **`POST /v1/wallet/top-ups/google`** — verify, then credit from the BFF's
   **own** tier table, behind a **fake verifier** so the endpoint, the tier
   table and the token uniqueness are real and tested today. The real Google
   call is gated on `AURAS-0002` step 7.
3. **Idempotency on the `purchaseToken`, by unique constraint** — not
   check-then-insert. One token, one ledger entry; a replay returns the
   original with `replayed: true`, never an error, because the app retries by
   design.

Governing sentence, and the one that outranks convenience: **never let the app
credit its own balance.** `AURAD-0010` is the spec, not a suggestion — the
ordering and the idempotency rule are ratified.

## What that means concretely

The credit amount comes from the SKU via a server-side table, never from the
request (the contract has no amount field at all). The caller comes from the
Firebase ID token. Google's `obfuscatedExternalAccountId` must equal the
caller's `purchaseAccountId`, which is what stops user A redeeming user B's
token — and it only works because the id is **server-minted**.

## The trap the fake verifier creates

A fake verifier that approves whatever it is handed is, by definition, "the app
credits its own balance". It is fine in a slave and fatal in production, so
what actually ships has to make that configuration unreachable — the same
problem `AURAT-0007` solved for the stub top-up by refusing in production, and
the same reason `purchaseAccountId` cannot simply be served unconditionally.

## Next

`004-context`.
