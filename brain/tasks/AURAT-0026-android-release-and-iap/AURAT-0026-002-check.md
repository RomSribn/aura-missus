# AURAT-0026 — 002 check

Date: 2026-08-17

## Brain

Grepped the whole brain for `keystore | applicationId | package name | Play
Console | Play Store | IAP | in-app purchase | StoreKit | Google Play Billing`.
**Exactly one hit outside this folder**, and it is not about either subject:

- `AURAT-0001-007-third-cause-spark-billing.md` — matches on "keystore" because
  it records registering the **debug** keystore SHA-1/SHA-256 for
  `com.psychoapp` via the Firebase Management API.

So there is **no prior art at all** for release packaging, signing, store
listing, or in-app purchases. This is a fresh subject in this project.

What exists and is adjacent:

| Artifact | Bearing on this task |
|---|---|
| `AURAD-0002` | Wallet is the only money source; append-only ledger; running block non-refundable. Binding. |
| `AURAD-0009` | A session is a scheduled slot, still paid from the wallet. Binding. |
| `AURAF-0009` — *Real payments (PSP)*, status **backlog, not started** | The **card** rail. Its open questions (which provider, EUR/USD, chatter payouts) are card questions and do not transfer to a store-billing rail. |
| `AURAT-0007` | `POST /v1/wallet/top-ups` shipped as a **stub that 503s in production**. The endpoint the store rail has to replace or wrap. |
| `AURAT-0019` | The wallet is a shared store; the server's post-move balance is published straight into it. Any credit path must land there the same way. |
| `AURAT-0001` (esp. `-007`) | Firebase project `aura-2781b`, **Spark** plan, SMS region allowlist `[ES]`, debug SHA-1/SHA-256 registered for `com.psychoapp`. gcloud authed as `roma.sribnyi@gmail.com`, Management API usable from this machine. |
| `AURAT-0006` | FCM push; device registry keyed by token, not package — but the FCM sender identity comes from `google-services.json`. |

## Repo (ground truth, read this branch)

- `android/app/build.gradle`: `namespace "com.psychoapp"`,
  `applicationId "com.psychoapp"`, `versionCode 1`, `versionName "1.0"`.
  **`buildTypes.release.signingConfig = signingConfigs.debug`** — the template
  default, with the template's own warning comment still in place. There is no
  release keystore anywhere in the repo, and no `bundleRelease` has ever been
  produced.
- `android/app/src/main/java/com/psychoapp/{MainActivity,MainApplication}.kt` —
  package directory to move.
- `android/app/google-services.json` — keyed `"package_name": "com.psychoapp"`,
  project `aura-2781b`.
- `android/settings.gradle`: `rootProject.name = 'PsychoApp'`.
- `app.json`: `{"name": "PsychoApp", "displayName": "PsychoApp"}` — the launcher
  label comes from `@string/app_name`, not this, but the RN CLI reads it.
- `package.json`: `"name": "PsychoApp"`, `"version": "0.0.1"`.
- iOS: `PRODUCT_BUNDLE_IDENTIFIER = org.reactjs.native.example.PsychoApp`,
  `PRODUCT_NAME = PsychoApp`, and the whole `ios/PsychoApp*` tree.
- No `react-native-iap`, no `react-native-nitro-modules`, no billing code of
  any kind in `package.json` or `src/`.
- `minifyEnabled` is **off** for release (`enableProguardInReleaseBuilds =
  false`), so ProGuard/R8 keep-rules are not currently a concern.

## Live Firebase (read via Management API, this machine, just now)

```
androidApps: 1:1022442840784:android:ebe0e4b242a2e759d734d5  com.psychoapp
             sha1   5e8f16062ea3cd2c4a0d547876baa6f38cabf625
             sha256 fac61745dc0903786fb9ede62a962b399f7348f0bb6f899b8332667591033b9c
iosApps:     1:1022442840784:ios:d75cb17b01adfc8ed734d5      org.reactjs.native.example.PsychoApp
```

That matters for the plan: **the Firebase half of the rename does not need the
owner to click through the console.** A new Android app under the new package
can be created, its SHA fingerprints registered, and its `google-services.json`
fetched, with the credentials already on this machine — same path `AURAT-0001`
used. (Doing it is still a write to an external service, so it gets asked for.)

## Next

`003-understand`.
