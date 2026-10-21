# AURAT-0108-009 — Merge

Date: 2026-10-21
Owner confirmed (AskUserQuestion: «Коммиты и merge»).

aura-web, branch `feature/AURAT-0108-web-psp-stub`:
- `27bbaae` Tests: longer async and per-test timeouts for the full run (only `configure` of
  `vitest.setup.ts` + `testTimeout`);
- `de9ea5d` Tests: pin the clock in the advisors suite;
- `edff725` AURAT-0108 itself.
Each typechecks alone (checked in a detached worktree; `27bbaae` still has the old time-of-day
failure, `de9ea5d` fixes it).

`develop` (`AURAT-0110`, `d4e6772`) merged into the branch in the slot — `a39ec3b`: conflict only in
the imports of `src/app/router/router.tsx` (both `SessionsPage` and `PSP_ENABLED`); `npm ci` for
`@aura/contracts` v0.23.0; Steiger — `shared/lib` over 15 modules with both tasks' helpers:
`downloadFile` and `loadPage` grouped under `shared/lib/browser/` (files unchanged, the test's
mock path follows). Then: lint ✓, typecheck ✓, prettier ✓, `npm test` 1112/1112 three full runs,
`npm run build` ✓, criterion (`VITE_PSP_ENABLED=true npx vite build`; `grep -l
'aura.fake-psp\|Approve slowly' dist/assets/*` — nothing, no sandbox chunk) ✓.

`wts-finish slave-1`: manor `develop` → `ca6bdca` (`Merge feature/AURAT-0108-web-psp-stub`),
pushed to origin. missus — nothing committed yet (one commit at close).

Next: owner's check in the manor per `007` — success to Booked on the local BFF stack
(`VITE_BFF_ORIGIN=http://localhost:3000` + `VITE_PSP_ENABLED=true`); on bff-dev — decline, cancel,
failed 3-D Secure, `processing`. Then approval, the real PSP's gaps as `AURAF-0020` rows from 036,
the missus commit, `wts-release` (on confirmation).
