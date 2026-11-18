# AURAT-0218-001 — Initial: продавец, ссылки на правила и согласие с Terms в шторке оплаты веба

Date: 2026-11-17
Выдана в `aura-app-manor` slave-0 из `AURAT-0209` (`AURAT-0209-008`, владелец: «Отдельная задача
веба»). Исполняется в `aura-web-manor` (и BFF, если согласие пишется на сервере).

## Зачем

- В `ui_mode: 'elements'` Stripe не показывает policies и контакты из Checkout Settings («add any
  additional fields, text, or policies directly to your page» —
  https://docs.stripe.com/payments/checkout/custom-components?ui=elements).
- Terms Element для аккаунта закрыт («without being gated», `AURAD-0023`, 2026-11-13), а согласие с
  Terms в live обязательно — это ворота live `AURAD-0023`.

## Что нужно

- В шторке оплаты, до кнопки оплаты и кошельков: продавец «Silvermind OÜ, Estonia», ссылки на Terms,
  Privacy и Terms §07 (`https://aura-app.cc/terms/#s07`).
- Своё согласие с Terms для всей сессии, включая Apple Pay / Google Pay / Link; запись согласия
  (версия, время) — решить в спеке; связь с `STRIPE_TERMS_CONSENT` / `consent_collection`.
- 24 языка, `@sensitive`.
- Согласовать с `AURAT-0216` (признание при брони) — не дублировать тексты.

## Срок

До live оплаты на вебе.
