# AURAT-0139-004 — context

Дата: 2026-10-25. Код — `aura-app` `feature/AURAT-0139-push-check` @ `ec9d30b`; BFF — только чтение
(`aura-bff-manor` manor `develop`).

## Расхождение с брифом манора — бриф устарел

Бриф: «ключ APNs в `aura-2781b`, скорее всего, не загружен». **Это не так.** `TECH-DEBT.md` #6 в
приложении: **PAID 2026-09-18** — ключ `RPFSU5KQLB` (Sandbox & Production, команда Silvermind OÜ
`6D62F96H2N`) загружен в `aura-2781b` → Cloud Messaging → Aura (iOS); с TestFlight `1.0.0 (1)`
пуш дошёл до iPhone (`fcm-fanout completed=1 failed=0`), токен `ios` зарегистрирован в прод-BFF.
Команда в проекте сейчас `DEVELOPMENT_TEAM = 6D62F96H2N` (не `7CP3SB86G2`, как в брифе — тот
был старой командой из `AURAT-0043`). Проверять в консолях надо, а загружать заново — нет.

## Цепочка (по коду)

1. Вход → `usePushRegistration` (`features/push/model/push-registration.ts`):
   `notifee.requestPermission()` → `messaging().getToken()` → `PUT /v1/devices/:token`
   (`api/devices-api.ts`), повтор на `onTokenRefresh`. Любая ошибка глушится.
2. Ответ оператора в Chatwoot → BFF `fanOut`: WS + задача `fcm-fanout` → `FcmSender`:
   data-only `{ type: 'message.new', advisorId }`, `android.priority=high`,
   `apns-priority: 5` + `content-available: 1`, без alert.
3. Фон / закрыто: `index.js` → `setBackgroundMessageHandler` → `displayMessageNotification`
   (notifee, канал `messages` HIGH, заголовок — имя персоны, тело «sent you a new message»).
4. Передний план: `ChatProvider` `onMessage` → `syncThread`, уведомления нет (живёт сокет).
5. Тап: `notification-taps.ts` — холодный старт (`getInitialNotification`), фон (stash →
   drain на `active`), передний план (`onForegroundEvent`) → тред советника.

## Сборки → BFF (`env/.env.*`)

| `AURA_ENV` | BFF |
|---|---|
| `dev` | `10.0.2.2:3000` / `localhost:3000` (Mac) |
| `staging` | `https://bff-dev.aura-app.cc` |
| `prod` | `https://bff.aura-app.cc` (TestFlight / App Store / Play) |
| `tunnel` | свой https-туннель |

Пуш придёт только от того BFF, в котором зарегистрирован токен, — и только на ответ в его же Chatwoot.

## Риски, подтверждённые кодом

- **iOS, тихий пуш.** `content-available` + приоритет 5 — система будит приложение по своему
  усмотрению: троттлинг, не после свайпа из переключателя (force-quit), не при выключенном
  Background App Refresh / в Low Power Mode. В сентябре один пуш дошёл — это не гарантия.
  Надёжный путь — видимый alert-пуш от BFF (имя персоны + общий текст, без содержимого сообщения)
  или alert + `mutable-content` с Notification Service Extension. Тогда систему рисует iOS, а не
  notifee, и в приложении нужен ещё `messaging().getInitialNotification()` /
  `onNotificationOpenedApp` для тапа. BFF — отдельная задача.
- **iOS, токен до APNs.** RNFB 24.1.1 (`RNFBMessagingModule.m:137`): без APNs-токена `getToken()`
  не ждёт, а сразу просит FCM и получает ошибку; `push-registration.ts` её глотает. На первом входе
  APNs успевает (OTP идёт долго), риск — при старте уже вошедшего пользователя. Смягчает
  `onTokenRefresh`, но не гарантирует. Лечится ожиданием `getAPNSToken()` перед `getToken()` на iOS.
- **Android:** force stop отключает доставку до ручного запуска; Samsung «спящие приложения» и
  подобное у других производителей — пункт чек-листа, не баг. Android 13+ — runtime-разрешение.
- **Токен в Firebase Console.** Приложение токен не показывает; Console «Send test message» шлёт
  notification-пуш, т.е. проверяет только трубу FCM/APNs, не наш код. Токен можно взять из BFF
  (`DeviceToken`) силами манора — правка приложения для этого не нужна.
