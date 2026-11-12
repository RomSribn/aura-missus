# AURAT-0208-007 — Spec v2 (решения 1–6 и замечания — `006`; исполнение — после «да» владельца)

Правки к `005`: решения владельца 1–6 записаны в таблицу; замечания `006` 1–4 внесены в п. 1, 2, 4,
8 и «Проверку в маноре». Спека целиком — шагом, по `brain/NAMING.md`.

Type: task (веб, денежный путь). Status: draft v2. Priority: P1.
Slave: `slave-1`, ветка `feature/AURAT-0208-web-stripe-checkout`.
Основания: `AURAD-0023`, `AURAI-0013` (Implementation Notes), `AURAF-0020` 037–041, BFF
`AURAT-0207-007-spec-v2`. Контекст — `AURAT-0208-004`.

## Что

При нехватке баланса шторка Book предлагает одну кнопку **«Pay $X»**. Она ведёт на страницу Stripe
Checkout, которую создаёт BFF, и возвращает человека на `/checkout?payment=`. Дальше — то, что уже
есть с `AURAT-0108`: опрос статуса, «Still confirming…», затем та же бронь с баланса тем же ключом.
Деньги зачисляет только BFF (`AURAD-0023` п. 2); веб ничего не считает за цену и только показывает.
Фейк и `/psp-sandbox` остаются инструментом разработки и в прод-сборку не попадают.

## 1. Флаг (решение 1)

- `VITE_PSP_ENABLED=true` включает оплату картой через BFF **в любой сборке**: dev, web-dev, прод.
  Имя переменной не меняется — она уже есть в Coolify, `Dockerfile` и `build.sh`.
- Фейк — только `import.meta.env.DEV && VITE_PSP_FAKE === 'true'` (новая переменная, тоже константа
  сборки): тогда вместо адаптера BFF — фейк и маршрут `/psp-sandbox`. `.env.development.local` в
  слоте и в маноре — `VITE_PSP_FAKE=true`, если нужен фейк; без неё dev против bff-dev ходит в
  настоящий sandbox.
- Константы — в `shared/config/env.ts`: `PSP_ENABLED` (смысл меняется: «карта включена») и
  `PSP_FAKE`. Комментарий «A real provider lifts `DEV`» уходит.
- Прод-сборка без фейка проверяется механически: `deploy/web/build.sh` после `vite build` ищет в
  сборке маркер фейка и роняет сборку, если нашёл. Маркер — значение, которое есть **только в коде
  фейка**: ключ его записи `FAKE_PSP_STORAGE_KEY = 'aura.fake-psp'` (`features/pay/config/pay.ts`,
  читает только `fake-psp.ts`). Путь `/psp-sandbox` маркером не годится: он в `ROUTES`
  (`shared/config/routes.ts:17`) и попадает в любую сборку (замечание 1). Что проверка работает,
  слот доказывает сборкой: без фейка маркера нет, с фейком (`--mode development`,
  `VITE_PSP_FAKE=true`) — есть; иначе (маркер не исчезает при tree-shaking) — путь песочницы и
  маркер переезжают в модуль, который грузится только с фейком. Плюс тест `env`: `PSP_FAKE` ложен
  при `PROD`.

## 2. Провайдер — адаптер BFF (после тега `v0.32.0`)

- Порт `TopUpProvider` (`features/pay/model/top-up-provider.ts`): `startCard` и `status` — без
  изменений; **новый** `cancel(paymentId) → TopUpStatus`; `payWithWallet` уходит (решение 2).
- Эндпоинты — в `entities/wallet/api` (RTK Query, `injectEndpoints`), ответы — `Schema.parse`
  контрактов:
  - `startCardTopUp` — `POST /v1/wallet/top-ups/card`, тело `CardTopUpRequest.parse(…)`, ответ
    `CardTopUpResponse`;
  - `cardTopUpStatus` — `GET /v1/wallet/top-ups/card/:paymentId` → `CardTopUpStatusResponse`;
  - `cancelCardTopUp` — `POST /v1/wallet/top-ups/card/:paymentId/cancel` → то же.
  `credited` из статуса или отмены кладёт `balanceMinor` в кэш `getWallet` (`updateQueryData`) —
  шапка обновляется без второго запроса.
- Адаптер `features/pay/model/card-provider.ts` — `createCardProvider(…)` поверх этих мутаций:
  - `startCard` → `{ redirectUrl }`; переход — как сейчас, `loadPage` (никакого iframe);
  - `status` и `cancel`: 404, сеть и 5xx — ошибка, то есть «ещё не ответ» (`settleTopUp` так её и
    считает); окно 60 с кончится — исход `processing`. 404 — не `declined`: BFF отвечает 404 и при
    выключенном `CARD_TOP_UP_ENABLED` / `BILLING_ENABLED`, а деньги могли уже уйти, и «Nothing was
    charged» было бы неправдой (замечание 2);
  - старт: 404 → исход «карта здесь выключена» (п. 7); 400 / 409 / 503 / сеть → `failed`, ключ брони
    цел.
  - `locale` страницы Stripe BFF берёт из `?lang=`, который `base-query` уже добавляет.
- `useTopUpProvider`: `PSP_FAKE` → фейк, `PSP_ENABLED` → адаптер BFF, иначе `null`.
- `@aura/contracts` `v0.29.0` → `v0.32.0` — **отдельный коммит** (правило 6) со сверкой
  `v0.30.0`–`v0.31.0` (сезонные тексты, перевод чата) по typecheck. Локальной копии схем нет: до тега
  этот пункт не начинается.

## 3. Кошелёк (решение 2)

Кнопка Apple Pay / Google Pay уходит: Checkout сам показывает их на своей странице. Вместе с ней —
весь путь кошелька: `payByWallet`, `PaymentMethodId 'wallet'`, `fake-wallet-prompt`, `TestWallet`,
`wallet-brand` с тестом, `WALLET_NAMES`, строка `topUp.wallet` (24 языка). Фейку остаётся только
hosted page (`/psp-sandbox`).

## 4. Сумма (решено владельцем) и потолок (решение 5)

- `topUpPlan`: пополнение = недостача вверх до целого доллара, **но не меньше
  `CARD_TOP_UP_MIN_USD`** (из контрактов); остаток остаётся на балансе (может быть больше $1).
  Заголовок файла скажет, что это правило веба, а не порт лестницы сторов.
- Если пополнение поднято до минимума — строка плана говорит почему: «The smallest card top-up is
  $5 — $3.40 stays on your balance after the session.»
- Недостача больше `CARD_TOP_UP_MAX_USD` (решение 5А): кнопки карты нет, строка — сначала «выберите
  сессию короче», приложение вторым (iOS-приложения ещё нет, «Top up in the Aura app» на iPhone —
  тупик; замечание 3). Как `pay-plan.ts` приложения: больше лестницы SKU он тоже не даёт.

## 5. Возврат и отмена

- `/checkout?payment=<id>` — как сейчас: опрос, `credited` → бронь тем же ключом.
- `/checkout?payment=<id>&cancelled=1` (`cancel_url`; `cancelled` — новый параметр `CheckoutSearch` в
  `shared/config/routes.ts`): сначала `provider.cancel(id)`, потом — по его ответу:
  `cancelled` → назад в шторку молча (как сейчас); `credited` → бронь (человек успел заплатить в
  другой вкладке); `pending` → обычный опрос; `declined` → шторка с «didn't go through».
- Отмена, которая не ответила, — опрос, как будто `pending` (BFF закроет сессию сверкой).

## 6. Back со страницы Stripe (041, решение 6)

Человек жмёт Back на странице Stripe — шторка Book возвращается из bfcache (`pageshow.persisted`)
или загружается заново, а запись попытки в `sessionStorage` жива. В обоих случаях веб ведёт на
`/checkout?payment=<id>&cancelled=1` (п. 5): BFF закрывает сессию или, если деньги ушли, зачисляет
их, и бронь доходит. Признак — запись попытки для этого советника при открытии шторки. Переход — в
`model/` (`use-pay`), не в `ui/`.

## 7. Карта выключена на BFF

`CARD_TOP_UP_ENABLED` на BFF выключен, а веб собран с `PSP_ENABLED` → старт отвечает 404. Шторка
показывает нынешнюю строку «Your balance is $X short. Top up in the Aura app…» и до перезагрузки
больше не предлагает карту. Ключ брони цел, ничего не списано. Новой строки нет.

## 8. Строки (решение 3) — `pay`, сразу на 24 языках

| Ключ | English | |
|---|---|---|
| `topUp.card` | `Pay {{amount}}` | без изменений (USD на кнопке) |
| `topUp.note` | `Opens Stripe’s secure page — you may be charged in your local currency` | меняется |
| `topUp.planMin` | `The smallest card top-up is {{min}} — {{left}} stays on your balance after the session.` | новая |
| `topUp.wallet` | — | удаляется |
| `topUp.tooMuch` | `Your balance is {{amount}} short — more than one card top-up can add ({{max}}). Pick a shorter session, or top up in the Aura app.` | новая (5А) |

`Stripe` — имя бренда, не переводится. Суммы — `Intl` (`formatUsdMinor`). Тексты исходов (`declined`,
`processing`, `credited.*`) не меняются. Платёжные тексты — на вычитку носителю до маркетинга в
стране (`AURAI-0010` решение 7), задачу это не держит.

## 9. Тесты (Vitest, слот)

- `top-up-plan.test.ts` — минимум $5, ровно $5, остаток > $1, потолок $120, долг на балансе.
- `app/__tests__/psp.test.tsx` — на **моке провайдера** (`useTopUpProvider` подменён): старт и уход
  (`loadPage` с `redirectUrl`), возврат `credited` → Booked, `declined`, отмена `cancelled=1` (молча
  в шторку; `credited` после отмены → Booked), Back из bfcache и Back с перезагрузкой → `/checkout?…
  &cancelled=1`, опрос, «Still confirming…», `processing`, 404 старта → строка «Top up in the app»,
  нет кнопки кошелька.
- `card-provider.test.ts` — адаптер на моке BFF (`fetch`): тело старта по схеме, разбор ответов,
  404 статуса и отмены → «ещё не ответ» (а не `declined`), 404 старта → «выключено»,
  `balanceMinor` → кэш кошелька.
- `psp.test.tsx` дополнительно: статус всё время 404 → после окна `processing`, не «didn't go
  through»; недостача больше $120 → нет кнопки карты, строка `topUp.tooMuch`.
- `fake-provider.test.ts` — без кошелька, с `cancel`.
- `env.test.ts` — `PSP_FAKE` ложен при `PROD`; `VITE_PSP_FAKE` проверяется как `true | false`.
- `build.sh` — проверка маркера фейка; `VITE_PSP_FAKE` в списке флагов `true | false`.

## 10. Порядок

Тег `v0.32.0` выпущен 2026-11-11 (origin: `refs/tags/v0.32.0` → `main` `34f978b`; сообщение из
`aura-app-manor` slave-0, сверено `git ls-remote`). Поэтому весь код — в слоте, одним заходом:

1. Подъём `@aura/contracts` `v0.29.0` → `v0.32.0` — первым, **отдельным коммитом** (правило 6).
2. Остальное: п. 1–8, порт с `cancel`, адаптер и эндпоинты, тесты п. 9. Границы суммы — из
   `CARD_TOP_UP_MIN_USD` / `MAX_USD` контрактов.
3. **Манор, после выката `AURAT-0207` на bff-dev с sandbox-секретами:** мёрж (с вопросом владельцу),
   проверка ниже. Пока BFF не выкачен, web-dev с `VITE_PSP_ENABLED=true` покажет строку п. 7
   («Top up in the app»): вреда нет, но значение в Coolify перед мёржем сверить.

## Решения владельца

Владелец 2026-11-11 (передано из `aura-app-manor`, `006`): все шесть — по рекомендации: **1А, 2А,
3 — вариант 1, 4 — следующими задачами, 5А (текст — по замечанию 3), 6А**.

| # | Вопрос | Варианты | Рекомендация |
|---|---|---|---|
| 1 | Флаг | **А** — `VITE_PSP_ENABLED` включает Stripe в любой сборке, фейк — только `DEV` + `VITE_PSP_FAKE`; Б — `VITE_PSP_PROVIDER = stripe \| fake` | **А**: одна переменная в Coolify, фейк не выразим в проде даже опечаткой |
| 2 | Кошелёк | **А** — убрать кнопку и весь путь кошелька, Apple Pay / Google Pay показывает Checkout; Б — Express Checkout Element на нашей странице (Elements, файл Apple Pay на домене, Currency Selector) | **А** |
| 3 | Текст кнопки | **1** — «Pay $26.00» + заметка «Opens Stripe’s secure page — you may be charged in your local currency»; 2 — «Continue to payment» | **1**, как «Charged by Apple as CA$36.49» в приложении |
| 4 | Строки 011 (пополнение из шапки) и 042 (продление при нехватке) | в эту задачу / следующими задачами | **следующими**, после запуска основного пути; ID — в `aura-app-manor` |
| 5 | Недостача больше $120 | **А** — карту не предлагать, строка «больше одного пополнения — пополните в приложении или выберите сессию короче»; Б — два пополнения подряд; В — пополнить $120 и сказать, что не хватает | **А**: редкий случай, без второго круга оплаты |
| 6 | Back со страницы Stripe | **А** — Back = отмена: `/checkout?…&cancelled=1`, BFF закрывает сессию или зачисляет, если деньги ушли; Б — шторка как сейчас (idle), повторное «Pay» открывает ту же страницу Stripe | **А**: закрывает 041 — деньги, ушедшие до Back, не теряются без брони |

## Вне задачи

BFF (`AURAT-0207`); условия и данные продавца (`AURAT-0209`); 011 и 042 (решение 4); прод-деплой
`web.aura-app.cc` и live-ключи — ворота `AURAD-0023`; сохранённые карты; правки `AURAF-0020` /
`AURAD-0023` (их делает `aura-app-manor` — после мёржа передам, какие строки стали ✓).

## Проверка в маноре (после мёржа и выката `AURAT-0207` на bff-dev)

web-dev / локальный dev против `bff-dev.aura-app.cc`, sandbox:

- `4242 4242 4242 4242` — зачисление, 3DS спрошен, Booked; баланс = пополнение − сессия;
- `4000 0025 0000 3155` — 3DS; `4000 0000 0000 9995` — отказ → шторка «didn't go through»;
- iDEAL / Bancontact — «Fail test payment»;
- `test+location_NL@example.com` — евро на странице Stripe, на балансе USD;
- ссылка «назад» Stripe (`cancelled=1`) и Back браузера — шторка, ничего не списано;
- «Still confirming…» (медленный метод), язык страницы Stripe = язык веба;
- недостача < $5 — пополнение $5, остаток на балансе.

## Выпуск

- Прод-окружение веба в Coolify: **`VITE_PSP_ENABLED=false` до ворот live `AURAD-0023`** (активация
  Stripe, Terms, НДС, `web.aura-app.cc`, live-ключи). `VITE_PSP_FAKE` в Coolify не задаётся нигде.
- web-dev: `VITE_PSP_ENABLED=true` — после выката `AURAT-0207` на bff-dev с
  `CARD_TOP_UP_ENABLED=true` и sandbox-секретами.
