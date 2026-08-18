# AURAF-0010 — Store-billing top-up (Google Play)

Type: product
Status: in-progress — both halves built (`AURAT-0026` app, `AURAT-0027` BFF);
dormant behind flags and gated on `AURAS-0002`
Priority: P1
Source spec: none (grounded in `AURAD-0010`; store docs at <https://openiap.dev>)

## What

Real money enters the wallet for the first time. On Android the user buys a
credit tier through Google Play's own checkout, our server verifies the
purchase with Google, and the wallet balance rises by the tier's nominal USD
amount. Everything downstream — booking, blocks, refunds — is untouched,
because the wallet was already the only rail (`AURAD-0002`, `AURAD-0009`).

This is the **store** rail. `AURAF-0009` is the **card** rail, and per
`AURAD-0010` it is probably not permitted for Android top-ups at all.

## Scope

| # | Src | Own | App | UI | BE | Del | Item |
|---|-----|-----|-----|----|----|-----|------|
| AURAF-0010-001 | me | ✓ | ✓ | ✓ | ✓ |  | User picks a credit tier in Top Up and pays through Google Play; the balance rises by the tier's nominal amount |
| AURAF-0010-002 | me | ✓ | ✓ | — | ✓ |  | The server verifies every purchase with Google before crediting; a forged or replayed claim credits nothing |
| AURAF-0010-003 | me | ✓ | ✓ | ✓ | — |  | Each tier shows the price Google will actually charge in the user's currency, not a hardcoded `$` |
| AURAF-0010-004 | me | ✓ | ✓ | ✓ | ✓ |  | A purchase interrupted by a crash, a kill or a dead network is redeemed on the next launch instead of being lost |
| AURAF-0010-005 | me | ✓ | ✓ | ✓ | — |  | A cancelled purchase is silent; a genuine failure says so and leaves the user's money with Google |
| AURAF-0010-006 | me | — | ✗ | — | ✗ |  | A refunded or revoked purchase debits the wallet (negative entry; balance may go below zero) |
| AURAF-0010-007 | me | — | — | — | — |  | Play Console: app created, tiers published, internal-testing track, licence testers — owner runbook, gated on account approval |
| AURAF-0010-008 | me | — | ✗ | ✗ | ✗ |  | The same rail on iOS via StoreKit — deferred until Apple's review clears |

`App` = approved against the source of truth (`AURAD-0010`), `Own` = owner
ratified. Rows 001–005 are `AURAT-0026` (app) + `AURAT-0027` (BFF); row 006 is
**not** `AURAT-0027` — see below; row 007 is the owner; row 008 has no task.

Row 003's `BE` was corrected `✗ → —`: the localized price comes from
`fetchProducts` against Play and the BFF has no part in it, so there was never
server work pending there.

**What `BE ✓` means on rows 001, 002 and 004, and what it does not.** `AURAT-0027` built
`POST /v1/wallet/top-ups/google`, the server-side tier table, the account check
and the token's unique constraint, and serves `purchaseAccountId` on
`GET /v1/wallet` — which is what switches the app's rail on at all. It has
**never verified a purchase with Google**: `AURAS-0002` step 7 (linked GCP
project + service account) is the owner's and is not done, so the real client is
unit-tested against a mocked transport and the runtime answer comes from a dev
verifier that only accepts `dev:` tokens and cannot credit a real purchase. The
code path is complete and refuses in the safe direction; the rail is not proven
end to end and cannot be until step 7.

**Row 006 moved off `AURAT-0027`** (owner decision, 2026-08-17). The RTDN
subscriber needs the Pub/Sub topic from `AURAS-0002` **step 8**, which does not
exist, and unlike the verifier it has no reachable trigger at all — it would be
dead code, which the build rules forbid. `AURAT-0027`'s schema already
accommodates it: a refund is a new negative `ledger_entries` row, and
`play_purchases` links a token to the credit it paid for, so the follow-up is
one migration plus a processor. Needs an ID minted in `aura-app-manor`.

## NOT in scope

- **Subscriptions.** Every tier is a *consumable* one-time product. A
  subscription is a different product shape, a different lifecycle and a
  different decision.
- **Paying for a session directly through the store**, bypassing the wallet.
  The wallet is the rail (`AURAD-0002`); a second one is a separate decision,
  and `AURAF-0009` already says so about cards.
- **Refunding a user's money back to Google.** Money leaving the product is
  `AURAF-0009`'s open question, unchanged.
- **Amazon Appstore, Meta Horizon, Vega OS.** The library supports them behind
  Gradle flavours; we ship the `play` flavour only.
- **Promo codes / offers.** `Coupons & Promo Codes` is an inert Profile row and
  stays inert.

## Context

- **The library is `react-native-iap` 16.3.1** (OpenIAP), Nitro-based, carrying
  **Play Billing 9.1.0**. That version is load-bearing: Google closes the
  publishing gate on **31 Aug 2026** for anything below Billing 8.
- **The gate that is not code.** Play Console products, licence testers and a
  real purchase all require an approved developer account, and a *production*
  release additionally requires 12 testers opted in for 14 continuous days
  (personal accounts). So rows 001–005 ship dormant behind a flag and row 007
  is a runbook, not a task.
- **Where it plugs in.** `TopUpSheet` → `useWallet.topUp()` →
  `POST /v1/wallet/top-ups` is the existing path, and that endpoint is a stub
  that 503s in production (`AURAT-0007`). The store rail is a *second*
  endpoint, not a replacement: the stub stays for dev, the store rail is what
  ships.
- **Both flags still apply.** Client `BILLING_ENABLED` and the BFF's own must
  be on before any wallet UI exists at all; the store rail adds a third,
  `STORE_BILLING_ENABLED`, because Play Console can be unconfigured long after
  billing itself is live.
