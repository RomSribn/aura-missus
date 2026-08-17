# AURAT-0027 — 001 initial

Date: 2026-08-17
Kind: BFF task. **ID minted in `aura-app-manor`** (the counter authority,
`AURAD-0006`); the work happens in **`aura-bff-manor`**.
Status: not started — blocked on `AURAS-0002` step 7 (service account).

## What

The server half of the Google Play top-up rail. `AURAT-0026` shipped the app
half: it buys through Play and hands the purchase to the BFF. Right now nothing
answers, so the rail is off by construction.

`AURAD-0010` is the spec. Read it first — the ordering and the idempotency rule
are decisions, not implementation choices.

## Scope

1. **`POST /v1/wallet/top-ups/google`** — body `GooglePlayTopUpRequest`
   (`purchaseToken`, `productId`; `@aura/contracts` **v0.7.0**), caller from the
   Firebase ID token as every other route. Credits only when all of:
   - `androidpublisher.purchases.products.get(ourPackage, productId, token)`
     returns `purchaseState = 0` (purchased);
   - `productId` is in the BFF's **own** tier table — and the credit comes from
     that table, never from the request;
   - Google's `obfuscatedExternalAccountId` equals the caller's
     `purchaseAccountId`;
   - the token has not been redeemed before.

   Answers `GooglePlayTopUpResponse` — and on a token seen before, the original
   entry with `replayed: true` rather than an error. The app retries by design.

2. **Idempotency on the `purchaseToken`**, enforced by a unique constraint, not
   by a check-then-insert. It is the only key both sides agree about.

3. **`purchaseAccountId` on `GET /v1/wallet`** — an opaque, stable, per-wallet
   id, ≤64 chars, no PII (Google forbids an identifiable id in that field).
   Server-minted precisely so the app cannot derive anyone else's. **Until this
   ships the app keeps the rail switched off**, so it is the first thing to do.

4. **Tier table** mapping SKU → credited minor units, matching
   `features/store-topup/config/products.ts`. Two copies is deliberate: the
   app's drives four cards, the BFF's is the money.

5. **Refunds** — RTDN subscriber; `ONE_TIME_PRODUCT_CANCELED` writes a
   compensating **negative** ledger entry. The balance may go below zero and is
   **never clamped**: `balance = Σ ledger` is the invariant `AURAT-0010`
   verified on device. Voided Purchases API as the periodic sweep.

6. **Production guard** — the stub `POST /v1/wallet/top-ups` already 503s in
   production (`AURAT-0007`). Nothing here changes that; the store rail is a
   separate route.

## NOT in scope

- Consuming the purchase — that is Play-side and the app's, deliberately after
  our 200 (`AURAD-0010`).
- iOS / StoreKit verification.
- Subscriptions.
- Paying out to chatters (`AURAF-0009` open question 3).

## Depends on

- `AURAS-0002` step 7: linked GCP project + service account JSON. Nothing here
  can be verified end to end before that.
- BFF `TECH-DEBT #7` (DB-level append-only enforcement on `ledger_entries`) is
  worth taking with this task: this is the first rail where an **outside party**
  can reverse an entry.

## Next

Run `wts-task` in `aura-bff-manor` and continue at `002-check` there.
