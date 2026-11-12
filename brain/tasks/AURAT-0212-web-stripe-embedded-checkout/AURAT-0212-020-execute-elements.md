# AURAT-0212-020 — Execute: Stripe Elements (спека v2 `015` + `016`–`019`)

Date: 2026-11-12. Slave `slave-1`, ветка `feature/AURAT-0212-web-stripe-embedded-checkout` (поверх
мёржа `0e7b88d`). Изменения проиндексированы, не закоммичены — ждут ревью владельца.

## Что сделано (aura-web)

**Порт и адаптер**
- `TopUpProvider.startCard → CardStart`. Варианты: `CardPage` (`redirect` | `embedded`), `{ kind:
  'off' }` (404), `{ kind: 'tooMany', retryAfterSeconds }` (429).
- `card-provider` просит `ui: 'elements'`.

**`model/use-card-checkout.ts` (новый; заменил `use-card-form.ts`)** — сессия Stripe в шторке.
- **Старт.** Сессия открывается, как только выбрано время и баланса не хватает, после паузы
  `CARD_SESSION_DEBOUNCE_MS` (300 мс). Новая сумма — новая сессия, старая закрывается в фоне.
  Шторку закрыли — сессия закрывается в фоне. Оплачиваемую сессию не трогает никто.
- **429.** Минуты из `Retry-After` (`minutesToWait`), один повтор после срока, раньше — никогда.
- **Истечение (60 мин).** `cancel`, строка `error.expired`, новая сессия — по нажатию.
- **Оплата.** `confirm(run)`:
  - `begin` → запись попытки (только сейчас, без секрета) → Stripe `confirm`;
  - да → `settleTopUp` → бронь тем же ключом;
  - нет → текст Stripe, запись стирается, сессия остаётся для другой карты;
  - нет ответа → спрашиваем BFF.
- **Фейк.** Страница `/psp-sandbox` по нажатию, как раньше.
- **Шаги.** `step: 'choice' | 'payment'`; «←» возвращает к выбору с той же сессией.

**Остальные модули `model/`**
- `use-stripe-checkout.ts` (новый): мост к `useCheckoutElements()`.
  - `payWithWallet(event)` → `confirm({ expressCheckoutConfirmEvent, redirect: 'if_required' })`;
    отказ → `event.paymentFailed`;
  - `payWithForm()`;
  - `askEmail` фиксируется при загрузке сессии;
  - `total` — сумма Stripe в выбранной валюте.
  - Импортируется только ленивым чанком.
- `stripe-appearance.ts` (новый): Appearance API из значений `tokens.css`, прочитанных в рантайме
  (`--accent-strong`, `--card`, `--ink`, `--ink-2`, `--error`, `--font-b`, `--r-ctrl`, `--line-2`),
  литералов нет.
- `stripe-js.ts`: `stripeFor(publicKey, language)`, `locale` Stripe = язык веба; ирландский →
  английский (Stripe его не знает), остальное проверяет компилятор.

**`use-pay.ts`**
- Вместо `useCardForm` / `payByCard` / `form` в `PayView` — `card: CardCheckoutView | null`.
- Фаза `form` ушла.
- `pageshow` смотрит `card.isAway()`.

**UI**
- `ui/card-choice.tsx`: каркас той же высоты (46 / 48 / 52), 429, `expired` / `failed` с «Pay $X»,
  ленивый `CardChoiceElements`.
- `ui/card-elements.tsx` (ленивый чанк):
  - выбор: `CurrencySelectorElement`, `TermsElement`, `ExpressCheckoutElement` (48 px, black,
    одна строка); «or» и «Other ways to pay» (ghost) — только если `availablePaymentMethods`
    непуст, иначе коралловая «Pay {{сумма Stripe}}»; текст отказа Stripe;
  - шаг оплаты: сумма Stripe + «Adds $X to your Aura balance», валюта, `ContactDetailsElement`
    (если нет email), `PaymentElement` (`wallets: never`), `TermsElement`, ошибка, «Pay», сноска.
- `ui/pay-step.tsx`, `ui/card.module.css`. Удалены `card-form.tsx`, `pay-form.tsx`,
  `pay-form.module.css`.
- `widgets/book-sheet`: на шаге оплаты — заголовок «Payment», без аватара и подзаголовка, «←»
  (только пока ничего не оплачивается), `fill`.

**`shared`**
- `minutesToWait` поднят из `redeem-promo-code` в `shared/lib/time/` (правило 4: оплате он тоже
  нужен).
- `time-zone` переехал туда же — Steiger ограничивает `shared/lib` 15 модулями.

**CSP** — `connect-src` + `https://fonts.googleapis.com`: элементы грузят наш шрифт по CSS Google
Fonts, Stripe требует разрешить его в `connect-src`. Тест заголовков дополнен.

**Строки (24 языка)**
- `pay`:
  - `topUp.note` → «Secure payment by Stripe»;
  - новые: `topUp.otherWays`, `topUp.or`, `topUp.loading`, `topUp.tooManyStarts`,
    `topUp.tooManyStartsLater`, `form.adds`.
- `book-sheet`: новая `pay.title` («Payment»).

**Build-rules «Payments»** переписан под Elements.

## Тесты

`psp.test.tsx` — моки `@stripe/react-stripe-js/checkout`. Hosted-сценарии `AURAT-0208` идут через
ответ `redirect` (путь фейка). Новый блок «Stripe Elements in the sheet» — 14 тестов:
- одна сессия при выбранном времени: валюта, кошельки, «or», запись попытки не пишется;
- без кошельков нет «or»;
- кошелёк → Booked; повторное открытие после Booked не ведёт на `/checkout`;
- отказ кошелька → `paymentFailed`, текст;
- шаг оплаты: `wallets: never`, поле email (и без него при email); Pay → Booked; «←» с той же
  сессией; отказ карты → текст и та же сессия;
- × → `cancel`;
- смена длительности → новая сессия на $27;
- 429 → «Try again in 2 min», кнопка неактивна;
- Stripe.js не загрузился → `failed` и новая сессия;
- истечение → `error.expired` и новая сессия.

Также `card-provider.test.ts` (`elements`, `off`, `tooMany`) и `minutes-to-wait.test.ts`.

## Прогон и что держит

- **Контракты `v0.34.0` ещё не выпущены.** В установленном `v0.33.0` у `CardCheckoutUi` нет
  `elements`:
  - typecheck падает ровно в одной строке (`card-provider.ts:47`);
  - тесты старта падают на `CardTopUpRequest.parse` (`ZodError`).
- **Проверка до тега.** Схему в `node_modules/@aura/contracts` временно дополнил `'elements'`,
  только для прогона. На ней: `typecheck` чисто, `lint` чисто, `npm test` — 116 файлов / 1965 тестов
  зелёные, `build` ок (`card-elements` 16,7 kB отдельно, Stripe в основном бандле нет, маркера фейка
  нет). Затем `npm ci`: `node_modules` снова честный `v0.33.0`.
- **Когда выйдет тег:** `npm install …#v0.34.0` отдельным коммитом (правило 6), прогон заново.
- `prettier` — только старый `src/pages/booked/config/locales/el.ts` (вне задачи).

## Открыто (проверка в маноре, после тега, мёржа и выката `AURAT-0213`)

- Прежний список `005` и экраны макета.
- Кошелёк с аккаунта без email (`017` §4).
- Terms в live: блокирует ли согласие кошелёк, переносится ли отметка на шаг; не рисуется ли
  `TermsElement` в sandbox.
- iDEAL / Bancontact — когда владелец их включит.
- Шрифт Hanken в полях Stripe (CSP `connect-src`).
