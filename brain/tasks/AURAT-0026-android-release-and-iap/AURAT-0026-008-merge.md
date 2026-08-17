# AURAT-0026 — 008 merge

Date: 2026-08-17

Merged on the owner's explicit in-turn approval ("Да, мёрж").

- Branch: `feature/AURAT-0026-android-release-and-iap`
- Commits: `4d932b7` (rename + release signing), `df6679a` (store top-up client)
- Merge commit on develop: **`6a9138b`**
- Pushed: `bf2411a..6a9138b develop -> develop`. `HEAD == origin/develop`.
- `wts-finish` refreshed slave-0 to the new master. slave-1 stays on the
  feature branch until the device pass.

## The merge needed a stash, and it was not routine

`wts-finish` aborted: the manor had **uncommitted local changes to
`src/shared/config/env.ts`**, the one file this branch also touched. Same class
of thing as `AURAT-0010`, but bigger — the manor's copy carries *two* local
edits, not one:

```
DEV_HOST_OVERRIDE = '192.168.31.55'   (LAN IP for physical-device runs)
BILLING_ENABLED   = true             (the flag ships false)
```

Stashed, merged, popped — and the pop **conflicted**, because both sides
changed the tail of the file (`STORE_BILLING_ENABLED` was appended right where
`BILLING_ENABLED` lives). Resolved by hand to keep all three facts: the manor's
LAN IP, the manor's `BILLING_ENABLED = true`, and the branch's new
`STORE_BILLING_ENABLED = false`. Verified by reading the three lines back, and
the stash was dropped only after that.

**Worth noticing for next time:** every task that appends to `env.ts` will hit
this, and the conflict is silent-ish — a careless `--theirs` would have shipped
`BILLING_ENABLED = false` into the manor and made the whole wallet UI vanish on
the next device run, which reads as a regression in *this* task. The local
edits stay uncommitted by design, so the file is a standing trap rather than a
one-off.

## Gates re-verified in manor after the merge

`npm install` (three dependency changes: `react-native-iap`,
`react-native-nitro-modules`, contracts → `#v0.7.0`), then tsc / eslint / jest
— **52 suites / 300 tests**, green.

The first `npm install` **failed** on a dropped SSH connection to GitHub while
cloning `@aura/contracts`, which left `node_modules` half-written and made all
52 suites fail. Recorded because the failure looks exactly like the branch
having broken everything, and it is not: a plain retry fixed it. Anyone seeing
52/52 red after this merge should re-run `npm install` before reading a single
stack trace.

`src/shared/config/env.ts` is the only dirty file in manor, as it always is.

## Not done in manor, deliberately

**`cd ios && pod install`.** `react-native-iap` autolinks on iOS too, so the
iOS `Podfile.lock` is now behind `package.json` and the next iOS build needs it.
It was skipped because a `pod install` on this machine also churns ~140 lines on
a CocoaPods 1.15.2 → 1.16.2 drift that belongs to no task (`AURAT-0025`
restored the lock by hand for exactly this reason). Left as the owner's step so
the churn is a deliberate commit, not a surprise inside this one.

## Device pass — open

The risky half is the rename, and the symptom is not what you would look at
first: the app **launches fine** under a broken Firebase registration and fails
only on identity. So:

1. App installs as **Aura** under `cc.silvermind.aura`.
2. **Phone-OTP sign-in works.** This is the real test of the Firebase
   re-registration and the debug SHA.
3. **A push arrives and its tap still deep-links** into the right thread —
   `google-services.json` changed, so the FCM sender identity did.
4. Top Up looks and behaves exactly as before (`STORE_BILLING_ENABLED` is off,
   so the Visa row and our own `$` prices, no Google Play row).
5. `./gradlew :app:bundleRelease` from a clean checkout **fails** without
   `android/keystore.properties`, with the message rather than a debug-signed
   AAB.

Not testable: any purchase. `AURAS-0002` is the gate, not the code.

## Next

`009-*` after the owner's verdict.
