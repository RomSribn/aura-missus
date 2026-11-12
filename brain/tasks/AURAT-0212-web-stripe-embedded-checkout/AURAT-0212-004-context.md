# AURAT-0212-004 — Context

Date: 2026-11-12

## Источники

- `AURAD-0023` (поправка 2026-11-11): Embedded Checkout (`ui_mode: 'embedded_page'`), та же Checkout
  Session; публичный ключ у веба не секретный; CSP пропускает Stripe.js; Apple Pay требует домена.
- BFF `AURAT-0211-005` (одобрена, `006`), `008`, `009` (`aura-bff-manor` slave-1): embedded —
  `return_url` = тот же `/checkout?payment=<id>`, `redirect_on_completion: 'if_required'`, `cancel` —
  `expire` любой открытой сессии; повтор открытой → тот же `client_secret` из `retrieve`; REVIEW и
  «оплачено, ждём» → `redirect` на страницу возврата в обоих режимах. Сессия живёт
  `CHECKOUT_TTL_MS = 60 мин`. Stripe API BFF — `2026-09-30.endive`.
- Контракты `v0.33.0` (тег `66a51e7` → `main` `3470114`, сверено `git ls-remote`): `CardCheckoutUi`,
  `CardTopUpRequest.ui` (default `hosted`), `CardTopUpResponse` — union по `kind`. JSDoc:
  `clientSecret` держать только в памяти — не в URL, storage, логах.
- `AURAT-0208` (develop `c7912bc`) — база.

## Код веба (develop `c7912bc`) — сверено

- Порт `features/pay/model/top-up-provider.ts`: `startCard → { redirectUrl } | null`, `status`,
  `cancel`. `useTopUpProvider`: `PSP_FAKE` → фейк, `PSP_ENABLED` → `card-provider`.
- `card-provider.ts` — старт без `ui`; 404 → `null` (карта выключена).
- `use-pay.ts:298` — `loadPage(page.redirectUrl)`; `savePending` до ухода; Back — `pageshow` /
  свежая загрузка → `/checkout?…&cancelled=1` (`finishOnCheckout`); `leftForCard`.
- `settle-top-up.ts` — опрос статуса 2 с / 60 с, `cancelled: true` — первый вопрос `cancel`.
- `use-payment-return.ts` + `pages/checkout` — возврат `/checkout?payment=`: остаётся для банков и
  `kind: 'redirect'`.
- `widgets/book-sheet` — `close()` закрывает только при `phase === 'idle'`; `Sheet` уже умеет `back`
  (кнопка перед заголовком); хост, который не закрыл шторку, получает её обратно (`AURAT-0138`).
- `shared/ui/sheet` — размеры `sm | md | lg`; на телефоне до 92% видимой высоты, полноэкранного
  варианта нет.
- `deploy/web/headers.conf` — CSP без Stripe, `Permissions-Policy` нет. `build.sh` подставляет
  BFF в `connect-src` и ищет маркер фейка; содержимое CSP не проверяет.
- `pay` `en.ts`: `topUp.note` = «Opens Stripe’s secure page — you may be charged in your local
  currency».

## Stripe — сверено по документации (MCP `search_stripe_documentation`, 2026-11-12)

- **CSP** (docs.stripe.com/security/guide):
  - Checkout: `connect-src`, `frame-src`, `script-src` — `https://checkout.stripe.com`; `img-src`
    — `https://*.stripe.com`;
  - Stripe.js: `connect-src` — `https://api.stripe.com` (+ `maps.googleapis.com` — только Address
    Element со своим ключом Google, нам не нужен); `frame-src` — `https://*.js.stripe.com`,
    `https://js.stripe.com`, `https://hooks.stripe.com` (3DS и редиректные методы); `script-src` —
    `https://*.js.stripe.com`, `https://js.stripe.com`;
  - Link: `frame-src`, `connect-src` — `https://link.com`, `https://*.link.com`; `img-src` —
    `https://*.link.com`.
  - Cross-origin isolation Stripe не поддерживает — у нас её нет.
- **Permissions-Policy** (docs.stripe.com/google-pay?platform=web): «Some web clients, including
  Chrome on Android, require that you include `self` in the payment allowlist. For example:
  `Permissions-Policy: payment=(self "https://js.stripe.com" "https://checkout.stripe.com")`» — для
  страниц с кнопкой Google Pay. Слова сессии BFF подтверждены.
- **Apple Pay** (docs.stripe.com/testing/wallets?ui=embedded-page): «Apple Pay requires Safari 17 or
  later because embedded checkout uses iframes with different domains». Домен регистрируется в
  каждом окружении отдельно; live-регистрация сама попадает в sandbox.
- **Вид формы**: Embedded page берёт Branding из Dashboard (цвета, шрифт, лого, форма кнопок);
  Appearance API — только у Checkout «embedded form» (Elements), не у нас. Кода веба это не
  касается.
- **Пакеты**: `@stripe/stripe-js` `10.2.0` (2026-10-26) — release train `endive`, совпадает с API
  BFF; `@stripe/react-stripe-js` `7.0.1` (2026-10-26), peer `react <20`, `stripe-js >=10 <11`.
  `EmbeddedCheckoutProvider` (`stripe` нельзя менять после первого рендера; `options.clientSecret`,
  `onComplete`), `EmbeddedCheckout`. `@stripe/stripe-js/pure` не вставляет скрипт при импорте —
  только при `loadStripe`, со `https://js.stripe.com/endive/stripe.js`.

## Противоречий нет

Шаг 001 и `AURAT-0211` сходятся. Уточнение к 001 п. 4: кроме `js.stripe.com` / `hooks.stripe.com` /
`api.stripe.com` нужны `checkout.stripe.com` (Checkout) и `*.js.stripe.com`.
