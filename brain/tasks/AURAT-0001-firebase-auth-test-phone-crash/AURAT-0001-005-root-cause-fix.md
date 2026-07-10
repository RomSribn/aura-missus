# AURAT-0001-005 — Root cause & fix

Date: 2026-06-18

Resolves the silent exit from `004-handoff`. Root cause confirmed from a real
on-device crash log; fix applied directly (executed, not spec-first — user
approved skipping `005-spec`).

## Root cause (confirmed, not hypothesised)

The handoff's ranked hypotheses (render crash / null MAIN / format mismatch)
were all wrong. Captured the actual native crash by relaunching the app on the
physical device with a console attached:

```
xcrun devicectl device process launch --console --terminate-existing \
  --device <UDID> org.reactjs.native.example.PsychoApp
```

Crash:

```
-[RNFBAuthModule signInWithPhoneNumber] instance: __FIRAPP_DEFAULT
FirebaseAuth/PhoneAuthProvider.swift:109: Fatal error: Unexpectedly found nil
  while implicitly unwrapping an Optional value
App terminated due to signal 5.
```

`FirebaseAuth.PhoneAuthProvider.verifyPhoneNumber` runs an **unconditional**
guard at the very top:

```swift
guard AuthWebUtils.isCallbackSchemeRegistered(
        forCustomURLScheme: callbackScheme,
        urlTypes: auth.mainBundleUrlTypes) else { fatalError(...) }
```

`ios/PsychoApp/Info.plist` had **no `CFBundleURLTypes` entry at all**, so
`auth.mainBundleUrlTypes` is `nil` and the implicit unwrap kills the app the
instant `signInWithPhoneNumber` is called. There is no JS error and no `Alert`
because it is a native `fatalError`, not a JS exception — hence "exits silently".

Key point: this guard runs **before** `appVerificationDisabledForTesting` can
take effect, which is why the test-number/test-flag path could never be reached.

Why `callbackScheme` exists but URL types don't: `GoogleService-Info.plist` for
this project has **no `CLIENT_ID` / `REVERSED_CLIENT_ID`** (no OAuth client), so
the SDK falls back to `app-<dashed GOOGLE_APP_ID>`. That scheme must still be
registered in Info.plist.

- `GOOGLE_APP_ID` = `1:1022442840784:ios:d75cb17b01adfc8ed734d5`
- required scheme = `app-1-1022442840784-ios-d75cb17b01adfc8ed734d5`

## Fix (applied to working tree in manor; not committed/merged — merge gate)

1. **`ios/PsychoApp/Info.plist`** — added `CFBundleURLTypes` with the Firebase
   callback scheme `app-1-1022442840784-ios-d75cb17b01adfc8ed734d5`. This is the
   actual crash fix. (`plutil -lint` OK.) **Native change → requires rebuild.**
2. **`src/shared/api/firebase/auth.service.ts`** — set
   `auth().settings.appVerificationDisabledForTesting = true` under `__DEV__`
   before `signInWithPhoneNumber`, so the registered Console test number resolves
   without real APNs/reCAPTCHA. Dev-only; never in release.
3. **`src/screens/verify-otp/model/use-verify-otp.ts` +
   `ui/OTPCodeField.tsx`** — OTP length 4 → 6 (`OTP_LENGTH` const + `cellCount`
   default 6). Console test codes are 6 digits (`111111`); the 4-digit field
   could never accept them.
4. **`src/app/navigation/RootNavigator.tsx`** — replaced
   `const MainScreen = () => null` with a visible placeholder so a successful
   login is not a blank screen mistaken for a crash.

Items 3–4 are correctness follow-ons surfaced during diagnosis, not the crash
cause.

## Expected flow after fix
`699001112` → Send code (no crash) → enter `111111` → auto-verify → "Signed in ✓".

## Status / next
- Native rebuild (`npx react-native run-ios`) required for the Info.plist change.
- Verify on device with test number, then commit and request merge approval
  (merge gate — no push to `origin master` without explicit in-the-moment OK).

## Pointers
- Prior steps: `001-check`, `002-understand`, `003-context`, `004-handoff`.
- Diagnosis method worth reusing: `devicectl ... process launch --console` to
  capture native (non-JS) RN crashes from a physical iOS device.
