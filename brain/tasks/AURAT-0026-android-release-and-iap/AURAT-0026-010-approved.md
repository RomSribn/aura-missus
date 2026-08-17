# AURAT-0026 — 010 approved

Date: 2026-08-18
Status: **done — owner-approved**

Owner ran the device pass on SM-A505FN and reported: **"смс приходит, пуш тоже"**.

That is the acceptance that mattered. The rename's failure mode is quiet — the
app launches perfectly well under a broken Firebase registration and fails only
on identity — so phone-OTP arriving is the real proof that creating the new
Android app for `cc.silvermind.aura`, registering the debug SHA-1/SHA-256 and
regenerating `google-services.json` all landed correctly. Push arriving proves
the FCM sender identity survived the same change.

Per-item results beyond those two are not on the record; the owner reported the
pass as a whole.

## Verified here rather than assumed

- App installs and runs as `cc.silvermind.aura/.MainActivity`, versionName
  `1.0.0`, launcher label **Aura**; JS boots on Fabric with no `FATAL` and no
  red screen (`009`).
- **The signing guard actually refuses.** `keystore.properties` was moved aside
  and `:app:bundleRelease` run: it fails with
  `Release signing is not configured: android/keystore.properties is missing…`
  and produces no AAB. This was the one claim in `007` that was configuration
  rather than evidence — the whole point of the change is that a missing
  keystore never silently yields a debug-signed build, and now that is tested,
  not asserted. The file was restored and diffed against a copy to confirm it
  came back byte-identical.
- `com.android.vending.BILLING` in the merged release manifest, and
  `openiap-google:3.3.1 → com.android.billingclient:billing:9.1.0` on the
  release classpath (`007`).

## Not tested, and cannot be

Any purchase. Play only transacts for an app the device received from Play,
signed by the right key, for a licensed tester. `STORE_BILLING_ENABLED` ships
`false` and the rail additionally needs a `purchaseAccountId` the BFF does not
serve yet, so the store code is unreachable by construction. `AURAS-0002` is the
gate; `AURAT-0027` is the server half, started 2026-08-17 in `aura-bff-manor`
slave-1.

## Carried forward, not minted

- **`pod install` is still owed** on the iOS side: `react-native-iap` autolinks
  there too, so `ios/Podfile.lock` is behind `package.json`. Deliberately left
  out of this task because a real `pod install` on this machine also churns
  ~140 lines on a CocoaPods 1.15.2 → 1.16.2 drift belonging to no task
  (`AURAT-0025` restored the lock by hand for that reason). Whoever next builds
  iOS takes it as its own commit.
- **The release gate should include `assembleDebug`** for any task touching
  native dependencies — the reasoning and the two failures that taught it are in
  `009`.
- **`npm ci` in a built tree needs three cleanups, not one** (`node_modules`,
  `android/.gradle`, the watchman watch). Also `009`.
- Google's own **app-signing certificate** cannot reach Firebase until the first
  Play upload; until then phone-OTP works on sideloaded builds and would fail on
  Play-installed ones (`AURAS-0002` step 4).
- `AURAF-0009`'s card rail is probably not permitted as the Android top-up rail
  (`AURAD-0010`). The feature's premise narrows; no task minted.

## Docs status

`AURAD-0010` accepted. `AURAF-0010` stays **in-progress** — its rows 001–005 are
app-done and BFF-pending, row 006 is `AURAT-0027`, row 007 is the owner's
runbook, row 008 (iOS) has no task.

Missus was committed twice for this task rather than once: `529ab06` mid-task,
with the owner's approval, because `AURAT-0027` starts in the other manor and
needed `AURAD-0010` in the shared brain rather than a retelling of it. This file
and `009` are the second.
