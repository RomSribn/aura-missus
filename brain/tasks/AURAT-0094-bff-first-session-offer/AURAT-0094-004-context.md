# AURAT-0094-004 — context

Источники: `AURAF-0017` (app-манор, staged), `AURAT-0094-001`, код `aura-bff`
@ `a474b40`, `aura-contracts` @ `3ca54da` (v0.20.0).

## Как сейчас
- `session-policy.ts`: `FIRST_SESSION_CREDIT_MINOR = 500`, `creditForBooking()`
  (min(500, subtotal)), `costAfterCredit()`.
- Право на кредит — **две копии одного предиката** `creditMinor > 0`:
  `PrismaSessionsRepository.hasSpentFirstSessionCredit` (pricing),
  и ещё раз внутри транзакции `book()` (под локами кошелька).
  В транзакции же репозиторий сам считает `min(creditIfFirstMinor, subtotal)` и
  `cost` — денежная арифметика живёт в data-слое.
- `GET /v1/wallet` → `WalletService.getBalance` (модуль `wallet`). `SessionsModule`
  импортирует `WalletModule` — обратный импорт даст цикл модулей.
- Prisma 7: доступны field references (`tx.session.fields.costMinor`) — сравнение
  `refundedMinor = costMinor` выражается без сырого SQL.
- Отмена пишет `refundedMinor` (полная = `costMinor`, поздняя = `floor(cost/2)`).
- Деск: `trial = creditMinor > 0` — остаётся как есть.
- OpenAPI (`src/contracts/openapi.ts`): описание `creditMinor` «Flat first-session
  credit»; в `walletResponseOpenApi` нет оффера. README (pricing) говорит «flat credit,
  cancelled first booking does not hand it back».
- Тесты с 500: `session-policy.spec.ts`, `sessions.service.spec.ts`,
  `prisma-sessions.repository.spec.ts`.

## Контракты
- `WalletResponse` без оффера; `SessionPricing.blocks[].creditMinor` описан как
  «Flat first-session credit». Релиз = ветка → typecheck/build → `main` + тег
  `v0.21.0` → push (внешнее действие — с подтверждения владельца) → `npm install
  …#v0.21.0` в BFF (переписывает lock).

## Противоречий нет
Решение владельца 2026-10-17 замещает `AURAT-0023` («кредит при отмене не
возвращается»); `AURAD-0009` помечается замещённым — новое решение (ID) минтится
в app-маноре, не здесь.
