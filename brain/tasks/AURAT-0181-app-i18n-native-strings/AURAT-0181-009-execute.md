# AURAT-0181-009 — execute (Android)

Дата: 2026-11-07. slave-0, ветка `feature/AURAT-0181-app-i18n-native-strings` (от `develop` @ `71e03d2`). Всё
застейджено (`git add -A` в master; brain — в manor missus), коммитов нет. Сделано по `007-spec-v2`.

## Файлы

**Android**
- `android/app/src/main/res/xml/locales_config.xml` — 24 языка в порядке `LANGUAGES`, `pt-PT`.
- `android/app/src/main/res/values-<lang>/strings.xml` × 23 — `app_name` = «Aura».
- `android/app/src/i18n/AndroidManifest.xml` — оверлей с `android:localeConfig`.
- `android/app/build.gradle`:
  - проба флагов вынесена в `auraFlag(key)`; Meta-проба работает через неё же, поведение то же;
  - `i18nEnabled = auraFlag("AURA_I18N_ENABLED")`;
  - `auraLanguages`, `androidResources.localeFilters += auraLanguages`;
  - `bundle.language.enableSplit = false`;
  - `androidComponents.onVariants` → `sources.manifests.addStaticManifestFile` при флаге. Основной путь сработал, запасной вариант с пустым `<locale-config/>` не понадобился.
- `AndroidManifest.xml` — `MainActivity.configChanges` += `locale|layoutDirection`, с комментарием.
- `AppLanguageModule.kt` (`AuraAppLanguage`):
  - `getLocales`, `setAppLanguage`;
  - событие `AuraAppLanguageChanged`: `ComponentCallbacks` на application context регистрируется в `initialize` и, на всякий случай, при первом `getLocales`; снимается в `invalidate`;
  - констант нет;
  - заглушки `addListener` / `removeListeners`.
- `AppLanguagePackage.kt`; `MainApplication.kt` — `add(AppLanguagePackage())` (общая строка с `AURAT-0188`).

**JS**
- `shared/lib/i18n/app-language-module.ts`:
  - единственная привязка к RN: `NativeModules` / `DeviceEventEmitter` / `Platform`;
  - `systemKeepsAppLanguage()` = Android, API ≥ 33 и модуль есть.
- `shared/lib/i18n/native-locales.ts`:
  - кэш последнего ответа Android, `readNativeLocales`, `writeAppLanguage`;
  - `appLanguageTag` (`pt` → `pt-PT`), `appLanguageOf`;
  - `deviceLanguage()`: синхронная, из кэша; без кэша — Hermes.
- `shared/lib/i18n/start.ts`:
  - режимы `off` / `system` / `file`;
  - `getLocales` читается в существующем `Promise.all`, только с флагом;
  - миграция файла в систему (`startFromSystem`);
  - `chooseLanguage` / `currentLanguageChoice` по режиму;
  - `syncSystemLanguage` (`follow`): сравнение с `wanted`, псевдоязык не трогается, счётчик `picks` против запоздавших чтений, в `file` устаревший выбор сбрасывается на ходу;
  - `watchSystemLanguage`: событие + `AppState`, только Android и только с флагом;
  - `clearLeftoverAppLanguage` (флаг выключен, API 33+);
  - `i18nSettled`.
- `shared/lib/device-locale.ts` — на Android с кэшем `deviceLocale()` = `system[0]`.
- `shared/lib/i18n/detect-language.ts` — комментарий: на Android это теперь запасной путь.
- `shared/index.ts`:
  - добавлены `deviceLanguage`, `i18nSettled`, `watchSystemLanguage`, `clearLeftoverAppLanguage`;
  - убран `systemLanguage`: у него не осталось потребителей.
- `features/app-language/model/use-language-sheet.ts` — подсказка «Язык устройства» берётся из `deviceLanguage()`.
- `features/push/model/channels.ts` — `ensure*Channel` ждут `i18nSettled()`. Текст пуша собирается после канала, поэтому тоже выходит на новом языке.
- `app/i18n/use-system-language-sync.ts` + вызов в `app/index.tsx`, рядом с `useDisabledLanguagesSync`.

**Тесты**
- `app/i18n/__tests__/native-locales.test.ts` (5): `locales_config` = `LANGUAGES` с `pt-PT`, `values-<lang>` × 23, `localeFilters`, `configChanges`, `localeConfig` только в оверлее и только при флаге.
- `shared/lib/i18n/__tests__/system-language.test.ts` (23):
  - флаг выключен: модуль не вызывается, кадр сразу; защита очищает оставшуюся локаль; `watchSystemLanguage` ничего не подписывает;
  - system: язык из системы; `[ru, es]` → es; чужая локаль → язык устройства; `fr` / `pt-PT` / `null`; явный язык устройства пишется явно; en → de → English из настроек; событие и возврат; запоздавшее чтение; псевдоязык; `i18nSettled`; выключенный сервером de; `englishDateLocale` en-US / en-IE; подписка на событие на Android;
  - миграция: перенос, устаревший файл, система главнее;
  - file на Android: список модуля, запись в файл, сброс устаревшего выбора на ходу.
- `features/push/.../announcement-notification.test.ts` — ждёт `i18nSettled()` вместо `i18nReady()`: каналы теперь ждут его, а тест считал микротаски.

## Проверки

- `npx tsc --noEmit` — ок. В `package.json` нет скрипта `typecheck`, проверка через `tsc` напрямую.
- `npm run lint` (`eslint .`) — ок; Prettier на новых файлах — ок.
- `npx jest --no-watchman` — **228 suites / 3117 tests passed**. В конце Jest пишет «A worker process has failed to exit gracefully». Новые сьюты отдельно этого не дают.
- Gradle (SDK `~/Library/Android/sdk`, `ANDROID_HOME`, без устройства и Metro):
  - `AURA_I18N_ENABLED=true :app:processDebugMainManifest` — BUILD SUCCESSFUL; в слитом манифесте есть `android:localeConfig="@xml/locales_config"` и `configChanges …|locale|layoutDirection`;
  - `AURA_I18N_ENABLED=false :app:processDebugMainManifest` — BUILD SUCCESSFUL; `localeConfig` нет, `configChanges` с `locale`;
  - `:app:compileDebugKotlin` — BUILD SUCCESSFUL, ошибок и предупреждений по `cc.silvermind.aura` нет;
  - `:app:processDebugResources` (флаг включён) — BUILD SUCCESSFUL: ресурс `@xml/locales_config` линкуется, `values-*` собираются;
  - предупреждение `AD_SERVICES_CONFIG … tools:replace` было и раньше (Meta SDK), к задаче не относится.

## Решения по ходу

- Защита при выключенном флаге работает на любом API ≥ 33, а не только на 33. На 34+ установка поверх и так сбрасывает локаль приложения, так что там это проверка без записи.
- Подсказка и отметка в шторке в system-режиме проверены на уровне `start`: шторка читает ровно `deviceLanguage()` и `currentLanguageChoice()`. Отрисовку шторки в Jest в system-режиме не делал: для неё нужен второй React в изолированном реестре.
- `deviceLocale()` обновляется вместе с кэшем, то есть по событию и при возврате, а не нативным вызовом на каждое чтение. Вызов был бы синхронным нативным.

## Не сделано / открыто

- Пункт в `.claude/aura-build-rules.md` — только текст, в отчёте координатору (вносит он, после `AURAT-0180`).
- `AURAF-0023-007` делится (Android ✓ / iOS ✗ `AURAT-0190`) при закрытии задачи.
- `AURAI-0010` — уточнение к решению владельца 1 дописано (застейджено в manor missus).
- Поведение на устройстве (событие при выборе в настройках, split-screen, сплиты AAB, `[ar]`) — проверка в маноре по `007` §«Проверка в маноре».
