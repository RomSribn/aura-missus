# AURAT-0212-015 — Spec v2: Elements (на одобрение владельцу; исполнение — после «да»)

Type: task (веб, денежный путь). Status: draft v2. Priority: P1.
Slave `slave-1`, ветка `feature/AURAT-0212-web-stripe-embedded-checkout`. Решение — `013`, контекст
— `014`. База — develop `0e7b88d` (Embedded Checkout работает и остаётся, пока новый путь не готов).

## Что

Шторка Book при нехватке баланса показывает три вещи:
- кнопки кошельков Stripe — Apple Pay / Google Pay / Link;
- выбор валюты Stripe;
- нашу кнопку «Pay $X by card».

Кошелёк платит сразу в шторке: системный лист кошелька → «Still confirming…» → Booked. Кнопка
карты открывает шаг оплаты: поле карты Stripe, наш заголовок и сумма, наша кнопка «Pay». Всё на
наших шрифтах и цветах через Appearance API. Деньги по-прежнему зачисляет только BFF по слову
Stripe. Порт, опрос статуса, бронь тем же ключом, отмена, Back (041) — те же.

## Вид — набросок (телефон)

```
Book a session with Olivia                ×
…длительность, дата, время…
$32.00 · Thu, Nov 12 · 9:30–9:40 PM
PAY WITH   Aura balance   $22.00 · not enough
We’ll add $10.00 to your balance and pay from it.
[ USD $10.00 | EUR €9.27 ]        ← выбор валюты Stripe (если есть)
[  Apple Pay  ] [  G Pay  ] [ link ]   ← кнопки Stripe
──────────── or ────────────
[ 🔒 Pay $10.00 by card ]             ← наша кнопка (coral)
Secure payment by Stripe · Free cancellation…
```

Шаг карты (← назад к выбору, × закрывает):

```
←  Pay by card                            ×
Add $10.00 to your Aura balance        ← наш текст; сумма — из сессии Stripe
[ email ]                              ← только если у аккаунта нет email
[ card number | MM/YY | CVC ]          ← PaymentElement, наши шрифты и цвета
[ country ]
[ ☐ I agree to the Terms ]             ← только в live
[ 🔒 Pay $10.00 ]                       ← наша кнопка
```

## Решения (на одобрение)

| # | Вопрос | Варианты | Рекомендация |
|---|---|---|---|
| 1 | Где карта | **А** — кнопка «Pay $X by card» в шторке → отдельный шаг с полем карты; Б — поле карты сразу в шторке под кошельками | **А**: шторка и так длинная, а поле карты с адресом и страной высокое |
| 2 | Сумма меняется (другая длительность) | **А** — новая сессия Stripe на новую сумму, старая закрывается в фоне, кнопки перемонтируются (≈0,5 с); Б — та же сессия, BFF меняет сумму (`runServerUpdate`, `update_line_items: server_only`) | **А**: проще BFF, нет второго пути изменения суммы у денег; Б — потом, если мигание кнопок мешает |
| 3 | Adaptive Pricing | **А** — оставить: выбор валюты Stripe над кнопками и на шаге карты, суммы на кнопках — из сессии Stripe в выбранной валюте; Б — выключить для Elements: всегда USD, банк сам конвертирует | **А**: так решено в `AURAD-0023`, плюс местные методы (iDEAL нужен EUR). Выбор валюты Stripe требует обязательно |
| 4 | Email для карты (вход по телефону) | **А** — поле email Stripe (`ContactDetailsElement`), только если у аккаунта нет email; Б — своё поле email → `confirm({ email })` | **А**: Stripe сам узнаёт email Link и проверяет формат; строк меньше |
| 5 | Embedded Checkout | **А** — веб полностью переходит на Elements, код Embedded (`card-form`, режим `embedded`) удаляется в этой задаче; Б — оставить Embedded запасным | **А**: один путь у денег. Hosted и Embedded на BFF снимаются отдельной задачей BFF |

## Как (веб)

1. **Сессия — когда шторка готова.** Баланса не хватает, длительность и время выбраны, карта на
   BFF включена → `startCard({ ui: 'elements' })`. Ответ — `clientSecret` и `publicKey`. Сумма
   поменялась → новая сессия (решение 2А), старая закрывается `cancel` в фоне. Закрыли шторку →
   `cancel` в фоне. Это `closeBehind` из `use-card-form`.
2. **Запись попытки (`pending-store`) — только при `confirm`.** Нажали «Pay» на шаге карты или
   подтвердили в листе кошелька → `savePending` → `confirm({ redirect: 'if_required' })`.
   Простое открытие шторки платежом не считается, путь 041 его не трогает.
3. **Исходы `confirm`:**
   - `success` → `settleTopUp` (опрос статуса BFF) → бронь тем же ключом → Booked; запись
     стирается, как сейчас;
   - `error` (отказ карты, 3DS не прошёл) → текст ошибки Stripe (на языке сессии) под полем карты;
     сессия цела, можно ввести другую карту; запись стирается;
   - банк → уход на `return_url` = `/checkout?payment=` — нынешний путь.
4. **Ответ `redirect`** (оплачено и ждёт подтверждения) → `/checkout?payment=`, как сейчас.
5. **Вид — Appearance API на наших токенах.**
   - `fonts`: наши Google Fonts; `fontFamily` — Hanken Grotesk;
   - цвета `--ink`, `--paper`, `--line`, `--error`, `--accent-strong`, радиусы `--r-ctrl`;
   - кнопки кошельков — тема `black` (их цвета задают Apple и Google).
   - Значения берутся из `tokens.css`: CSS-переменные в iframe Stripe не доходят, поэтому их читают
     один раз через `getComputedStyle` в `model/` — без литералов в коде.
6. **Высота.** Кошельки — одна строка кнопок фиксированной высоты. Поле карты — наша вёрстка,
   Stripe меняет высоту только своего блока (ошибка, 3DS). Пока элементы грузятся — каркас той же
   высоты.
7. **Истечение сессии (60 мин)** — как сейчас: `cancel`, новая сессия при следующем действии; строка
   `error.expired` нужна только на шаге карты.
8. **CSP** — тот же список Stripe: Elements грузятся с `js.stripe.com`, к ним `api.stripe.com`,
   `hooks.stripe.com`, `link.com`. `checkout.stripe.com` остаётся для `checkout`-SDK. Тест заголовков
   — как есть.
9. **Строки** (24 языка):
   - `topUp.byCard` «Pay {{amount}} by card»;
   - `topUp.or` «or»;
   - `form.title` «Pay by card»;
   - `form.adds` «Add {{amount}} to your Aura balance»;
   - `form.pay` «Pay {{amount}}»;
   - `book-sheet pay.back` уже есть.
   - Сумма в `{{amount}}` — отформатированная Stripe строка из сессии (валюта Adaptive Pricing).
     Наш `formatUsdMinor` — только для USD без Adaptive Pricing.
   - `form.loading` и `error.expired` остаются, тексты Embedded уходят.
10. **Тесты** — Vitest с моком `@stripe/react-stripe-js/checkout`:
    - кнопки в шторке; кошелёк → Booked;
    - шаг карты → `confirm` → Booked;
    - `confirm` с ошибкой → текст, повтор той же сессией;
    - смена длительности → новая сессия, `cancel` старой;
    - × → `cancel`, без записи попытки;
    - запись пишется только при `confirm`;
    - банк → `/checkout`; `redirect` → `/checkout`; истечение.

## Что нужно от BFF и контрактов (отдельная задача BFF, ID — `aura-app-manor`)

- `@aura/contracts` `v0.34.0`: `CardCheckoutUi` + `'elements'`. Ответ — тот же
  `{ kind: 'embedded', clientSecret, publicKey }`; имя вида на проводе обсуждаем с BFF.
- BFF `ui: 'elements'`: `ui_mode: 'elements'`, `return_url` = `/checkout?payment=<id>`;
  `adaptive_pricing`, `consent_collection`, `customer_email`, `expires_at` — как сейчас. Тот же
  `paymentId` с другим `ui` — 409, как сейчас.
- Сессии будут создаваться при открытии шторки (решение 2А) — их станет больше. Незаполненные
  закрываются `cancel`, остальные истекают сами. BFF стоит проверить лимит частоты старта.
- Снятие `hosted` / `embedded` на BFF — после этой задачи.
- Поправка `AURAD-0023` (Elements вместо готовой формы; Checkout Session та же) — `aura-app-manor`.

## Порядок

1. «Да» владельца на спеку → координатору: ID задачи BFF и контракты `v0.34.0`.
2. Веб пишется в этом слоте на моках, по черновику контракта. Мёрж — после тега `v0.34.0`, мёржа
   BFF и выката на bff-dev, с вопросом владельцу.
3. Проверка на web-dev: прежний список `005`, плюс кошельки в шторке, выбор валюты и вид шага карты.

## Вне задачи

Сохранённые карты; своя кнопка Apple Pay вне Stripe; Branding Dashboard (для Elements не нужен).
