# AURAT-0212-022 — Execute: правки ревью v2 (`021`)

Date: 2026-11-12

0. **Контракты.** `@aura/contracts` `v0.33.0` → `v0.34.0` — отдельным коммитом `79f3b16` (правило 6).
   Дальше всё гонялось на настоящем пакете; временная правка `node_modules` больше не нужна.
1. **Тупик при сбое Stripe.**
   - `useStripeCheckout`: `useCheckoutElements()` с `type: 'error'` → `card.failed()` → сессия
     закрыта, статус `failed` («That didn’t go through», «Pay $X» открывает новую).
   - `ExpressCheckoutElement` `onLoadError` → `walletsKnown(false)`: строки кошельков нет, «Pay
     {{сумма}}» доступна.
   - Два теста.
2. **`export` сняты:** `CardCheckoutStatus` / `CardCheckoutEvents` / `CardCheckout` (ушли вместе с
   разбором), `StripeCheckoutBridge`, `CardPage`, `CardStart`, `stripeLocale`.
3. **Имена.** `const { provider, balance, events } = latest.current`; в старте — `{ provider }`.
4. **Разбор.**
   - `model/use-card-session.ts` (298 строк) — сумма → сессия: debounce, старт, именованные
     обработчики ответа (`onAnswer` → `onTooMany` / `onPage` / `onSession`, `onExpired`, `fail`),
     429 и один повтор, истечение, Stripe.js, закрытие, `release` после оплаты, `reset`.
   - `model/use-card-checkout.ts` (252) — композиция, шаг, кошельки, ошибка, `confirm` / `settle`.
   - Шаг и кошельки сбрасываются на каждую новую сессию. Шаг оплаты есть только при `ready`.
5. **FSD.**
   - `lib/stripe-appearance.ts` — чистое `stripeAppearance(token)` + юнит-тест (2).
   - Чтение токена — `model/page-token.ts` (DOM).
   - Вызов — в чанке элементов (`Session`, раз на сессию). `appearance` из `CardCheckoutView`
     убран.
6. **Мелочи.**
   - Ранние выходы `confirm` (нет сессии, уже платится, страница фейка, `begin()` → null)
     вызывают `onRefused`.
   - `WALLET_OPTIONS` — константа модуля без `undefined`: `paymentMethodOrder: ['applePay',
     'googlePay', 'link']`, `paymentMethods: {}`.
   - Высота кошельков — один источник: `WALLET_BUTTON_HEIGHT` → `WALLET_ROW_VARS`
     (`--wallet-h`) → `card.module.css`.

Прогон:
- `lint`, `typecheck` — чисто;
- `npm test` — 117 файлов / 1969 тестов зелёные;
- `build` — ок: `card-elements` 17,4 kB отдельно, маркера фейка нет.
- Под нагрузкой машины (load average 18) два теста `psp` один раз упали по таймауту 5 с, отдельно и
  при повторе — зелёные.

В проверку в маноре добавлено: сохраняется ли на шаге оплаты валюта, выбранная в шторке (разные
`CheckoutElementsProvider` на одном `clientSecret`).
