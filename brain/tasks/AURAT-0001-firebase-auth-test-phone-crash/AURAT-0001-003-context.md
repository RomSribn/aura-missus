# AURAT-0001-003 — Context

Date: 2026-06-16

## Touched areas (with refs)
- `src/screens/phone-auth/model/use-phone-auth.ts` — `handleSendCode()`; country
  code hardcoded `+34`; success → `navigation.navigate(VERIFY_OTP)`, error →
  `Alert.alert`. Navigation/promise error handling to review.
- `src/shared/api/firebase/auth.service.ts` — `sendOTP` /
  `signInWithPhoneNumber`, `ConfirmationResult` stored as instance field;
  error-code mapping (~lines 100–144).
- `src/screens/verify-otp/model/use-verify-otp.ts` — success →
  `navigation.replace(SCREENS.MAIN)`.
- `src/app/navigation/RootNavigator.tsx:15` — `MainScreen = () => null`
  (placeholder; possible crash sink).
- `src/app/navigation/AuthNavigator.tsx` — stack; **no error boundary**.
- Native: `ios/.../AppDelegate.swift` (`FirebaseApp.configure()`), iOS APNs /
  RecaptchaVerifier absent; Android `google-services.json`, SHA-1 unverified.

## Constraints
- Manor is štab — **no feature dev, no merge without in-the-moment approval**
  (merge gate). Investigation/fix lives under this task; merge to master gated.
- Need real device/emulator logs to diagnose a silent exit: `npx react-native
  log-ios` / `log-android`, Xcode console, `adb logcat`. Running the live app is
  a manor-only activity.
- Test numbers must be entered in the **exact** registered E.164 format; the
  hardcoded `+34` prefix interacts with this.

## Unknowns (to resolve before spec)
- Which platform exhibits the crash — iOS, Android, or both?
- Does the exit happen *during* send, or *after* navigating to `VerifyOTP`/`MAIN`?
- Is there a JS redbox in dev, or only a silent exit in release?
- Exact test number + format used vs. what is registered in Console.
- Are SHA-1 (Android) and APNs/reCAPTCHA (iOS) actually required here, or does the
  test-number path bypass them?

## Next step
Reproduce with logs attached to pin the failing frame, then write `004-spec`.
Need user input on the unknowns above (platform, dev vs release, exact number).
