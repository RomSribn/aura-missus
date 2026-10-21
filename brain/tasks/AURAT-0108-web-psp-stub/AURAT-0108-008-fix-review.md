# AURAT-0108-008 — Fix: owner's review of `007`

Date: 2026-10-20
Slave: slave-1, branch `feature/AURAT-0108-web-psp-stub`. Not committed — staged for review.

## Owner's remarks («до коммита нужны правки»)

1. The fake reached a production build (`vite build` with the flag: `aura.fake-psp`, the sandbox
   strings and its chunk in `dist`) — the rule 9 exception holds only if it does not. Make the flag
   a build constant, gate the three entries, criterion: `grep -l 'aura.fake-psp\|Approve slowly'
   dist/assets/*` finds nothing.
2. Row 029 is taken (`AURAT-0114`), 030–035 too; this task's gaps start at 036. No BFF task for
   the test top-up («Не нужна»): success — tests and the local BFF stack; bff-dev — failure
   branches only. Remove the row, fix `006` item 1, Context — «сквозной успех — на локальном стеке
   BFF», the real PSP's gaps as rows from 036 at close.
3. Open redirect: `return=/%09/evil.com` passed `isSitePath`, the URL parser drops the tab →
   `//evil.com`. Resolve with `new URL(value, location.origin)`, same origin, `pathname + search +
   hash`; tests on `%09` and `%0A`.
4. Small: bfcache Back from the provider's page may leave the sheet `paying` → reset on
   `pageshow` with `persisted`; the lazy sandbox route needs `HydrateFallback`; `wait()` in
   `settle-top-up.ts` — the abort listener `{ once: true }`.
5. Tests: the raised timeouts — own commit; fix `advisors.test.tsx` "next 4 slots" here (pin the
   clock), own commit, so the full run before merge is green.
6. Manor check: success to Booked on the local BFF stack (`VITE_BFF_ORIGIN=http://localhost:3000`
   + `VITE_PSP_ENABLED=true`); on bff-dev — decline, cancel, failed 3-D Secure, `processing`.

The rest approved (one key per attempt surviving the hosted page; retry under the same key; "money
on the balance" only after the credit; flag off = `AURAT-0107`; the same keys in all 24 languages).

## Done

1. `PSP_ENABLED = import.meta.env.DEV && import.meta.env.VITE_PSP_ENABLED === 'true'` in
   `shared/config/env.ts` (`Env.pspEnabled` gone; the value is still validated); `payments.ts`
   re-exports it. Gated: the sandbox route, `createFakeProvider` (`useTopUpProvider` → null when
   off; `usePay` / `usePaymentReturn` handle it), the `TestWallet` render. Criterion ✓ — nothing
   found, no sandbox chunk; `npm run build` ✓.
2. `AURAF-0020`: the backlog table with row 029 removed; Context — only failure branches on
   bff-dev, end-to-end success on the local BFF stack. `006` item 1 — no BFF task. Rows from 036 —
   at close.
3. `sitePath` in `shared/config/routes.ts` — `new URL(value, window.location.origin)`; tests:
   `%09`, `%0A`, `%0D%0A` → null; `/check%09out?payment=p1%23x` → `/checkout?payment=p1#x`.
4. `usePay`: `pageshow` + `persisted` after leaving for the card → `idle`, the key kept (test in
   `psp.test.tsx`, fails without the fix); `HydrateFallback: () => null` on the sandbox route (no
   warning left); `{ once: true }`.
5. `advisors.test.tsx`: `vi.useFakeTimers({ toFake: ['Date'], shouldAdvanceTime: true })` at
   10:00 local, slots relative to it — green in four time zones.
6. `007` updated: criterion, manor check, open items.

Checks: lint ✓, typecheck ✓, build ✓, prettier ✓, `npm test` 942/942 three full runs.

## Commits (after the owner's OK)

aura-web, in order: (1) test timeouts (`vitest.setup.ts`, `vite.config.ts`); (2) the clock in
`advisors.test.tsx`; (3) `AURAT-0108` itself.

Second look (`aura-app-manor` HQ for the owner, 2026-10-20): fixes pass. Notes taken: `006` item 1
cites the spec's review, not `008`; the bfcache reset joins the real PSP's gaps (`007`); commit 1
carries only `configure` of `vitest.setup.ts` (the `checkout-page` namespace goes with commit 3),
each commit typechecks alone; `develop` (`AURAT-0110`, `d4e6772`) is merged into the branch in
the slot before `wts-finish`. (`VITE_PSP_ENABLED=yes` fails the app's start in `readEnv`, not the
build.)

Next: owner's confirmation → commits → `develop` into the branch, checks → merge (only on the
owner's confirmation).
