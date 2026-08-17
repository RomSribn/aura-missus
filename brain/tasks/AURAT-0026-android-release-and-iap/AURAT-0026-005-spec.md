# AURAT-0026 — 005 spec

Date: 2026-08-17
Status: **draft — awaiting approval**

## Owner's answers (2026-08-17)

- App name: **Aura — Psychic Reading**. Launcher label will be the short
  **"Aura"** (Android truncates under the icon at ~10 characters); the full
  name is the Play Console listing title, which is console metadata and lives
  in no file here.
- Rename scope: **Android only.** iOS bundle id, the Xcode project, `app.json`,
  `package.json` and the JS component name stay `PsychoApp` — invisible to
  users, and each rename costs a device pass that buys nothing while Apple is
  still reviewing.
- Upload keystore: **generated here.**

## Artifacts this task produces

| ID | Kind | Where | State |
|---|---|---|---|
| `AURAD-0010` | decision — Play Billing is the Android rail, the server credits | written, **needs ratification** |
| `AURAF-0010` | feature — store-billing top-up | written, draft |
| `AURAT-0026` | this task — app half | in progress |
| `AURAT-0027` | BFF task — verify with Google and credit | reserved, brief written at execute; **runs in `aura-bff-manor`** |
| `AURAS-0002` | runbook — Play Console + Play Developer API setup | reserved; the owner's steps once the account clears |

`AURAT-0027` and `AURAS-0002` are reserved in `active-work.md` now and written
at execution. IDs are minted here because this manor is the counter authority
(`AURAD-0006`).

---

## Part 1 — Android identity and a real release build

Everything here is verifiable today. One commit.

**Gradle** (`android/app/build.gradle`)

- `namespace` and `applicationId` → `cc.silvermind.aura`.
- `versionName "1.0.0"` (matching `APP_VERSION_LABEL`, which already claims
  1.0.0), `versionCode 1`.
- A real `signingConfigs.release`, read from **`android/keystore.properties`**
  — untracked, and absent from a fresh clone. Missing file must fail the
  release build with a sentence that says what to do, **not** fall through to
  the debug key. The template's silent `signingConfig signingConfigs.debug` on
  release is the bug being fixed; replacing it with a silent fallback would be
  the same bug wearing a hat.
- `enableProguardInReleaseBuilds` stays **false**. Turning on R8 is a real
  change with its own failure modes (Firebase, Nitro, reflection) and belongs
  in its own task, not smuggled into a rename.

**Sources** — `android/app/src/main/java/com/psychoapp/` →
`.../java/cc/silvermind/aura/`, `package` lines updated.
`MainActivity.getMainComponentName()` keeps returning `"PsychoApp"` and gains a
comment saying why: it must equal `AppRegistry.registerComponent` in
`index.js`, which the owner chose not to rename.

**Label** — `strings.xml` `app_name` → `Aura`.

**Keystore** — generated with `keytool` at **`~/.aura/aura-upload.keystore`**,
i.e. outside every worktree, so manor and all slaves share one copy and no
`git clean` can destroy it. `android/keystore.properties` (untracked) points at
it by absolute path; `android/keystore.properties.example` is committed so the
convention is discoverable. `.gitignore` gains `android/keystore.properties`
(`*.keystore` is already ignored with a `!debug.keystore` exception).

**Firebase** — the rename orphans the registered Android app, and phone-OTP and
FCM both break without a new one (`AURAT-0001`). Via the Management API with
this machine's existing credentials:

1. create the Android app `cc.silvermind.aura`;
2. register the **debug** keystore SHA-1/SHA-256 (unchanged fingerprints —
   `debug.keystore` is committed and is not being replaced);
3. register the **upload** keystore's SHA-1/SHA-256;
4. download the new `google-services.json` and commit it.

The old `com.psychoapp` app is **left in place**, not deleted — deleting it
would strand any build that is already installed somewhere.

> **This is a write to an external service and will be asked for separately
> before it runs.** Everything else in Part 1 is local.

**Gate**: `./gradlew :app:bundleRelease` produces a signed AAB, and
`apksigner verify --print-certs` names our upload certificate rather than the
Android debug one. `ANDROID_HOME` and JDK 21 are present on this machine.

### What Part 1 does *not* claim

A release build **cannot reach a backend**: `env.ts` ships
`https://bff.invalid` for production by design (the real URL arrives with the
`AURAD-0005` hosting follow-through), and the RN Gradle plugin sets
`usesCleartextTraffic=false` for release. "Release-ready" here means
*buildable, signable, uploadable* — not *production-functional*. Saying
otherwise would be a lie the first install would expose.

---

## Part 2 — The store top-up client

One commit. Ships **dormant**: it is inert until three flags line up, and
purchases cannot be tested at all until the developer account clears.

**Dependencies** — `react-native-iap@^16.3.1` + its peer
`react-native-nitro-modules@^0.36.5`. No Gradle edits: the library ships its
own `NitroIap_*` defaults and takes our `rootProject.ext` Kotlin/SDK/NDK
values where they exist, and the store flavour defaults to `play`.

**Flag** — `STORE_BILLING_ENABLED = false` in `shared/config/env.ts`, a third
flag beside client `BILLING_ENABLED` and the BFF's own. It exists because Play
Console can stay unconfigured long after billing itself is live, and because
`Platform.OS !== 'android'` must also switch the whole rail off.

**New slice `features/store-topup/`**

```
config/products.ts     TOP_UP_TIERS — the single source of the tier list
api/store-topup-api.ts redeemGooglePurchase() → POST /v1/wallet/top-ups/google
lib/account-id.ts      one-way hash of the Firebase uid → obfuscatedAccountId
model/use-store-topup.ts  the whole orchestration
model/types.ts
index.ts
```

`use-store-topup` owns, in this order, because the order is the safety
property (`AURAD-0010`):

1. `initConnection` on mount when the rail is live, `endConnection` on unmount;
2. `fetchProducts({skus, type:'in-app'})` — so each tier can show **Google's
   own localized price**, not a hardcoded `$`;
3. `requestPurchase({request:{google:{skus:[sku], obfuscatedAccountId}}})`;
4. `purchaseUpdatedListener` → `redeemGooglePurchase` → publish the server's
   balance into `walletStore` → **only then** `finishTransaction({purchase,
   isConsumable:true})`;
5. `purchaseErrorListener` → user-cancelled is silent, everything else is a
   visible failure;
6. on mount, `getAvailablePurchases()` → redeem anything left un-consumed by a
   crash or a dead network.

**Tier list de-duplicated.** `TOP_UP_AMOUNTS` / `DEFAULT_TOP_UP_AMOUNT` are
**deleted** from `screens/profile/config/constants.ts`; `TOP_UP_TIERS` in the
feature is the one source, used by both the store rail and the existing stub
path. Hard rule 4 — one source of truth per constant — and the SKU has to sit
next to the amount anyway or they drift.

SKUs: `aura.topup.usd10 / usd25 / usd50 / usd100` → `1000 / 2500 / 5000 /
10000` minor units.

**`TopUpSheet`** keeps its shape. When the rail is live each card gains
Google's localized price under the nominal tier and the decorative
"Visa ···· 4242" row becomes a Google Play row; when it is not, the sheet is
exactly what ships today.

**Contract** — `@aura/contracts` **v0.7.0**, additive: `GooglePlayTopUpRequest`
`{purchaseToken, productId, packageName}` and `GooglePlayTopUpResponse`
`{entryId, balanceMinor, currency, creditedMinor, replayed}`. Declared in the
shared package rather than in the app, because re-declaring is what every prior
task logged as debt. The shape is agreed here, in writing, with `AURAT-0027`
before either side builds on it — the lesson of `AURAT-0023/0024`.

> **Cutting v0.7.0 means a commit and a tag push to
> `github.com/RomSribn/aura-contracts`.** That is outward-facing and will be
> asked for separately.

**Tests** (jest, native module mocked in `jest.setup.js`): the credit lands in
the shared wallet store; `finishTransaction` is **not** called when the server
refuses; an un-consumed purchase found at mount is redeemed; a user-cancelled
purchase produces no error state; the rail is inert on iOS and with the flag
off.

### Honest limits of Part 2

Nothing here proves a purchase works. It cannot: Play Billing only transacts
for an app the device got from Play, signed by the right key, for a licensed
tester. What the tests prove is the *ordering* and the *refusal paths* — which
are the parts that lose money if wrong.

---

## Part 3 — the two gated things, written down rather than blocked on

- **`AURAS-0002`** — the owner's runbook: register the developer account,
  create the app under `cc.silvermind.aura`, upload the first AAB to internal
  testing (which is what unlocks the in-app products screen), create the four
  tiers, add licence testers, link the GCP project and mint the Play Developer
  API service account, create the RTDN Pub/Sub topic, register the **Play
  app-signing** certificate SHA-1 in Firebase, and — for production — 12
  testers opted in for 14 continuous days.
- **`AURAT-0027`** — the BFF half, with `AURAD-0010` as its spec: verify with
  `purchases.products.get`, credit from the server's own tier table, key
  idempotency on the `purchaseToken`, reject a token whose
  `obfuscatedExternalAccountId` does not match the caller, and handle RTDN
  refunds as negative ledger entries.

---

## Order of work, and where it can stop

1. Part 1 without Firebase → build gate.
2. Firebase re-registration (**asked**) → new `google-services.json`.
3. Part 2 without the contract cut.
4. Contract v0.7.0 + tag push (**asked**) → `package.json` bump.
5. `AURAS-0002` + `AURAT-0027` briefs.

Steps 1–2 stand alone and are worth having even if the rest is rejected. If
the contract push is refused at step 4, Part 2 lands with the redeem call
typed locally and a follow-up to migrate — worse, but not blocking.

## Risks

- **Nitro + New Architecture on RN 0.85** is the one genuinely new native
  surface. Mitigated by making a release AAB build the gate, not a smoke test.
- **The 31 Aug 2026 Billing-8 gate is two weeks away.** We land on 9.1.0, so
  it is a non-issue — but only if the library version does not get pinned
  backwards.
- **The rename breaks Firebase if step 2 is skipped.** Phone-OTP and FCM both
  fail silently on a device. The device pass after merge must include *signing
  in*, not only launching.

## Verification after merge (manor, device)

Play-independent: the app installs under the new package with the "Aura"
label; **phone-OTP sign-in works**; an FCM push still arrives and its tap still
deep-links; Top Up looks and behaves exactly as before (all three flags off);
a release AAB builds and is signed by the upload key.

## Next

`006-approval`.
