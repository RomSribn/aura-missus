# AURAT-0139-009 — spec: свои пуши из Firebase Console

Status: draft
Дата: 2026-10-25

## Решения владельца (на `008`)

- Слать будем **и служебные, и промо**: служебные — всем, промо — только согласившимся.
- Объём кода — **A + диплинк**.

## 1. Показ на переднем плане

- **iOS:** `firebase.json` в корне `aura-app`:
  `"messaging_ios_foreground_presentation_options": ["banner", "list", "sound"]`. Это затрагивает
  только пуши с `notification`; пинги о сообщениях data-only, без alert, на них не влияет.
- **Android:** в `features/push` подписка на `onMessage`: если у сообщения есть `notification`,
  то notifee рисует его в канале `announcements`. `message.new` пропускается: его по-прежнему
  ведёт `ChatProvider` (сокет), уведомления нет.

## 2. Android: канал, иконка, цвет

- Канал `announcements` («Announcements», importance DEFAULT) создаётся при старте вместе с
  `messages`.
- `AndroidManifest.xml`: `com.google.firebase.messaging.default_notification_channel_id` =
  `announcements`, `default_notification_icon` = `@drawable/ic_notification`,
  `default_notification_color` = coral `accent`.
- `ic_notification`: монохромный vector drawable. Источник — знак бренда; если монохромной
  версии нет, временно `sparkle.svg` из набора иконок. Тот же `smallIcon` получат и notifee-
  уведомления о сообщениях (сейчас у них иконка лаунчера).

## 3. Диплинк по тапу

Console → кампания → Additional options → **Custom data**: `advisorId = <id>` открывает тред
этого советника. Список ключей закрытый: v1 знает только `advisorId`, любой другой ключ просто
открывает приложение.

Системное уведомление notifee не видит, поэтому `subscribeToThreadOpens` дополнительно слушает
`messaging().getInitialNotification()` (холодный старт) и `onNotificationOpenedApp` (фон).
Передний план (§1, Android) уже идёт через notifee и его `onForegroundEvent`. Обёртки — в
`shared/api/firebase/messaging.service.ts`, логика — в `notification-taps.ts`.

## 4. Промо только с согласием — topic `promo`

Служебные пуши: Console → Target **User segment → app Aura (iOS) + Aura (Android)**. Получат все
установки, включая вышедших из аккаунта.

Промо: Console → Target **Topic `promo`**. Приложение подписывает устройство на `promo`
(`subscribeToTopic`), только пока согласие включено, и отписывает (`unsubscribeFromTopic`) при
выключении и при выходе из аккаунта.

**Где хранится согласие (решает владелец):**

- **4a. Переиспользовать `marketingOptIn`.** Поле уже есть в профиле, хранится в BFF и
  переключается в Create Account / Edit Profile (`OptInRow`). Правка только в приложении: текст
  меняется на «email and push updates…», подписка на topic идёт за полем. Минусы: у новых
  пользователей галочка стоит по умолчанию (`PROFILE_FORMS.md`: `optIn` default true). Apple 4.5.4
  требует *явного* согласия, GDPR не признаёт заранее отмеченную галочку. А старые согласия давали
  только на email, и отличить их нельзя.
- **4b. Отдельное согласие на промо-пуши, по умолчанию выкл.** Новое поле профиля (контракты +
  BFF, отдельная задача в `aura-bff-manor`, ID отсюда). В приложении — строка **Notifications**
  в Profile (по дизайну README §10, иконка `bell`), в ней `Toggle` «Offers & news». Чисто
  юридически, но дольше, и нужен текст/вид строки.

## Тесты

Юнит-тесты на разбор custom data (`advisorId` → тред, прочее → ничего), на выбор канала для
переднего плана и пропуск `message.new`, на подписку и отписку topic по согласию. Lint и
typecheck. Живая проверка — новые сборки (Play + TestFlight), потом «Send test message» с custom
data на свой токен.

## Вне задачи

- Картинки в пушах на iOS (Notification Service Extension).
- Сегменты по аудиториям: нужна Google Analytics и правка App Privacy.
