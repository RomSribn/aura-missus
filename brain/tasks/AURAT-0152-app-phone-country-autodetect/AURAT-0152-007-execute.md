# AURAT-0152-007 — execute

Ветка `feature/AURAT-0152-app-phone-country-autodetect`, коммиты `ee8a371`, `e8687a0` (от `develop` @ `bd67aca`).

- `android/.../DeviceCountryModule.kt` + `DeviceCountryPackage.kt` — первый свой нативный модуль
  `AuraDeviceCountry`: константы `simCountry` / `networkCountry` (`TelephonyManager`, без разрешений).
  Legacy-модуль через interop New Architecture: константы отдаются и через `getConstants()`, и свойствами
  (`JavaInteropTurboModule.cpp`). Зарегистрирован в `MainApplication.kt`.
- `screens/phone-auth/lib/device-country.ts` — цепочка SIM → сеть → пояс → регион локали → ES, страна вне
  `SMS_REGIONS` пропускается. Локаль — публичный `I18nManager.getConstants().localeIdentifier`, запасной
  `Intl`. Разбор локали понимает script-подтег (`zh-Hant-TW`), `_POSIX`, переопределение региона
  (`@rg=uazzzz`, `-u-rg-`).
- `screens/phone-auth/config/time-zone-countries.ts` — 133 пояса из `zone.tab` 2026f + старые имена. Сверено с
  вебом (`AURAT-0153`, `time-zone-regions.ts`): конфликтов нет, 6 слитых в 2022 канадских поясов добавлены.
- Тесты `lib/__tests__/device-country.test.ts` (порядок сигналов, пропуск неподдерживаемых, алиасы, разбор
  локалей, покрытие таблицы = `SMS_REGIONS`).

Проверено в slave: `jest` 160/160 наборов (1187 тестов), `tsc --noEmit`, eslint, `gradlew :app:compileDebugKotlin`
(классы модуля собраны). iOS не собирался: нативного кода там нет.

Не проверено на устройстве. Для проверки в маноре (после мёржа, `npm ci`, **нативная** пересборка Android):
A50 с украинской SIM → `+380`; без SIM / авиарежим → по поясу (выключить автопояс, выбрать London → `+44`);
iOS — по поясу/региону. Ручной выбор и вставка `+…` — как раньше.
