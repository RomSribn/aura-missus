# AURAT-0207-001 — Initial (заготовка; исполняется в `aura-bff-manor`)

Date: 2026-11-11
Выдан в `aura-app-manor` (slave-0) по просьбе владельца: «да, подготовь задачи, чтобы полностью
подключить страйп к вебу».

Основания:
- решение — `AURAD-0023`;
- исследование и план — `AURAI-0013`, раздел Implementation Notes, сверенный со
  `stripe_implementation_planner` Stripe;
- фича — `AURAF-0009`;
- закрывает BE-часть бэклога `AURAF-0020` 037–040.

Веб — `AURAT-0208`, начинается после этой задачи и новой версии контрактов. Старт — `wts-task` в
`aura-bff-manor`, спека — на одобрение владельцу.

Факты о коде ниже собраны 2026-11-11 по `develop` `0638f5b`. В спеке их нужно перепроверить.

## Что нужно

Пополнение кошелька на вебе через Stripe Checkout: оплата на странице Stripe с переходом на неё и
возвратом. Это новый вид пополнения рядом с Google Play и App Store, сделанный по их образцу:
`AURAD-0010` / `AURAD-0017`, `play-top-up.service.ts`, `apple-top-up.service.ts`,
`*-refund.service.ts`.

1. **Контракты** (`aura-contracts`, новая минорная версия; BFF сейчас на v0.31.0):
   - старт: `{ paymentId: uuid, amountMinor, returnPath }` → `{ redirectUrl }`;
   - статус: `{ status: 'pending' | 'credited' | 'declined' | 'cancelled', … }` — те же значения,
     что `TopUpStatus` у веба (`features/pay/model/top-up-provider.ts:13`);
   - коды отказа: сумма вне правила, чужой `paymentId`, путь возврата не на нашем origin.
2. **Старт — `POST /v1/wallet/top-ups/stripe`**: рядом с `/google` и `/apple`, под
   `BillingEnabledGuard`.
   - Сумму задаёт правило BFF (решение 1). Сумма из тела запроса — только заявка.
   - Параметры Checkout Session:
     - `mode=payment`;
     - `line_items[0].price_data` в USD, без `currency_options`: иначе Adaptive Pricing эту валюту
       не пересчитает;
     - `payment_method_types` не передавать — методы включаются в Dashboard;
     - `client_reference_id = paymentId`, `metadata { paymentId, userId }`;
     - idempotency key запроса к Stripe — из `paymentId`.
   - `success_url` и `cancel_url` — origin запроса из `WEB_ALLOWED_ORIGINS` плюс `returnPath`
     (`AURAF-0020-039`). `cancel_url` несёт пометку отмены (решение 4).
   - `locale` — из `?lang=`, который веб уже шлёт в каждом запросе. Stripe поддерживает 23 языка
     из 24: `ga` → `en`; `pt` сверить со списком Stripe.
   - `customer_email` — почта пользователя, если она есть.
   - `consent_collection.terms_of_service = required` — согласие с Terms пригодится в диспуте.
     Для этого в публичных данных Stripe должна стоять ссылка на Terms.
   - `expires_at` — меньше суток по умолчанию; минимум у Stripe — 30 минут.
   - Повторный старт с тем же `paymentId` отдаёт ту же открытую сессию. `paymentId` другого
     пользователя — отказ.
3. **Хранение** — своя таблица по образцу `PlayPurchase` / `ApplePurchase`. Так велит комментарий
   в `prisma/schema.prisma` (строки 361–371): у PSP своя таблица, а не колонка в ledger.
   - Колонки: `checkoutSessionId @unique`, `paymentId @unique`, пользователь, сумма в USD, сумма и
     валюта покупателя из `presentment_details`, статус, `paymentIntent` / `charge`,
     `ledgerEntryId @unique`.
   - У одного пополнения может быть несколько возвратов и диспутов, поэтому они хранятся отдельными
     строками.
4. **Зачисление** — одна идемпотентная функция по ID Checkout Session.
   - Запрашивает сессию у Stripe и зачисляет только при `payment_status = paid`.
   - Пишет запись в ledger с ключом `stripe:<sessionId>`, под блокировкой кошелька, как
     `creditPlayPurchase`. При гонке или повторе возвращает уже записанный результат.
   - Её вызывают вебхук (п. 5) и статус (п. 6), пока пополнение `pending`. Stripe советует оба пути:
     вебхук может задержаться.
5. **Вебхук `POST /webhooks/stripe`** — по образцу `webhooks/apple` и `webhooks/play`.
   - Version-neutral, `@Public()`, `@ApiExcludeController`.
   - Подпись `Stripe-Signature` проверяется по `request.rawBody` (`main.ts` его уже включает, для
     Chatwoot).
   - Событие уходит в очередь BullMQ с `jobId = event.id`, ответ 200 — сразу. Прежде чем вернуть
     клиента на сайт, Stripe ждёт ответа на `checkout.session.completed` до 10 с.
   - События:
     - `checkout.session.completed` — зачислить, если `paid`, иначе ждать;
     - `checkout.session.async_payment_succeeded` — зачислить;
     - `checkout.session.async_payment_failed` → `declined`;
     - `checkout.session.expired` → `cancelled`;
     - `charge.refunded` — возврат, сделанный вне BFF (например, в Dashboard) → компенсирующая
       запись на сумму, которая ещё не учтена;
     - `charge.dispute.created` → списание; баланс может уйти в минус (`AURAD-0010` п. 5);
     - `charge.dispute.closed` с исходом `won` → обратная запись.
6. **Статус — `GET /v1/wallet/top-ups/:paymentId`** (`AURAF-0020-038`).
   - Возвращает `pending` / `credited` / `declined` / `cancelled`.
   - Пока `pending` — сверка со Stripe (п. 4), не чаще раза в N секунд на одно пополнение. Веб
     опрашивает каждые 2 с, до 60 с.
7. **Отмена** — по решению 4.
8. **Возврат неистраченного на карту** (Terms §07) — действие в бэкофисе.
   - Показать пополнения пользователя через Stripe и кнопку «вернуть $X на карту».
   - Частичный возврат через Stripe Refunds, сумма ≤ min(остаток пополнения, баланс), затем
     отрицательная запись в ledger.
   - Сейчас денежных действий в бэкофисе нет вообще, только промокоды. Истории кошелька тоже нет
     (`TECH-DEBT #29`).
9. **Сверка** — повторяющаяся задача, как у Play и Apple: пополнения в `pending` старше N минут
   сверяются со Stripe. Работает только при `BILLING_ENABLED`.
10. **Конфиг** (`src/config/env.schema.ts`, префикс `STRIPE_*`).
    - `STRIPE_SECRET_KEY` (restricted, `rk_…`) и `STRIPE_WEBHOOK_SECRET`.
    - Обязательны в production при включённом биллинге — как `requirePlayVerifierInProduction`.
    - Версия API Stripe закреплена в коде.
    - Секреты хранятся только в Coolify (`AURAS-0004`), шаблон — `deploy/env/bff.env.example`.
11. **Тесты** — Jest. Stripe спрятан за портом с фейком, как `play-purchase.port.ts` и
    `fake-play.verifier.ts`. Покрыть:
    - старт: сумма, повтор, чужой `paymentId`, путь возврата;
    - зачисление: `paid`, `unpaid`, повтор, гонка;
    - вебхук: подпись, повтор события;
    - отмена и истечение;
    - возврат и диспут, в том числе с уходом баланса в минус;
    - статус.

    В слоте — только чистые тесты. Живой путь проверяется в маноре на sandbox.

## Решения для спеки (с рекомендацией)

1. **Правило суммы** (`AURAF-0020-040`).
   - Сейчас веб пополняет недостачу, округлённую вверх до доллара (`top-up-plan.ts`). У сторов
     лестница $1…$120 (`top-up-tiers.ts`).
   - У Stripe в каждом платеже фиксированная часть €0,25 (обычная карта ЕЭЗ — 1,5% + €0,25). Поэтому
     с $1 комиссия ≈ 30%, с $5 — ≈ 7%, с $10 — ≈ 4%.
   - Варианты:
     - А — как сейчас, целые доллары от $1;
     - Б — минимум $5 (или $10), остаток остаётся на балансе;
     - В — фиксированные суммы.
   - **Рекомендация: Б** — целые доллары, от $5 до $120 (верх — как у лестницы сторов). Решает
     владелец; на вебе это одна функция.
2. **Почта для `customer_email`** — из профиля, если она есть. Без неё Checkout спросит почту сам.
   **Рекомендация: передавать.**
3. **Типы записей в ledger.**
   - Зачисление — существующий `TOPUP`.
   - Для возвратов и диспутов: либо новые `CARD_REFUND`, `CARD_DISPUTE`, `CARD_DISPUTE_REVERSAL`,
     либо переиспользовать `STORE_REFUND` / `STORE_REFUND_REVERSAL`.
   - **Рекомендация: новые типы** — в истории и бэкофисе видно, что это карта, а не стор.
4. **Отмена.** Если на странице Stripe нажать «назад», клиент возвращается по `cancel_url`, а
   сессия остаётся открытой до истечения.
   - А — `cancel_url` с пометкой; веб вызывает `POST /v1/wallet/top-ups/:paymentId/cancel`, BFF
     закрывает сессию через Stripe expire → `cancelled`.
   - Б — ждать `expires_at`.
   - **Рекомендация: А.** Иначе человек сам вернулся, а веб 60 с показывает «подтверждаем».
5. **Сумма возврата при Adaptive Pricing.** Деньги списаны в валюте покупателя. По документации
   Stripe нужно сверить:
   - в какой валюте задаётся частичный возврат;
   - в какой валюте приходят суммы в `charge.refunded`;
   - как пересчитать их в USD кошелька — например, пропорционально зачисленному.

   Решить в спеке после сверки.
6. **Сигнал о диспуте** — приватная заметка в Chatwoot по образцу `AURAT-0204`. Без неё диспут
   увидят только в Stripe. **Рекомендация: заметка в desk.**

## Владелец — до проверки в маноре (sandbox `Silvermind OU sandbox`)

- В Dashboard sandbox:
  - включить Adaptive Pricing;
  - включить методы: карты, Apple Pay, Google Pay, Link, iDEAL, Bancontact, BLIK;
  - добавить ссылку на Terms в публичные данные.
- Создать restricted-ключ с правами по спеке.
- Зарегистрировать вебхук `https://bff-dev.aura-app.cc/webhooks/stripe` на события из п. 5.
- Секреты положить в Coolify (development). В чат ключи не присылать.

## Вне задачи

- Веб — `AURAT-0208`.
- Условия и данные продавца — `AURAT-0209`.
- НДС и Stripe Tax — `AURAI-0013` шаг 4.
- Live-ключи и прод — ворота `AURAD-0023`.
- Сохранённые карты.
- Продление через PSP — `AURAF-0020-042`.
- История кошелька для пользователя — `TECH-DEBT #29`, если владелец не включит её сюда.
