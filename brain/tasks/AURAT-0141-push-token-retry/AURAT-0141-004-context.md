# AURAT-0141-004 — context

## Данные прода (2026-10-25, владелец запускал запросы; цифры без PII)

- `device_tokens`: 257, все `android`; iOS — 0.
- `users` с 2026-10-15: 351; без токена — 111. Из них имя + чат: 74 (у пользователей с токеном — 205).
- Пользователи без токена, но с чатом (за всё время): 90; из них **писали советнику после
  2026-10-21 15:38 UTC (старт контейнера BFF = начало логов) — 20**; удалённых аккаунтов — 0.
- Логи BFF с 2026-10-21 15:38: `PUT /v1/devices` — 370, все 204; `DELETE` — 4 (выход), 204;
  `FCM tokens pruned` — 7 (все `registration-token-not-registered`, android).
- User-agent: почти весь трафик `okhttp` (Android-приложение); веб и iOS — единицы.
- Вывод: ≥ 9 активных Android-пользователей с работающим приложением, у которых `PUT` либо не
  отправлялся, либо токен исчез без следа в логах.

## Код (ground truth)

- `src/features/push/model/push-registration.ts`: на `onAuthStateChanged(user)` —
  `await notifee.requestPermission()` → `getToken()` → `registerDevice` (PUT). Любая ошибка —
  `catch {}`. Повтор — только `onTokenRefresh` и следующий `onAuthStateChanged` (новый процесс / вход).
- notifee `requestPermission` на Android 13+ (`NotifeeApiModule.java`): один глобальный callback
  (`setRequestPermissionCallback`) и `activity.requestPermissions`; результат приходит только через
  `onRequestPermissionsResult`. Если activity пересоздана / результат потерян / второй вызов
  перетёр callback — промис **не разрешается никогда**, и `getToken` не вызывается до конца жизни
  процесса. Android держит процесс днями.
- Сбой сети / BFF при старте — тоже до следующего холодного старта.
- BFF `PrismaDevicesRepository.upsert` по уникальному `token` с `update: { userId }` — второй
  аккаунт на том же телефоне забирает токен у первого (не логируется). Ожидаемое поведение, не баг.
- BFF удаляет токены: выход (`DELETE`), удаление аккаунта, `FCM tokens pruned` при пинге о сообщении.
- Эндпоинта для клиентской диагностики в BFF нет; Analytics/Crashlytics в приложении нет.
- `AppState` уже используется (`ChatProvider`, `notification-taps`, `use-paid-session`).
