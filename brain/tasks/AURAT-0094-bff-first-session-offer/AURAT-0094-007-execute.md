# AURAT-0094-007 — execute

Дата: 2026-10-17. Слот `slave-1`.

## aura-contracts (ветка `feature/AURAT-0094-first-session-offer`, не закоммичено)
- `src/wallet.ts`: `FirstSessionOffer { active: boolean; pct: int 1..100 }`,
  `WalletResponse.firstSessionOffer?`.
- `src/session.ts`: описание `creditMinor` → «скидка первой сессии = subtotal − cost».
- `package.json` 0.21.0, README (таблица модулей + абзац v0.21.0).
- `typecheck` + `build` — ок. `dist` подложен в `node_modules` BFF для проверки.

## aura-bff
- `session-policy.ts`: `FIRST_SESSION_DISCOUNT_PCT = 50`, `firstSessionDiscount`
  (клиент платит floor), `discountForBooking`, `costAfterDiscount`; плоские 500 удалены.
- новый `sessions/first-session-offer.query.ts` — единый предикат «оффер использован»
  (`creditMinor > 0` и НЕ `CANCELLED ∧ refundedMinor = costMinor`, field reference).
- `PrismaSessionsRepository`: `hasUsedFirstSessionOffer` (было
  `hasSpentFirstSessionCredit`), транзакция `book()` берёт тот же предикат и готовую
  цену `firstSessionPrice {creditMinor, costMinor}` от сервиса — арифметики в
  data-слое больше нет.
- `SessionsService`: pricing и book считают через политику.
- `WalletsRepository.hasUsedFirstSessionOffer` (тот же предикат),
  `WalletService.getBalance` → `firstSessionOffer: { active, pct: 50 }`.
- OpenAPI: `firstSessionOffer` в кошельке, новое описание `creditMinor`.
- README: pricing / wallet / деск — формулировки «discount» вместо «flat credit».
- Комментарии деска («Trial») — только слово; поведение не тронуто.
- Тесты: policy (50%, округление 1101 → 550), service pricing (500/1000/1500),
  предикат, бронь в репозитории (оффер есть / нет), кошелёк (active true/false).

Проверки: `tsc`, `eslint`, `nest build`, `jest` — 119 suites / 1505 tests ok.
Новые/изменённые файлы прогнаны prettier (кроме `openapi.ts` и
`prisma-wallets.repository.ts` — они были неотформатированы до задачи, целиком не
переформатировал).

## Открыто
- `package.json` BFF всё ещё `#v0.20.0`: переход на `#v0.21.0` (+ lock) — после
  push тега contracts (нужно твоё «да»). До этого BFF собирается только с
  подложенным `dist`.
- Слот не прогонял `npm ci` в preflight — сделал руками (`npm ci` + `prisma generate`).
