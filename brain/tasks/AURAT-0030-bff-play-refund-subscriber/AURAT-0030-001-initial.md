# AURAT-0030 — 001 initial

Date: 2026-08-19
Kind: BFF task. **ID minted in `aura-app-manor`** (the counter authority,
`AURAD-0006`); the work happens in **`aura-bff-manor`**.
Status: not started — blocked on `AURAS-0002` step 8 (Pub/Sub topic), which is
itself downstream of step 7 (service account).

## What

Money can now enter the wallet through Google Play (`AURAT-0027`). This is the
other direction: Google can **refund or revoke** a purchase after we have
credited it, and the credit may already be spent.

`AURAD-0010` settles what happens, and it is not negotiable at implementation
time:

> A refund is a **compensating negative ledger entry**, and the balance may go
> below zero. It **stays** below zero until a later top-up covers it; the
> balance is **never clamped**, because clamping breaks `balance = Σ ledger` —
> the invariant `AURAT-0010` verified on device — and delivered sessions are
> never clawed back.

Booking already refuses when the balance cannot cover the cost, so a negative
balance simply blocks buying more. That is the intended behaviour, not a bug to
be defended against.

Closes `AURAF-0010-006`, the last `✗` in that feature's scope table apart from
iOS.

## Why it was not built with `AURAT-0027`

Deliberately, and the reason is worth keeping: the subscriber has **no reachable
trigger** without the Pub/Sub topic. Building it would have merged a processor
nothing can call — build rule 8. The verifier was different: it is selected by
config and its refusal paths are exercisable today.

## What `AURAT-0027` already left in place

- `play_purchases` — `purchaseToken` (unique) → `walletId`, `productId`,
  `creditedMinor`, `orderId`, and `ledgerEntryId` (**unique**, 1:1 with the
  credit). This is where a refund finds what to reverse and how much.
- The locked credit transaction shape (`SELECT … FOR UPDATE` on the wallet, then
  append, then update the cached balance) — the debit must use the same one.
- `ledger_entries_append_only`, a `BEFORE UPDATE OR DELETE` trigger. The
  database will now *reject* any attempt to "fix" the original entry, which is
  precisely the mistake this task must not make.
- `LedgerEntryType` is `TOPUP | SESSION_CHARGE | SESSION_REFUND`. A Play refund
  is none of those; it needs its own value.

## Scope

1. **Receive the notification.** RTDN arrives as a base64 JSON payload on a
   Pub/Sub topic (`AURAS-0002` step 8). Only `ONE_TIME_PRODUCT_CANCELED`
   matters; every other notification type — subscriptions, test pings, voided
   purchase events we do not handle — is acknowledged and dropped, the way the
   Chatwoot receiver already treats events it does not want.

2. **Debit, as a new entry.** Look the token up in `play_purchases`; append a
   **negative** entry of exactly `creditedMinor`, in the same locked
   transaction; let the balance go where it goes.

3. **Idempotency, again on the token.** Google retries, and a second
   notification must not debit twice. Server-derived key, the way the credit's
   `play:<sha256(token)>` and the session refund's key already are.

4. **A refund for something we never credited is a no-op**, not a debit. A
   purchase we refused (wrong account, wrong state, unparseable response) has no
   `play_purchases` row, and inventing a debit for it would take money from a
   user who never got any.

5. **Voided Purchases API sweep** — the periodic backstop for a notification
   that was never delivered, the same role the message reconciliation poll plays
   for Chatwoot (`AURAI-0002` §2.4). A lost RTDN otherwise means a refund we
   never see.

## Open — decide before writing the code

- **Push or pull?** A Pub/Sub *push* subscription means a new **public** route,
  and it must verify Google's signed OIDC token before trusting a byte — an
  unverified refund endpoint is a way for anyone to zero a wallet. A *pull*
  subscription means a BullMQ job and no public surface at all. This is the
  shape of the whole task and should be settled first; the second option looks
  smaller and safer, but adds a dependency this service does not have yet.
- **How the refund links back.** `play_purchases.ledgerEntryId` is `@unique` and
  1:1 with the credit, so the refund entry cannot reuse it. Either a second
  nullable column, or a row per movement, or no link at all beyond the shared
  token. Cheap to decide now, expensive to migrate later.
- **Does a refund need to reach Chatwoot?** A chatter seeing a user's balance go
  negative mid-conversation is a support question, and nothing in `AURAD-0010`
  answers it.

## NOT in scope

- Refunding a user's money **back to Google** — money leaving the product is
  `AURAF-0009`'s open question, unchanged.
- Clawing back delivered sessions. Explicitly refused by `AURAD-0010`.
- Clamping the balance at zero. Same.
- iOS / StoreKit refunds.

## Depends on

- `AURAS-0002` **step 8** — Pub/Sub topic set as the app's RTDN endpoint, with
  publish rights for the service account. Which needs **step 7** first, since it
  is the same service account.
- **`TECH-DEBT #17`** is the honest context: `GooglePlayVerifier` has still
  never spoken to Google. The Voided Purchases sweep in scope item 5 is a second
  call to the same API by the same credentials, so it inherits that exposure —
  the first real purchase is what proves either of them.

## Next

Run `wts-task` in `aura-bff-manor` and continue at `002-check` there.
