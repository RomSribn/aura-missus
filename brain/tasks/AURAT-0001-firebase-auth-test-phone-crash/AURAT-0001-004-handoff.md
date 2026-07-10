# AURAT-0001-004 — Handoff (resume here)

Date: 2026-06-16

Self-contained progress dump so a fresh session can continue without re-reading
the codebase. This is **not** the spec yet — spec (`005`) is blocked on the open
questions at the bottom.

## Task in one line
Firebase phone (OTP) auth: with a **Firebase Console test phone number**, after
tapping **Send code** the app **exits silently** — no Alert, no visible error,
no redbox reported. Find why and fix it. Merge to master is gated on approval.

## Environment (confirmed from code)
- React Native 0.85.3, iOS + Android, FSD layout, TypeScript.
- `@react-native-firebase/auth` v24.1.1.
- Firebase project `aura-2781b`, Android package `com.psychoapp`.
- Repo root: `project/manor/master/aura-app/`.

## Flow as implemented (file map)
1. `src/screens/phone-auth/ui/PhoneAuthScreen.tsx` — phone input + "Send code"
   button (`loading={isLoading}`, `disabled={!canSubmit}`).
2. `src/screens/phone-auth/model/use-phone-auth.ts` — `handleSendCode()`:
   - builds number with **hardcoded country code `+34`**,
   - `await authService.sendOTP(fullPhoneNumber)`,
   - on success → `navigation.navigate(SCREENS.VERIFY_OTP, { phone })`,
   - on error → `Alert.alert(...)`. No `.catch` around navigation.
3. `src/shared/api/firebase/auth.service.ts` — `sendOTP(phone)` →
   `auth().signInWithPhoneNumber(phone)`, stores `ConfirmationResult` as an
   **instance field** (`this.confirmationResult`); `verifyOTP(code)` →
   `confirmationResult.confirm(code)`; `resendOTP`; Firebase error-code mapping
   (~lines 100–144).
4. `src/screens/verify-otp/ui/VerifyOTPScreen.tsx` +
   `src/screens/verify-otp/model/use-verify-otp.ts` — auto-verify on 4 digits
   (~480ms debounce); success → `navigation.replace(SCREENS.MAIN)`.
5. Navigation:
   - `src/app/navigation/AuthNavigator.tsx` — stack `PhoneAuth` + `VerifyOTP`,
     **no error boundary / fallback screen**.
   - `src/app/navigation/RootNavigator.tsx:15` — **`const MainScreen = () => null;`**
     (placeholder — `MAIN` renders nothing).
   - `src/app/navigation/constants.ts` — `SCREENS.PHONE_AUTH='PhoneAuth'`,
     `VERIFY_OTP='VerifyOTP'`, `MAIN='Main'`.
- Native config: iOS `ios/GoogleService-Info.plist` + `FirebaseApp.configure()`
  in `ios/.../AppDelegate.swift`; Android `android/app/google-services.json`.
  iOS Podfile uses static frameworks (`$RNFirebaseAsStaticFramework = true`).

## Key insight (why this matters for diagnosis)
A Firebase **test** number returns a `ConfirmationResult` **without** sending a
real SMS and **without** native verification (no APNs / no reCAPTCHA). So a
failure on a *test* number is unlikely to be SMS/quota/reCAPTCHA — it points to
the **client code that runs on the success path**, i.e. after `sendOTP` resolves
(navigation + render of `VerifyOTP`, and ultimately the null `MAIN`).

## Hypotheses (ranked, with where to look)
1. **Render/navigation crash after success** — navigate to `VerifyOTP`, or later
   reaching `MAIN` (`() => null`) throws. In release a JS render error can
   hard-exit with no message. → `use-phone-auth.ts` success branch,
   `RootNavigator.tsx:15`, `AuthNavigator.tsx` (no boundary).
2. **Phone format mismatch** — hardcoded `+34` vs the number registered in
   Console. If rejected, confirm the rejection actually surfaces via `Alert`
   rather than throwing uncaught. → `use-phone-auth.ts`, `auth.service.ts`.
3. **Uncaught promise / fatal JS exception** in send or navigation (no boundary).
4. **Native verification still invoked** (mis-registered test number → real
   reCAPTCHA/APNs path) → silent native failure. → iOS APNs/Recaptcha absent;
   Android SHA-1 in Console unverified.

## What to do next (concrete)
1. **Reproduce with logs attached** (manor-only activity — live app):
   - iOS: `npx react-native log-ios` and/or Xcode console while repro.
   - Android: `npx react-native log-android` and/or `adb logcat | grep -i -E "firebase|fatal|exception|react"`.
   - Note: does it die *during send* or *after navigating* to `VerifyOTP`/`MAIN`?
   - Dev build first (look for a redbox); then release if only release crashes.
2. Pin the failing frame/line from the logs.
3. Likely quick wins to verify regardless:
   - Replace `MainScreen = () => null` with a real/placeholder component that
     renders something, to rule out the null-screen crash.
   - Wrap the auth stack in an error boundary so failures show instead of exiting.
   - Make `handleSendCode` surface navigation errors (catch around navigate).
   - Verify the test number is passed in exact registered E.164 format vs the
     hardcoded `+34`.
4. Write `AURAT-0001-005-spec.md` with the fix plan + acceptance, get approval
   (`...-approval.md`), then execute. **No merge to master without explicit
   in-the-moment approval (merge gate).**

## Open questions (BLOCKERS for spec — get from user)
- Platform exhibiting the crash: iOS, Android, or both?
- Build type: dev (redbox visible?) or release?
- Crash timing: during send, or after navigating to the OTP screen?
- Exact test number + format as registered in Console (vs hardcoded `+34`).
- Are Android SHA-1 and iOS APNs/reCAPTCHA actually configured in the Console?

## Pointers
- Ticket steps: `001-check`, `002-understand`, `003-context`, this `004-handoff`.
- Tracker line: `active-work.md` → "In progress" → AURAT-0001.
