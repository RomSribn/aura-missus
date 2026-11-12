# AURAT-0212-017 — Находки BFF AURAT-0213 и черновик контрактов `v0.34.0`

Date: 2026-11-12. Источник: координатор, со слов BFF `AURAT-0213` (`aura-bff-manor` slave-2). Черновик
— до одобрения владельцем; веб пишет моки по нему.

## Контракт `v0.34.0` (черновик)

- `CardCheckoutUi = ['hosted', 'embedded', 'elements']`.
- Ответ для `elements` — тот же `{ kind: 'embedded', clientSecret, publicKey }`.
- **Новое: 429 `card_top_up_too_many_starts` + `Retry-After` (секунды).**
  - Лимит — 20 новых `paymentId` за 10 мин на аккаунт; повтор того же `paymentId` не считается.
  - `Retry-After` читается через CORS: на bff-dev `access-control-expose-headers: Date,
    Retry-After`.
- В sandbox проверено координатором (MCP): сессия `ui_mode: 'elements'` создаётся, `retrieve`
  отдаёт тот же `client_secret`.

## Что это значит для веба — в спеку v3

1. **429.**
   - Своя строка (24 языка), без автоповтора до `Retry-After`. Пока ждём, кнопки кошельков и шага
     оплаты неактивны.
   - Минуты считаются из `Retry-After`, как в промокодах (`AURAT-0145`).
   - Сейчас веб считал бы 429 `failed`.
2. **Debounce ≈300 мс** смены суммы перед новой сессией (решение 2А): перебор длительностей не
   съедает лимит.
3. **Adaptive Pricing на клиенте:** `adaptivePricing: { allowed: true }` в
   `CheckoutElementsProvider`, по умолчанию `false`. `CurrencySelectorElement` — над кнопками
   кошельков, как в макете.
4. **Email у кошельков.** В типах `@stripe/stripe-js` 10.2.0 у `ExpressCheckoutElement` в режиме
   Checkout (`StripeCheckoutExpressCheckoutElementOptions`) нет `emailRequired`. Есть только
   `buttonHeight`, `buttonTheme`, `buttonType`, `layout`, `paymentMethodOrder`, `paymentMethods`.
   Значит, email у кошелька Checkout запрашивает сам, по нуждам сессии. `confirm`-событие несёт
   `billingDetails`. Прямой фразы в документации нет — в проверку добавлено: оплата кошельком
   (Apple Pay, Google Pay, Link) аккаунтом без email. Если кошелёк не пройдёт, поле email ставится
   и перед кошельками.
5. **Terms (live).** Есть `createTermsElement()` и `session.canConfirm` («false while data … must
   collect is missing»). Как блокируется `confirm` кошелька, проверяется на sandbox со ссылкой на
   Terms перед live (уже в `016`).
6. В sandbox включены только `card` и `link`. iDEAL / Bancontact с экрана 4 макета появятся, когда
   владелец включит их (Settings → Payment methods).

Код по-прежнему ждёт «да» владельца на макет и решения 1–5 спеки `015`.
