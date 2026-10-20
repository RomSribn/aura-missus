# AURAT-0101-009 — Execute (fix from 008)

Date: 2026-10-20
Changes staged, **not committed**.

## Done

- `.env.development` committed (`.gitignore` exception): `VITE_BFF_ORIGIN=https://bff-dev.aura-app.cc`,
  `VITE_BFF_WS_PATH=/ws`, `VITE_FIREBASE_AUTH_DOMAIN`, `VITE_FIREBASE_PROJECT_ID` (`aura-2781b`),
  `VITE_PSP_ENABLED=false`. `npm run dev` needs no `.env.local`.
- `shared/config/env.ts`: `VITE_FIREBASE_API_KEY` / `VITE_FIREBASE_APP_ID` optional (blank = unset),
  both-or-neither; `env.firebase` is `null` without them. Origin, WS path, auth domain, project id and the
  PSP flag are still validated strictly.
- `shared/api/firebase.ts`: with `env.firebase === null` the SDK is never initialised — `useAuthStatus()`
  is `guest` from the first render, `getIdToken()` → `null`, `signOut()` no-op.
- `.env.example`, README «Setup» rewritten accordingly.
- Tests: env (Web App on / off / half-set, committed `.env.development` parses with sign-in off),
  `firebase.test.ts` (guest-only mode, SDK not initialised).

## Checks

lint (eslint + steiger) ✓ · typecheck ✓ · test — 11 files, 73 tests ✓ · build ✓ · prettier ✓.

## Note

`.env.development` is read only in development mode. A production build (`npm run build` /
`npm run preview`) reads none of it — its values come from `.env.local` or the deploy (separate task).

Next: owner review in IDE → commit → merge gate.
