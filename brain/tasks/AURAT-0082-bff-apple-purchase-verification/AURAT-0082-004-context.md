# AURAT-0082-004 — Контекст

Дата: 2026-09-30

## Источники

- `AURAD-0017` (accepted), `AURAD-0010` (пять правил рельса), `AURAT-0082-001`.
- Код рельса Google (ground truth, `develop` @ `5453ec5`):
  `wallet/play-top-up.service.ts`, `wallet/play-tiers.ts`,
  `wallet/play-refund.service.ts`, `wallet/prisma-wallets.repository.ts`,
  `play/*` (порт, верификатор, фейк, RTDN-контроллер), `jobs/play-refund.*`,
  `config/env.schema.ts` (обязательность в production + BILLING_ENABLED),
  `prisma/schema.prisma` (`PlayPurchase`, `LedgerEntryType.STORE_REFUND`).
- `@aura/contracts` **v0.20.0** — поставлен в scratchpad и прочитан по `dist/index.d.ts`:
  `AppleTopUpRequest {transactionId: string, productId: string}`,
  `AppleTopUpResponse {entryId, balanceMinor, currency:'USD', creditedMinor, replayed}`.
- `AURAT-0081` в missus `origin/master` — только `001-initial`; шаги приложения в
  мозг не запушены. Опираюсь на слова владельца (002).

## Библиотека: `@apple/app-store-server-library` **3.1.0** (последняя), прочитана по установленному `dist/*.d.ts` и `*.js`

- `new AppStoreServerAPIClient(signingKey, keyId, issuerId, bundleId, environment)`;
  `getTransactionInfo(transactionId): Promise<{signedTransactionInfo?: string}>`
  → `GET /inApps/v1/transactions/{id}`. Ошибки — `APIException {httpStatusCode,
  apiError}`; `APIError.TRANSACTION_ID_NOT_FOUND = 4040010`,
  `INVALID_TRANSACTION_ID = 4000006`. Токен (ES256, `bid`) клиент делает сам.
- HTTP через `node-fetch` v2 **без таймаута**; `makeFetchRequest` — `protected`,
  можно переопределить в подклассе и добавить `signal`.
- `new SignedDataVerifier(rootCertsDER[], enableOnlineChecks, environment,
  bundleId, appAppleId?)` — **один на окружение**; для `Production`
  `appAppleId` обязателен (кидает в конструкторе). `verifyAndDecodeTransaction`
  проверяет цепочку до корня, `bundleId` **и** `environment ==` своему.
  `verifyAndDecodeNotification` — то же для уведомления (+ `appAppleId` в проде).
  Ошибки — `VerificationException {status}`.
- **Корневые сертификаты библиотека не везёт** — их передаём сами.
  `AppleRootCA-G3.cer` скачан с apple.com: CN=Apple Root CA - G3, до 2039-04-30,
  SHA-256 `63:34:3A:BF:…:3E:91:79` — совпадает с опубликованным отпечатком.
- Модель транзакции: `transactionId, originalTransactionId, bundleId, productId,
  type ('Consumable'…), appAccountToken, revocationDate, revocationReason,
  environment ('Production'|'Sandbox'), price, currency, storefront`.
- Типы уведомлений V2 включают `REFUND`, `REFUND_REVERSED`, `REFUND_DECLINED`,
  `CONSUMPTION_REQUEST`, `REVOKE`, `TEST`; транзакция лежит в
  `data.signedTransactionInfo`, окружение — в `data.environment`.
- Зависимости библиотеки: `jsonwebtoken`, `jsrsasign`, `node-fetch@2`,
  `base64url`, и `@types/node@^25` в `dependencies` (проверить, что не ломает
  наш typecheck на `@types/node@22`).

## Находки / расхождения

- **Коды отказа.** `001` пишет 409 на чужой `appAccountToken`; рельс Google
  отвечает на то же **403**. Приложение не финиширует покупку на любом не-2xx,
  так что для него разницы нет — предлагаю коды Google (единообразие).
- `REFUND_REVERSED` у Google аналога нет: `LedgerEntryType` его не умеет, нужен
  новый тип (enum неизменяем для строки — выбрать имя один раз).
- Рельс Google имеет **часовой добор** (Voided Purchases API) за push'ем. Apple
  сама повторяет V2-уведомление при не-2xx; добор есть через Notification
  History API. Решение владельца — делать ли сейчас.
- Прод-хост отвечает `401` на этот ключ до первой продажи (`001`) — считать
  промахом наравне с `404`.
- Сендбокс-покупка на **проде** BFF тоже начислится (порядок Apple, AURAD-0017).
  Это даёт деньги тестировщикам TestFlight, если сборка смотрит на прод;
  сборка 2 смотрит на dev. Предлагаю писать окружение в строку покупки.
