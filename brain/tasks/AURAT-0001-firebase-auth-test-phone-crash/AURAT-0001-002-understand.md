# AURAT-0001-002 — Understand

Date: 2026-06-16

## What the user reports
Test phone numbers are configured in Firebase Console (Auth → Sign-in method →
Phone → "Phone numbers for testing"). User enters such a number, taps **Send
code**. The app **closes / drops out without any visible error**.

A Firebase *test* number is special: it returns a `ConfirmationResult`
**without** sending a real SMS and **without** running device verification
(no APNs/reCAPTCHA). So a failure on a test number points away from
"SMS/quota/reCAPTCHA" and toward the **client code path that runs on success** —
i.e. what happens *after* `sendOTP` resolves.

## Leading hypotheses (ranked)
1. **Navigation target / render crash after success.** `handleSendCode` success
   → navigate to `VerifyOTP`; or a downstream render (e.g. reaching the null
   `MAIN` screen) throws. A JS render error in release can hard-exit with no
   visible message.
2. **Phone number format mismatch.** Country code is hardcoded `+34` in
   `use-phone-auth.ts`. If the test number was registered with a different
   country code/format, Firebase rejects it; need to confirm the rejection path
   actually surfaces (Alert) rather than throwing uncaught.
3. **Uncaught promise / unhandled error** in the send or navigation step causing
   a fatal JS exception (no error boundary in `AuthNavigator`).
4. **Native verification still invoked** despite test number (mis-registered
   number → real reCAPTCHA/APNs path) → silent native failure.

## Goal
Reproduce, capture the actual error (native + JS logs), identify the failing
line, fix it, and add a guard so this class of failure shows an error instead of
exiting silently.
