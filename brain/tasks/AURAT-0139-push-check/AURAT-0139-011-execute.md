# AURAT-0139-011 — execute: свои пуши, части 1–3

Дата: 2026-10-25
Ветка: `aura-app` `feature/AURAT-0139-push-check` (от `ec9d30b`), **не закоммичено** — ждёт
просмотра владельцем.

## Что сделано

| Файл | Что |
|---|---|
| `firebase.json` (новый) | iOS: показ на переднем плане `banner`/`list`/`sound`; Android: канал FCM по умолчанию `announcements` |
| `android/.../AndroidManifest.xml` | `default_notification_icon` → `@drawable/ic_notification`; `default_notification_color` → `@color/notification_accent` с `tools:replace`. Канал — **не здесь**: его meta-data пишет `@react-native-firebase/messaging` из `firebase.json`. Цвет через `firebase.json` ломает release (см. «Проверки») |
| `android/.../drawable/ic_notification.xml` (новый) | монохромная иконка — залитый `sparkle` из набора иконок, **временно**, до знака бренда от дизайна |
| `android/.../values/colors.xml` | `notification_accent` = coral `#EC5F73` |
| `shared/api/firebase/messaging.service.ts` | `getInitialNotification`, `onNotificationOpenedApp` |
| `features/push/config/constants.ts` | `ANNOUNCEMENTS_CHANNEL_*`, `NOTIFICATION_SMALL_ICON` |
| `features/push/lib/parse-push-data.ts` | `advisorIdFromTapData` — `advisorId` из data уведомления, общий для notifee и FCM |
| `features/push/model/announcement-notification.ts` (новый) | Android: канал создаётся при старте; кампания на переднем плане → notifee (`message.new` пропускается). iOS — ничего (рисует система) |
| `features/push/model/notification-taps.ts` | плюс тапы по системным уведомлениям FCM: холодный старт и фон |
| `features/push/model/message-notification.ts` | `smallIcon` — та же иконка у уведомлений о сообщениях |
| `app/providers/PushBootstrap.tsx` | подписка `subscribeToForegroundAnnouncements` |
| `jest.setup.js` | моки `getInitialNotification`, `onNotificationOpenedApp`, `AndroidImportance.DEFAULT` |
| тесты | `parse-push-data` (+2), `announcement-notification` (новый, 5), `notification-taps` (новый, 4) |

## Проверки

- `tsc --noEmit` — 0 ошибок; `eslint` по изменённым файлам — чисто; `prettier` — отформатировано.
- Jest `src/features/push` + `src/app` — 6 наборов, 22 теста; **полный прогон — 132 набора,
  977 тестов, все зелёные.**
- `./gradlew :app:processDebugMainManifest --offline` — склейка без конфликта; в итоговом
  манифесте `default_notification_icon` = `@drawable/ic_notification`,
  `default_notification_channel_id` = `announcements`, `default_notification_color` =
  `@color/notification_accent` (т.е. `firebase.json` читается).
- **Первый `apk:staging` упал** на `:react-native-firebase_messaging:verifyReleaseResources`:
  RNFB вставляет `messaging_android_notification_color` в манифест *своей библиотеки*, а
  `@color/notification_accent` есть только в приложении — release проверяет ресурсы библиотеки
  отдельно, debug-склейка этого не ловит. Исправлено: цвет убран из `firebase.json` (библиотека
  оставляет свой `@color/white`), в манифесте приложения — `default_notification_color` с
  `tools:replace="android:resource"`.
- По пути: `setImmediate` в тестах висит — `jest.setup.js` включает fake timers; сброс
  промисов через микрозадачи, как в `open-url.test.ts`.

## Что заметить

- Канал `announcements` — importance DEFAULT: в шторке без всплывающего баннера. Важность канала
  Android фиксирует при первом создании; поднять потом можно только новым id канала.
- Тап с `advisorId` у вышедшего из аккаунта пользователя просто открывает приложение
  (`navigateToThread` молчит без пользователя) — как у уведомлений о сообщениях.
- `advisorId` неизвестного советника откроет тред без персоны — id брать из списка советников.
- iOS: notifee пересылает чужие (не notifee) уведомления делегату RNFB — проверено по коду notifee
  (`NotifeeCore+UNUserNotificationCenter.m`), на устройстве — при живой проверке.

## Как слать (для владельца, после сборки с этой веткой)

1. Firebase `aura-2781b` → Messaging → New campaign → **Firebase Notification messages**.
2. Notification title / text. Картинка — только Android (iOS без NSE её не покажет).
3. **Target:**
   - служебное: User segment → app **Aura (iOS)** и **Aura (Android)** (две строки);
   - промо — topic `promo`, **только после AURAT-0140 + части 4**; до этого промо не слать.
4. Additional options → Custom data: `advisorId` = id советника — тап откроет его тред
   (необязательно).
5. Сначала **Send test message** на свой токен, потом на всех.

## Живая проверка (манор + владелец, после мёржа и новых сборок)

| # | Состояние | Ожидание |
|---|---|---|
| 1 | Android, приложение открыто | уведомление в шторке, канал Announcements, иконка-звёздочка coral |
| 2 | Android, свёрнуто/закрыто | то же, канал Announcements (не Miscellaneous) |
| 3 | iPhone, приложение открыто | баннер сверху |
| 4 | iPhone, свёрнуто/закрыто/force-quit | уведомление |
| 5 | тап с `advisorId` (1–4, холодный старт и фон) | открывается тред советника |
| 6 | тап без custom data | просто открывается приложение |
| 7 | пуш о сообщении (регрессия) | как раньше; на Android — новая иконка |

## Дополнение: «Оцените приложение» (вариант A, по просьбе владельца)

Custom data `action` = `rate` → тап открывает страницу Aura в сторе: iOS — `itms-apps://…/id6813629245?action=write-review`
(сразу форма отзыва), Android — `market://details?id=cc.silvermind.aura` (страница, формы-ссылки у Play нет);
если стор-приложение не открылось — веб-страница стора. Ссылки зашиты в `config/constants.ts`
(`STORE_REVIEW_URLS`), URL из пуша не берётся. Нативный попап оценки (In-App Review / SKStoreReviewController)
— **не здесь**: показ решает ОС без обратной связи; это отдельная задача (показ внутри приложения в удачный момент).

- `lib/parse-push-data.ts`: `advisorIdFromTapData` → `tapTargetFromData` (`thread` | `store-review`) + `tapDataOf`.
- `lib/store-review.ts` (новый): `openStoreReview`.
- `model/notification-taps.ts`: `subscribeToThreadOpens` → `subscribeToNotificationTaps`, ведёт тап по цели.
- `model/announcement-notification.ts`: перерисованный на переднем плане пуш несёт и `action`.
- Тесты: +3 parse, +1 announcement, +3 taps; push+app — 6 наборов, 28 тестов.
- Слать «оцените» — как маркетинг: по topic `promo` после AURAT-0140; без вознаграждения за оценку.

## Дополнение: «Карта дня» (по просьбе владельца)

Custom data `action` = `daily-card` → тап открывает экран карты дня (`SCREENS.DAILY_CARD`, поверх вкладок, как с Home).
- `TapTarget` + `daily-card`; `subscribeToNotificationTaps` принимает `TapNavigation` (`openThread`, `openDailyCard`).
- `app/navigation/navigation-ref.ts`: общий отложенный переход (`openWhenReady`), `navigateToDailyCard`;
  `flushPendingThreadNavigation` → `flushPendingNavigation`.
- Тесты push+app — 6 наборов, 30 тестов.
- Холодный старт проверить отдельно: тап при неготовом навигаторе и ещё не восстановленной сессии отбрасывается
  (`getCurrentUser()` = null) — так же, как у треда.

## Проверка владельцем на Android до мёржа (2026-10-25)

Staging-APK (`apk:staging`, bff-dev) по кабелю на Galaxy A50 (Android 11), пуши — Console «Send test message»
по токену из `device_tokens` bff-dev. Владелец подтвердил: пуш доходит; `action=rate` открывает Play;
`action=daily-card` открывает карту дня — в т.ч. из полностью закрытого приложения (холодный старт).
iPhone — после мёржа, TestFlight.

## Дальше

- Часть 4 — после AURAT-0140 (контракты + BFF).
- Нужна монохромная иконка бренда от дизайна — заменить `ic_notification.xml`.
