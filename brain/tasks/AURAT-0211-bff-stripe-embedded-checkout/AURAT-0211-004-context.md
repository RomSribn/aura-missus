# AURAT-0211-004 — Context

Date: 2026-11-12

## Источники

- `AURAD-0023` + поправка 2026-11-11 (с диска `aura-app-manor`, коммит d384377) — high.
- `AURAT-0207` 001–013 (hosted Checkout, решения владельца, ключ `rk_test_` и его права) — high.
- Код `develop` 06754f5 — ground truth. Факты шага 001 (ветка 0207) перепроверены, номера строк
  совпадают.
- Stripe SDK `stripe@23.0.1`, `apiVersion: '2026-09-30.endive'` (`.d.ts`) и документация Stripe
  (через Stripe MCP).

## Что в коде сейчас

- `src/modules/stripe/stripe-card-payments.ts:111` `createCheckout` — `success_url` / `cancel_url`,
  `ui_mode` не задан (= `hosted_page`). Порт `card-payments.port.ts`: `CheckoutRequest` с
  `successUrl` / `cancelUrl`, `CheckoutSession.url`.
- `src/modules/wallet/card-top-up.service.ts` `start` — ответ `{ redirectUrl }` в четырёх местах:
  открытая сессия (`session.url`), REVIEW и «оплачено, ждём» (`topUp.successUrl` — наша страница
  возврата), новая сессия. Повтор открытой сессии уже читает её у Stripe (`getCheckout`).
- Строка `stripe_top_ups` фиксирует все параметры сессии до первого вызова Stripe (ключ
  идемпотентности `checkout:<paymentId>` требует тех же параметров). Колонки режима нет.
- `cancel` → `expireCheckout` → `apply`: от `ui_mode` не зависит.
- Конфиг: `CARD_TOP_UP_ENABLED` + `STRIPE_SECRET_KEY` / `WEBHOOK_SECRET` / `TOP_UP_PRODUCT_ID`
  обязательны с флагом; `STRIPE_TERMS_CONSENT`. Публичного ключа нет. Пример — `deploy/env/bff.env.example`.
- Контракты: `@aura/contracts` `v0.32.0`, `CardTopUpRequest { paymentId, amountMinor, returnPath }`,
  `CardTopUpResponse { redirectUrl }`. Клон пакета — `/Volumes/Work/personal/ai-manors/aura-contracts`
  (`main`, чистый, последний тег v0.32.0).

## Stripe (сверено)

- `2026-09-30.endive`: `ui_mode: 'hosted_page' | 'embedded_page' | 'elements' | 'form'`;
  `redirect_on_completion: 'always' | 'if_required' | 'never'` (только для `embedded_page`,
  по умолчанию `always`); `return_url` обязателен для `embedded_page`, если в сессии есть методы с
  уходом к банку; `success_url` / `cancel_url` для `embedded_page` запрещены.
- `client_secret` — поле объекта сессии (для `embedded_page` — для Stripe.js). Повторный маунт
  открытой сессии тем же секретом — штатный путь Stripe («open → remount»). Что `retrieve` его
  возвращает — по типам SDK да (поле объекта Session); подтвердить вживую в маноре.
- Adaptive Pricing, `consent_collection`, 3DS, `integration_identifier`, `expire` — работают и со
  встроенной формой.
- **Домены.** Apple Pay во встроенной форме требует зарегистрированный Payment method domain
  (Dashboard или API `payment_method_domains`), отдельно в live и в каждом sandbox; регистрация в
  live сама попадает в sandbox. Файл ассоциации Apple **не нужен**: merchant validation Stripe
  делает сам. Регистрация нужна и для Google Pay, Link, PayPal, Klarna. Apple Pay во встроенной
  форме — только Safari / iOS 17+.
- Для веба (не BFF): Stripe.js грузить только с `js.stripe.com`; CSP; заголовок
  `Permissions-Policy: payment=(self "https://js.stripe.com" "https://checkout.stripe.com")`
  нужен Chrome на Android для Google Pay; не класть форму в ещё один iframe.
- Права restricted-ключа не меняются: создание встроенной сессии — те же Checkout Sessions Write.

## Противоречия

Нет. Поправка `AURAD-0023` уже признаёт, что «без файлов на нашем домене» верно только для hosted;
по документации файла не нужно и для embedded — нужна только регистрация домена в Stripe.

## Обновление (2026-11-12)

Координатор свёл брейн `aura-app-manor` с origin: `aura-missus` origin/master = `860e152`. Missus
манора и ветка задачи переведены на него (fast-forward). Теперь в общем брейне лежат:
`AURAD-0023` с поправкой (совпадает с диском), `AURAI-0013`, строки `AURAF-0009`, шаг 001 этой
задачи (совпадает с копией, которую клали с диска) и `AURAT-0212`. Форма ответа в `AURAT-0212`
совпадает со спекой 005.
