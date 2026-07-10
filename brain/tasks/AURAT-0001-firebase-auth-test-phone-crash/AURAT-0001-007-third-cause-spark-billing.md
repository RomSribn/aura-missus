# AURAT-0001-007 — Region verified fixed; third cause: Spark billing

Date: 2026-07-02

Continues from `006`. Context: workspace moved to a new MacBook (M2 Pro);
full env re-verified the same day — app builds & runs on iPhone 14 Pro Max
and Samsung Galaxy A50, Metro alive on both.

## Region policy — already fixed

`006` ended with "allow +34 in Console". Verified via Identity Toolkit
**Admin** API (gcloud OAuth, project `aura-2781b`):

```bash
curl -s -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "x-goog-user-project: aura-2781b" \
  "https://identitytoolkit.googleapis.com/admin/v2/projects/aura-2781b/config"
```

```json
"smsRegionConfig": { "allowlistOnly": { "allowedRegions": ["ES"] } }
```

Region gate is open. Test flow confirmed end-to-end on **both** platforms:
test number `+34 699 001 112` → OTP `111111` signs in.

## New symptom

Real `+34` number: no SMS arrives. Test number works. (No JS error captured —
RN 0.85 routes console.* to the new debugger, not Metro stdout.)

## Third cause (confirmed): project is on Spark

```bash
curl -s -H "Authorization: Bearer <token>" \
  "https://cloudbilling.googleapis.com/v1/projects/aura-2781b/billingInfo"
# → "billingEnabled": false
```

Since 2024 Firebase sends **real** phone-auth SMS only on the Blaze plan;
Console test numbers are exempt. This exactly matches the observed behaviour
and blocks real SMS on every platform regardless of client config.

## Also true (will bite right after Blaze)

- Debug builds set `appVerificationDisabledForTesting = true`
  (`__DEV__`-gated, `src/shared/api/firebase/auth.service.ts:22`). In this
  mode the backend accepts **only** test numbers — by design. A real-number
  test needs the flag off (or a Release build).
- Android app had **zero** SHA fingerprints in Firebase → Play Integrity
  verification would fail. **Fixed 2026-07-02**: registered debug.keystore
  SHA-1 `5e8f…f625` and SHA-256 `fac6…3b9c` for `com.psychoapp` via Firebase
  Management API (`androidApps/{app}/sha`). `google-services.json` unchanged
  (cert hashes surface there only with Google Sign-In OAuth clients; not
  needed for phone auth).
- iOS real-number verification without an APNs key falls back to reCAPTCHA
  via the `REVERSED_CLIENT_ID` URL scheme added in `005` — expected to work.

## Remaining to close AURAT-0001

1. User upgrades `aura-2781b` to Blaze (Console → Usage & billing).
2. One-off device test: dev flag off + real `+34` number on iPhone & Samsung.
3. Revert the flag, close the task.

## Pointers

- Prior steps: crash fix `005`, region policy `006`.
- Diagnostics worth reusing: Admin-API config GET (above) for the live SMS
  region policy; `cloudbilling …/billingInfo` for the plan; `006`'s
  `accounts:sendVerificationCode` probe for un-truncated backend errors.
- gcloud is now installed and authed on this machine (`roma.sribnyi@gmail.com`,
  default project `aura-2781b`).
