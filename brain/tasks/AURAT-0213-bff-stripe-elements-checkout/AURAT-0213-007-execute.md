# AURAT-0213-007 — Execute

Date: 2026-11-12

## Контракты (`aura-contracts`, ветка `feature/v0.34.0-card-elements-checkout`, не закоммичено)

- `src/card-top-up.ts`: `CardCheckoutUi` + `'elements'` с JSDoc. В нём: клиент рисует шторку сам,
  `CurrencySelectorElement` обязателен и конвертацию надо разрешить при инициализации, `TermsElement`
  ставится, когда сессия требует согласия, email собирается при его отсутствии, редирект — только
  у банков, при смене суммы — новая попытка и `cancel` старой. `kind: 'embedded'` — для `embedded` и
  `elements`. Новый код `CARD_TOP_UP_TOO_MANY_STARTS` (429 + `Retry-After`).
- `README.md` — заметка `v0.34.0`, строка таблицы. `package.json` — `0.34.0`.
- Сборка (`tsup`) и `tsc` ок; `dist` положен в `node_modules/@aura/contracts` слота для проверки.
  `package.json` BFF пока ссылается на `#v0.33.0`. После тега его надо перевести на `#v0.34.0`.

## BFF (`aura-bff`, ветка задачи, не закоммичено)

- `prisma/schema.prisma` + миграция `20261112200000_stripe_elements_checkout`:
  `ALTER TYPE "StripeCheckoutUi" ADD VALUE 'ELEMENTS'`.
- `stripe/card-payments.port.ts` — `ui` на три значения, JSDoc.
- `stripe/stripe-card-payments.ts` — `returnParams` через `switch`: `elements` →
  `{ ui_mode: 'elements', return_url }`. Ветки `hosted` и `embedded` не тронуты.
- `wallet/card-top-up-starts.ts` (новый) — счётчик новых попыток на аккаунт. Сделан по образцу
  `PromoAttempts`: Redis, ключ — sha256 от user id, `MULTI` с `SET NX EX`, `INCR` и `TTL`, ключ без
  TTL лечится. Если Redis не ответил, попытка проходит, в лог пишется `warn` без id.
- `wallet/card-top-up-rules.ts` — `CARD_TOP_UP_STARTS_PER_WINDOW = 20`,
  `CARD_TOP_UP_STARTS_WINDOW_SECONDS = 600`.
- `wallet/card-top-up.service.ts`:
  - маппинг `ui` ↔ состояние таблицами на три значения;
  - `toShow`: всё, что не `HOSTED`, отвечает `kind: 'embedded'`;
  - лимит проверяется только для нового `paymentId`, до строки и до Stripe. Сверх лимита —
    `CardTopUpStartsExhausted(retryAfterSeconds)`.
- `wallet/card-top-up.controller.ts` — 429 `card_top_up_too_many_starts` + `retry-after`, как у
  промокодов; Swagger `ApiTooManyRequestsResponse`.
- `wallet/card-top-ups.repository.ts` (тип), `wallet.module.ts` (провайдер), `contracts/card-top-up.ts`
  (реэкспорт кода), `contracts/openapi.ts` (`ui` enum, описания), `README.md` (раздел карт).

## Тесты (моки Stripe и Redis, без БД)

- адаптер: точные ключи возврата `elements`; `hosted` и `embedded` — прежние ключи; остальное тело
  совпадает с hosted; секрет без страницы;
- сервис (`elements`): старт → `kind: 'embedded'`, повтор → тот же секрет, 409 в четыре стороны,
  complete/unpaid и REVIEW → `redirect`, нет секрета → 503, `cancel`;
- сервис (лимит): считаются новые попытки во всех `ui`, повтор не считается и проходит сверх
  лимита, сверх лимита — ни строки, ни Stripe, 400 — до счётчика;
- `card-top-up-starts.spec.ts`: 20 проходят, 21-я ждёт окно, окно не сдвигается, аккаунты
  раздельно, в ключе нет id, лечение TTL, Redis упал → пропуск с `warn`;
- `card-top-up.controller.spec.ts`: 429 + `retry-after`, прочее — как есть.

## Не трогал

`AURAD-0023` / `AURAF-0009`: строка `AURAT-0213` и поправка есть в коммите координатора d4f40fe,
придут с его push. Иначе были бы две правки одних и тех же строк.

## Проверки

`tsc --noEmit` ок, `eslint` (wallet, stripe, contracts) чисто, `prettier` по своим файлам; `jest` —
197 наборов / 3031 тест зелёные (на локальной сборке контрактов `v0.34.0`); `nest build` ок.

Дальше: ревью владельца в IDE → «да» на тег `v0.34.0` → BFF на тег, коммит → «да» на merge.
