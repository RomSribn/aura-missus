# AURAT-0094-005 — spec

Тип: task (исполнение `AURAF-0017`, строки 001, 002, 010 — BE). Новой фичи не
заводим. Status: **draft**, ждёт одобрения.

## 1. `@aura/contracts` v0.21.0 (клон вне маноров, `main`)

- `wallet.ts`: новая схема `FirstSessionOffer = { active: boolean; pct: int 1..100 }`
  (экспортируется), `WalletResponse.firstSessionOffer: FirstSessionOffer.optional()`.
  Комментарий: опционально ради выпущенных сборок и BFF до 0.21; отсутствие = оффера нет.
- `session.ts`: только описание `blocks[].creditMinor` → «скидка первой сессии,
  = subtotal − cost; 0, когда оффер не действует». Имя поля — прежнее.
- `package.json` → `0.21.0`, таблица модулей в README, `wallet.spec`/тест на новое поле
  (если в пакете есть тесты), `typecheck && build`.
- Релиз: merge в `main`, тег `v0.21.0`, push `main` + тег — **только после твоего
  отдельного «да»** (публичный репозиторий; приложение ждёт этот тег).

## 2. BFF

**Политика (`session-policy.ts`)** — единственное место арифметики:

```ts
export const FIRST_SESSION_DISCOUNT_PCT = 50;
// клиент платит floor(subtotal × 50/100); скидка — остальное (полцента — клиенту)
export function firstSessionDiscount(subtotalMinor: number): number
export function discountForBooking(subtotalMinor: number, eligible: boolean): number
export function costAfterDiscount(subtotalMinor: number, discountMinor: number): number
```

`FIRST_SESSION_CREDIT_MINOR` и `creditForBooking/costAfterCredit` уходят.

**Право на оффер — один предикат, три места.** Новый файл
`sessions/first-session-offer.query.ts`: Prisma-`where` «оффер израсходован»:

```
conversation.userId = U AND creditMinor > 0
AND NOT (status = CANCELLED AND refundedMinor = costMinor)   // field reference, без raw SQL
```

Используют: транзакция `book()` (под локами, как сейчас), `getPricing` (через
переименованный `hasUsedFirstSessionOffer`) и `GET /v1/wallet`.

**Бронь.** Сервис считает скидку политикой и передаёт в репозиторий готовое
`firstSessionDiscountMinor` (вместо `creditIfFirstMinor: 500`); репозиторий под
локами только решает «применить / нет» и пишет `creditMinor`/`costMinor` как
сейчас. Денежная арифметика уходит из data-слоя. Схема БД и миграции — без изменений.
Продление — без изменений (полная цена).

**Кошелёк.** `WalletsRepository.hasUsedFirstSessionOffer(userId)` (Prisma-реализация
берёт тот же `where`), `WalletService.getBalance` добавляет
`firstSessionOffer: { active, pct: FIRST_SESSION_DISCOUNT_PCT }` — всегда, пока
маршрут открыт (`BILLING_ENABLED`). Почему через репозиторий кошелька, а не через
`SessionsModule`: `SessionsModule` уже импортирует `WalletModule`, обратный импорт —
цикл модулей; прецедент обратного направления уже есть (репозиторий сессий пишет
ledger).

**Прочее.**
- OpenAPI: `firstSessionOffer` в `walletResponseOpenApi`, новое описание `creditMinor`.
- `@aura/contracts` → `#v0.21.0` (`npm install`, lock).
- README: pricing (скидка 50%, возвращается при отмене с полным возвратом), `GET /v1/wallet`.
- Деск («Trial» = `creditMinor > 0`), уведомления, Telegram — не трогаю.
- Тесты: переписать захардкоженные 500 (`session-policy`, `sessions.service`,
  `prisma-sessions.repository` spec), новые кейсы: округление на нечётном subtotal;
  оффер возвращается после полной отмены и **не** после поздней; кошелёк отдаёт
  `active: true/false`, `pct: 50`.

## Пограничный случай (к сведению)
Старые строки эпохи −$5, где кредит покрыл блок целиком (`costMinor = 0`) и сессию
отменили поздно: `refundedMinor = 0 = costMinor` → оффер вернётся. Человек ничего не
получил, так что это в духе решения; на новые брони не распространяется (50% всегда
оставляют ненулевую цену).

## Проверка
Слот: lint, typecheck, build, unit-тесты. Манор после мёржа: бронь первой сессии
(списано 50%), `GET /v1/wallet` до/после, отмена ≥24 ч → оффер снова `active`,
поздняя отмена → нет.

## Порядок
1. contracts (локально: build + подложить `dist` в `node_modules` BFF для проверки)
2. BFF-код и тесты → твой ревью в IDE
3. твоё «да» → push contracts `main` + `v0.21.0` → `npm install …#v0.21.0` в BFF
4. коммит BFF → merge gate (`wts-finish`) — отдельным вопросом.

## После
`AURAD-0009` помечается замещённым новым решением — ID минтится в `aura-app-manor`;
таблицу scope `AURAF-0017` (BE ✗→✓) правит владелец фичи там же, чтобы не
конфликтовать с его staged-версией.
