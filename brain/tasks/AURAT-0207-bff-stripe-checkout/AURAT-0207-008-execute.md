# AURAT-0207-008 — execute

Date: 2026-11-11. Слот `slave-1`, ветка `feature/AURAT-0207-bff-stripe-checkout`, от develop
`0638f5b`. Не закоммичено — всё в stage на просмотр владельцу.

## Контракты — выпущены (с «да» владельца)

`aura-contracts` `v0.32.0`: модуль `card-top-up.ts` (`CardTopUpRequest/Response`,
`CardTopUpStatus`, `CardTopUpStatusResponse`, `CARD_TOP_UP_MIN_USD = 5`, `MAX = 120`, три кода
отказа), README. `main` `34f978b` (merge), коммит `9c05938`, тег `v0.32.0` в origin. BFF стоит на
`github:RomSribn/aura-contracts#v0.32.0`. Сессии веба (`AURAT-0208`) сообщено.

## BFF — что сделано

- **Схема** — миграция `20261111120000_stripe_card_top_ups`: `stripe_top_ups`, `stripe_refunds`,
  `stripe_disputes` (+ `withdrawnMinor` — что списал диспут, ровно это и возвращается),
  `stripe_events` (курсор сверки); типы ledger `CARD_REFUND`, `CARD_REFUND_FAILED`,
  `CARD_DISPUTE`, `CARD_DISPUTE_REVERSAL`; все FK на ledger — `RESTRICT`. SQL получен
  `prisma migrate diff` между схемами (без БД); на живой БД — в маноре.
- **Адаптер** `src/modules/stripe/`: порт `CardPayments` (наружу — только наши типы),
  `StripeCardPayments` на `stripe@23.0.1`, API `2026-09-30.endive` закреплён; `StripeModule` даёт
  `null` при выключенном флаге; `POST /webhooks/stripe` — подпись по raw body → очередь
  `stripe-events` (`jobId = event.id`) → 200.
- **Кошелёк**: `CardTopUpService` (старт / статус / отмена / `settle`), `CardEventsService`
  (события, возвраты, диспуты, сверка, «Вернуть на карту»), `CardTopUpsRepository` + Prisma
  (блокировка кошелька, движение пишется один раз), правила (`card-top-up-rules.ts`),
  `CardTopUpEnabledGuard`, контроллер `wallet/top-ups/card` (три маршрута, OpenAPI).
- **Задачи**: `StripeEventsProcessor` (`event`, `sweep`), `StripeEventsScheduler` (раз в 5 мин;
  флаг выключен — снимает расписание).
- **Бэкофис** «Пополнения картой»: список (поиск по id / телефону), страница пополнения
  (возвраты, диспуты, ссылка в Dashboard), «Вернуть на карту» в два шага, ключ формы =
  idempotency key Stripe.
- **Конфиг**: `CARD_TOP_UP_ENABLED` (по умолчанию `false`), `STRIPE_SECRET_KEY` (`rk_` / `sk_`;
  `sk_` в production отклоняется), `STRIPE_WEBHOOK_SECRET`, `STRIPE_TOP_UP_PRODUCT_ID` —
  обязательны только с флагом. `deploy/env/bff.env.example` — права ключа и список событий.
- **Документы**: README (модуль, маршруты, вебхук, бэкофис), `TECH-DEBT` #38.

## Решения по ходу (сверх спеки v2)

1. Повтор старта при сессии `complete` + `unpaid` (банковский метод подтвердит позже) — не 409, а
   `redirectUrl = successUrl`: иначе веб начал бы вторую попытку и человек заплатил бы дважды.
   Оплачено / истекло — по-прежнему 409.
2. Повтор старта без сессии, когда до `expiresAt` строки осталось < 31 мин (минимум Stripe — 30) →
   `CANCELLED` + 409: параметры менять нельзя (тот же ключ), а такой запрос Stripe отклонит.
3. Отказ Stripe на создание сессии (4xx) → строка `CANCELLED` + 503; неоднозначный сбой → строка
   остаётся `PENDING`, повтор шлёт тот же запрос.
4. Вебхук о сессии, которой нет в строке (запись после ответа Stripe не прошла), находит пополнение
   по `client_reference_id` и привязывает сессию; если у пополнения уже другая сессия — не зачисляет.
5. `refund.created` добавлен к `refund.updated` / `refund.failed` / `charge.refunded`;
   `requires_action` считается `pending` (возврат уже есть).
6. Диспут: строку записывает и staff chat уведомляет **первое** пришедшее событие о диспуте
   (`funds_withdrawn` может прийти раньше `created`) — найдено тестами, исправлено.
7. Стенд с выключенным флагом: страница бэкофиса и маршруты — 404, вебхук — 503, вкладки нет.

## Проверки (в слоте, без БД / Redis / Stripe)

- `tsc --noEmit`, `eslint` по изменённым файлам, `nest build` — чисто; `*.spec-fixtures.ts` в
  `dist` не попадают.
- Jest: **195 наборов, 2928 тестов — все зелёные** (новых — 251: правила, старт / статус / отмена
  / settle, события, возвраты, диспуты, сверка, возврат из бэкофиса, адаптер с настоящей подписью
  Stripe, вебхук, конфиг, задачи, view).
- Prettier — только на изменённых файлах (`env.schema.spec.ts` содержит 3 старые неотформатированные
  строки вне правки — не трогал).

## Известные ограничения

- Сверка закрывает пополнение без сессии через час, не спрашивая Stripe. Если Stripe сессию создал,
  а запись не прошла, человек URL не получил (старт ответил 503), так что оплатить её он не мог;
  повтор старта привязывает ту же сессию по ключу. Почти недостижимо — оставлено.
- `TECH-DEBT` #38: возврат на карту не резервирует баланс; `stripe_events` без чистки.

## Брейн

`AURAF-0009`, `AURAF-0020` (строки 037–040, путь 038 → `/top-ups/card/:paymentId`), `AURAD-0023`,
`AURAT-0208-001` правит `aura-app-manor` (там непушнутые правки тех же файлов). Здесь — только
папка задачи.

## Дальше

Просмотр владельцем в IDE → коммит в feature-ветку → вопрос о мёрже в `develop` (merge gate) →
проверка в маноре на sandbox (список в шаге 007, раздел «Проверка в маноре»).
