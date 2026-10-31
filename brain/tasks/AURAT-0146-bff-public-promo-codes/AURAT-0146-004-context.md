# AURAT-0146-004 — context

Дата: 2026-10-31

## Источники
- `AURAI-0009` §1–§2, §8 (high, решения владельца); `AURAF-0022` строки 001–002; `AURAT-0143` (модель).
- Код `aura-bff` `develop` @ `af00d64` (ground truth): `src/modules/promo-codes/*`,
  `src/modules/backoffice/{backoffice-promo-codes.controller.ts,views/promo-codes.view.ts,http/backoffice.forms.ts}`,
  `prisma/schema.prisma:381-457`, `src/modules/sessions/{session-policy.ts,sessions.service.ts}`,
  `src/config/env.schema.ts:298`.
- `aura-contracts` `main` @ `9848a02` (v0.25.0) `src/promo.ts`.
- Клиенты (manor-клоны): app `src/features/promo-code/*`, web `src/features/redeem-promo-code/*`.

## Ключевые находки
1. `normalisePromoCode` пропускает только 8 символов алфавита без 0/O/1/I/L — `WINTER5` сейчас
   получает `promo_code_not_found` до базы. Контракт пускает до 64 символов; **оба клиента шлют
   ввод как есть** (только `autoCapitalize`/`maxLength=64`) — vanity-код пройдёт без их релиза.
2. Одноразовость = `PromoRedemption.codeId @unique` + 1:1 связь `PromoCode.redemption`. Её снятие
   ломает Prisma-связь: станет `redemptions PromoRedemption[]`; затронуты `findBatch`, `totals`,
   `disableCode`, `disableBatch`, `promoCodeStatus`.
3. Частичный unique не может ссылаться на `promo_batches.kind` (другая таблица) → вид копируется в
   строку погашения (как уже скопирован `batchId` «чтобы правило было ограничением»). Прецедент
   частичных unique в сырой SQL есть (`sessions_one_active_per_conversation`).
4. **Расхождение с `AURAI-0009`:** ключ проводки `promo:<codeId>` менять **не нужно** — unique в
   `ledger_entries` это `(walletId, idempotencyKey)`, то есть ключ уже уникален на кошелёк.
5. Отключение: `disableBatch`/`disableCode` пропускают коды с погашением («погашенный не отзывается»)
   — для публичного кода с первым же погашением его стало бы невозможно отключить. Надо разделить.
6. Повтор под замком кошелька: найденное погашение той же партии сейчас = `campaign_used`; для
   публичного кода (одна партия = один код) это должен быть `replayed`.
7. Самая дешёвая сессия считается из живых данных: `min(advisors.priceMinorPerMinute WHERE active)`
   × `min(SESSION_BLOCK_MINUTES)` с −50% (`firstSessionDiscount`). Дефолт 10 мин, $2.20 → $11.00.
   Прод-значения в слоте недоступны — порог считается на лету, поэтому хардкод не нужен.
8. Отказы клиентов: app `refusal-copy.ts`, web locales — понимают все 6 кодов v0.25.0; для
   публичного кода остаются только `not_found`/`expired`/`disabled`, новых не нужно.
9. Сводка бэкофиса («выпущено = сумма × количество», «активно = непогашенные») для публичного кода
   неверна — нужен отдельный учёт.
10. Пересечение с `AURAT-0147`: вкладки бэкофиса (`layout.view.ts`) эта задача **не трогает** —
    всё внутри вкладки «Промокоды». Порог «самая дешёвая сессия» живёт в модуле sessions; когда
    0147 сделает скидки данными, порог надо будет пересчитать там же (скидка кампании > 50%
    удешевит сессию).
