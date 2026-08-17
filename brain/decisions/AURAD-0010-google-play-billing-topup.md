# AURAD-0010 — Google Play Billing is the Android top-up rail; the server credits, never the app

Date: 2026-08-17
Status: **accepted** (owner-ratified 2026-08-17, with `AURAT-0026`'s spec)

## Decision

On Android, money enters the product through **Google Play Billing**: the Top Up
sheet sells **consumable in-app products** whose only effect is to credit the
prepaid USD wallet. Nothing else about the money model moves — the wallet stays
the single source (`AURAD-0002`), a session is still paid from it
(`AURAD-0009`), the ledger stays append-only.

Five things this settles, each of which has exactly one defensible answer:

1. **The SKU defines the credit, not the price paid.** `aura.topup.usd10`
   credits `1000` minor units whether Google charged €9.49, ₺349 or $9.99.
2. **Only the BFF credits the wallet.** The app's purchase result is a *claim*,
   never an authority.
3. **The idempotency key is the Play `purchaseToken`.**
4. **The Play transaction is consumed only after our own server has credited.**
5. **A refund is a compensating negative ledger entry, and the balance may go
   negative.**

## How it works

**Buy.** The app requests the purchase with an `obfuscatedAccountId`: an
opaque, stable id **minted by the server** and served with the wallet
(`purchaseAccountId`). Server-minted rather than derived client-side from the
uid, because an app that can derive its own can derive somebody else's — and
Google forbids an identifiable id in that field either way. Google runs its own
checkout; the app never sees a card.

**Redeem.** The app posts `{purchaseToken, productId}` to
`POST /v1/wallet/top-ups/google`. The BFF, which already knows the caller from
the Firebase ID token, calls the Play Developer API
(`purchases.products.get`) and credits only if **all** of these hold:

- `purchaseState` is *purchased* (not pending, not cancelled);
- `productId` is in the BFF's own tier table — the credit amount is read from
  **that table**, never from the request body;
- `obfuscatedExternalAccountId` returned by Google matches the caller's
  `purchaseAccountId` — this is what stops user A redeeming user B's token;
- the token has not been redeemed before.

No package name travels in the request: the BFF asks Google about *its own*
package, so a token belonging to another one is simply not found. A field that
can only fail and never protect is worse than no field.

Then one append-only ledger entry, and the new balance comes back in the
response — landing in the shared wallet store exactly the way every other money
move already does (`AURAT-0019`).

**Idempotency is the token, not a client uuid.** The stub top-up keys on a
client-generated uuid because there is no external fact to key on; here there
is one, and it is the only thing both sides agree about. One token = one ledger
entry, enforced by a unique constraint. A replay returns the original entry and
credits nothing.

**Finish last.** `finishTransaction({isConsumable: true})` — which consumes the
purchase on Play — runs only after the BFF's 200. Consuming first would mean a
lost network round trip becomes money taken and nothing delivered. Ordered this
way the failure mode is benign: an app killed mid-redeem leaves the purchase
un-consumed, `getAvailablePurchases()` finds it on the next launch and redeems
it then. And if we never manage to, Google auto-refunds anything unacknowledged
after **three days** — the user gets their money back rather than silently
losing it.

**Refunds go negative.** Google can refund or revoke a purchase after we have
credited, and the credit may already be spent. The ledger is append-only, so a
refund is a **negative entry**, and `balance = Σ ledger` is preserved — the
invariant `AURAT-0010` verified on device across seven money moves. If that
takes the balance below zero it **stays** below zero until a later top-up
covers it; the balance is never clamped, because clamping breaks that
invariant, and delivered sessions are never clawed back. Booking already
refuses when the balance cannot cover the cost, so a negative balance simply
blocks buying more. Detection is Play's Real-time Developer Notifications
(`ONE_TIME_PRODUCT_CANCELED`) with the Voided Purchases API as a sweep.

## Why

- **It is very likely not optional.** Google Play's Payments policy requires
  Play Billing for digital content or services consumed inside the app. Aura's
  sessions are chat, delivered in-app; a wallet top-up buys exactly that. The
  "real-world service" carve-out covers things consumed *outside* the app,
  which this is not. Read straight, **the card rail of `AURAF-0009` cannot be
  the Android top-up rail** — that is a compliance risk, not a preference.
  `AURAF-0009` narrows to iOS-external / web / anything Google exempts, and it
  should say so.
- **The app crediting itself is the one unrecoverable mistake here.** A
  client-side purchase result is trivially forgeable on a rooted device; if it
  could mint balance, the wallet would be free. Server verification is the
  entire security model, which is why it is written into the decision and not
  left to the implementation.
- **The SKU-defines-the-credit rule** is the only one that cannot mint money:
  Play sells at Google's local price points and exchange rates move, so any
  rule deriving the credit from the price paid eventually credits more than it
  charged.

## Cost, and an open question that is the owner's

Google takes **15%** of the first $1M/year of developer earnings and **30%**
above it. A `$10` top-up nets about `$8.50`. Whether that is absorbed or the
Android tiers are re-priced is a business call, not a technical one, and it is
deliberately left open here.

Also open: whether the **−$5 first-session credit** (`AURAF-0009` question 2)
survives contact with a store rail, and who funds it.

## Consequences

- Implemented by `AURAF-0010`; app half `AURAT-0026`, BFF half `AURAT-0027`.
- `AURAF-0009` (card PSP) narrows — it is no longer the Android rail.
- BFF `TECH-DEBT #7` (DB-level append-only enforcement on `ledger_entries`)
  stops being a nice-to-have: this is the first rail where an outside party can
  reverse an entry.
- Nothing here applies to iOS. StoreKit is the same shape and a different
  verification API; it gets its own round when Apple's review clears.

Informed by `AURAD-0002`, `AURAD-0009`, `AURAT-0007`, `AURAT-0019`.
