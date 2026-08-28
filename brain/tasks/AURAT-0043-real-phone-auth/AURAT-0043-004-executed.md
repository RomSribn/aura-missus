# AURAT-0043-004 — Что сделано, что осталось владельцу

Дата: 2026-08-28
Ветка: `feature/AURAT-0043-real-phone-auth` (slave-1), от `develop` @ `e23eaac`
Проверено: `tsc --noEmit` чисто, `eslint .` чисто, `jest` — **70 наборов, 466
тестов, все зелёные**
**Не проверено:** ничего на устройстве. Слейв не запускает стек — это манор
после мержа

## Код

### Стена 1 — набрать не-испанский номер

- `shared/config/countries.ts` — **245 стран**, сгенерировано из
  `libphonenumber-js@1.13` + `Intl.DisplayNames` там, где был полный ICU.
  Названия, порядок сортировки и свёрнутые ключи поиска запечены на этапе
  генерации: `Intl` в Hermes ненадёжен, а список, который на одном телефоне
  читается словами, а на другом кодами, — тот же дефект, что `formatClockTime`
  уже обходит вручную.
- `shared/lib/phone.ts` — `toE164`, `isCompleteNumber`, `formatNational`,
  `maxNationalDigits`, `nationalPlaceholder`, `flagEmoji`, `formatPhoneNumber`.
  Всё делегирует библиотеке: правила для 245 стран руками не ведутся.
- `screens/phone-auth/ui/CountryPickerSheet.tsx` — лист с поиском по названию,
  ISO-коду и коду набора (`+380` и `380` одинаково), строка `React.memo`,
  `getItemLayout`.
- `screens/phone-auth/lib/country-search.ts`, `lib/device-country.ts` —
  сопоставление и стартовая страна.
- Плитка страны **получила `onPress`**. До этого это был `TouchableOpacity`
  без обработчика — нажималась и не делала ничего.

Три бывших испанских правила сняты: `+34` больше не константа, `length >= 9`
стал `isCompleteNumber(digits, country)`, группировка `3-3-3` стала
`AsYouType` по стране. Здесь **сознательное расхождение с
`AUTH_PHONE_SMS.md` §1**, который просит `XXX XXX XXX`: спека рисовалась при
зашитом `+34`, и группировать 244 страны по-испански было бы неверно. Сама
спека на это и указывает — «adjust the max-length/validation per country».

Стартовая страна берётся **из локали устройства**, а не запоминается между
запусками: хранилища ключ-значение в проекте нет вообще, а заводить его — это
нативный модуль и `pod install`, которого слейву нельзя, ради настройки, важной
один раз за установку. Оба чтения (`SettingsManager` на iOS, `I18nManager` на
Android) — ядро RN и оба под `try`, с падением на `ES`.

### Стена 5 — `__DEV__` выключал проверку в каждой дев-сборке

- `AURA_AUTH_TEST_MODE` объявлен в `env/resolve.js`, задокументирован в
  `env/README.md`, добавлен в `.env.dev`, `.env.prod`, `.env.tunnel` —
  **`false` везде**.
- `shared/config/env.ts` экспортирует `AUTH_TEST_MODE`;
  `auth.service.ts` читает его вместо `__DEV__`.

Теперь дев-сборка по умолчанию проверяет настоящий номер по-настоящему.

### Стена 3 — у iOS не было возможности пуша

- `ios/PsychoApp/PsychoApp.entitlements` (`development`) и
  `PsychoAppRelease.entitlements` (`production`);
  `CODE_SIGN_ENTITLEMENTS` прописан в **обе** конфигурации `project.pbxproj`.
- `PRODUCT_BUNDLE_IDENTIFIER` в обеих конфигурациях →
  **`cc.silvermind.aura`**.
- Новое iOS-приложение зарегистрировано в Firebase (см. ниже), новый
  `GoogleService-Info.plist` положен на место, **схема возврата в `Info.plist`
  переписана под новый `GOOGLE_APP_ID`**.

### Ошибки и поведение при отказе

- `AuthError` с `code` и `cause`; экспортированы `AUTH_REGION_BLOCKED` и
  `AUTH_RATE_LIMITED`.
- Карта ошибок сгруппирована по тому, что человек может сделать: исправить
  номер, подождать, ничего. Добавлены коды, которых раньше не было и которые
  реальные номера начнут приносить, как только проверка перестанет быть
  выключенной: `invalid-app-credential`, `missing-client-identifier`,
  `app-not-authorized`, `unauthorized-domain`, `captcha-check-failed`.
- **Отказ по региону** ловится по тексту ответа, а не по коду — документированного
  клиентского кода у него нет. Ветка помечена как требующая подтверждения на
  устройстве.
- `Alert.alert` убран с обоих экранов: сообщение теперь в экране, рядом с полем,
  и его можно перечитать.
- **Тряска четырёх ячеек** при неверном коде (`AUTH_PHONE_SMS.md` §4) — её
  просили, её не было.
- `console.error(error)` заменён на `console.warn` с кодом и местом вызова:
  объект ошибки носит в себе номер телефона, а PII в логи нельзя.

### Заодно

`formatPhoneNumber` больше не предполагает девять цифр — экран профиля покажет
номер любой страны. Старые `formatPhoneGroups` / `formatPhoneNumber` из
`lib/format.ts` удалены вместе с их тестами (правило 5: экспортов без
потребителей не бывает).

### Тесты

`shared/config/__tests__/countries.test.ts`, `shared/lib/__tests__/phone.test.ts`,
`screens/phone-auth/lib/__tests__/country-search.test.ts` — 33 новых.

Отдельно стоит назвать один: таблица стран **сверяется с библиотекой на каждом
прогоне**. Расхождение кода набора после обновления `libphonenumber-js` уронит
набор тестов, а не чей-то вход.

## Записи в боевые проекты (одобрены владельцем поимённо)

| Действие | Результат |
|---|---|
| `POST projects/aura-2781b/iosApps` | **`1:1022442840784:ios:16fa182197eb4117d734d5`**, bundle `cc.silvermind.aura`, `ACTIVE`. Старое приложение под шаблонным id **не тронуто** |
| `gcloud services enable playintegrity.googleapis.com` | Включён, подтверждён в списке |
| `smsRegionConfig` | **Не тронут** — решение владельца, см. `-003` |

## Осталось владельцу — без этого ничего не проверить

1. **Привязать платёжный аккаунт.** Пока проект на Spark, реальной SMS не будет
   ни при какой правке кода (`-003`, `TECH-DEBT` #7). Платёжных аккаунтов у вас
   ноль, значит пробный период ($300 / 90 дней) скорее всего доступен.
2. **Загрузить APNs Auth Key** в `aura-2781b` для `cc.silvermind.aura` —
   Firebase Console → Project settings → Cloud Messaging. Нужен аккаунт Apple
   Developer. Без него iOS не подтвердит приложение и не примет пуши.
3. **Связать приложение в Play Console** с Play Integrity.
4. **Расширять `smsRegionConfig` по одному `PATCH`** по мере появления рынков.

## Замечено и намеренно не сделано

- ~~`CFBundleDisplayName` на iOS до сих пор `PsychoApp`~~ — **поправлено по
  просьбе владельца в том же проходе**: под иконкой теперь `Aura`, как на
  Android. Изменён **только** этот ключ: `CFBundleName` остаётся
  `$(PRODUCT_NAME)`, потому что на `PRODUCT_NAME` завязаны `withModuleName:` в
  `AppDelegate` и `AppRegistry.registerComponent` из `app.json` — переименование
  там приложение не переименовало бы, а не дало бы ему смонтироваться.
- **App Check в проекте нет** (`@react-native-firebase/app-check` не в
  зависимостях). Google называет его вторым механизмом защиты от SMS-abuse
  рядом с региональной политикой. Отдельная задача: это нативная зависимость.
- Первая сборка iOS с entitlements **должна быть проверена в маноре** —
  автоматической подписи предстоит добавить возможность Push к App ID, и слейв
  этого проверить не может.

## Приёмка

Пункты 2–6 из `-001` проверяемы как есть. Пункт 1 — реальный номер — ждёт
платёжного аккаунта.

---

## Дополнение 2026-08-28 — сборки в маноре после мержа

Мерж в `develop` локальный (`1ef4e32`), origin не тронут по решению владельца.
В маноре доставлен `libphonenumber-js`, перепроверено: tsc чисто, eslint чисто,
466 тестов зелёные.

### Android — собрано, поставлено, работает

`assembleDebug` → `BUILD SUCCESSFUL`. APK (`cc.silvermind.aura`, versionCode 12)
установлен на устройство `R58M37RG00M`, запущен, бандл загрузился, **в logcat ни
одной ошибки RN**. В сборке зашит `AURA_AUTH_TEST_MODE=false`, то есть это
именно тот режим, ради которого задача и делалась.

### iOS — то, ради чего всё и затевалось

Первая сборка под устройство **упала ровно там, где и предсказывалось**:

```
error: Provisioning profile "iOS Team Provisioning Profile: *"
       doesn't include the Push Notifications capability.
error: ... doesn't include the aps-environment entitlement.
```

Профиль был **wildcard**, а wildcard App ID пуши нести не может в принципе. То
есть отказ сборки — это не поломка от правки, а её работа: до `AURAT-0043`
таргет не объявлял entitlements вовсе, wildcard-профиля хватало, и iOS молча
оставался без пушей и без проверки приложения. Теперь Xcode отказывается
собирать бинарь, который всё равно не смог бы подтвердиться.

С `-allowProvisioningUpdates` (одобрено владельцем) Xcode завёл явный App ID.
**Проверено на диске, а не по логу:**

```
profile: iOS Team Provisioning Profile: cc.silvermind.aura
app-id: 7CP3SB86G2.cc.silvermind.aura
aps-environment: development
```

Итог сборки — `** BUILD SUCCEEDED **`, `XCODEBUILD_EXIT=0`, ошибок ноль.
Проверено в готовом `.app`:

| Что | Значение |
|---|---|
| `codesign` Identifier / Team | `cc.silvermind.aura` / `7CP3SB86G2` |
| entitlements, вшитые в бинарь | `7CP3SB86G2.cc.silvermind.aura`, `aps-environment: development` |
| `CFBundleIdentifier` | `cc.silvermind.aura` |
| `CFBundleDisplayName` | `Aura` |
| `BUNDLE_ID` в Firebase-плисте внутри `.app` | `cc.silvermind.aura` — совпадает |
| схема возврата против `GOOGLE_APP_ID` | `app-1-1022442840784-ios-16fa182197eb4117d734d5` — **совпадает** |

Последняя строка важнее прочих: именно рассогласование схемы и `GOOGLE_APP_ID`
было ловушкой, названной в `-002`, и она проверена машиной, а не глазами.

### Ловушка на будущее: два Metro за один кэш

Между двумя iOS-сборками была ещё одна неудача, и она **не относится ни к коду,
ни к подписи**. Скрипт `Bundle React Native code and images` запускается с
`--reset-cache` и сносит общий `$TMPDIR/metro-cache`. Если в этот момент
работает Metro (например, поднятый для Android-устройства), он пишет туда же:

```
Error: ENOTEMPTY: directory not empty, rmdir '.../T/metro-cache/fa'
    at FileStore.clear (metro-cache/src/stores/FileStore.js:58)
```

Лечится тем, что iOS-сборке даётся свой `TMPDIR`. Стоит помнить: симптом
выглядит как поломка сборки, а причина — соседний процесс.

## Что теперь осталось владельцу

Список из `-001` сократился на два пункта — App ID с Push заведён, Play
Integrity включён. Осталось:

1. **Платёжный аккаунт** — без него реальной SMS не будет (`TECH-DEBT` #7).
2. **Ключ APNs** в `aura-2781b` для `cc.silvermind.aura`. Это **последнее**, что
   отделяет iOS от рабочего телефонного входа и рабочих пушей.
3. **Связка в Play Console** с Play Integrity.
