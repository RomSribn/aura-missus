# AURAT-0139-008 — add: свои пуши из Firebase Console

Дата: 2026-10-25
Status: draft — ждёт решения владельца

## Слова владельца

> пуши с сообщений работают, я хочу отправлять кастомные пуши с firebase

## Что уже работает без кода

Firebase Console → Messaging → кампания **Notifications** шлёт notification-пуш (с `title`/`body`).
Такой пуш **рисует сама ОС**, наш код не нужен:

| | Свёрнуто / закрыто | Приложение открыто | Тап |
|---|---|---|---|
| Android | показывается, канал FCM «Miscellaneous», иконка по умолчанию | **не показывается** (`onMessage`, `ChatProvider` молча игнорирует не-`message.new`) | открывает приложение |
| iOS | показывается, в т.ч. после force-quit | **не показывается** (`firebase.json` нет → `messaging_ios_foreground_presentation_options` = `[]`, `RNFBMessaging+UNUserNotificationCenter.m:87`) | открывает приложение |

Наш `setBackgroundMessageHandler` на такой пуш ничего не делает (`MessagePushData` не проходит) —
двойных уведомлений не будет.

## Пробелы (по коду)

1. **Открытое приложение** — кастомный пуш пропадает на обеих платформах.
2. **Android канал и иконка**: в `AndroidManifest.xml` нет
   `com.google.firebase.messaging.default_notification_channel_id` / `default_notification_icon` /
   `default_notification_color` → канал «Miscellaneous», маленькая иконка — лаунчер (обычно серый
   кружок/квадрат). Монохромной иконки уведомлений в `res/drawable` нет — нужен ассет.
3. **Тап никуда не ведёт** — только открывает приложение. Диплинк по ключу из «Additional options →
   Custom data» (например `screen=advisor`, `advisorId=…`) — правка `notification-taps.ts` +
   `messaging().getInitialNotification` / `onNotificationOpenedApp` (notifee системные пуши не видит).
4. **Картинка**: Android — работает из коробки; iOS — нужен Notification Service Extension
   (новый таргет Xcode + pod `FirebaseMessaging` extension helper).
5. **Таргетинг**: в приложении нет Google Analytics (App Privacy: только auth и messaging) →
   в Console доступны «все установки приложения», **topic** и тест по токену; сегменты по
   аудиториям/свойствам требуют Analytics (и правки App Privacy). Подписки на topic в коде нет.
6. **Правила стора** — Apple 4.5.4: пуши с промо/маркетингом — только после явного согласия в UI и с
   выключателем в приложении. Текущий запрос разрешения — для сообщений. Для служебных объявлений
   (изменения в сервисе, техработы) отдельное согласие не нужно. При идущем ревью Apple (`AURAT-0079`,
   отказ 4.3(b)) лишний повод не давать.

## Варианты объёма (решает владелец)

- **A — минимум:** (1) показ кастомного пуша на переднем плане: iOS — `firebase.json`
  `["banner","list","sound"]`; Android — `onMessage` с `notification` → notifee на новом канале;
  (2) Android: канал «Announcements» + meta-data канала/иконки/цвета, иконка — нужен ассет.
- **B — A + диплинк по custom data** (тред советника; список экранов — закрытый).
- **C — B + согласие на промо:** переключатель в Settings → подписка на topic `promo`; кампании в
  Console — на topic. Нужен дизайн переключателя.
- Картинка на iOS (NSE) — отдельно, если понадобится.

## Осторожно при отправке

Проект `aura-2781b` — боевой: «Send to all users of Aura» уйдёт **всем реальным пользователям**,
включая вышедших из аккаунта (FCM-токен живёт у установки). Первые пуши — только «Send test
message» на свой токен (токен из `DeviceToken` в BFF берёт манор).
