# AURAT-0207-004 — context

Date: 2026-11-11. Код — develop `0638f5b`, контракты — `aura-contracts` `main` `abafea0` (тег `v0.31.0`
+ одна правка JSDoc).

## Основания (читались по путям `aura-app-manor`)

- `AURAD-0023` — пять решений: сумму задаёт BFF в USD; зачисляет только BFF и только по данным
  Stripe; ключ — ID Checkout Session; возврат и диспут — компенсирующие записи, баланс может уйти в
  минус; методы — в Dashboard, валюта — Adaptive Pricing.
- `AURAI-0013` Implementation Notes — параметры сессии, события, `presentment_details`, тесты sandbox.
- `AURAF-0009` «Состояние» и `AURAF-0020` 037–041 — строки, которые закрывает задача.

## Факты кода (шаг 001 перепроверен — совпадает)

- Образцы: `PlayTopUpService` / `AppleTopUpService` (заявка → проверка у провайдера → зачисление
  одной транзакцией с строкой покупки; гонка → `Duplicate…Error` → перечитать победителя),
  `PlayRefundService` / `AppleRefundService` (push + почасовая сверка, одна функция, ключ записи
  уникален, сумма — из строки покупки, баланс не зажимается).
- Вебхуки провайдеров: `webhooks/apple`, `webhooks/play` — `@ApiExcludeController`, `@Public()`,
  `VERSION_NEUTRAL`, проверка → очередь с `jobId` → 200. `request.rawBody` включён в `main.ts`
  (`rawBody: true`), Chatwoot уже читает его.
- Очереди: `src/jobs/queues.ts` (имена, опции, `allQueueOptions`), процессоры тонкие
  (`LoggingWorkerHost`), планировщик не регистрирует сверку при `NODE_ENV=test` и при выключенном
  `BILLING_ENABLED`; сервис проверяет флаг второй раз.
- Ledger: `LedgerEntryType` = `TOPUP`, `SESSION_CHARGE`, `SESSION_REFUND`, `STORE_REFUND`,
  `STORE_REFUND_REVERSAL`, `PROMO_CREDIT`; append-only триггер — тип строки навсегда.
  `(walletId, idempotencyKey)` уникален. Комментарий в `schema.prisma` 361–371: у PSP своя таблица.
- Конфиг: `env.schema.ts`, правила `require…InProduction` действуют только при `NODE_ENV=production`
  и `BILLING_ENABLED=true`; Coolify шлёт пустую строку вместо «нет» — есть общий препроцессор.
- `WEB_ALLOWED_ORIGINS` — массив origin-ов (CORS и `/ws`), `src/common/web/web-origins.ts`.
- Язык запроса — `languageFromQuery` (`src/common/language/request-language.ts`), только `?lang`.
- Почта пользователя — `UserRecord.email` (необязательная, не уникальная).
- Бэкофис: разделы кампании / промокоды / отзывы / удаления; денежных действий нет; ролей у
  операторов нет; образец двухшагового действия — «Проверьте партию» → создать (ключ формы).
- Staff chat (Telegram, `StaffChatPort`, `AURAT-0092`) — для оперативных уведомлений команды, без
  PII. Удобнее заметки в desk для диспута: у человека несколько разговоров (по советнику), и какой
  из них «тот самый» — неясно.
- `TECH-DEBT #29` — истории кошелька нет нигде (ни маршрута, ни экрана).
- Веб (`aura-web`): `TopUpProvider.startCard({ paymentId, amountMinor, returnPath })` →
  `{ redirectUrl }`; `returnPath` = `paths.checkout({ payment })` — путь с query
  (`/checkout?payment=<uuid>`); `TopUpStatus` = `pending | credited | declined | cancelled`.
- Stripe в коде нет. npm `stripe`: `23.0.1` (2026-10-22), `23.1.0` (2026-10-29), Node ≥ 20.

## Сверка со Stripe (MCP, sandbox `Silvermind OU sandbox`, livemode=false)

- Checkout Session и PaymentIntent остаются в валюте интеграции (USD); что видел покупатель —
  `presentment_details { presentment_amount, presentment_currency }` (с API `2025-03-31.basil`;
  есть также у Charge и Refund).
- **Возврат** (`POST /v1/refunds`): `amount` — в валюте платежа, то есть в USD. Покупателю
  возвращается в его валюте по текущему курсу; разницу курса несёт продавец, не кошелёк. Значит
  решение 5 шага 001 простое: суммы возвратов и `charge.amount_refunded` — уже USD, пересчёт не
  нужен.
- **Диспут**: деньги со счёта снимаются не при `charge.dispute.created` (у inquiry их не снимают
  вовсе), а при `charge.dispute.funds_withdrawn`; при выигрыше возвращаются
  `charge.dispute.funds_reinstated`. Сумма диспута может отличаться от платежа. На один платёж
  бывает больше одного диспута.
- `locale`: из 24 языков приложения Stripe не знает только `ga`; `mt` есть; для `pt` есть `pt`,
  `pt-BR`, `pt-PT`.
- `expires_at`: от 30 минут до 24 часов. `consent_collection.terms_of_service = required` требует
  ссылку на Terms в публичных данных Dashboard. Есть `adaptive_pricing.enabled` на сессии и
  `integration_identifier`. Права ключа на создание сессии — `checkout_session_write`.
- Перед созданием сессии Stripe-инструмент просит решить вопрос налогов (Stripe Tax) — вне задачи:
  `AURAI-0013` шаг 4; сессии создаются без `automatic_tax`.

## Противоречия / поправки к шагу 001

1. Диспут: в шаге 001 — `created` → списание, `closed/won` → возврат. Точнее по деньгам —
   `funds_withdrawn` / `funds_reinstated` (inquiry ничего не снимает). Предложено в спеке.
2. Сигнал о диспуте: шаг 001 предлагает заметку в desk; у пользователя может быть несколько
   разговоров. Предложено — staff chat + страница в бэкофисе.
3. Неудачный возврат на карту (`refund.failed`, редко) в шаге 001 не назван — без него деньги
   ушли бы с баланса, а на карту не пришли. Добавлено в спеку.
