# AURAT-0212-021 — Fix: ревью кода v2 (координатор)

Date: 2026-11-12

Координатор проверил проиндексированный код Elements. Владелец, дословно (в `aura-app-manor`):
«передай, остальное по рекомендации». Делать замечания 1–6, включая рекомендации 4 и 5.

Прогон координатора:
- lint чисто;
- typecheck — одна ошибка (`'elements'` нет в `v0.33.0`);
- vitest — 31 падение в `psp.test.tsx` (`ZodError`, та же причина);
- `profile.test.tsx` нестабилен, вне задачи.
- Sandbox: у `web-dev.aura-app.cc` `apple_pay`, `google_pay`, `link` — active.

**Тег `@aura/contracts` `v0.34.0` на origin** (`54d8c66` → `016b5b0`): `'elements'` в
`CardCheckoutUi`, `CARD_TOP_UP_TOO_MANY_STARTS` (429). Подъём — отдельным коммитом (правило 6).

Замечания:

1. **Тупик, если Stripe не загрузился.**
   - `useCheckoutElements()` с `type: 'error'` → статус `failed` (`error.failed`, новая сессия по
     нажатию).
   - `ExpressCheckoutElement` `onLoadError` → `walletsKnown(false)`.
   - Тест на каждый случай.
2. **Снять `export` без потребителей:** `CardCheckoutStatus`, `CardCheckoutEvents`, `CardCheckout`,
   `StripeCheckoutBridge`, `CardPage`, `CardStart`, `stripeLocale`.
3. **Имена:** `{ provider: asked, balance: wallet, events: told }`, `{ provider: start, language:
   lang }` → исходные имена.
4. **Разбить `use-card-checkout.ts`** (394 строки) на `use-card-session.ts` (сумма → сессия:
   debounce, старт, 429 и повтор, истечение, Stripe.js, закрытие, reset) и `use-card-checkout.ts`
   (композиция, `confirm` / `settle`, шаг). Обработку ответа старта — в именованные функции.
5. **FSD.** `stripe-appearance` читает DOM. Чистое преобразование — в `lib/` (на вход функция
   чтения токена, юнит-тест). Вызов — в чанке элементов; `appearance` из `CardCheckoutView` убрать.
6. **Мелочи:**
   - ранние выходы `confirm` вызывают `onRefused`;
   - опции `ExpressCheckoutElement` — константа модуля без `undefined`;
   - `48px` в `card.module.css` — один источник с `WALLET_BUTTON_HEIGHT`.

В проверку в маноре: сохраняется ли на шаге оплаты валюта, выбранная в шторке. У шагов разные
`CheckoutElementsProvider` на одном `clientSecret`.
