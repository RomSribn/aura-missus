# AURAT-0207-007 — spec v2 (одобрена владельцем 2026-11-11, `006`)

Спека v2 целиком — отдельным шагом по `brain/NAMING.md`: в папке задачи — только шаги.
В `005` и `006` она названа `AURAT-0207-bff-stripe-checkout.md` — это тот же текст; файл без номера
шага удалён в этой же ветке (до origin не доходил). Правки по ходу исполнения — в `008-execute`.

---

Type: technical (money rail)
Status: in-progress — спека v2 одобрена владельцем 2026-11-11 (`AURAT-0207-006`)
Priority: P1
Slave: slave-1, ветка `feature/AURAT-0207-bff-stripe-checkout`
Основания: `AURAD-0023`, `AURAI-0013` (Implementation Notes), `AURAF-0009`, `AURAF-0020` 037–040
Контекст и сверка со Stripe: `AURAT-0207-004-context.md`; правки v2 — `AURAT-0207-006-approval.md`

## Что

Третий вид пополнения USD-кошелька рядом с Google Play и App Store — карта на вебе через страницу
Stripe Checkout. Устроен по их образцу: заявка клиента → BFF сам спрашивает Stripe → зачисление
одной транзакцией с уникальным ключом; обратные движения — компенсирующими записями; быстрый путь
(вебхук) и запасной (сверка). Под `BILLING_ENABLED` **и** собственным флагом
`CARD_TOP_UP_ENABLED` (по умолчанию выключен); работа и проверка — в sandbox.

## 1. Контракты — `@aura/contracts` `v0.32.0` (минорная)

Новый модуль `card-top-up.ts` (экспорт из `index.ts`, строка в README):

| Схема | Поля |
|---|---|
| `CardTopUpRequest` | `paymentId: uuid`, `amountMinor: int`, `returnPath: string` (путь, начинается с `/`, ≤ 512) |
| `CardTopUpResponse` | `redirectUrl: string` (url страницы Stripe) |
| `CardTopUpStatus` | `'pending' \| 'credited' \| 'declined' \| 'cancelled'` — те же значения, что `TopUpStatus` веба |
| `CardTopUpStatusResponse` | `paymentId`, `status`, `amountMinor` (зачисление в USD), `balanceMinor` (текущий баланс — веб обновит шапку без второго запроса) |
| константы | `CARD_TOP_UP_MIN_USD = 5`, `CARD_TOP_UP_MAX_USD = 120` — правило суммы (решение 1), одно на веб и BFF |
| коды отказа (`ApiError.code`) | `card_top_up_amount_invalid` (400), `card_top_up_return_path_invalid` (400), `card_top_up_payment_conflict` (409: тот же `paymentId` с другой суммой; чужой `paymentId`; попытка уже закрыта) |

Порядок выпуска — как обычно (`main`, тег, push — после «да» владельца): BFF ставит `v0.32.0` до
мёржа в develop; веб (`AURAT-0208`) стартует с этого тега.

## 2. Старт — `POST /v1/wallet/top-ups/card`

Рядом с `/google` и `/apple`, под `BillingEnabledGuard` и `CardTopUpEnabledGuard` (флаг выключен →
404, как у выключенного биллинга), `200`. Имя `card`, а не `stripe`: веб и OpenAPI не знают
провайдера (как приложение не знает Chatwoot). Лимитов на число или сумму пополнений в сутки нет
(решение владельца 10).

1. Сумма: `amountMinor` — целые доллары в границах `CARD_TOP_UP_MIN_USD…MAX_USD`, иначе 400. Это
   правило BFF, а не доверие заявке: зачислено будет ровно `amountMinor`, ниже — `price_data` той
   же суммы.
2. `returnPath`: начинается с `/`, не с `//`, без схемы и `\`; origin берётся из заголовка `Origin`
   запроса и должен быть в `WEB_ALLOWED_ORIGINS`, иначе 400 (`AURAF-0020-039`). Без `Origin`
   (не браузер) — 400. URL собираются через `URL` API: в `returnPath` уже есть `?payment=`, и
   пометка отмены добавляется `searchParams.set('cancelled', '1')`, а не склейкой строк.
3. `paymentId` уже есть:
   - у другого пользователя → 409;
   - у этого, с другой суммой → 409;
   - у этого, сессия есть → **сначала спросить Stripe, что она ещё `open`**; открыта — та же
     `redirectUrl` (`AURAD-0023` п. 3); уже оплачена — `settle`, истекла — `CANCELLED`; в обоих
     случаях 409 (новая попытка — новый `paymentId`);
   - у этого, сессии нет (прошлый вызов Stripe не ответил) → повторить создание **из параметров,
     сохранённых в строке** (п. 3 ниже), с тем же ключом идемпотентности;
   - уже зачислено / отказ / отмена → 409.
4. Иначе — строка `stripe_top_ups` (`pending`) **со всеми параметрами сессии** — `expiresAt`
   (`now + 1 ч`), `locale`, `customerEmail`, `successUrl`, `cancelUrl` — записывается до первого
   вызова Stripe. Запрос к Stripe всегда строится из строки, никогда заново из «сейчас»: Stripe
   отклоняет повтор с тем же ключом и другими параметрами и кэширует этот отказ на 24 ч.
   Checkout Session:
   - `mode=payment`, одна позиция `price_data { currency: usd, unit_amount: amountMinor,
     product: STRIPE_TOP_UP_PRODUCT_ID }` — один постоянный продукт на окружение, а не новый на
     каждую сессию (пригодится для `tax_code`, когда дойдём до НДС); без `currency_options`;
   - `adaptive_pricing.enabled = true` (явно, не полагаясь на Dashboard);
   - `payment_method_options.card.request_three_d_secure = 'any'` — 3DS для всех карт (решение
     владельца 9): без него платёж до ~€30 может пройти по исключению для мелких сумм, и
     мошеннический диспут ляжет на нас;
   - `payment_method_types` не передаётся (методы — в Dashboard);
   - `client_reference_id = paymentId`, `metadata { paymentId, userId }` (наш внутренний `users.id`,
     не Firebase UID), то же в `payment_intent_data.metadata` — чтобы возврат и диспут из Dashboard
     находили пополнение;
   - `success_url` / `cancel_url` — из строки (п. 2);
   - `locale` из `?lang=`: язык как есть, `ga` → `en`, `pt` → `pt-PT`, без языка → `auto`;
   - `customer_email` — почта профиля, если есть (решение 2);
   - `consent_collection.terms_of_service = required`;
   - `expires_at` — из строки (решение 7: 1 час);
   - `integration_identifier = web-top-up`;
   - idempotency key запроса — `checkout:<paymentId>`.

   Ответ Stripe → `checkoutSessionId`, `url` в строку, `customerEmail` обнуляется (почта нужна
   только до ответа Stripe и не хранится у пополнения дольше); клиенту — `{ redirectUrl }`.
   Ошибка Stripe → 503, строка остаётся `pending`; повтор того же `paymentId` создаст сессию из
   строки, а не повторённая — закроется сверкой как `cancelled`.

## 3. Хранение (Prisma, одна миграция)

- `stripe_top_ups`: `id`, `paymentId @unique` (uuid веба), `walletId`, `amountMinor` (USD,
  зачисление), `status` (`PENDING | CREDITED | DECLINED | CANCELLED`); параметры сессии —
  `expiresAt`, `locale`, `customerEmail?` (только до ответа Stripe), `successUrl`, `cancelUrl`;
  от Stripe — `checkoutSessionId? @unique`, `checkoutUrl?`, `presentmentAmountMinor?`,
  `presentmentCurrency?`, `paymentIntentId? @unique`, `chargeId? @unique`; `ledgerEntryId?
  @unique` (зачисление); `checkedAt?` (последний запрос к Stripe — для ограничения статуса),
  `createdAt`, `settledAt?`.
- `stripe_refunds`: `id`, `topUpId`, `stripeRefundId @unique`, `amountMinor` (USD),
  `ledgerEntryId @unique`, `failedEntryId? @unique` (Stripe потом не смог вернуть / отменил),
  `source` (`BACKOFFICE | STRIPE`), `operatorId?`, `createdAt`.
- `stripe_disputes`: `id`, `topUpId`, `stripeDisputeId @unique`, `amountMinor` (USD),
  `withdrawnEntryId? @unique`, `reinstatedEntryId? @unique`, `createdAt`.
- `stripe_events`: `eventId @unique`, `type`, `createdAt` (время события у Stripe), `handledAt` —
  обработанные события; на нём держится курсор сверки (п. 9).
- Новые типы ledger (решение 3): `CARD_REFUND` (−), `CARD_REFUND_FAILED` (+, возврат на карту не
  прошёл или отменён), `CARD_DISPUTE` (−), `CARD_DISPUTE_REVERSAL` (+, деньги по диспуту
  вернулись).

Почему отдельные строки возвратов и диспутов: у одного пополнения их может быть несколько (частичные
возвраты; повторный диспут), а `refundEntryId` одной колонкой, как у Play/Apple, этого не скажет.

## 4. Зачисление — одна идемпотентная функция `settle(topUpId)`

Её вызывают вебхук, статус, старт-повтор, отмена и сверка; другого пути к зачислению по карте нет.

1. Строка уже не `PENDING` → вернуть как есть.
2. Запросить сессию у Stripe (`expand: payment_intent.latest_charge`).
3. `status = complete` и `payment_status = paid` → под блокировкой кошелька, одной транзакцией:
   запись `TOPUP` на `amountMinor` **из строки** (не из ответа Stripe), ключ
   `stripe:<checkoutSessionId>`, строка → `CREDITED` с `paymentIntentId`, `chargeId`,
   `presentment_*`. Дубль ключа/гонка → перечитать, вернуть победителя.
   Дополнительная сверка: `amount_total`, `currency` и `client_reference_id` сессии совпадают со
   строкой, иначе не зачислять (лог `error`). `no_payment_required` при сумме > 0 не бывает —
   тоже не зачислять, лог `error`.
4. `complete` + `unpaid` (отложенный метод) → оставить `PENDING`.
5. `expired` → `CANCELLED` (ничего не списано).
6. `open` → `PENDING`.

Отказ отложенного метода (`async_payment_failed`) → `DECLINED`.

## 5. Вебхук — `POST /webhooks/stripe`

`@ApiExcludeController`, `@Public()`, `VERSION_NEUTRAL`, `200`.

- Подпись `Stripe-Signature` — `stripe.webhooks.constructEvent(rawBody, header, secret)` (допуск
  по времени — штатные 300 с). Нет подписи / не сошлась → 400. Флаг выключен или секрета нет →
  503 (Stripe повторит).
- Событие → очередь `stripe-events` c `jobId = event.id`, ответ — сразу. В очередь кладётся только
  `{ eventId, type, objectId, created }`; обработчик сам перечитывает объект у Stripe — не верим
  телу события дольше, чем нужно, и порядок событий не важен. После успешной обработки —
  строка в `stripe_events`.
- События (одни и те же для вебхука и сверки):

| Событие | Что делаем |
|---|---|
| `checkout.session.completed`, `checkout.session.async_payment_succeeded` | `settle` |
| `checkout.session.async_payment_failed` | → `DECLINED` |
| `checkout.session.expired` | → `CANCELLED`, если ещё `PENDING` |
| `charge.refunded`, `refund.created`, `refund.updated`, `refund.failed` | сверить возвраты charge: `GET /v1/refunds?charge=…` (`charge.refunds` в текущих версиях API не приходит). Возврат в `pending` или `succeeded`, которого нет в `stripe_refunds` → `CARD_REFUND` на его сумму (USD) — так попадают возвраты из Dashboard, и тот же момент, что у бэкофиса: деньги ушли клиенту — списаны с баланса. Возврат в `failed` или `canceled` с записью и без `failedEntryId` → `CARD_REFUND_FAILED` на ту же сумму |
| `charge.dispute.funds_withdrawn` | `CARD_DISPUTE` на `dispute.amount`, не больше зачисленного минус уже возвращённое; баланс может уйти в минус (`AURAD-0010` п. 5) |
| `charge.dispute.funds_reinstated` | `CARD_DISPUTE_REVERSAL` на списанное по этому диспуту |
| `charge.dispute.created` | только уведомление команде (решение 6), денег не двигает |

Поправка к шагу 001: деньги по диспуту двигаем не на `created` / `closed:won`, а на
`funds_withdrawn` / `funds_reinstated` — ровно когда их снимает и возвращает Stripe (inquiry не
снимает ничего). Событие без нашего пополнения (`metadata.paymentId` пусто или неизвестно) —
пропустить, лог `warn` без PII.

Очередь: `attempts: 5`, экспоненциальная задержка — в отличие от Play/Apple, здесь обработчик
делает сетевой запрос к Stripe, и временный сбой не должен ждать сверки.

## 6. Статус — `GET /v1/wallet/top-ups/card/:paymentId`

Под теми же двумя guard-ами. Чужой или неизвестный `paymentId` → 404. Пока `PENDING` и `checkedAt`
старше 5 с — `settle` (не чаще раза в 5 с на пополнение; веб спрашивает раз в 2 с до 60 с).
Ответ — `CardTopUpStatusResponse`.

Путь отличается от `/v1/wallet/top-ups/:id` из `AURAF-0020-038` словом `card`: у Play/Apple
статуса нет, а общий `:id` спорил бы с `POST /top-ups/google|apple`. Строку 038 и `AURAD-0023`
правит `aura-app-manor` (здесь `AURAF-0020` не трогаем — там непушнутые правки того же файла).

## 7. Отмена — `POST /v1/wallet/top-ups/card/:paymentId/cancel` (решение 4)

Веб зовёт её, вернувшись по `cancel_url`. `PENDING` → `expire` сессии в Stripe → `CANCELLED`. Если
Stripe отвечает, что сессия уже `complete` (человек успел заплатить в другой вкладке) — `settle`,
отмены нет. Уже не `PENDING` → вернуть как есть. Ответ — `CardTopUpStatusResponse`.

## 8. Возврат на карту из бэкофиса (Terms §07)

Новый раздел бэкофиса **«Пополнения картой»** (`/backoffice/card-top-ups`):

- список: новые сверху, по 50; поиск по id пользователя или телефону; колонки — время, пользователь
  (имя / id), сумма USD, что видел покупатель (`€9,32`), статус, возвращено, диспут;
- страница пополнения: всё о нём, возвраты и диспуты (ссылка на платёж в Dashboard по `chargeId`),
  текущий баланс и форма **«Вернуть на карту»**: сумма ≤ min(зачислено − уже возвращено −
  под диспутом, баланс); по умолчанию — максимум;
- два шага, как у промокодов: «Проверьте возврат» (сумма, остаток пополнения, баланс после) →
  «Вернуть». Ключ формы → idempotency key Stripe `refund:<formKey>`;
- порядок: сначала Stripe Refund (`reason: requested_by_customer`, `metadata { topUpId, operator }`),
  затем в одной транзакции `stripe_refunds` + `CARD_REFUND` (и при `pending`, и при
  `succeeded` — как у возврата из Dashboard). Упадёт запись — её допишут события возврата
  (ключ — `stripeRefundId`). Повтор формы — Stripe вернёт тот же возврат, у нас — тот же ряд;
- открытый диспут → кнопка недоступна (Stripe не даёт вернуть платёж под диспутом).

Окно между проверкой баланса и записью — секунды; если человек в эти секунды забронирует сессию,
баланс уйдёт в минус на эту сумму (то же правило `AURAD-0010` п. 5). Резервирование баланса не
делаю — оно добавило бы состояние «возврат запрошен», а выигрыш — доли секунды у оператора.

Курс возврата покупателю (по текущему или по курсу платежа) **не подтверждён**: документация
Stripe и `AURAI-0013` говорят разное. На код не влияет — кошелёк в USD, возврат задаётся в USD;
влияет только на текст Terms (`AURAT-0209`).

## 9. Сверка

Повторяющаяся задача в той же очереди, раз в 5 минут, только при `BILLING_ENABLED` и
`CARD_TOP_UP_ENABLED` (планировщик + второй замок в сервисе, как у Play/Apple):

- `PENDING` старше 10 минут → `settle`; если сессии так и нет (Stripe не ответил на старте) и строке
  > 1 ч → `CANCELLED`;
- события Stripe (`GET /v1/events`, только типы из п. 5) **после курсора** — время самого позднего
  события в `stripe_events` минус 10 минут запаса, не глубже 72 часов. Уже записанные в
  `stripe_events` пропускаются без запроса объекта; остальные — тот же обработчик. Повтор
  безвреден (уникальные ключи), но и не делается без нужды.

Лог каждого прогона — только счётчики (`TECH-DEBT #30`).

## 10. Конфиг

- `CARD_TOP_UP_ENABLED` — по умолчанию `false`. `NODE_ENV=production` стоит на всех стендах,
  включая bff-dev, а на проде биллинг включён (покупки Android): ключи, обязательные при одном
  `BILLING_ENABLED`, уронили бы прод-BFF вместе с покупками в приложении, как только код дойдёт
  до `main` раньше live-ключей. Поэтому ключи обязательны **только при включённом флаге** (в любом
  окружении — fail fast).
- `STRIPE_SECRET_KEY` (`rk_…`, restricted; `sk_…` отклоняется при `NODE_ENV=production`),
  `STRIPE_WEBHOOK_SECRET` (`whsec_…`), `STRIPE_TOP_UP_PRODUCT_ID` (`prod_…`, постоянный продукт
  «Aura balance top-up», создаётся владельцем в Dashboard на окружение). Пустая строка из Coolify —
  «нет».
- Флаг выключен: `/card*` → 404, вебхук → 503, сверка не регистрируется; ключи, если заданы, не
  используются.
- Версия API Stripe — константа в адаптере; npm `stripe` — точная версия `23.0.1` (самая свежая
  старше двух недель).
- Права restricted-ключа (для владельца): Checkout Sessions — write; Charges / PaymentIntents —
  read; Refunds — write; Disputes — read; Events — read; Products — read.
- `deploy/env/bff.env.example` — четыре строки с комментарием.

## 11. Устройство кода

- `src/modules/stripe/` — адаптер: SDK, порт `CardPayments` (создать / прочитать / закрыть сессию,
  вернуть, список возвратов charge, прочитать диспут, список событий, проверка подписи) — наружу
  только наши типы, ни одного типа Stripe (как Chatwoot, правило 1); фейк для тестов; контроллер
  вебхука.
- `src/modules/wallet/` — `CardTopUpService` (старт, статус, отмена, `settle`), `CardRefundService`
  (возвраты, диспуты, сверка), методы репозитория с блокировкой кошелька; контроллер — три маршрута;
  `CardTopUpEnabledGuard`.
- `src/jobs/` — `stripe-events` процессор и планировщик, тонкие.
- `src/modules/backoffice/` — контроллер, сервис страниц, view «Пополнения картой».
- Staff chat — уведомление о диспуте (решение 6).

## 12. Тесты (только чистые, в слоте)

Jest, Stripe — фейк порта, репозиторий — in-memory, как у Play/Apple:

- старт: сумма вне правила, путь возврата (чужой origin, `//evil`, схема; `?payment=` +
  `cancelled=1`), повтор с тем же `paymentId` (сессия открыта — та же ссылка; истекла / оплачена —
  409), повтор после неответа Stripe (тот же запрос из строки, тот же ключ), другая сумма, чужой
  `paymentId`, локаль (`ga`, `pt`, без языка), почта есть / нет и обнуляется после ответа, 3DS
  `any`, постоянный продукт;
- `settle`: `paid`, `unpaid`, `expired`, повтор, гонка двух вызовов, сумма/валюта/ссылка не сошлись;
- вебхук: нет подписи, неверная подпись, флаг выключен, событие → задача с `jobId = event.id`;
- отмена: открытая, уже оплаченная, уже закрытая;
- возвраты: из бэкофиса, из Dashboard в `pending` и `succeeded`, повтор, `failed` / `canceled`,
  предел суммы;
- диспут: списание с уходом в минус, возврат денег, повторные события, два диспута;
- сверка: курсор, пропуск записанных событий, глубина 72 ч;
- статус: ограничение 5 с, 404 на чужой;
- конфиг: флаг выключен без ключей (стартует), флаг включён без ключей (не стартует), половина
  ключей, `sk_` в production;
- view бэкофиса — разметка и экранирование.

## Решения владельца

Владелец 2026-11-11 (передано из `aura-app-manor`): 1–8 — по рекомендации; 9–10 — добавлены.

| # | Вопрос | Решение |
|---|---|---|
| 1 | Правило суммы | **целые доллары $5–$120** |
| 2 | `customer_email` из профиля | **передавать** |
| 3 | Типы ledger | **новые `CARD_*`** |
| 4 | Отмена | **`cancel_url` + `POST …/cancel`** |
| 5 | Возврат при Adaptive Pricing | всё в USD, пересчёта нет |
| 6 | Сигнал о диспуте | **staff chat (Telegram) + страница в бэкофисе** |
| 7 | Срок сессии | **1 час** |
| 8 | История кошелька (`TECH-DEBT #29`) | **не в этой задаче** |
| 9 | 3DS | **для всех карт**: `request_three_d_secure = 'any'` |
| 10 | Лимиты пополнений в сутки на пользователя | **не ставить** |

## Вне задачи

Веб (`AURAT-0208`), условия (`AURAT-0209`), НДС и Stripe Tax, live-ключи и прод (ворота
`AURAD-0023`), сохранённые карты, продление через PSP (`AURAF-0020-042`), история кошелька, правки
`AURAF-0020` / `AURAD-0023` / `AURAT-0208-001` (их делает `aura-app-manor`).

## Проверка в маноре (sandbox, после мёржа)

Владелец заранее в Dashboard sandbox:

- включить Adaptive Pricing и методы оплаты;
- **добавить USD-счёт для выплат**: Adaptive Pricing работает, только если валюта цены — одна из
  валют выплат аккаунта, а у эстонского по умолчанию EUR. Без этого `test+location_NL` покажет
  доллары;
- **включить чеки на email**;
- ссылка на Terms в публичных данных;
- продукт «Aura balance top-up» → `STRIPE_TOP_UP_PRODUCT_ID`;
- restricted-ключ с правами из п. 10;
- вебхук `https://bff-dev.aura-app.cc/webhooks/stripe` на события п. 5;
- секреты и `CARD_TOP_UP_ENABLED=true` — в Coolify (development).

Проверить: карта `4242…` (зачисление, 3DS спрошен), `…3155` (3DS), `…9995` (отказ), «назад»
(отмена), `test+location_NL@example.com` (евро, `presentment_*`), возврат из бэкофиса и из
Dashboard, диспут тестовой картой (`4000 0000 0000 0259`), сверка при выключенном вебхуке, прод-
конфиг без флага (стартует).
