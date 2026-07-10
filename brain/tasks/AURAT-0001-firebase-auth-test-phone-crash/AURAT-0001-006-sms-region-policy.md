# AURAT-0001-006 — Second root cause: SMS region policy

Date: 2026-06-18

Continues from `005`. After the native crash fix, "Send code" no longer exits
silently — it now surfaces a proper `Alert` and a JS error. That error revealed
a **second, server-side** cause, unrelated to the crash.

## Symptom (after the 005 fix)
On device, tapping Send code → Alert + console:

```
auth.service.ts  Error sending OTP:
  NativeFirebaseError: [auth/operation-not-allowed]
  This operation is not allowed. You must enable this service in the console.
```

This is the expected error-handling path working (good — no more silent exit).

## How the real cause was found
RNFirebase collapses the backend message to a generic `operation-not-allowed`.
Probed Identity Toolkit directly with the app's own API key + test number,
bypassing the whole native iOS layer:

```bash
curl -s -X POST \
  "https://identitytoolkit.googleapis.com/v1/accounts:sendVerificationCode?key=<API_KEY>" \
  -H "Content-Type: application/json" \
  -H "X-Ios-Bundle-Identifier: org.reactjs.native.example.PsychoApp" \
  -d '{"phoneNumber":"+34699001112"}'
```

Backend returned the **full** message:

```
HTTP 400
OPERATION_NOT_ALLOWED : SMS unable to be sent until this region enabled by the app developer.
```

## Root cause
Firebase Auth **SMS region policy**. The region of the phone number — Spain
(`+34`) — is not in the allowed list, so the request is rejected before any SMS
/ verification step. This applies to the region even for a Console *test*
number in this flow, which is why `+34699001112` is refused.

This is NOT: provider disabled, Identity Toolkit API disabled, API-key
restriction, APNs, or a stale/wrong client config — all of those were verified
correct (Console review of project `aura-2781b` + direct API probe + local
`GoogleService-Info.plist` API_KEY/PROJECT_ID match confirmed).

## Fix (Console-side; no code, no rebuild)
Firebase Console → Authentication → Settings → **SMS region policy** (project
`aura-2781b`):
- Add **Spain (+34)** to the allowlist (Allow policy), or switch to an
  allow-all policy for development.
- Save. Server-side — just retry Send code; re-probe with the curl above to
  confirm the error changes (region OK → next gate is reCAPTCHA-related; on
  device with `appVerificationDisabledForTesting` + test number it passes).

## Status
- Client crash fix: done & committed (`005`).
- Remaining blocker is entirely Console config (SMS region). Once the region is
  allowed, the test-number flow should complete end to end.

## Note on the earlier iOS hypotheses
APNs-key / Team ID / REVERSED_CLIENT_ID matter only for **real** (non-test)
iOS phone auth in production. They are not what blocks the current test flow —
the SMS region policy is. Track those separately if/when moving to production.

## Pointers
- Prior steps: `001`–`004`, root-cause/fix `005`.
- Diagnostic worth reusing: hit `accounts:sendVerificationCode` with curl to get
  the un-truncated backend error that RNFirebase hides behind `operation-not-allowed`.
