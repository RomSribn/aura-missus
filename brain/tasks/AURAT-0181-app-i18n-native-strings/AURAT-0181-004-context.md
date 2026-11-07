# AURAT-0181-004 — context

Дата: 2026-11-07. Код — `develop` @ `71e03d2` (slave-0).

## Что в коде сейчас (ground truth)

- `android/app/src/main/AndroidManifest.xml`: нет `android:localeConfig`; `MainActivity.configChanges` =
  `keyboard|keyboardHidden|orientation|screenLayout|screenSize|smallestScreenSize|uiMode` — **без `locale` и
  `layoutDirection`**: смена языка (системного или языка приложения) пересоздаёт Activity, RN пересоздаёт корень и
  теряет навигацию (`AURAI-0010` §7).
- `res/`: только `values/strings.xml` (`app_name` = «Aura», id Meta — `translatable="false"`); `values-<lang>` нет,
  `res/xml/` нет. В `app/build.gradle` нет `localeFilters` / `resConfigs` и блока `bundle { language }`.
  minSdk 24, target/compile 36, AGP 8.12.0.
- Флаги в Gradle: уже есть образец — `env/flag.js AURA_META_ATTRIBUTION_ENABLED` → `manifestPlaceholders`. Ключ
  `AURA_I18N_ENABLED` в `env/resolve.js` — `bool`, по умолчанию `false`, `flag.js` его принимает.
- JS (`shared/lib/i18n`):
  - `systemLanguage()` — язык из Hermes (`Intl.DateTimeFormat().resolvedOptions().locale`), один тег, читается
    синхронно при старте и в `chooseLanguage` / `currentLanguageChoice`. Подписки на смену системного языка во
    время работы нет.
  - Выбор хранится в `Documents/aura-language.json` = `{language, osLanguage}`; «последнее изменение побеждает»
    определяется по смене системного языка (`isStaleChoice`).
  - `disabledLanguages` — выбор не трогается, на экране английский; лист языков их не предлагает
    (`useDisabledLanguages`).
- Уже сделано другими задачами: SMS — `auth().setLanguageCode(currentLanguage())` перед `verifyPhoneNumber`
  (`auth.service.ts:124`, `AURAT-0157`); каналы уведомлений — имена из `t()`, переименуются при смене языка
  (`features/push/model/channels.ts`). Канал по умолчанию для кампаний Firebase Console — `announcements`
  (`firebase.json`) — тот же, что создаёт приложение.
- Нативный код приложения: `MainActivity.kt`, `MainApplication.kt` (`add(DeviceCountryPackage())`),
  `DeviceCountryModule.kt` (legacy-модуль через interop — образец для нового).
- Камера и микрофон на Android не объявлены (`AndroidManifest.xml`): системных запросов доступа с текстом
  приложения нет; диалог `POST_NOTIFICATIONS` и выбор фото рисует система на своём языке — переводить нечего.

## Нативные тексты на Android, которые видит человек

| Что | Чьё | На каком языке сейчас |
|---|---|---|
| Подпись на рабочем столе / в настройках | `app_name` = «Aura» | бренд, не переводится |
| Меню выделения текста (Копировать / Вставить), нативные кнопки фреймворка | ресурсы Android | язык конфигурации приложения |
| Подписи ролей и состояний для TalkBack (`link`, `header`, «развёрнуто»…) | `react-android` `views/uimanager/values-*` | язык конфигурации; у RN есть 22 из 23 наших — **нет ga и mt**; `values-pt` — бразильский, `pt-rPT` — есть |
| Канал «Прочие» Firebase (если пуш придёт до создания канала) | `firebase-messaging` | язык конфигурации |
| Billing Google Play, Custom Tabs, выбор фото / файлов, диалог уведомлений | другие приложения / система | их язык — не наш |

«Язык конфигурации» = язык приложения в настройках Android 13+, иначе язык устройства, согласованный с языками
ресурсов APK. Выбор в Profile → Language его сейчас не меняет — эти тексты остаются на языке устройства.

## Android (из документации и AOSP — не проверено на устройстве)

- 13+ (API 33): `LocaleManager.setApplicationLocales / getApplicationLocales` — язык приложения хранит система;
  настройки «Язык приложения» и программный выбор — одно значение. Рекомендация Android для приложений со своим
  выбором языка — писать через этот API, чтобы оба места совпадали. Система сама сохраняет его при переустановке
  из бэкапа устройства. `LocaleManager.getSystemLocales()` — список языков устройства без языка приложения.
- 14+ (API 34): `setOverrideLocaleConfig` — список языков в настройках можно менять во время работы.
- Ниже 13 системного выбора языка приложения нет.
- AAB: Play ставит только языковые сплиты языков устройства. Язык приложения вне их → нативные ресурсы этого языка
  не установлены (JS-строки не страдают — они в бандле).
- Пункт «Язык» в настройках приложения появляется, только если в манифесте есть `localeConfig`.

## Противоречия

- Решение владельца 1 (`AURAI-0010`): выбор — файл на телефоне + «последнее изменение побеждает». На Android 13+ это
  даёт случай, когда новое действие проигрывает: система en, в приложении выбран de, потом в настройках выбран
  English → системный язык «не сменился» (en = en), приложение остаётся на de. И меню выделения / TalkBack при
  выборе в приложении остаются на языке устройства. Решение — в спеке (вопрос 1 владельцу).
- `AURAF-0023-007` говорит «запросы доступа (камера, фото)» — на Android таких текстов нет (см. выше); строка
  целиком закрывается только после iOS-части.
