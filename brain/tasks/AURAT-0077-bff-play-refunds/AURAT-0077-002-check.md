# AURAT-0077-002 — Что уже есть в brain и в коде

Дата: 2026-09-18
Слот: `slave-2`, ветка `feature/AURAT-0077-bff-play-refunds`
(`aura-bff` от `develop` @ `d3c8ec8`, brain от `089c6a6`).

## Главное: у задачи есть предшественник — `AURAT-0030`

`brain/tasks/AURAT-0030-bff-play-refund-subscriber/` — **та же задача**,
заведена 2026-08-19, два файла:

- `001-initial` — полный скоуп (RTDN → компенсирующая запись → идемпотентность
  по токену → sweep по Voided Purchases), три открытых вопроса, список «не в
  скоупе». Скоуп верен целиком и переиспользуется здесь.
- `002-manual-until-volume` (2026-08-27) — решение владельца «логику рефаунда
  будем делать руками, но написать задачу на реализацию нормальную». Там же
  выписана точная ручная SQL-процедура и **срочная развилка**: тип записи под
  возврат магазина надо добавить в enum **до первого возврата**, потому что
  триггер `ledger_entries_append_only` запрещает `UPDATE` — тип фиксируется
  навсегда в момент вставки.

`AURAT-0077` — это не новая задача, а **включение** `AURAT-0030` по его же
триггеру: покупки пошли на проде (2026-09-17), ручной путь перестаёт быть
достаточным. Новых ID не выпускаем; работаем под `AURAT-0077`, а `AURAT-0030`
закрываем ссылкой.

## Вопрос про отрицательный баланс уже решён

`AURAD-0010` (принято владельцем 2026-08-17), пункт 5 решения и раздел
«Refunds go negative»:

> баланс **может уйти ниже нуля** и **остаётся** там до следующего пополнения;
> баланс **никогда не зажимается**, потому что зажим ломает `balance = Σ ledger`
> — инвариант, который `AURAT-0010` проверял на устройстве; доставленные сессии
> назад не отбираются.

То есть в спеке это не открытый вопрос с вариантами, а **подтверждение
ратифицированного решения** — см. `005-spec` §Вопросы владельцу.

## Что уже построено в `aura-bff` (`AURAT-0027`)

- `POST /v1/wallet/top-ups/google` → `PlayTopUpService.redeem` →
  `WalletsRepository.creditPlayPurchase`.
- `play_purchases`: `purchaseToken` **unique**, `walletId`, `productId`,
  `creditedMinor`, `orderId`, `ledgerEntryId` **unique** (1:1 с зачислением).
- Форма денежной транзакции: `$transaction` → `SELECT "balanceMinor" … FOR
  UPDATE` → `ledgerEntry.create` → `wallet.update`.
- Триггер `ledger_entries_append_only` `BEFORE UPDATE OR DELETE` — `INSERT`
  разрешён.
- `LedgerEntryType` = `TOPUP | SESSION_CHARGE | SESSION_REFUND` — **нет типа
  под возврат магазина**.
- `GooglePlayVerifier` — JWT `google-auth-library`, scope
  `https://www.googleapis.com/auth/androidpublisher`, ручной `fetch` с
  таймаутом 10 с, строгий разбор через Zod, отказ в безопасную сторону.
- Планировщики BullMQ: `ReconciliationScheduler` (`upsertJobScheduler`,
  `every: 60_000`), `QueueRetentionScheduler`, `AccountErasureScheduler` —
  готовая форма для периодического прохода.
- `grep -i "pubsub\|RTDN\|voided\|revoke"` по `src/` — пусто. Обратного хода
  нет, как и сказано в заглушке.

## Состояние вокруг

- `AURAF-0010-006` — единственный `✗` в фиче, кроме iOS. Закрывается этой
  задачей.
- `TECH-DEBT #23` — ровно про это; закрывается или переписывается.
- `AURAT-0076-003` (2026-09-17) — Play Console заполнен, ждём ответ Google.
- `GET /v1/wallet` отдаёт `{ balanceMinor, currency, purchaseAccountId }`.
  **Эндпоинта истории кошелька в сервисе нет вообще** — проверено по
  `wallet.controller.ts` и `contracts/wallet.ts`.
