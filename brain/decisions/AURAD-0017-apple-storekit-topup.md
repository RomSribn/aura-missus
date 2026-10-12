# AURAD-0017 — StoreKit is the iOS top-up rail; the server credits, never the app

Date: 2026-09-25
Status: **accepted** (owner's call 2026-09-25, at the App Store listing step of
`AURAT-0079`: *«B. Рельс StoreKit»*)

## Decision

On iOS money enters the product through **StoreKit in-app purchases**: the same
Top Up sheet sells the **same four consumables** it sells on Play, and their
only effect is to credit the prepaid USD wallet. Nothing about the money model
moves — the wallet stays the single source (`AURAD-0002`), a session is still
paid from it (`AURAD-0009`), the ledger stays append-only.

`AURAD-0010` already settled the shape of a top-up rail. **All five of its rules
carry over unchanged**, and they are the reason this decision is short:

1. The **product id defines the credit**, not the price paid.
2. **Only the BFF credits** the wallet. The app's purchase result is a claim.
3. The idempotency key is the **store's own id for the transaction**.
4. The store transaction is **finished only after our server has credited**.
5. A refund is a **compensating negative ledger entry**, and the balance may go
   negative.

## The four things Apple does differently

**1. The identity field is `appAccountToken`, and it must be a UUID.** Play's
`obfuscatedAccountId` accepts any opaque string; Apple accepts a UUID and
nothing else. `purchaseAccountId` is already one —
`@default(dbgenerated("gen_random_uuid()")) @db.Uuid` (`AURAT-0027-005`) — so
the binding is the *same fact on both rails*: no new column, no second id, and
the app still never mints it. What it buys is the same thing it buys on Android:
the server can refuse a transaction claimed by somebody else's account.

**2. The authority is the App Store Server API, not the JWS in the app's hand.**
StoreKit 2 hands the app a signed transaction, and it is tempting to post it and
verify the signature server-side. We do not: the app posts
`{transactionId, productId}` and the BFF asks Apple
(`GET /inApps/v1/transactions/{transactionId}`) — exactly the shape of the Play
rail, where the app posts a token and the server asks Google. A signature proves
the payload was signed; it does not prove the purchase is still standing, was
not refunded a minute ago, and belongs to this account. Apple's legacy
`verifyReceipt` is deprecated and is not an option.

Credit only if **all** of these hold:

- the JWS chain verifies to Apple's root and `bundleId` is `cc.silvermind.aura`;
- `productId` is in the BFF's **own** tier table — the amount is read from that
  table, never from the request body;
- `appAccountToken` returned by Apple matches the caller's `purchaseAccountId`;
- the transaction is a consumable purchase, not revoked;
- that `transactionId` has not been redeemed before.

**3. There are two environments, and the same build meets both.** A purchase
made from TestFlight or by a sandbox tester lives in Apple's **sandbox**; a
purchase from the App Store lives in production. The server tries production and
falls back to sandbox on a miss — Apple's own documented order. This is not a
build flag and must not become one: a TestFlight build that only knows sandbox
becomes a production build that credits nothing.

**4. Product ids are shared with Play.** `aura.topup.usd10 / usd25 / usd50 /
usd100` exist in both catalogues and mean the same credit. One tier table, keyed
by product id; the rail is told apart by the endpoint the app called, not by the
id. The display names in App Store Connect read `$10 wallet credit` while Apple
may charge `$9.99` — that is rule 1 again, and it is the same gap Play has had
since August.

*Measured 2026-09-30 (`AURAT-0081-011`/`012`):* the gap is wider than that.
Only the USA carries the manual price; the other 174 storefronts are Apple's
automatic prices with local tax, so `usd25` is €29 across the eurozone and $29
in Ukraine and most dollar storefronts. The owner accepted this — no manual
per-territory prices. Separately, TestFlight showed the US `displayPrice`
($25.00) under a tier whose sheet charged $29; this is to be re-checked on the
first production sale, not patched with a "+VAT" label.

## What this costs

Two tasks, in two repositories: `AURAT-0081` (app — the iOS branch of the
top-up rail) and `AURAT-0082` (BFF — verification, crediting, and the refund
notification). Plus three things only the account holder can do: the **Paid
Applications Agreement** with bank and tax details, without which no in-app
purchase can be sold at all; an **In-App Purchase key** for the App Store Server
API; and a **sandbox tester**.

## Why not the alternative

The other branch was to ship iOS without the paid part — hide the wallet, the
Sessions tab and the Book button, and sell nothing. It was the faster release
and it was refused: it makes the App Store listing a different product from the
Play one, and the work would have to be undone on the next release anyway.
