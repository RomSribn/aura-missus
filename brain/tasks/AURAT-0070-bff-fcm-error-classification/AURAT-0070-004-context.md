# AURAT-0070-004 — контекст

Дата: 2026-09-14 · slave-2 · `feature/AURAT-0070-bff-fcm-error-classification`

## Код (`aura-bff` @ `1fa9fbe`)

| Место | Что там |
|---|---|
| `src/modules/delivery/fcm.sender.ts` | `STALE_TOKEN_CODES` из трёх кодов; остальные сбои → `warn` с числом и `throw` → BullMQ повторяет всю задачу |
| `src/jobs/fcm-fanout.processor.ts` | одна строка: `sendNewMessagePing(job.data)` |
| `src/jobs/queues.ts` | `fcmFanoutQueueOptions`: `attempts: 3`, exp от 2 с; `FcmFanoutJobData { userId, advisorId }` |
| `src/modules/delivery/delivery.service.ts` | ставит задачу `ping` после WS |
| `src/modules/delivery/devices.repository.ts` | `listTokens(userId): string[]`; интерфейс `DeviceTokenRecord { token, platform }` объявлен, но нигде не используется |
| `prisma/schema.prisma` `DeviceToken` | `platform String?`; контракт регистрации — `ios` / `android`, необязательное поле |
| `src/modules/delivery/fcm.sender.spec.ts` | 4 теста: payload без содержимого, нет устройств, удаление мёртвого, повтор на `internal-error` |

`listTokens` вызывает только `FcmSender`. Логгер — `nestjs-pino`, в проекте
уже пишут `logger.warn({ поля }, 'сообщение')`. `UnrecoverableError` и
`job.updateData` в проекте не используются.

История: `STALE_TOKEN_CODES` (вместе с `invalid-argument`) заведён в `8e4578c`
(`AURAT-0005`) и с тех пор не менялся. В спеке `AURAT-0005` о повторе
написано одно: «`fcm-fanout` — 3× exp backoff», а удалять токен — на
`unregistered`.

## `firebase-admin` 13.10.0 — откуда берутся коды

- `sendEachForMulticast` → `sendEach` → `Promise.allSettled` по токенам. Любой
  отказ одного токена превращается в `{ success: false, error }`, весь вызов
  не падает.
- HTTP-ответ FCM с JSON → `FirebaseMessagingError.fromServerError`, коды
  `messaging/*`. Не-JSON: 400 → `invalid-argument`, 401/403 →
  `authentication-error`, 500 → `internal-error`, 503 → `server-unavailable`,
  прочее → `unknown-error`.
- Ошибки, не являющиеся HTTP-ответом (сеть, получение OAuth-токена), тоже
  приходят в `error` токена, но со своим кодом: `app/network-error`,
  `app/network-timeout`, `app/invalid-credential`.
- Серверные коды FCM v1 и что из них делает SDK:
  `UNREGISTERED`/`NOT_FOUND` → `registration-token-not-registered`;
  `INVALID_ARGUMENT` → `invalid-argument`;
  `THIRD_PARTY_AUTH_ERROR`/`APNS_AUTH_ERROR`/`UNAUTHENTICATED` →
  `third-party-auth-error`;
  `SENDER_ID_MISMATCH`/`PERMISSION_DENIED` → `mismatched-credential`;
  `QUOTA_EXCEEDED`/`RESOURCE_EXHAUSTED` → `message-rate-exceeded`;
  `UNAVAILABLE` → `server-unavailable`; `INTERNAL` → `internal-error`;
  `UNSPECIFIED_ERROR` → `unknown-error`.
- Кода `invalid-apns-credentials` из `001` в этой версии нет: отсутствующий или
  неверный ключ APNs приходит как `messaging/third-party-auth-error`.

Полный список клиентских кодов рассылки: `invalid-argument`,
`invalid-recipient`, `invalid-payload`, `invalid-data-payload-key`,
`payload-size-limit-exceeded`, `invalid-options`,
`invalid-registration-token`, `registration-token-not-registered`,
`mismatched-credential`, `invalid-package-name`,
`device-message-rate-exceeded`, `topics-message-rate-exceeded`,
`message-rate-exceeded`, `third-party-auth-error`, `authentication-error`,
`server-unavailable`, `internal-error`, `unknown-error` (+ `too-many-topics`,
к рассылке по токенам не относится).

## BullMQ 5.80.1

- `job.updateData(data)` сохраняет новые данные задачи; повтор после `throw`
  получает их. Этим можно сузить повтор до упавших токенов без новых задач.
- `UnrecoverableError` — упасть без повторов.

## Противоречий нет

`001` и код совпадают. Одно уточнение к `001`: пункт про
`invalid-apns-credentials` — см. выше.

## Дальше

`005-spec`.
