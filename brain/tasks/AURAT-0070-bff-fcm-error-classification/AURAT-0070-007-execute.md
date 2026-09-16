# AURAT-0070-007 — исполнение

Дата: 2026-09-15 · slave-2 · `feature/AURAT-0070-bff-fcm-error-classification`
Статус: **сделано, не закоммичено — на просмотр владельцу**

## Файлы (`aura-bff`)

| Файл | Что |
|---|---|
| `src/modules/delivery/fcm-errors.ts` (новый) | `classifyFcmFailure(code)` → `stale` / `config` / `transient`; таблица кодов из спеки, всё незнакомое и отсутствие кода → `transient` |
| `src/modules/delivery/fcm.sender.ts` | исключение на сбоях токенов больше не бросается; делит ответы по классам, удаляет `stale`, `error` на `config`, `warn` на `transient`, возвращает `{ retryTokens }`; при повторе шлёт только на пересечение `data.tokens` с текущими устройствами пользователя |
| `src/jobs/fcm-fanout.processor.ts` | учёт повтора: если `retryTokens` не пуст — `job.updateData({ ...data, tokens })` и `throw` |
| `src/jobs/queues.ts` | `FcmFanoutJobData.tokens?: string[]` + комментарий |
| `src/modules/delivery/devices.repository.ts`, `prisma-devices.repository.ts` | `listTokens` → `listDevices` (токен + платформа, используется `DeviceTokenRecord`, который раньше был объявлен и нигде не использовался); `listTokens` удалён |
| `src/modules/delivery/fcm-errors.spec.ts` (новый) | каждый код таблицы, неизвестный код, `undefined` |
| `src/modules/delivery/fcm.sender.spec.ts` | 11 тестов: payload, нет устройств, три кода `stale`, сценарий из `001` (Android ок + 2 iOS `third-party-auth-error` → один `error`, без повтора), смешанный ответ, ошибка без кода, платформа `null`, два случая повтора по `tokens`, в логе нет токенов и `userId`, сбой всего вызова пробрасывается |
| `src/jobs/fcm-fanout.processor.spec.ts` (новый) | `updateData` + исключение / без них |

Q1 = A: одни ошибки настройки → задача `completed`.

## Решения по ходу

- **Текст `warn`**: `'FCM delivery incomplete: transient failures'` вместо
  «…will be retried» из спеки. Sender не знает номер попытки, и на третьей
  попытке «will be retried» было бы неправдой.
- Логи — `nestjs-pino`: `logger.error({ failures }, msg)` разбирается так же,
  как уже используемый `warn({…}, msg)` (проверено по `nestjs-pino` 4.6.1).
  Форма записи: `failures: [{ code, platform, count }]`.
- При повторе список токенов лежит в данных задачи в Redis (`bull:fcm-fanout`),
  в логи не попадает.
- В тестах логгер перехватывается через `jest.spyOn(Logger.prototype, …)` с
  `restoreAllMocks` после каждого теста. В проекте такого приёма раньше не
  было, но `clearMocks: true` сбрасывает только вызовы, а не шпионов.
- Prettier применён к изменённым файлам. Весь `src` prettier-чистым не
  является (47 файлов с замечаниями, не мои) — не трогал.

## Проверки в слоте

- `npm run typecheck` — exit 0
- `npm run lint` — exit 0
- `npx jest` — 66 наборов, 887 тестов, все зелёные (до prettier); после
  prettier перепрогнаны `fcm.sender` и `fcm-fanout.processor` — 13/13

## Открыто

- Точный код FCM на отсутствующий ключ APNs вживую не наблюдали. Ожидается
  `messaging/third-party-auth-error`. Если придёт другой код, в логе будет
  три `warn` с ним, таблица правится одной строкой.
- Для проверки после мёржа dev BFF должен быть подключён к аккаунту
  «Aura Dev» в production-Chatwoot (`AURAT-0071-008`); отсюда не видно,
  сделано ли.
- Замечено по ходу (не эта задача, для `aura-app-manor`): `AURAS-0004` и
  `AURAD-0015` не отражают окружение `production` (`bff.aura-app.cc` снова
  работает, `main` = `develop` = `1fa9fbe`) и то, что Chatwoot делит
  production-`aura-redis` с production BFF — ждут `AURAD-0016`.

## Дальше

Просмотр владельцем в IDE → коммит в ветку → вопрос о мёрже в `develop`.
