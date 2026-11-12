# AURAT-0212-007 — Execute

Date: 2026-11-12. Slave `slave-1`, ветка `feature/AURAT-0212-web-stripe-embedded-checkout`.
Исполнено по спеке `005` с решениями 1А–4А и замечаниями `006`. Изменения проиндексированы, не
закоммичены — ждут ревью владельца.

## Пакеты

- `@aura/contracts` `v0.32.0` → `v0.33.0` (`package.json`, `package-lock.json`) — при коммите
  отдельным коммитом (правило 6).
- `@stripe/stripe-js` `10.2.0`, `@stripe/react-stripe-js` `7.0.1` — точные версии.

## Код (aura-web)

- **Порт** `features/pay/model/top-up-provider.ts`: `startCard → CardPage | null`, где
  `CardPage = CardTopUpResponse` (`redirect` | `embedded`).
- **Адаптер** `card-provider.ts`: старт всегда с `ui: 'embedded'`.
- **Фейк** `fake-provider.ts`: отвечает `kind: 'redirect'` на `/psp-sandbox` (2А).
- **Stripe.js** `model/stripe-js.ts` (новый): `stripeFor(publicKey)` — один экземпляр на ключ,
  динамический `import('@stripe/stripe-js/pure')`; неудачная загрузка при следующем вызове
  повторяется.
- **`use-pay.ts`**:
  - новая фаза `form`, `PayError` `expired`, в `PayView` — `form` и `backFromForm`;
  - ответ `embedded` открывает форму: запись попытки в `sessionStorage` без секрета, таймер
    `CARD_FORM_TTL_MS`, `leftForCard` для Back из банка;
  - ответ `redirect` → `loadPage`;
  - `onComplete` → `settleTopUp` в шторке;
  - «←» → `settleTopUp` с `cancelled`;
  - истечение → то же, исход `cancelled` → `error.expired`;
  - размонтирование при открытой форме (× / Esc / фон / свайп / уход) → `cancel` в фоне
    (`closeBehind`); запись стирается при любом ответе, кроме `pending`;
  - Stripe.js не загрузился → `cancel` в фоне и `failed`.
- **Замечание 1 `006`.** Расчёт в шторке стирает запись попытки при любом исходе, кроме `unknown`
  и `aborted`. Кроме того, `finish` стирает запись того же ключа, как только ответ брони закрыл
  ключ: это покрывает и бронь с баланса после `unknown`.
- **Замечание 2 `006`.** `config/pay.ts` `CARD_FORM_TTL_MS = 60 мин`, рядом комментарий со ссылкой
  на `CHECKOUT_TTL_MS` BFF (`src/modules/wallet/card-top-up.service.ts`).
- **`pending-store.ts`**: `forgetPending(paymentId?)` стирает только запись этого платежа — поздний
  ответ фонового `cancel` не сотрёт более новую попытку.
- **UI**:
  - `ui/pay-form.tsx` — шаг оплаты, строка `form.loading`, `React.lazy`;
  - `ui/card-form.tsx` — `EmbeddedCheckoutProvider` + `EmbeddedCheckout`, отдельный чанк;
  - `ui/pay-form.module.css`.
- **`shared/ui/sheet`**: `fill` — на телефоне шторка на всю видимую высоту; `back` принимает
  `undefined`.
- **`widgets/book-sheet`**:
  - при открытой форме — `fill`, кнопка «←» `pay.back`, под шапкой только `PayForm`;
  - `close()` пускает и при фазе `form` (3А).
- **`pages/checkout`**: `expired` в `nextOf` — для полноты, туда не приходит.
- **`deploy/web/headers.conf`**:
  - CSP по списку Stripe (`script-src`, `frame-src`, `connect-src`), комментарий в шапке;
  - новый заголовок `Permissions-Policy: payment=(self "https://js.stripe.com"
    "https://checkout.stripe.com")`.
- **Строки** (24 языка):
  - `pay` `topUp.note` меняется;
  - `pay` `form.loading` и `error.expired` — новые;
  - `book-sheet` `pay.back` — новая.
  - Кавычки — в обычае каждого языка, глагол кнопки — как в `topUp.card`.
- **Комментарии** про «страницу Stripe» обновлены: `pay-actions.tsx`, `payment-method.ts`.

## Тесты

- `app/__tests__/psp.test.tsx`. Hosted-сценарии `AURAT-0208` идут через ответ `redirect`, тело
  старта — с `ui: 'embedded'`. Ответ статуса и отмены в заглушке несёт баланс, зачисленный только
  при `credited`. Новый блок «the embedded form» — 10 тестов:
  - форма → `onComplete` → Booked без `loadPage`, секрета нет в `sessionStorage`;
  - повторное открытие шторки после Booked → `replacePage` не вызван (замечание 1);
  - «←» молча возвращает к выбору;
  - «←» при `credited` → Booked;
  - × → шторка закрыта, `cancel`, запись стёрта;
  - × при `pending` → следующее открытие идёт путём 041;
  - ответ `redirect` на свою `/checkout` → `loadPage`;
  - строка загрузки и «←» пока грузится Stripe.js;
  - Stripe.js не загрузился → `failed` и `cancel`;
  - истечение через 60 мин → `cancel`, `error.expired`, новое «Pay» — новый `paymentId`.
- `app/__tests__/headers.test.ts` (новый): источники Stripe в трёх директивах CSP, `img-src
  https:`, `Permissions-Policy`.
- `card-provider.test.ts`: тело старта с `ui: 'embedded'`, оба вида ответа.
- `fake-provider.test.ts`: `kind: 'redirect'`.

## Прогон (слот)

- `npm run lint` (eslint + steiger) — чисто.
- `npm run typecheck` — чисто.
- `npm test` — 115 файлов, 1960 тестов, зелёные.
- `npm run build` — ок:
  - `card-form` — отдельный чанк 14 kB, загрузчик `stripe-js/pure` — отдельный чанк 3 kB;
  - в основном бандле Stripe нет;
  - маркера фейка `aura.fake-psp` в `dist` нет.
- `prettier --check .` ругается только на `src/pages/booked/config/locales/el.ts`: файл не тронут,
  проблема с develop, вне задачи.

## Вне репозиториев

- `aura-web-manor/.claude/aura-web-build-rules.md`, «Payments»: встроенный Checkout, CSP,
  `Permissions-Policy`, тест заголовков; «No wallet button» — «inside Stripe's form».
- `aura-web-manor/active-work.md`: slave-1 занят `AURAT-0212`.

## Открыто

- Проверка в маноре (`005`, «Проверка в маноре»): BFF `AURAT-0211` уже на bff-dev. Что в Coolify
  web-dev `VITE_PSP_ENABLED=true` — проверено владельцем в `AURAT-0208`.
- Вид формы (Branding в Dashboard Stripe) — настройка владельца.
- `AURAF-0020` / `AURAF-0009` правит `aura-app-manor`; после мёржа передать координатору, что
  сделано.

Дальше — ревью владельца в IDE; после «ок» — коммиты (контракты отдельно) и вопрос о мёрже.
