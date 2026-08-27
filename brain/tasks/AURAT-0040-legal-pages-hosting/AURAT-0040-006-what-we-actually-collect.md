# AURAT-0040-006 — Что сервис собирает на самом деле

Дата: 2026-08-27
Источник: `prisma/schema.prisma` (375 строк) и код на `develop` @ `fc62f29`;
половина приложения — `aura-app-manor/project/slave-0/master`.
Это пункт 3 задачи из `001` — фактура, из которой пишется политика.

## Таблицы

| Таблица | Поля про человека |
|---|---|
| `users` | `firebaseUid`, `phoneE164?`, `chatwootContactId?`, `chatwootSourceId?` |
| `device_tokens` | `token` (unique), `platform?` |
| `conversations` | `userId`, `advisorId`, `chatwootConversationId` |
| `messages` | `content`, `direction`, `chatwootMessageId`, `chatwootCreatedAt`, `idempotencyKey?` |
| `message_attachments` | `kind`, `contentType`, `fileName`, `fileSizeBytes?`, `width?`, `height?`, `sourcePath` |
| `wallets` | `balanceMinor`, `purchaseAccountId` |
| `ledger_entries` | `type`, `amountMinor`, `balanceAfterMinor`, `idempotencyKey` |
| `play_purchases` | `purchaseToken` (unique), `orderId?`, `productId`, `creditedMinor` |
| `sessions` | время, минуты, цена, возвраты |

`advisors` — каталог, не пользовательские данные.

**Колонки имени нет.** **Колонки даты рождения нет.** **Колонки IP нет.**
Имя чаттера не хранится нигде: у `Message` нет колонки отправителя
(`AURAD-0001` — персона, не человек за ней).

## Что шлёт приложение

Ровно две вещи сверх содержимого переписки:

- `PUT /v1/devices/:token` с телом `{ platform }` — токен FCM и строка платформы.
  Больше в этом запросе нет ничего (`features/push/api/devices-api.ts:10`).
- Телефон — и тот уходит не нам, а Firebase: вход по одноразовому коду.

Зависимости приложения по этой части: `@react-native-firebase/app`, `/auth`,
`/messaging`. **Ни Crashlytics, ни Sentry, ни analytics, ни device-info, ни
localize.**

## Три поправки к перечню в `001`

1. **«вложения — у нас в `message_attachments`» — неточно.** Байты вложения не
   хранятся **никогда** (`AURAD-0011`): только метаданные плюс `sourcePath` —
   путь к объекту стойки, который резолвит один лишь адаптер. BFF отдаёт байты
   устройству потоком, копии не оставляя. Тексты сообщений — да, наши.
2. **`purchaseAccountId` — не данные Google.** Он на `wallets`, минтится
   Postgres'ом (`gen_random_uuid()`), PII не несёт и существует затем, чтобы
   токен одного человека не зачли другому. Данные Google — `purchaseToken` и
   `orderId` на `play_purchases`.
3. **`users.birthDate` не существует.** `AURAT-0039` не начата и заблокирована
   решениями владельца. Дата рождения — предмет будущего, не настоящего.

## Кому уходит наружу

| Получатель | Что | Юрисдикция |
|---|---|---|
| Google (Firebase Auth) | Номер телефона — им же и проверяется | Google |
| Google (FCM) | Токен устройства, текст пуша | Google |
| Google Play | `purchaseToken` при проверке покупки | Google |
| Cloudflare R2 | Ночные дампы **обеих** баз; вложения стойки | Бакеты **EU-юрисдикции** |
| Hetzner | Хост | Хельсинки, **ЕС** |
| Resend | Транзакционная почта стойки | EU-регион; адресаты — **чаттеры** |
| Netlify | Хостинг юридических страниц | — (появилось 2026-08-27) |
| *(будущее)* RapidAPI | Дата рождения, если `AURAT-0039` доедет | **не проверена** (`AURAT-0039-003`) |

**Chatwoot — не третья сторона.** Своя установка на том же хосте, своя база на
том же сервере Postgres (`AURAS-0004`). «Отдельная копия в Chatwoot» из `001`
нашу инфраструктуру не покидает.

## Что физически нельзя удалить

`ledger_entries` защищён триггером `ledger_entries_append_only`
(`prisma/migrations/20260817120000_play_purchases/migration.sql:68`), который
поднимает `RAISE EXCEPTION` на `UPDATE` и на `DELETE`: «a correction is a new,
compensating entry». Денежный след неудаляем **по устройству базы**, а не по
политике хранения.

## Что удалить можно

Единственный `@Delete` во всём сервисе — `DELETE /v1/devices/:token`
(`modules/delivery/devices.controller.ts:40`), отзыв push-токена при выходе.
**Ни удаления аккаунта, ни удаления переписки, ни удаления вложений нет.**
