# AURAT-0082-005 — Спецификация

Дата: 2026-09-30
Тип: **задача** (фичу не заводим — это `AURAF-0010-008`, BE-колонка, по
`AURAD-0017`). Статус: **draft**, ждёт одобрения.

Форма — зеркало рельса Google (`AURAT-0027` + `AURAT-0077`). Новых решений о
деньгах нет: всё, что ниже, уже сказано в `AURAD-0010` / `AURAD-0017`; здесь —
как это ложится на код.

## 0. Зависимости

- `@aura/contracts` → `github:RomSribn/aura-contracts#v0.20.0`; в
  `src/contracts/wallet.ts` ре-экспорт `AppleTopUpRequest`/`AppleTopUpResponse`,
  в `contracts/openapi.ts` — их OpenAPI-схемы (как у Google), в
  `contracts/wallet.spec.ts` — пин формы.
- `@apple/app-store-server-library` **3.1.0** (официальная, Apple). Её API
  сверен по установленной версии (`004`).
- Корень Apple **Root CA - G3** зашиваем в код (публичный сертификат, PEM-строкой
  в `.ts`, чтобы не трогать сборку ассетов), с комментарием про отпечаток
  SHA-256 и срок (2039-04-30).

## 1. Конфигурация (`env.schema.ts`)

| Переменная | Значение для нас |
|---|---|
| `APPLE_IAP_KEY_ID` | `CSNPA77W6Y` |
| `APPLE_IAP_ISSUER_ID` | `9bc0ba73-…-ecfedfebab2a` |
| `APPLE_IAP_PRIVATE_KEY` | содержимое `.p8` (тот же `pemPrivateKey()`, проверка разбора на старте) |
| `APPLE_BUNDLE_ID` | `cc.silvermind.aura` |
| `APPLE_APP_APPLE_ID` | `6813629245` (нужен верификатору прод-подписей) |

Все пять — **вместе или никак**; в `production` при `BILLING_ENABLED=true` —
обязательны (та же refinement, что у `GOOGLE_PLAY_*`). Не настроено вне прода →
`POST /wallet/top-ups/apple` отвечает `503`, вебхук — `401`. **Фейкового
верификатора с dev-токенами не делаю** (в отличие от Play): на dev будет
настоящий песочный ключ, а отказы покрыты юнит-тестами — меньше кода на денежном
пути.

## 2. Адаптер `src/modules/apple/` (Apple не выходит за его пределы — правило 1)

- `apple-transaction.port.ts` — `AppleTransactionVerifier.verify(transactionId)
  → VerifiedAppleTransaction | null`, в наших словах: `transactionId,
  productId, appAccountToken | null, consumable: boolean, revoked: boolean,
  environment: 'production' | 'sandbox'`.
- `app-store-server.client.ts` — подкласс `AppStoreServerAPIClient`, который
  переопределяет `protected makeFetchRequest` и добавляет таймаут (у библиотеки
  его нет; значение — как у клиента Play).
- `app-store.verifier.ts` — два клиента + два `SignedDataVerifier` (прод,
  песочница). Порядок:
  1. прод `getTransactionInfo`; **`401`, `404`/`4040010`, `4000006` → промах**
     (401 — ловушка из `001`, пересмотреть после первой продажи);
  2. при промахе — песочница; там `404`/`4000006` → `null` (не наша покупка);
     `401` в песочнице и любая иная ошибка → исключение (500, приложение
     повторит, покупка не финиширована);
  3. `signedTransactionInfo` → `verifyAndDecodeTransaction` верификатором **того
     же** окружения (цепочка до корня, `bundleId`, `environment`), online-проверки
     (OCSP) включены. Не прошло → `null` + лог без тела;
  4. `transactionId` в ответе должен совпасть с запрошенным.
- `apple-notifications.controller.ts` — `POST /webhooks/apple`
  (`@Public`, `VERSION_NEUTRAL`, вне Swagger), тело `{signedPayload}`.
  Проверка подписи **до** того, как хоть что-то из тела принято на веру
  (`apple-notification.decoder.ts`: окружение берётся из непроверенного
  `data.environment` только чтобы выбрать верификатор; сам верификатор это же
  окружение и проверяет). Неверная подпись → `401`. `REFUND` /
  `REFUND_REVERSED` с проверенной транзакцией → задача в очередь `apple-refund`,
  `200`. Всё остальное (`TEST`, `CONSUMPTION_REQUEST`, `REFUND_DECLINED`, …) →
  `200` и забыть. Apple повторяет при не-2xx — падение Redis = повтор, не потеря.

## 3. Начисление — `wallet/apple-top-up.service.ts`

`POST /v1/wallet/top-ups/apple`, `200`, тело `AppleTopUpRequest`, ответ
`AppleTopUpResponse`. Порядок как у Google:

| # | Проверка | Ответ |
|---|---|---|
| 1 | `productId` в таблице тиров (сумма — оттуда) | 400, база не тронута, Apple не спрошена |
| 2 | `transactionId` уже выкуплен **этим** кошельком | 200 `replayed: true`, записей нет, Apple не спрошена |
| 2′ | …выкуплен **другим** кошельком | 409 |
| 3 | Apple не знает транзакцию / подпись не сошлась / не `cc.silvermind.aura` | 409 |
| 4 | Не `Consumable` или есть `revocationDate` | 409 |
| 5 | `productId` Apple ≠ `productId` запроса | 409 |
| 6 | `appAccountToken` отсутствует или ≠ `purchaseAccountId` (без учёта регистра — UUID) | **403** (как у Google; в `001` было 409 — приложению всё равно, оно не финиширует на любом не-2xx) |
| 7 | Всё сошлось | одна `TOPUP`-запись + строка `apple_purchases` в одной транзакции под блокировкой кошелька; гонка на уникальном `transactionId` → сходимся на победителе |

Ключ идемпотентности записи: `apple:<transactionId>` (id Apple — короткое
число, хэшировать незачем). `transactionId` и `appAccountToken` в логи не
пишутся — только id строки покупки и суммы.

**Таблица тиров одна на оба магазина**: `play-tiers.ts` → `top-up-tiers.ts`,
`PLAY_TOP_UP_TIERS` → `TOP_UP_TIERS`; Google-рельс переходит на неё же.

## 4. Схема — миграция `…_apple_purchases`

```
model ApplePurchase {                       // зеркало PlayPurchase
  id, transactionId @unique, productId, walletId,
  ledgerEntryId @unique,                    // кредит
  refundEntryId? @unique,                   // REFUND
  refundReversalEntryId? @unique,           // REFUND_REVERSED
  creditedMinor, environment ('Production'|'Sandbox'), createdAt
}
enum LedgerEntryType { …, STORE_REFUND_REVERSAL }
```

- `STORE_REFUND` переиспользуем — он про магазин вообще, не про Google.
- `STORE_REFUND_REVERSAL` — новый (положительная сумма = `creditedMinor`).
  Имя выбираем раз и навсегда: триггер append-only запрещает перетипизировать.
- `environment` пишем ради аудита: песочная покупка на прод-BFF начисляет
  настоящий баланс (порядок Apple из `AURAD-0017`), и это должно быть видно
  по строке.
- Ничего существующего не трогается; `play_purchases` без изменений.

## 5. Возвраты — `wallet/apple-refund.service.ts` + `jobs/apple-refund.processor.ts`

- `REFUND` → `debitAppleRefund`: под блокировкой кошелька, перечитать строку,
  если `refundEntryId` уже есть — `skipped`; иначе `STORE_REFUND` на
  `-creditedMinor`, ключ `apple-refund:<transactionId>`. Баланс может уйти в
  минус и не зажимается.
- `REFUND_REVERSED` → `creditAppleRefundReversal`: только если возврат был и
  отката ещё нет; `STORE_REFUND_REVERSAL` на `+creditedMinor`, ключ
  `apple-refund-reversed:<transactionId>`.
- Транзакция, которую мы не начисляли, → `skipped` (ничего не списываем).
- Повторный `REFUND` после отката — `skipped` с `warn` (одна пара на покупку;
  реальный случай не ожидается).
- Процессор тонкий: имя задачи → сервис. `jobId` = тип + `transactionId`, чтобы
  схлопнуть повторы Apple (настоящий барьер — уникальные ключи).

## 6. Тесты (чистые, без БД/Redis/Apple)

- `apple-top-up.service.spec` — все строки таблицы §3, гонка, реплей чужого.
- `app-store.verifier.spec` — прод-хит; прод 401/404/4000006 → песочница;
  песочница 404 → null; песочница 401/500 → throw; провал подписи → null;
  несовпадение `transactionId`. Клиенты и верификаторы подменяются.
- `apple-notification.decoder.spec` / `…controller.spec` — неверная подпись 401,
  `REFUND`/`REFUND_REVERSED` → очередь, прочие → 200 без очереди.
- `apple-refund.service.spec`, `apple-refund.processor.spec`.
- `env.schema.spec` — группа из пяти, обязательность в проде.
- `wallet.controller.spec` — `200`, а не `201`, как пинится у Google.
- Подпись и цепочку реальной Apple в юнит-тестах не гоняем — это прогон в маноре.

## 7. Документы

- `AURAF-0010-008` BE → ✓ после прогона; `TECH-DEBT.md` — строка «Apple-ветка
  не видела живой продажи в проде» (аналог #17) и, если решим не делать добор, —
  строка про него.
- `README.md` BFF — переменные `APPLE_*`, URL уведомлений.

## 8. После мёржа (манор/владелец, не слэйв)

1. Прописать `APPLE_*` на dev (ключ `.p8` из `~/.appstoreconnect/private_keys/`).
2. App Store Connect → App Information → **App Store Server Notifications**:
   Version 2, **Sandbox URL** → `https://<dev>/webhooks/apple`,
   **Production URL** → `https://<prod>/webhooks/apple` (прод — когда там будут
   переменные).
3. Первый прогон: владелец открывает TestFlight-сборку 2 → висящая
   `aura.topup.usd25` выкупается → +2500, строка `apple_purchases`
   (`environment = Sandbox`), покупка финиширована; повторный запуск —
   ничего нового.
4. Возврат в песочнице — через «Refund Request» в TestFlight/Settings; проверить
   `STORE_REFUND` и `balance = Σ ledger`.

## Решения, нужные от владельца

1. **Добор возвратов (backstop).** У Google есть часовой проход по Voided
   Purchases. Для Apple аналог — Notification History API (180 дней).
   **Рекомендую не делать в этой задаче**: Apple сама повторяет V2-уведомление
   при не-2xx (несколько раз в течение ~3 суток), а ручной добор всегда можно
   сделать запросом истории. Записать в `TECH-DEBT`. Если хочешь как у Google —
   +сервис, +планировщик, ~150 строк.
2. **Коды отказа** — как у Google (403 за чужой аккаунт), а не 409 из `001`.
   Рекомендую так.
