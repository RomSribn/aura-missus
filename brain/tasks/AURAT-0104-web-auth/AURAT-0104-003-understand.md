# AURAT-0104-003 — Understand

Date: 2026-10-20

A person signs in to aura-web with their phone number in the `auth` dialog — Firebase JS SDK,
the same Firebase project and uid as the mobile app, a 6-digit SMS code. A new person (no
`displayName` on `GET /v1/me`) is asked «Tell us who you are» and saves it with `PATCH /v1/me`
(or skips). Every guest-blocked action opens the sign-in and, after success, resumes with the
same data (the deep links of `AURAT-0103`); the top nav shows Log in / the avatar; signing in
or out drops the person-dependent API answers.

Next: context (004).
