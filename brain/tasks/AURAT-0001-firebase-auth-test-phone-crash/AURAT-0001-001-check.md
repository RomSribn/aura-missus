# AURAT-0001-001 — Check

Date: 2026-06-16

Bug ticket. Firebase **phone (OTP) authentication** already implemented in
`master/aura-app`. Using Firebase Console **test phone numbers**, after pressing
"Send code" the app **exits silently — no error, no Alert, no crash log shown to
the user.**

Already in place:
- `@react-native-firebase/auth` v24.1.1, RN 0.85.3, iOS + Android. FSD layout.
- Service `src/shared/api/firebase/auth.service.ts` — `sendOTP` →
  `auth().signInWithPhoneNumber(phone)`, stores `ConfirmationResult`; `verifyOTP`,
  `resendOTP`; Firebase error-code mapping.
- Screen `src/screens/phone-auth/` (`PhoneAuthScreen.tsx` + `model/use-phone-auth.ts`).
  `handleSendCode()` calls `sendOTP`, on success navigates to `VERIFY_OTP`, on
  error shows `Alert.alert`.
- Screen `src/screens/verify-otp/` — on success `navigation.replace(SCREENS.MAIN)`.
- Firebase config present: iOS `GoogleService-Info.plist` + `FirebaseApp.configure()`
  in `AppDelegate.swift`; Android `google-services.json` (project `aura-2781b`,
  package `com.psychoapp`).

Not in place / suspicious (to confirm in 003):
- `SCREENS.MAIN` is a placeholder — `const MainScreen = () => null;`
  (`src/app/navigation/RootNavigator.tsx:15`).
- iOS: no APNs and no RecaptchaVerifier wired → reCAPTCHA fallback has no UI host.
- Android: SHA-1 fingerprint registration in Firebase Console unverified.

Scope: find why the app dies on "Send code" with test numbers and fix it.
No merge to master without explicit approval.
