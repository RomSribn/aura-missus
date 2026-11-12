# AURAT-0213-004 — Context

Date: 2026-11-12

## Код (ground truth, `develop` 6d9ce2b)

- `src/modules/stripe/stripe-card-payments.ts` — `returnParams(request)`: `embedded` →
  `ui_mode: 'embedded_page'`, `return_url`, `redirect_on_completion: 'if_required'`; `hosted` — без
  `ui_mode`, `success_url` / `cancel_url` (тело как до AURAT-0211, ради повторов под тем же ключом).
  Остальное тело общее. `toSession` маппит `client_secret`.
- `card-payments.port.ts` — `CheckoutRequest.ui: 'hosted' | 'embedded'`, `CardPayments.publicKey`.
- `card-top-up.service.ts` — `toCheckoutUi`, 409 на другой `ui`, `toShow` (EMBEDDED →
  `{ kind: 'embedded', clientSecret, publicKey }`), `logNothingToShow`, `createCheckout(... ui ...)`.
- `card-top-ups.repository.ts` — `CardCheckoutUiState = 'HOSTED' | 'EMBEDDED'`; Prisma enum
  `StripeCheckoutUi { HOSTED EMBEDDED }`, миграция `20261112120000_stripe_embedded_checkout`.
- `contracts/openapi.ts` — `ui` enum и `oneOf` ответа; `contracts/card-top-up.ts` — реэкспорт.
- Фейк Stripe для тестов — `card-fakes.spec-fixtures.ts` (`request.ui === 'embedded'`).
- Лимиты: глобальный `@fastify/rate-limit` 120/мин на IP (in-memory). Образец лимита на
  пользователя — `promo-codes/promo-attempts.ts`: счётчик в Redis по sha256 от user id,
  `SET NX EX` + `INCR` в `MULTI`, 429 с `Retry-After`, код отказа в контрактах
  (`promo_code_too_many_attempts`). `RedisModule` глобальный.
- Контракты: `/Volumes/Work/personal/ai-manors/aura-contracts`, `main` 3470114 = `v0.33.0`, чисто.

## Stripe (SDK 23.0.1, API `2026-09-30.endive`, документация)

- `ui_mode: 'elements'` есть в типах. `return_url` — «required if `ui_mode` is `embedded_page` or
  `elements` and redirect-based payment methods are enabled»; `success_url` / `cancel_url` — «not
  allowed if ui_mode is `embedded_page` or `elements`»; `redirect_on_completion` — «applies to
  `ui_mode: embedded_page`». **Для `elements` его не передаём**: редирект решает клиент
  (`confirm({ redirect: 'if_required' })` — «will only redirect if your user chooses a redirect-based
  payment method»).
- `client_secret` — «Applies to … `embedded_page` or `elements`»; в `elements` им инициализируется
  `initCheckoutElementsSdk`. Отдаёт ли его `retrieve` для `elements` — в доках прямо не сказано
  (для `embedded` проверено в sandbox, `AURAT-0212` 17000a8) → проверка в маноре.
- Нельзя в `elements`: `custom_text`, `custom_fields`, `submit_type`, `branding_settings`,
  `after_expiration` и др. — мы их не шлём.
- Stripe прямо требует для эндпоинта создания сессии в Elements: «Limit repeated Session creation:
  Apply server-side limits using relevant account or user signals… Idempotency alone isn't abuse
  prevention» — довод за решение 2А.
- **Email:** «You must provide a valid customer email when completing a Checkout Session» (Elements).
  У нас `customer_email` — только если email есть в профиле (вход по телефону) → без него веб
  собирает email сам (`ContactDetailsElement` или `confirm({ email })`). Веб это уже заложил
  (`AURAT-0212-015`, решение 4).
- **Adaptive Pricing на клиенте:** `initCheckoutElementsSdk({ adaptivePricing: { allowed: true } })`
  (по умолчанию `false`) и `CurrencySelectorElement` обязателен («You must render the Currency
  Selector Element in your use of Adaptive Pricing with Elements»). Серверная часть та же
  (`adaptive_pricing.enabled`).
- **Terms в live:** `consent_collection.terms_of_service: 'required'` — «requires customers to check a
  terms of service checkbox before being able to pay. There must be a valid terms of service URL set
  in your Dashboard settings». Для `elements` документация **не описывает**, как собирается согласие.
  В типах `@stripe/stripe-js` 10.2.0 (веб) есть `checkout.createTermsElement()` /
  `getTermsElement()` и `session.canConfirm` («false while data that Checkout or mounted Elements
  must collect is missing»). Блокирует ли отсутствие галочки `confirm` кошелька
  (`expressCheckoutConfirmEvent`) — не описано. → Проверка перед live на sandbox со ссылкой на Terms
  (в sandbox сейчас её нет, `STRIPE_TERMS_CONSENT=none`).

## Веб (`AURAT-0212-015`, advisory)

Ждёт: `CardCheckoutUi` + `'elements'`, ответ `{ kind: 'embedded', clientSecret, publicKey }`,
`return_url` `/checkout?payment=<id>`, остальное тело как сейчас; новая сессия на смену суммы,
старая — `cancel` в фоне; «BFF стоит проверить лимит частоты старта».

## Противоречий нет

Шаг `001` и веб сходятся. Уточнение к `001` п.1: `redirect_on_completion` для `elements`
действительно не задаётся — подтверждено типами SDK и справочником API.
