# AURAT-0088-004 — Контекст

Дата: 2026-10-14

## Пакет — проверено по тарболу, не по памяти

`react-native-fbsdk-next@13.4.3` (последняя, 2026-02-02), скачан в scratchpad
через `npm pack`, исходники прочитаны. В проект пока **не** установлен.

- Модули — старые bridge-модули (`NativeModules.*`, `@ReactModule`), не
  TurboModule. На RN 0.85 работают через interop-слой — так же, как уже
  живущие `react-native-inappbrowser-reborn` и `react-native-vector-icons`.
  Подтвердится только сборкой.
- Android-зависимость: `facebook-android-sdk:${facebookSdkVersion ?: '18.+'}` —
  **полный** SDK (login, share, gaming, messenger, applinks), версия плавающая.
  Сейчас `18.+` = `18.3.0`. Корневой `android/build.gradle` переменной
  `facebookSdkVersion` не задаёт.
- API, нужный задаче:
  - `Settings.initializeSDK()` → `FacebookSdk.fullyInitialize()`;
    `setAutoLogAppEventsEnabled`, `setAdvertiserIDCollectionEnabled`.
  - `AppEventsLogger.logEvent(name, valueToSum?, params?)`,
    `AppEventsLogger.logPurchase(amount, currencyCode, params?)`.
    На Android `logPurchase` делает `Currency.getInstance(code)` — невалидный
    код бросает исключение в нативном методе. Валюту передавать только из
    контракта (`"USD"`).
  - Константы `AppEvents.CompletedRegistration`, `AppEvents.InitiatedCheckout`,
    `AppEventParams.ContentID/ContentType/Currency` — из `getConstants()`.
- **Ловушка iOS:** корневой `index` пакета на импорте выполняет
  `new NativeEventEmitter(NativeModules.FBAccessToken)` и три
  `requireNativeComponent`. Без нативного модуля на iOS это падение при старте.
  Значит, импорт пакета допустим только из файла `*.android.ts`.
- `react-native-fbsdk-next.podspec` тянет `FBSDKCoreKit ~> 18.0`; автолинк
  добавит его в iOS при следующем `pod install`, если явно не отключить
  (`react-native.config.js` → `dependencies[...].platforms.ios = null`).

## Нативный SDK — что он делает сам (`facebook-core-18.3.0.aar`)

Манифест AAR вливает в приложение:
- `com.google.android.gms.permission.AD_ID`;
- `ACCESS_ADSERVICES_ATTRIBUTION`, `ACCESS_ADSERVICES_AD_ID`,
  `ACCESS_ADSERVICES_CUSTOM_AUDIENCE`, `ACCESS_ADSERVICES_TOPICS`
  (Privacy Sandbox);
- `FacebookInitProvider` — автоинициализация до JS;
- зависимость `com.android.installreferrer`.

В `classes.jar` есть пакет `com.facebook.appevents.iap` с обёртками над
BillingClient v2–v7 и настройкой сервера `IAP_AUTOMATIC_LOGGING_ENABLED_BITMASK`:
**SDK умеет сам логировать покупки Play по ответу магазина**, если в консоли
Meta включено «Log in-app events automatically». Это ровно то, что задача
запрещает, и при нашем ручном событии в USD (а Play платят в местной валюте)
дедупликация не сработает → двойной счёт.

## Код приложения

- Android: `cc.silvermind.aura`, `MainActivity`, `minSdk 24`, ProGuard выключен,
  `versionCode 22 / 1.0.1` (ещё не в Play — TECH-DEBT #12).
- Регистрация: `screens/create-account/model/use-create-account.ts`,
  `saveProfile(...)` → `enterApp`. Сюда же попадает переустановивший без имени
  (`land-after-sign-in.ts`) — событие для него тоже уйдёт.
- Пополнение: лист `topup` в `screens/profile/model/use-profile.ts`, два входа —
  кнопка (`openSheet('topup')`) и параметр `sheet: 'topup'` из пикера блоков.
- Покупка: `features/store-topup/model/use-store-topup.ts`, `redeem()` →
  `redeemGooglePurchase` → `walletStore.setBalance` → `finishTransaction`.
  Контракт `GooglePlayTopUpResponse` (`@aura/contracts` 0.20.0):
  `entryId`, `creditedMinor` («что SKU зачислил»), `currency: "USD"` (literal),
  `replayed` («токен уже был погашен, ничего не зачислено повторно»).
  → «ровно один раз» = слать только при `replayed === false`.
- Сборочные цели: `AURA_ENV` = dev / staging / prod / tunnel
  (`env/resolve.js`, инлайн через Babel). Play получает только `prod`.

## Декларации (из `AURAT-0076-003`, `AURAT-0079-008`, `AURAT-0042-119`)

- **Play, App content → Advertising ID: «нет»**, AD_ID в манифесте нет.
- **Play, Data safety: shared — «ничего»**; collected включает Device or other
  IDs, App interactions, Purchase history — но не для рекламы и без передачи.
- **App Store, App Privacy:** 10 типов, все Linked, **трекинга нет**,
  аналитики нет. `1.0.0 (2)` на ревью; `1.0.1 (3)` загружена новым поездом
  (`AURAT-0087-012`) — обе собраны до этой ветки.
- **Страны Play: 34** — ЕС-27, Исландия, Лихтенштейн, Норвегия, Великобритания,
  Швейцария, Украина, США (`AURAT-0076-003`). То есть основная аудитория — под
  GDPR / ePrivacy.
- Политика `aura-app.cc/privacy/` — список третьих лиц, Meta там нет.

## Противоречия

- Бриф: «1.0.0 (2) на ревью». В репо уже есть коммит `build(ios): 1.0.1 (3)`
  и шаг `AURAT-0087-012` — загружена, не отправлена. Для задачи не важно: обе
  сборки старше ветки, iOS заморожен в любом случае.
