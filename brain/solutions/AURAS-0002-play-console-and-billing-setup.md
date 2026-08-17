# AURAS-0002 — Play Console and Google Play Billing setup

Date: 2026-08-17
Status: active — **owner-executed**; nothing here can be done from a session

## Problem

Half of a Google Play Billing integration is not code. `AURAT-0026` shipped
everything that can be built and tested locally; the rest is a sequence of
console steps gated on an approved developer account, and it has to exist
written down or it becomes an unanswerable "what's left?" every time the
subject comes up.

Grounded in `AURAD-0010`. App half `AURAT-0026`, BFF half `AURAT-0027`.

## Solution

Run these in order. Each step unlocks the next — that ordering is the whole
point, and it is why the work cannot simply be "done later in one sitting".

### 1. Developer account

Register at <https://play.google.com/console> ($25, one-off) and pass identity
verification. **Personal vs organisation matters**: a personal account created
after 13 Nov 2023 must later run a closed test with **12 testers opted in for
14 continuous days** before it may even *apply* for production access.
Organisation accounts are exempt. The 14 days start when the twelfth tester
opts in, so if production timing matters, this is the decision that sets it.

### 2. Create the app

Create the app under package **`cc.silvermind.aura`**. The package is not
reserved until the first upload — nothing before this point claims the name.
Listing title: **Aura — Psychic Reading** (22 of the 30 allowed characters).
The launcher label in the build is the short "Aura" on purpose.

### 3. Upload the first AAB

```bash
cd android && ./gradlew :app:bundleRelease
# → app/build/outputs/bundle/release/app-release.aab
```

Signing comes from `android/keystore.properties`; the upload keystore lives
outside the repo (see `keystore.properties.example`). Upload to the **internal
testing** track. This is what makes the in-app products screen usable.

Accept **Play App Signing** (the default). Google then holds the app signing
key and yours is only an *upload* key — which is why losing it is recoverable.

### 4. Register the Play app-signing certificate in Firebase

Play Console → *Setup → App integrity* → copy the **app signing** certificate's
SHA-1 and SHA-256, and add them to the Firebase Android app for
`cc.silvermind.aura`. Without it, phone-OTP fails Play Integrity on builds
installed **from Play** — while the same build sideloaded works, which makes it
an easy failure to misdiagnose. (`AURAT-0026` already registered the debug and
upload certificates; only Google's own is missing, and it does not exist until
step 3.)

### 5. Create the four products

*Monetise → Products → In-app products*, all **consumable one-time** products:

| Product ID | Credits |
|---|---|
| `aura.topup.usd10` | $10.00 |
| `aura.topup.usd25` | $25.00 |
| `aura.topup.usd50` | $50.00 |
| `aura.topup.usd100` | $100.00 |

The IDs must match `features/store-topup/config/products.ts` **exactly** — the
app drops any tier Play does not return, so a typo shows up as a missing card
rather than an error. Set the base price in USD and let Google generate local
prices; the app displays Google's price and credits the tier's nominal amount
(`AURAD-0010`).

### 6. Licence testers

*Setup → Licence testing*: add the tester Google accounts. They buy with test
cards and are never charged. They must also be on the internal-testing track
and install **from Play** — a sideloaded build cannot transact, and that alone
accounts for most "it doesn't work" reports.

### 7. Server-side verification (unblocks `AURAT-0027`)

1. Play Console → *Setup → API access* → link a Google Cloud project.
2. Create a service account; grant it **View financial data** and
   *Manage orders and subscriptions* on the app.
3. Download the JSON key and hand it to the BFF as a secret.
4. The BFF calls `androidpublisher.purchases.products.get(packageName,
   productId, token)` and credits only on a *purchased* state.

Reads over the Play Developer API are quota-limited (order of 200k/day), which
is far above anything this rail will produce.

### 8. Refund notifications

Create a Pub/Sub topic, set it as the app's **Real-time developer
notifications** endpoint, and give the service account publish rights. The BFF
subscribes and writes a compensating negative ledger entry on
`ONE_TIME_PRODUCT_CANCELED`. The Voided Purchases API is the periodic sweep
for anything a lost notification missed.

### 9. Production

Only after the closed-testing requirement from step 1 is satisfied, apply for
production access and answer the feedback questionnaire.

## Current Behavior

Done in `AURAT-0026`: package `cc.silvermind.aura`, an upload keystore and a
signed AAB, the Firebase Android app with debug + upload SHAs, and the whole
client purchase flow — dormant behind `STORE_BILLING_ENABLED`, which also
requires Android, a live wallet and a server-minted `purchaseAccountId`.

Not done, and not doable from here: every step above.

## Next

Steps 1–3 are the unblocking sequence; nothing else can start until an AAB is
on a track. Step 7 is what `AURAT-0027` waits on.

## Watch out

- **Billing Library 8+ is required for any upload from 31 Aug 2026.** We ship
  Play Billing **9.1.0** via `react-native-iap` 16.3.1, so this is satisfied —
  but a downgrade of that dependency would silently break publishing.
- **Google's cut** is 15% of the first $1M/year, 30% above. A $10 tier nets
  about $8.50 (`AURAD-0010`, open question).
- **Play Billing is likely mandatory** for these top-ups, not optional
  (`AURAD-0010`): the sessions are digital services consumed in-app, so the
  card rail of `AURAF-0009` should not be the Android one.
