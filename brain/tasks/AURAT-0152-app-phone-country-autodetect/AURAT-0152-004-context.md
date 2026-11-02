# AURAT-0152-004 — context

**Автоопределение уже написано, но на нашей сборке молча не работает.**

- `usePhoneAuth` стартует с `deviceCountry()` (`screens/phone-auth/lib/device-country.ts`): регион из локали,
  если он в `SMS_REGIONS`, иначе `DEFAULT_COUNTRY_ISO2 = 'ES'`.
- Локаль читается свойствами `NativeModules`: iOS — `NativeModules.SettingsManager.settings.AppleLocale`,
  Android — `NativeModules.I18nManager.localeIdentifier`.
- Приложение на New Architecture (`android/gradle.properties: newArchEnabled=true`, RN 0.85.3, bridgeless).
  Там `NativeModules` = `global.nativeModuleProxy` → `BridgelessNativeModuleProxy` отдаёт сам TurboModule
  (`ReactCommon/.../TurboModuleBinding.cpp`). У TurboModule константы — только через метод `getConstants()`,
  свойством их нет: `I18nManager.js` и `Settings.ios.js` самого RN читают именно `getConstants()`.
  Итог: обе ветки дают `undefined`, `try/catch` это проглатывает, и всегда возвращается `'ES'`.
  Это и есть «захардкоженная Испания».
- Под Jest этот путь тоже падает в `'ES'`, поэтому тесты ошибку не ловили; отдельного теста на
  `deviceCountry` нет.

**Сигналы, которые есть без нативного кода:**

- Часовой пояс — `deviceTimeZone()` уже в `shared/lib/time-zone.ts` (Intl в Hermes), работает на устройстве
  (бронь группирует слоты по нему). Пояс ставится по сети автоматически, т. е. говорит, *где* человек.
- Локаль — публичный `I18nManager.getConstants().localeIdentifier` (iOS и Android), запасной —
  `Intl.DateTimeFormat().resolvedOptions().locale`. Локаль — это *настройка языка/формата*; часто `en_US`
  у людей вне США.

**С нативным кодом:** Android `TelephonyManager.getSimCountryIso()` / `getNetworkCountryIso()` — страна
SIM-карты, лучший сигнал для номера, без разрешений. iOS аналога нет (`CTCarrier.isoCountryCode` с iOS 16.4
возвращает `--`). Своих нативных модулей в приложении сейчас нет ни одного.
