# AURAT-0181-012 — fix: модуль не создавался на Android 12 и ниже

Дата: 2026-11-07. Найдено в маноре на A50 (Android 11, API 30), `develop` @ `68f0333`, debug с `AURA_I18N_ENABLED=true`:
красный экран «Render Error», в logcat — `HostObject::get for prop 'AuraAppLanguage': java.lang.NoClassDefFoundError:
Failed resolution of: Landroid/app/LocaleManager;`.

## Причина

Interop-слой, создавая legacy-модуль, перебирает его объявленные методы через reflection. При этом разрешаются типы
во всех сигнатурах, включая private. В `AppLanguageModule.kt` был `private fun localeManager(): LocaleManager?`, а
`LocaleManager` появился только в API 33. На Android 12 и ниже модуль не создавался вовсе. Проверки `SDK_INT` в телах
методов не спасают: сигнатура разрешается раньше. На API 36 класс есть, поэтому 011 прошёл. Ревью и Jest этого
поймать не могли: нужен запуск на старом API.

## Правка (слот slave-0, ветка `feature/AURAT-0181-app-i18n-native-strings`, застейджено, без коммита)

- `AppLanguageApi33.kt` — новый `@RequiresApi(TIRAMISU) internal object` с `read(context)` и `write(context, tag)`.
  В его сигнатурах только `Context`, `String`, `LocaleList` (API 24); `LocaleManager` — только в теле.
- `AppLanguageModule.kt`:
  - `LocaleManager` нет нигде: ни в импорте, ни в полях, ни в сигнатурах;
  - хелпер вызывается только под `SDK_INT >= TIRAMISU`;
  - в KDoc записано правило: в модуле не должно быть типов новее minSdk.
- `app-language-module.ts`: `appLanguageModule()` ловит исключение при чтении `NativeModules.AuraAppLanguage` и
  возвращает `null`. Если модуль когда-нибудь снова не создастся, приложение идёт за языком телефона (как без модуля),
  а не падает.
- Охранные тесты (`app/i18n/__tests__/native-locales.test.ts`):
  - каждый `*Module.kt` пакета (`AppLanguageModule`, `DeviceCountryModule`, `KeyboardFrameModule` из 0188) не называет
    в импортах, полях и сигнатурах классов новее API 24 (`LocaleManager`, `LocaleConfig`, `WindowInsetsController`,
    `WindowInsetsAnimation`, `WindowMetrics`, `OnBackInvokedCallback` / `Dispatcher`);
  - `LocaleManager` встречается только в `AppLanguageApi33.kt` с `@RequiresApi(TIRAMISU)`;
  - старый код этот тест не прошёл бы: строка `private fun localeManager(): LocaleManager?`.
- Jest:
  - `app-language-module.test.ts`: модуль, падающий при создании, читается как `null`, и
    `systemKeepsAppLanguage()` = false; на Android 11 модуль выдаётся, но `systemKeepsAppLanguage()` = false;
  - `system-language.test.ts`: флаг выключен, API ниже 33 — ни `appLanguageModule()`, ни `getLocales`, ни
    `setAppLanguage` не вызываются (старт, `watchSystemLanguage`, защита, перечитывание, выбор, `deviceLanguage`).

## Пути JS к модулю

| Режим | Кто трогает модуль |
|---|---|
| **off** (флаг выключен, прод сейчас) | никто: `boot` не читает (`I18N_ENABLED` замыкает `Promise.all` и выбор режима); `watchSystemLanguage` выходит на флаге; `follow` выходит на `mode === 'off'`; `chooseLanguage` идёт в файл; `deviceLanguage()` / `deviceLocale()` читают только кэш (при off он пуст → Hermes / `I18nManager`, как раньше). Единственное исключение — защита `clearLeftoverAppLanguage`, и та только на API ≥ 33: `systemKeepsAppLanguage()` проверяет `Platform.Version` до обращения к модулю. На Android 11 с выключенным флагом модуль не создаётся вообще — как до 0181. |
| **file** (флаг включён, API ниже 33 — A50) | `boot` (`getLocales` — список языков телефона), `follow` по событию / возврату. Падало именно здесь; после правки модуль создаётся. |
| **system** (флаг включён, API 33+) | как было. |

`useAdvisorCatalogSync()` в JS-стеке — первая строка `App`, на которой отрисовка показала ошибку. Сам каталог модуль
не трогает (`catalog-store.ts` читает `currentLanguage()` / `i18nReady()`).

## Проверки

`:app:compileDebugKotlin` — BUILD SUCCESSFUL. `tsc --noEmit` — 0. `eslint .` — 0. Jest — 231 сьют / 3148 тестов (с
новым кодом `develop` из слияния). Запуска на устройстве в слоте нет — проверка на A50 за координатором.
