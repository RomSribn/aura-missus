# AURAT-0026 — 004 context

Date: 2026-08-17

Sources: the brain (`002-check`), the code on this branch (ground truth), the
live Firebase project via the Management API, `openiap.dev`'s `llms-full.txt`
(fetched today), the `react-native-iap@16.3.1` tarball itself, and Google's
own published policy pages. Library facts below come from **reading the
published package**, not from the marketing page — the docs site is a SPA and
returns nothing to a fetcher.

---

## A. The library the owner named

`react-native-iap`, current **16.3.1** (published 2026-08-14). Not the version
the owner's link's prose describes — the site still says "v14.4.0+ uses Nitro"
— but the same line.

| Fact | Value | Our project |
|---|---|---|
| Peer: `react-native-nitro-modules` | `^0.36.5` | new dep, must be installed alongside |
| React Native | 0.79+ | **0.85.3** ✓ |
| Kotlin | "2.1.20 or later" | root `ext.kotlinVersion = 2.1.20` ✓ (exactly the validated version) |
| Android minSdk | 23 | **24** ✓ |
| compileSdk / targetSdk | 36 | **36** ✓ |
| NDK | 27.1.12297006 | identical ✓ |
| Java/Kotlin target | 17 | RN 0.85 default ✓ |
| Play Billing Library | **9.1.0** (via `openiap-google` 3.3.1) | — |
| iOS | StoreKit 2, iOS 15+, needs the *In-App Purchase* capability in Xcode | not this round |
| Amazon peer deps | `@amazon-devices/*` | marked `optional: true` in `peerDependenciesMeta` — no install noise |

Two things that matter and are easy to get wrong:

- **The library ships its own `android/gradle.properties`** with every
  `NitroIap_*` default it needs (AGP 8.13.2, coroutines 1.11.0,
  play-services-base 18.10.0, junit 4.13.2). `rootProject.ext` wins where it
  exists, so our Kotlin/SDK/NDK values are used and **nothing has to be added
  to the app's `gradle.properties`**. The store flavour defaults to `play`
  (`horizonEnabled` / `fireOsEnabled` both unset → `missingDimensionStrategy
  "platform", "play"`).
- It ships `consumer-rules.pro` keeping `com.margelo.nitro.iap.**`, so R8
  would not strip the Nitro HybridObject. Moot for now — the app has
  `enableProguardInReleaseBuilds = false`.

**The Play Billing version is load-bearing, not a detail.** Google's
deprecation schedule closes the publishing gate on **31 August 2026 — two
weeks from today**: from then, new apps and updates must ship Billing Library
**8 or later**. Being on 9.1.0 clears it with room. Anything older than v8
could not be uploaded at all.

Relevant client API (read off `src/types.ts` / `src/index.ts`):
`initConnection` / `endConnection`, `fetchProducts({skus, type:'in-app'})`,
`requestPurchase({request:{google:{skus, obfuscatedAccountId}}, type:'in-app'})`,
`purchaseUpdatedListener` / `purchaseErrorListener`, `finishTransaction({purchase,
isConsumable})`, `getAvailablePurchases()`, and the `useIAP` hook over the top.
`PurchaseAndroid` carries `purchaseToken`, `productId`, `packageNameAndroid`,
`transactionId`, `isAcknowledgedAndroid`, `purchaseState`,
`obfuscatedAccountIdAndroid` — i.e. everything the server needs to verify.

---

## B. What the account approval actually gates — the owner's real question

Split honestly, because the answer is "most of it, but not the part that
proves it works".

### Not gated — doable now, and it is the larger half

1. **Package rename and everything Gradle.** `applicationId`, `namespace`, the
   Kotlin package dirs, `rootProject.name`, the launcher label.
2. **Release signing.** An **upload keystore** is generated locally with
   `keytool`; Google never sees it until the first upload. A signed, verifiable
   release AAB/APK can be produced and installed today.
3. **The Firebase half of the rename.** `google-services.json` for
   `cc.silvermind.aura` + SHA registration, via the Management API with the
   credentials already on this machine (`AURAT-0001` used the same path).
4. **The whole client integration**: install, connection lifecycle, catalog
   fetch, purchase request, listeners, error taxonomy, and — the important
   one — *never* finishing a transaction until our own server has said yes.
   All unit-testable with the native module mocked.
5. **The app↔BFF contract** for redeeming a purchase, as a `@aura/contracts`
   bump, plus the BFF task that implements it.
6. **The decision** about how a store purchase becomes wallet balance:
   verification, idempotency, refunds, who credits the ledger.
7. **Product/SKU naming** and the mapping from the existing `TOP_UP_AMOUNTS`
   (`$10 / $25 / $50 / $100`, default `$25`).

### Gated — cannot be finished, at any effort, until the account clears

1. **Creating the app in Play Console** and therefore the package name being
   claimed. `cc.silvermind.aura` is not reserved until someone uploads it.
2. **Creating the in-app products.** SKUs live in Play Console, which needs
   the app, which needs an uploaded build.
3. **Any real purchase.** Play Billing only transacts for an app the device
   got *from Play*, signed by the right key, for a licensed tester account.
   There is no offline mode and the old static SKUs
   (`android.test.purchased`) are long gone.
4. **The Play app-signing certificate's SHA-1**, which Firebase needs for
   phone-auth Play Integrity on Play-distributed builds — it only exists after
   the first upload.
5. **Server-side verification against Google.** The Play Developer API needs a
   service account on a GCP project *linked from Play Console*; RTDN needs a
   Pub/Sub topic configured there too.
6. **Production release.** Personal accounts created after 13 Nov 2023 need a
   closed test with **12 testers opted in for 14 continuous days** before they
   may even apply for production access. Organisation accounts are exempt.
   The 14 days start when the 12th tester opts in — so this is a calendar
   cost, not an engineering one, and it starts only after approval.

**Consequence for the plan:** everything in the first list ships now and is
verified by build + unit tests; everything in the second becomes a written
runbook the owner executes the day the account clears. Nothing in the code
should be *shaped* by the gate — the flag pattern this project already uses
(`BILLING_ENABLED`, both halves) is exactly the right tool.

---

## C. Two findings the owner has to decide on, not just be told

### C1. On Android, Play Billing is very likely not optional — which puts `AURAF-0009` in question

Google Play's Payments policy requires Google Play Billing for purchases of
*digital content or services consumed within the app*. Aura's sessions are
chat, delivered inside the app; a wallet top-up buys exactly that. The
"real-world service" exemption (which would allow a card PSP) fits things
consumed outside the app, which this is not.

Read straight, that means the **card rail of `AURAF-0009` cannot be the
Android top-up rail** — not "would be nicer as IAP", but would risk removal.
It stays valid for iOS-external/web and for anything Google's rules exempt.
This should be stated in the decision rather than discovered later.

### C2. The fee changes the unit economics, and the credited amount is a decision

Play takes 15% of the first $1M/year of developer earnings and 30% above it.
A `$10` top-up nets ~`$8.50`. The wallet is USD minor units end to end
(`AURAD-0002`), but Play sells in the buyer's local currency at Google's own
price points, so *the price paid and the credit granted are different numbers
and always will be*.

The only coherent rule: **the SKU defines the credit, not the price paid.**
`aura.topup.usd10` credits `1000` minor units whether the user paid €9.49 or
₺349. Anything else lets an exchange-rate move mint balance.

Whether the owner absorbs the 15% or re-prices the Android tiers is a business
call that belongs in the decision, not in code.

---

## D. Ground truth in this repo that constrains the work

- `buildTypes.release.signingConfig = signingConfigs.debug` — the RN template's
  own "Caution!" comment is still there. There is no release keystore in the
  repo and no `bundleRelease` has ever run here.
- `versionCode 1` / `versionName "1.0"`; `APP_VERSION_LABEL` in
  `screens/profile/config/constants.ts` says `Aura · version 1.0.0`. Two
  sources for one number.
- Launcher label is `@string/app_name` = **"PsychoApp"**, and
  `MainActivity.getMainComponentName()` returns `"PsychoApp"`, which must keep
  matching `AppRegistry.registerComponent` in `index.js` / `app.json`.
- **The RN Gradle plugin sets `usesCleartextTraffic=false` for release**
  (debug `true`). Combined with `env.ts` — production `BFF_HTTP_URL` is the
  deliberate placeholder `https://bff.invalid` — a release build today
  installs and runs but **cannot reach any backend**. "Release-ready" in this
  task means *buildable, signable and uploadable*, not *production-functional*;
  the real URL arrives with the `AURAD-0005` hosting follow-through.
- The top-up path that exists: `TopUpSheet` (amount grid + a fake
  "Visa ···· 4242" row) → `use-profile` → `useWallet.topUp()` →
  `topUpWallet()` → `POST /v1/wallet/top-ups` → `walletStore.setBalance(
  result.balanceMinor)`. The BFF endpoint is a stub that **503s in
  production** (`AURAT-0007`). Whatever IAP does must land in the same store
  the same way (`AURAT-0019`), or two screens disagree about money.
- `bffRequest` already carries the Firebase ID token and treats **404 as
  "billing is not live"**. `BILLING_ENABLED` ships **`false`** client-side.
- Firebase, read live today: android app `com.psychoapp` (debug SHA-1
  `5e8f…f625`, SHA-256 `fac6…3b9c`), ios app
  `org.reactjs.native.example.PsychoApp`, project `aura-2781b` on **Spark**.
  Renaming the package **orphans that Android app** — a new one must be
  registered or phone-OTP and FCM both break.

## Contradictions / things that disagree

- `AURAF-0009` assumes a card PSP is the way money enters the wallet. On
  Android that is probably not permitted (C1). Not a blocker for this task,
  but the feature's premise narrows and the owner should know.
- The docs page the owner linked describes v14.x; the shipped package is
  16.3.1. Followed the package.

## Next

`005-spec`, after two questions to the owner (rename scope; who makes the
upload keystore).
