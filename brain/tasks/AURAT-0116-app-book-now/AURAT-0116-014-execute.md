# AURAT-0116-014 — Execute (fix 013)

Date: 2026-10-22

- `screens/booking/model/use-book-review.ts` — `onTopUp`: `MAIN › PROFILE ›
  { screen: PROFILE_ROOT, params: { sheet: 'topup' } }` (как Quick book и тред); `as never`
  убран — форма параметров теперь проверяется типами.
- `screens/booking/model/__tests__/use-book-review.test.tsx` — тест «Top Up lands on Profile
  with the sheet open».

Проверки: `tsc`, `npm run lint` — чисто; `jest` — 128 suites / 950 tests passed.

Дальше: ревью владельца → коммит в ветку → merge (с подтверждения) → новая staging-сборка на
устройство.
