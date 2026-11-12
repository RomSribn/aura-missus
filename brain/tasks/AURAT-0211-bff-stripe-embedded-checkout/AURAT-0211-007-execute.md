# AURAT-0211-007 — Execute

Date: 2026-11-12 · Status: in-progress — ждёт ревью владельца (не закоммичено).

## Решение 3 подтверждено вживую

Координатор (sandbox через Stripe MCP, 2026-11-12) создал встроенную сессию с параметрами спеки
(`embedded_page`, `if_required`, `return_url`, Adaptive Pricing, 3DS `any`,
`integration_identifier`): Stripe принял, `url: null`; `client_secret` есть и в ответе создания,
и в `GET /v1/checkout/sessions/{id}` открытой сессии, значения совпадают. Запасной вариант
«колонка для секрета» не нужен; пункт проверки в маноре про `retrieve` — проверен.
Тестовая сессия `cs_test_a04T6m…` (`paymentId` `diag-aurat-0211-embedded`) истечёт сама; её
`checkout.session.expired` на bff-dev — без строки, BFF подтверждает получение.

## `@aura/contracts` `v0.33.0` — `/Volumes/Work/personal/ai-manors/aura-contracts`

Ветка `feature/v0.33.0-card-embedded-checkout` (от `main` 34f978b), **не закоммичено, тега нет**.
- `src/card-top-up.ts`: `CardCheckoutUi` (`hosted` | `embedded`); `CardTopUpRequest.ui`
  (`default('hosted')`); `CardTopUpResponse` — `discriminatedUnion('kind')`:
  `redirect { redirectUrl }` | `embedded { clientSecret, publicKey }`; JSDoc 409 — «другой `ui`».
- `package.json` 0.33.0; `README.md` — строка модуля и абзац `v0.33.0`.
- `typecheck` + `build` — ок. `dist` скопирован в `node_modules/@aura/contracts` слота для проверки.

## BFF — `slave-1/master`

- `prisma/schema.prisma` + миграция `20261112120000_stripe_embedded_checkout`: enum
  `StripeCheckoutUi { HOSTED EMBEDDED }`, `stripe_top_ups.checkoutUi NOT NULL DEFAULT 'HOSTED'`.
- `stripe/card-payments.port.ts`: `CheckoutRequest.ui`, `CheckoutSession.clientSecret`,
  `CardPayments.publicKey`.
- `stripe/stripe-card-payments.ts`: `returnParams` — embedded → `ui_mode: 'embedded_page'`,
  `return_url = successUrl`, `redirect_on_completion: 'if_required'`; hosted — тело как раньше
  (без `ui_mode`); `client_secret` → `clientSecret`; `publicKey` из конфига.
- `stripe/stripe.module.ts`: `publishableKey` из `STRIPE_PUBLISHABLE_KEY`.
- `wallet/card-top-up.service.ts`: `checkoutUi` в строке; другой `ui` → 409; `toShow` — открытая
  сессия → `redirect(url)` / `embedded(clientSecret, publicKey)`; REVIEW и paid-pending →
  `redirect(successUrl)` в обоих режимах; нет `url` / секрета у новой сессии → 503 и `error` в логе
  (без секрета).
- `wallet/card-top-ups.repository.ts`, `prisma-card-top-ups.repository.ts`: поле `checkoutUi`.
- `config/env.schema.ts`: `STRIPE_PUBLISHABLE_KEY` (`pk_(test|live)_…`), обязателен с флагом,
  режим test/live = режим секретного ключа.
- `contracts/card-top-up.ts`, `contracts/openapi.ts` (запрос с `ui`, ответ `oneOf` +
  `discriminator`), `wallet/card-top-up.controller.ts` (описания).
- `deploy/env/bff.env.example`, `README.md`.

## Тесты

- адаптер: параметры embedded; всё прочее совпадает с hosted; hosted без `ui_mode`;
  `client_secret` из create и retrieve; `publicKey`;
- сервис: `ui` по умолчанию hosted; embedded-старт → `{kind:'embedded'}`, секрета нет в строке;
  повтор — тот же секрет через `getCheckout`; 409 на смену режима в обе стороны; paid-pending и
  REVIEW → `redirect`; оплачено в форме → зачисление + 409; нет секрета → 503, повтор показывает;
  отмена встроенной;
- **секрет не в логах**: общий `afterEach` спеки сервиса проверяет, что ни одна строка лога ни в
  одном тесте не содержит `_secret_` (рядом с проверкой PII). Тело ответа HTTP-лог не пишет вовсе
  (`http-logger.options.ts`: от ответа — только статус, тело запроса/ответа не логируется).
- env: ключ обязателен, формат, несовпадение test/live (3 случая), тестовая пара на bff-dev.

Прогон: `tsc` ок, `eslint` (изменённые файлы) ок, `npm run build` ок, `prettier` — только
изменённые файлы, `jest` — 195 наборов / 3005 тестов зелёные.

## Открыто

- Тег `v0.33.0` + push `aura-contracts` — вопрос владельцу. После тега —
  `npm install @aura/contracts@github:RomSribn/aura-contracts#v0.33.0` (перепишет lock) и только
  потом коммит BFF.
- До merge: `STRIPE_PUBLISHABLE_KEY=pk_test_…` в Coolify bff-dev (владелец).
- `cancelUrl` у встроенной строки по-прежнему вычисляется и хранится (колонка NOT NULL), в Stripe
  не уходит.
