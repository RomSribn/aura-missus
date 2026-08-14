# AURAT-0020-003 — Approved

Date: 2026-08-14
Status: **done — owner-approved after a device pass**

## What the owner verified

On the physical iPhone: chat thread → block sheet → **"Top up"** now lands on a
live Profile with its Top Up sheet open. The screen responds, and the app no
longer has to be restarted to recover.

## Shipped

Merged into develop (`057bac2`, code `a706886`, user-approved merge gate) and
pushed; brain pushed (`6b9a7a9`). Gates green in slave-0 and re-verified in
manor: tsc / eslint / jest, **42 suites / 199 tests** (was 41 / 193), plus a
release bundle.

`BottomSheet` now reports when it is *gone* rather than when it was asked to go,
and `goTopUp` waits for that before navigating. Since `goTopUp` was the only
cross-screen navigation out of a sheet, the whole class is closed.

## Left on the record

- **The Android path is unverified.** RN implements `Modal.onDismiss` for iOS
  only, so Android takes the other branch — the slide-out ending is its signal.
  That branch has never run on a device; Android also has no presentation to
  deadlock, which is why it was safe to treat differently, but "safe by
  reasoning" is not "seen working". First thing to check whenever Android is
  next built.
- The other four `BottomSheet` consumers (Language, Edit profile, Top Up, the
  card-of-the-day sheet) share the changed component. Their ordinary closes were
  not each individually re-run; the shared contract is covered by
  `BottomSheet.test.tsx`.

## Related

Found during the `AURAT-0019` device pass; both were pre-existing from
`AURAT-0010`, and neither was caused by `AURAT-0015`.

slave-0 released.
