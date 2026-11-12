# AURAT-0211-005 — Spec

Date: 2026-11-12 · Status: approved (шаг 006).
Тип: **задача** (фича `AURAF-0009`, решение `AURAD-0023` поправка 2026-11-11). Новой фичи нет.
Priority: P1 (за `billing_enabled` и `CARD_TOP_UP_ENABLED`). База: `AURAT-0207` (develop 06754f5).
Пара: веб `AURAT-0212` (`aura-web-manor`) — после этой задачи и контрактов `v0.33.0`.
Следующие версии спеки — `AURAT-0211-NNN-spec-vN.md` (`brain/NAMING.md`: в папке задачи только шаги).

---

## Что

Старт пополнения картой умеет создать **ту же** Checkout Session во встроенном виде
(`ui_mode: 'embedded_page'`) и отдать вебу то, чем её смонтировать: `client_secret` сессии и
публичный ключ. Зачисление (`settle` / `apply`), вебхук, сверка, статус, отмена, возвраты, диспуты,
REVIEW — без изменений. На время перехода работают оба режима: веб сам говорит, какой ему нужен.

## Решения (на одобрение)

| # | Вопрос | Предлагаю |
|---|---|---|
| 1 | Режим | **1Б** — оба. Запрос `ui: 'hosted' \| 'embedded'`, по умолчанию `hosted`: web-dev на `v0.32.0` работает как сейчас. Hosted убирается отдельной правкой после того, как `AURAT-0212` попадёт в `develop` (ID выдаёт `aura-app-manor`) |
| 2 | Публичный ключ | **2А** — BFF отдаёт его в ответе старта из `STRIPE_PUBLISHABLE_KEY`; веб новой переменной сборки не заводит |
| 3 | `client_secret` на повторе | **Не хранить.** Повтор открытой сессии и сейчас читает её у Stripe (`getCheckout`) — секрет берётся из того же ответа. В БД и логах секрета нет. Подтвердить на sandbox в маноре, что `retrieve` его отдаёт; если нет — колонка, отдельной правкой |
| 4 | Тот же `paymentId`, другой `ui` | **409** `card_top_up_payment_conflict`, как другая сумма: режим зафиксирован в строке до вызова Stripe (ключ идемпотентности требует тех же параметров) |
| 5 | `STRIPE_PUBLISHABLE_KEY` | **Обязателен с `CARD_TOP_UP_ENABLED`**, формат `pk_(test\|live)_…`, режим совпадает с секретным ключом (`pk_test_` ↔ `rk/sk_test_`), иначе BFF не стартует. **Следствие:** до деплоя на bff-dev владелец кладёт `pk_test_…` того же sandbox в Coolify |

## Как

### Контракты `@aura/contracts` `v0.33.0` (`src/card-top-up.ts`)

```ts
export const CardCheckoutUi = z.enum(['hosted', 'embedded']);

CardTopUpRequest = z.object({
  paymentId, amountMinor, returnPath,            // как в v0.32.0
  ui: CardCheckoutUi.default('hosted'),          // новое; без поля — hosted
});

CardTopUpResponse = z.discriminatedUnion('kind', [
  // Перейти по адресу: страница оплаты (hosted) или наша страница возврата
  // (оплачено и ждёт подтверждения — в любом режиме).
  z.object({ kind: z.literal('redirect'), redirectUrl: z.string().url() }),
  // Смонтировать встроенную форму.
  z.object({ kind: z.literal('embedded'), clientSecret: z.string().min(1), publicKey: z.string().min(1) }),
]);
```

- Совместимость: старый веб читает `redirectUrl`, лишнее `kind` zod-объект отбрасывает.
- Имена на проводе нейтральные (`clientSecret`, `publicKey`), провайдер в контракте не назван — как в `v0.32.0`.
- Код отказа 409 в JSDoc дополняется «другой режим».

### BFF

1. **Схема.** `stripe_top_ups.checkoutUi` — enum `StripeCheckoutUi { HOSTED EMBEDDED }`,
   `NOT NULL DEFAULT 'HOSTED'` (миграция; существующие строки — hosted).
2. **Порт** (`card-payments.port.ts`): `CheckoutRequest.ui: 'hosted' | 'embedded'`;
   `CheckoutSession.clientSecret: string | null`; `CardPayments.publicKey: string` — ключ знает
   только адаптер, `STRIPE_*` не выходит из модуля `stripe`.
3. **Адаптер** (`stripe-card-payments.ts`):
   - `embedded` → `ui_mode: 'embedded_page'`, `return_url: successUrl` (тот же
     `/checkout?payment=<id>`), `redirect_on_completion: 'if_required'`; `success_url` /
     `cancel_url` не передаются (Stripe их запрещает);
   - `hosted` → параметры **байт в байт как сейчас** (без `ui_mode`), чтобы повтор строки,
     начатой до деплоя, ушёл в Stripe с тем же телом под тем же ключом;
   - остальное общее: USD + Adaptive Pricing, 3DS `any`, `STRIPE_TERMS_CONSENT`, metadata,
     `expires_at`, `integration_identifier`, `locale`, `customer_email`;
   - `toSession` маппит `client_secret`.
4. **Сервис** (`card-top-up.service.ts` `start`):
   - новая строка пишет `checkoutUi` из запроса; повтор с другим `ui` → 409;
   - открытая сессия: hosted → `redirect(session.url)`, embedded → `embedded(clientSecret, publicKey)`;
   - REVIEW и «оплачено, ждём» → `redirect(successUrl)` в обоих режимах (как сейчас);
   - новая сессия без `url` (hosted) или без `clientSecret` (embedded) → 503, как сейчас без `url`.
   - `cancel` не меняется: `expire` работает для любой открытой сессии.
5. **Конфиг**: `STRIPE_PUBLISHABLE_KEY` (решение 5) в `env.schema.ts`, `stripe.module.ts`,
   `deploy/env/bff.env.example`; README — раздел про карты.
6. **OpenAPI** (`contracts/openapi.ts`): запрос с `ui`, ответ — `oneOf` двух видов; описание
   маршрута старта.

### Тесты (на моке Stripe, без БД)

- адаптер: параметры встроенной сессии; hosted без изменений (точное тело); `client_secret` в сессии;
- сервис: embedded-старт → `{ kind: 'embedded', clientSecret, publicKey }`; повтор открытой — тот же
  секрет из `getCheckout`; другой `ui` → 409; REVIEW / paid-pending в embedded → `redirect`;
  нет секрета → 503; hosted-путь — прежние ожидания с `kind: 'redirect'`; отмена встроенной;
- env: `STRIPE_PUBLISHABLE_KEY` обязателен с флагом, формат, несовпадение test/live.

## Порядок выпуска

1. Контракты `v0.33.0` — ветка в `aura-contracts`, сборка; BFF проверяется на локально
   скопированном `dist`. **Тег и push — только с «да» владельца.**
2. После тега — `npm install @aura/contracts@…#v0.33.0` в BFF, коммит в ветку задачи.
3. Merge в `develop` — с «да» владельца (`wts-finish`).
   **До этого** владелец кладёт `STRIPE_PUBLISHABLE_KEY=pk_test_…` (тот же sandbox, что и
   `rk_test_`) в Coolify bff-dev — иначе после выката bff-dev упадёт при старте, как было с
   `sk_test_` в `AURAT-0207`. Напоминание — в вопросе про merge.

## Не BFF, но нужно для встроенной формы (→ координатору / `AURAT-0212`)

- Payment method domain: `web-dev.aura-app.cc` в sandbox — **зарегистрирован** координатором
  2026-11-12 (`pmd_1Uaxr3PzZXCl9nsG4HT7Sl34`, кошельки `active`); `web.aura-app.cc` в live — с
  воротами live (live сам попадает в sandbox). Нужен для Apple Pay (обязательно), Google Pay, Link. Файл ассоциации Apple
  **не нужен** — merchant validation делает Stripe. Apple Pay в embedded — Safari / iOS 17+.
- Веб: Stripe.js только с `js.stripe.com`; CSP; `Permissions-Policy: payment=(self
  "https://js.stripe.com" "https://checkout.stripe.com")`; форма не во вложенном iframe.
- Веб в режиме `embedded` обязан понимать и `kind: 'redirect'` (оплачено и ждёт — на страницу возврата).

## Проверка в маноре (после merge, вместе с `AURAT-0212`)

bff-dev + sandbox: `4242…` с 3DS — оплата в шторке, без ухода с сайта; iDEAL (если включён) —
уход к банку и возврат на `/checkout`; закрыли шторку → `cancel` → сессия `expired`, ничего не
списано; повтор «Pay» тем же `paymentId` → та же форма (тот же `client_secret` из `retrieve`);
web-dev на `v0.32.0` до мёржа веба — hosted как раньше.

## Вне задачи

Веб (`AURAT-0212`); удаление hosted; сохранённые карты; своя форма на Payment Element.
