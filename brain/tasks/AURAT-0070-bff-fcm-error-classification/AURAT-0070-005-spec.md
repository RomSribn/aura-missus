# AURAT-0070-005 — спека: три класса ошибок FCM, повтор только по упавшим токенам

Дата: 2026-09-14 · slave-2 · `feature/AURAT-0070-bff-fcm-error-classification`
Статус: **на утверждение** · Тип: задача (без фичи) · Родитель по коду: `AURAT-0005`

---

## 1 · Классы ошибок

Новый файл `src/modules/delivery/fcm-errors.ts`: чистая функция
`classifyFcmFailure(code: string | undefined): 'stale' | 'config' | 'transient'`
и таблица кодов. Коды сверены с `firebase-admin` 13.10.0 (`004-context`).

| Класс | Коды | Что делаем |
|---|---|---|
| **stale** — мёртвый токен | `messaging/registration-token-not-registered`, `messaging/invalid-registration-token`, `messaging/invalid-argument` | удалить токен, не повторять; `log` со счётчиками |
| **config** — настройка, авторизация, запрос | `messaging/third-party-auth-error`, `messaging/authentication-error`, `messaging/mismatched-credential`, `messaging/invalid-package-name`, `messaging/invalid-payload`, `messaging/invalid-data-payload-key`, `messaging/payload-size-limit-exceeded`, `messaging/invalid-options`, `messaging/invalid-recipient` | не удалять, не повторять; `error` со счётчиками |
| **transient** — временная | `messaging/internal-error`, `messaging/server-unavailable`, `messaging/message-rate-exceeded`, `messaging/device-message-rate-exceeded`, `messaging/topics-message-rate-exceeded`, `messaging/unknown-error`, `app/network-error`, `app/network-timeout` — **и любой код не из таблицы, включая отсутствие кода** | повторить по этому токену; `warn` со счётчиками |

Почему так:

- `invalid-argument` остаётся мёртвым токеном, как сейчас и как советует
  Firebase: FCM v1 отдаёт этот код на токен неверного формата. Payload у нас
  постоянный и покрыт тестом.
- `mismatched-credential` не удаляем: SDK сводит в него и «токен из другого
  проекта», и «у сервисного аккаунта нет прав». Различить нельзя, значит
  токены не трогаем.
- Неизвестный код повторяем. Новый код не должен молча терять пинг. Повторов
  не больше трёх, код виден в логе, и после этого его можно внести в таблицу.
- `app/invalid-credential` (не удалось получить OAuth-токен Google) тоже идёт
  по умолчанию в повтор: причиной бывает и сеть, и неверный ключ, и по коду
  их не различить.

## 2 · Повтор только по упавшим токенам

Через данные задачи, без новых задач в очереди.

- `FcmFanoutJobData` (`src/jobs/queues.ts`) получает необязательное
  `tokens?: string[]`. Без него шлём на все устройства пользователя (первая
  попытка). С ним — только на эти токены.
- `FcmSender.sendNewMessagePing(data)` больше не бросает исключение на сбоях,
  а возвращает `{ retryTokens: string[] }` — токены с временной ошибкой.
- `FcmFanoutProcessor` делает только учёт повтора: если `retryTokens` не пуст,
  вызывает `job.updateData({ ...job.data, tokens: retryTokens })` и бросает
  `Error('FCM delivery incomplete: N token(s) to retry')`. BullMQ повторяет
  задачу с суженным списком. Настройки очереди те же: `attempts: 3`,
  экспоненциальная пауза от 2 с.
- При повторе список `tokens` пересекается с текущими устройствами
  пользователя. Токен, который за это время удалили или который перерегистрировал
  другой пользователь, повторно не получает пинг. Если пересечение пустое,
  отправки нет, задача завершается успешно.
- Сбой самого вызова `sendEachForMulticast` (исключение до ответов по токенам)
  по-прежнему пробрасывается и повторяет задачу целиком: в этом случае ничего
  не было отправлено.

Сценарий из `001` после правки: Android — успех, два iOS —
`third-party-auth-error` → одна попытка, `retryTokens` пуст, один `error` в
логе. Android получает пинг один раз.

**Ошибки config без временных — задача завершается успешно**, а не падает
через `UnrecoverableError`. Сигналом служит `error` в логе. В наборе failed
очереди остаются только задачи, у которых после всех повторов не прошли
временные ошибки. Иначе, пока ключа APNs нет, туда падала бы задача на каждое
сообщение, и настоящие сбои сети в этом списке терялись бы. См. **Q1**.

## 3 · Логи

Одна запись на класс за попытку и только если в этом классе есть сбои:

```
error  { failures: [{ code: 'messaging/third-party-auth-error', platform: 'ios', count: 2 }] }
       'FCM rejected delivery: configuration or credentials'
warn   { failures: [...] }  'FCM delivery incomplete, failed tokens will be retried'
log    { failures: [...] }  'FCM tokens pruned'
```

- Без токенов, без `userId`, без `advisorId`: только код, платформа, число.
- Платформа: значение из `DeviceToken.platform`; `null` → `'unknown'`.
- Нет кода в ошибке → `code: 'unknown'` (и класс transient).

## 4 · Репозиторий устройств

`DevicesRepository.listTokens(userId): string[]` → `listDevices(userId):
DeviceTokenRecord[]` (токен + платформа). Интерфейс `DeviceTokenRecord` уже
объявлен и сейчас не используется. `PrismaDevicesRepository` выбирает
`token` и `platform`. У `listTokens` других вызовов нет, метод удаляется.
Миграции нет.

## 5 · Тесты (юнит, без Redis/FCM)

`fcm-errors.spec.ts`:
- каждый код из таблицы → свой класс; неизвестный код и `undefined` → transient.

`fcm.sender.spec.ts` (существующие 4 теста адаптируются, поведение
«удалить мёртвый» и «payload без содержимого» сохраняется):
- все три кода stale → удаление, `retryTokens` пуст;
- Android успех + 2 iOS `third-party-auth-error` → без удаления, `retryTokens`
  пуст, один `error` с `{ code, platform: 'ios', count: 2 }`;
- смешанный ответ stale + config + transient → удалён только stale, в
  `retryTokens` только transient;
- `data.tokens` задан → отправка только на пересечение с устройствами
  пользователя; пустое пересечение → нет вызова FCM;
- ни одна запись лога не содержит строку токена;
- платформа `null` → `'unknown'` в логе.

`src/jobs/fcm-fanout.processor.spec.ts` (новый):
- `retryTokens` не пуст → `updateData` с `tokens` и исключение;
- пуст → без `updateData`, без исключения.

## 6 · Что не меняется

- Payload пинга (data-only, решение 3 `AURAT-0005`), WS-ветка, `DeliveryService`.
- Настройки очереди `fcm-fanout`.
- Ключ APNs в Firebase (владелец) и повтор регистрации токена в приложении
  (`AURAT-0052`).

## 7 · Проверки

**В слоте:** `npm run lint`, `npm run typecheck`, `npx jest`.

**После мёржа (= деплой в `development`, `AURAS-0004`), пока ключа APNs нет:**
отправить сообщение пользователю с iOS-токеном. Ожидается:

1. в логе одна запись `error` с `messaging/third-party-auth-error` / `ios`,
   без `warn` о повторе;
2. в `bull:fcm-fanout` не прибавилось failed;
3. Android того же пользователя получает пинг один раз.

Риск: точный код на отсутствующий ключ заранее не наблюдали (`dryRun` не
доходит до APNs). Если придёт код вне таблицы, будет три `warn` с этим кодом.
Это видно в логе, и таблица правится одной строкой в той же задаче.

После загрузки ключа владельцем пуш доходит до iPhone, ошибок в логе нет.

---

## Вопрос к владельцу

**Q1 · Ошибка настройки: задача завершается успешно или падает без повторов?**
**Рекомендую: успешно.** Отказ зафиксирован `error` в логе. Если задача падает
через `UnrecoverableError`, в failed очереди, пока нет ключа APNs, копится
по задаче на каждое сообщение. Альтернатива: падать без повторов, чтобы
failed-счётчик очереди тоже показывал проблему настройки.
