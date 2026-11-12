# AURAT-0213-005 — Spec

Date: 2026-11-12 · Status: done (принято 2026-11-13, шаг `011`).
Тип: **задача** (фича `AURAF-0009`, решение `AURAD-0023`, поправка 2026-11-12). Новой фичи нет.
Priority: P1 (за `billing_enabled` и `CARD_TOP_UP_ENABLED`). База: `AURAT-0211` (`develop` 6d9ce2b).
Пара: веб `AURAT-0212` v2 (`aura-web-manor` slave-1, спека — шаг `015`).
Следующие версии спеки — `AURAT-0213-NNN-spec-vN.md`.

---

## Что

Старт пополнения картой умеет третий режим — `ui: 'elements'`: **та же** Checkout Session с
`ui_mode: 'elements'`, из которой веб сам собирает шторку из Stripe Elements (кошельки, выбор валюты,
шаг карты). Зачисление, вебхук, сверка, статус, отмена, возвраты, диспуты, REVIEW — без изменений.
`hosted` и `embedded` уходят в Stripe **байт в байт как сейчас**. Плюс лимит частоты новых попыток
на аккаунт: веб будет создавать сессию заранее — при открытии шторки и при смене длительности.

## Решения (на одобрение)

| # | Вопрос | Предлагаю |
|---|---|---|
| 1 | Ответ для `elements` | **1А** — тот же `{ kind: 'embedded', clientSecret, publicKey }`. Форма ответа та же, контракт меняется меньше; веб знает, какой `ui` просил. Имя `kind` поправим, когда снимем `hosted` / `embedded` |
| 2 | Лимит частоты старта | **2А** — не больше **20 новых попыток за 10 минут** на аккаунт, сверх — **429** `card_top_up_too_many_starts` с `Retry-After` (секунды). Окно открывает первая попытка (как у промокодов). Считаются только **новые** `paymentId`; повтор того же `paymentId` (потерянный ответ, повторный маунт) не считается и лимитом не режется. Для всех трёх `ui`. Число — на твоё слово |
| 3 | Redis недоступен при проверке лимита | **Пропускать** с `warn` в логе: лимит — защита от злоупотребления, а не от двойного списания; деньги он не трогает, а падение Redis не должно закрывать оплату |

Почему 20 / 10 мин: открыл шторку (1) + несколько смен длительности (по 1) + переоткрытия — обычный
человек укладывается в 5–8. Stripe сам требует такой лимит для Elements («Limit repeated Session
creation… Idempotency alone isn't abuse prevention»). Перебор карт внутри одной сессии лимит не
закрывает — это Radar и 3DS `any`, как сейчас.

## Как

### Контракты `@aura/contracts` `v0.34.0` (`src/card-top-up.ts`)

```ts
export const CardCheckoutUi = z.enum(['hosted', 'embedded', 'elements']);
export const CARD_TOP_UP_TOO_MANY_STARTS = 'card_top_up_too_many_starts';
// CardTopUpRequest — без изменений (ui по умолчанию hosted).
// CardTopUpResponse — без изменений; kind 'embedded' — для ui 'embedded' и 'elements'.
```

JSDoc:
- `elements` — клиент рисует всё сам из Stripe Elements на `clientSecret` / `publicKey`:
  `ExpressCheckoutElement`, `PaymentElement`, **`CurrencySelectorElement` обязателен** (Adaptive
  Pricing; на клиенте — `adaptivePricing: { allowed: true }`), согласие с Terms — `TermsElement`,
  когда сессия его требует; email — свой (`ContactDetailsElement` / `confirm({ email })`), если у
  аккаунта его нет; `confirm({ redirect: 'if_required' })` — уход на `returnPath` только у банковских
  методов; закрыли — `cancel`;
- 409 — «другой `ui`» (уже есть), новый 429 — «слишком много новых попыток, `Retry-After`».

Совместимость: старые клиенты (`v0.33.0`) не шлют `elements`; 429 им приходит только сверх лимита.

### BFF

1. **Схема.** `enum StripeCheckoutUi` + `ELEMENTS` — миграция `ALTER TYPE … ADD VALUE 'ELEMENTS'`.
   Существующие строки не трогаются.
2. **Порт.** `CheckoutRequest.ui: 'hosted' | 'embedded' | 'elements'`; JSDoc `url` / `clientSecret`.
3. **Адаптер** (`returnParams`): `elements` → `ui_mode: 'elements'`, `return_url: successUrl` (тот же
   `/checkout?payment=<id>`), **без** `redirect_on_completion` (по справочнику он только для
   `embedded_page`; редирект решает клиент) и без `success_url` / `cancel_url`. Ветки `hosted` и
   `embedded` не меняются. Остальное тело общее: USD + `adaptive_pricing`, 3DS `any`,
   `STRIPE_TERMS_CONSENT`, metadata, `expires_at`, `integration_identifier`, `locale`, `customer_email`.
4. **Сервис** (`start`): маппинг `ui` ↔ состояние на три значения; `toShow`: `EMBEDDED` и `ELEMENTS` →
   `{ kind: 'embedded', … }`, нет секрета → 503 и `error` в логе, как сейчас. 409 на другой `ui` — как
   сейчас. Лимит (решение 2) проверяется **до** создания строки, только когда строки с этим
   `paymentId` ещё нет; при отказе ни строки, ни вызова Stripe.
5. **Лимит** — `CardTopUpStarts` в модуле `wallet` по образцу `PromoAttempts`: Redis, ключ — sha256
   от нашего user id (в Redis нет id людей), `SET NX EX` + `INCR` в `MULTI`, `Retry-After` из TTL,
   самолечение ключа без TTL. Константы — в правилах карты (`card-top-up-rules.ts`), не в env.
   Контроллер ставит `retry-after` и 429 с кодом из контрактов.
6. **OpenAPI** (`contracts/openapi.ts`): `ui` enum + `elements`, описание `kind: 'embedded'`, 429 в
   описании маршрута старта.
7. **README** — раздел карт: третий режим, лимит.

### Тесты (на моке Stripe и Redis, без БД)

- адаптер: точное тело `elements` (есть `ui_mode` и `return_url`, нет `redirect_on_completion`,
  `success_url`, `cancel_url`); тела `hosted` и `embedded` — прежние ожидания без изменений;
- сервис: `elements`-старт → `kind: 'embedded'` с секретом и ключом; повтор открытой — тот же секрет
  из `getCheckout`; другой `ui` → 409 (в обе стороны с `elements`); нет секрета → 503; REVIEW и
  «оплачено, ждём» в `elements` → `redirect` на страницу возврата;
- лимит: 20-я новая попытка проходит, 21-я → 429 с `Retry-After`, строка не создана, Stripe не
  вызван; повтор существующего `paymentId` сверх лимита проходит; Redis упал → пропуск с `warn`;
  ключ без TTL лечится.

## Порядок выпуска

1. Контракты `v0.34.0` — ветка в `aura-contracts`, сборка; BFF проверяется на локально собранном
   пакете. **Тег и push — только с «да» владельца.**
2. После тега — `npm install @aura/contracts@…#v0.34.0`, коммит в ветку задачи.
3. Merge в `develop` (`wts-finish slave-2`) — отдельное «да». Новых env нет.
4. Выкат на bff-dev, потом merge веба `AURAT-0212`.

## Проверка в маноре (после merge, вместе с `AURAT-0212`)

bff-dev + web-dev + sandbox:
- ~~`retrieve` сессии `elements` отдаёт `client_secret`~~ — подтверждено координатором в sandbox
  2026-11-12 (`cs_test_a0fgkDIA…`: тело `elements` без `redirect_on_completion` принято, `url: null`,
  `GET` отдаёт тот же `client_secret`); на bff-dev с `rk_test_` — заодно со стартом;
- кошелёк из шторки → Booked; карта `4242…`, `…3155` с 3DS, `…9995` — отказ на шаге карты;
- `test+location_NL@example.com` — евро в `CurrencySelectorElement`, зачисление в USD;
- смена длительности → новая сессия, старая `expired`; закрыли шторку → `cancel`;
- банк (если включён) — уход и возврат на `/checkout`;
- 21-я новая попытка за 10 минут → 429, веб показывает понятную ошибку и читает `Retry-After`
  (CORS отдаёт его через `exposedHeaders`, `src/common/web/web-origins.ts`; путь заголовка до браузера
  покрыт только юнит-тестом — замечание координатора).

## Перед live (в шаги выката, `AURAD-0023` ворота live)

Согласие с Terms в `elements` документацией Stripe не описано; в типах Stripe.js есть
`createTermsElement()` и `session.canConfirm`. **Проверить на sandbox со ссылкой на Terms в public
details и `STRIPE_TERMS_CONSENT=required`:** (1) `TermsElement` показывает галочку; (2) карта без
галочки не подтверждается; (3) Apple Pay / Google Pay / Link из `ExpressCheckoutElement` без галочки —
отказ или блок кнопок; (4) у оплаченной сессии `consent.terms_of_service = accepted`. Если кошелёк
проходит без согласия — решение до live (галочка над кнопками и блок кнопок до неё на вебе).

## Вне задачи

Веб (`AURAT-0212`); снятие `hosted` / `embedded` на BFF; смена суммы в той же сессии
(`runServerUpdate`); сохранённые карты.
