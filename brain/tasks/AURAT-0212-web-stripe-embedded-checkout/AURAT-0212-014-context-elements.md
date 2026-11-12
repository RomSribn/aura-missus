# AURAT-0212-014 — Context: Elements с Checkout Sessions

Date: 2026-11-12. Сверено по документации Stripe (MCP) и типам `@stripe/stripe-js` 10.2.0 /
`@stripe/react-stripe-js` 7.0.1, которые уже стоят в вебе.

## Stripe

- **Режим.** `ui_mode: 'elements'`: та же Checkout Session — `line_items`, Adaptive Pricing, 3DS,
  вебхук `checkout.session.completed`, `expire`. Клиент получает `client_secret` сессии и рисует
  элементы сам.
- **React** — `@stripe/react-stripe-js/checkout`:
  - `CheckoutElementsProvider` (`stripe`, `options: { clientSecret, elementsOptions: { appearance,
    fonts, loader }, adaptivePricing: { allowed } }`);
  - `useCheckoutElements()` — сессия и действия;
  - элементы `ExpressCheckoutElement`, `PaymentElement`, `CurrencySelectorElement`,
    `ContactDetailsElement`, `TermsElement`.
  Новых пакетов не нужно.
- **Оплата.** `confirm({ redirect: 'if_required', returnUrl?, expressCheckoutConfirmEvent?, email? })`
  → `{type:'success', session}` | `{type:'error', error}`. Карта и кошельки завершаются на месте;
  редиректный метод (банк) уходит на `return_url` сессии.
- **Вид.** Appearance API полностью: `theme`, `variables` (цвета, `fontFamily`, радиусы, отступы),
  `rules` (CSS по классам элементов) и `fonts` (`cssSrc` — наши Google Fonts). Шрифты и цвета — из
  наших токенов. У Embedded Checkout такого нет.
- **Кнопки кошельков** (`ExpressCheckoutElement`): Apple Pay / Google Pay / Link (и PayPal / Klarna,
  если включены). Нужна сессия, то есть `client_secret` заранее. Тема и раскладка кнопок
  настраиваются. Нужен зарегистрированный домен — web-dev уже зарегистрирован.
- **Adaptive Pricing в Elements.** Нужен `adaptivePricing.allowed: true` на клиенте и
  **обязательный** `CurrencySelectorElement` («You must render the Currency Selector Element» —
  требование Stripe, в том числе юридическое).
  - Ставится над кнопками кошелька и рядом с суммой.
  - Суммы в локальной валюте показываются из `session.total` (уже отформатированы Stripe); в API
    сессия остаётся в USD.
- **Сумма сессии.** Есть `runServerUpdate`: сервер меняет `line_items` сессии с `permissions:
  { update_line_items: 'server_only' }`, а клиент перечитывает сессию, не перемонтируя элементы.
  Иначе — новая сессия на каждую новую сумму.
- **Email.** Checkout Session требует email. Сейчас BFF передаёт `customer_email` только если он
  есть у аккаунта (`user.email`), а вход у нас по телефону. Для карты без email нужен
  `ContactDetailsElement` или `confirm({ email })`. Кошелёк email отдаёт сам.
- **Terms.** В live — `consent_collection.terms_of_service: 'required'` (`AURAD-0023`). В Elements
  согласие показывает `TermsElement`. В sandbox `STRIPE_TERMS_CONSENT=none` — не показывается.

## Код

- BFF (`6d9ce2b`): `ui` — только `hosted | embedded`. Сессия: `adaptive_pricing: { enabled: true }`,
  `customer_email` по наличию, `consent_collection` по флагу, `expires_at` 60 мин. Для Elements BFF
  нужно новое значение `ui` и `ui_mode: 'elements'` с `return_url`, а для смены суммы на той же
  сессии — маршрут обновления.
- Веб (develop `0e7b88d`):
  - `useCardForm` (Embedded) становится основой: жизнь формы, закрытие в фоне, истечение, исходы в
    `finish`;
  - порт `TopUpProvider` и `settleTopUp` (опрос статуса и бронь тем же ключом) остаются;
  - `pending-store` и путь 041 остаются, но запись пишется в момент `confirm`, а не при старте
    сессии: иначе каждое открытие шторки считалось бы платежом.

## Чего не делаем

- Payment Intents — нет: Adaptive Pricing только у Checkout Sessions.
- «Embedded form» (`CheckoutFormProvider`) — это та же готовая форма без `rules`.
