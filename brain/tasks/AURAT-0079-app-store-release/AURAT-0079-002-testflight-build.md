# AURAT-0079-002 — Первая сборка iOS в TestFlight и первый пуш на iPhone

Дата: 2026-09-18
Решение владельца: **«сначала TestFlight, решение по платежам потом»**

## Итог

Сборка **1.0.0 (1)** собрана против прода (`https://bff.aura-app.cc`), загружена
в TestFlight и проверена на iPhone 14 Pro Max (iOS 26.6.1):

| Проверка | Итог |
|---|---|
| Вход по реальному номеру | прошёл **без reCAPTCHA** — проверка приложения идёт тихим пушем APNs |
| Токен устройства | в проде появился первый `ios`-токен (19:18:34 UTC) |
| Сообщение ↔ чаттер | ответ советника сохранён 19:19:50 |
| **Пуш на iPhone** | **пришёл**; `fcm-fanout` `completed=1 failed=0` |
| Логи BFF | предупреждений и ошибок 0 |

**Это закрывает `TECH-DEBT` #6.** Пушей на iOS не было ни разу за всё время
проекта; теперь есть ключ, право в сборке, токен и доставленный пуш.

## Что понадобилось со стороны владельца

- Аккаунт Apple Developer организации, Team ID `6D62F96H2N`.
- Ключ APNs `RPFSU5KQLB` (Sandbox & Production, Team Scoped) → Firebase.
- **Освобождение bundle id.** `cc.silvermind.aura` был занят прежней командой
  `7CP3SB86G2` (App ID завёл Xcode в `AURAT-0043`); владелец удалил его там и
  зарегистрировал заново в команде организации с Push Notifications.
- Приложение в App Store Connect: `6813629245`, SKU `aura-ios-001`.
- Регистрация устройства (UDID `00008120-001425281E44C01E`).
- Ключ App Store Connect API `Y597YZ5Q6C`, issuer
  `9bc0ba73-046e-410f-9499-ecfedfebab2a`, роль App Manager. Файл лежит у
  владельца и скопирован в `~/.appstoreconnect/private_keys/` (права `600`).

## Правки в репозитории

| Файл | Что |
|---|---|
| `ios/PsychoApp.xcodeproj/project.pbxproj` | `DEVELOPMENT_TEAM` `7CP3SB86G2` → `6D62F96H2N`; `MARKETING_VERSION` `1.0` → `1.0.0` |
| `ios/PsychoApp/Info.plist` | `ITSAppUsesNonExemptEncryption = false` |
| `ios/Podfile.lock` | `pod install` после смены зависимостей |
| `TECH-DEBT.md` | строка #6 закрыта |

## Подпись: три тупика и рабочий путь

Шаблон React Native держит в конфигурации Release сертификат **разработчика**.
При сборке из окна Xcode подпись подменяется на распространительную, при сборке
командой — нет.

1. **Как есть** → `xcodebuild` просит профиль разработчика, а его нельзя
   создать: «Your team has no devices». У новой команды не было ни одного
   устройства.
2. **Прописать `Apple Distribution` вручную** → конфликт: автоподпись не
   разрешает задавать сертификат руками.
3. **Пустое имя сертификата** → сборка проходит, но приложение **не подписано
   и без `aps-environment`**. Экспорт подписывает его распространительным
   сертификатом, однако права берутся из самого приложения, а их нет. Такая
   сборка ставится и молчит — ровно то, что описывает `TECH-DEBT` #6.
4. **Ручная подпись профилем, созданным Xcode** → два отказа: профиль
   Xcode-managed нельзя указывать вручную, и распространительного сертификата
   **нет в связке ключей** — он облачный, закрытый ключ хранится у Apple.

**Рабочий путь:** зарегистрировать устройство → собрать архив **автоматической**
подписью (получается сертификат разработчика и `aps-environment: development`)
→ экспортировать методом `app-store-connect`, при экспорте Xcode переподписывает
облачным распространительным сертификатом и подставляет права из профиля App
Store, включая `aps-environment: production`.

Команды (параметры подписи в файлы проекта не заводились):

```bash
cd ios && RCT_NEW_ARCH_ENABLED=1 pod install
AURA_ENV=prod RCT_NEW_ARCH_ENABLED=1 xcodebuild -workspace PsychoApp.xcworkspace \
  -scheme PsychoApp -configuration Release -destination 'generic/platform=iOS' \
  -archivePath <path>/Aura.xcarchive -allowProvisioningUpdates archive
xcodebuild -exportArchive -archivePath <path>/Aura.xcarchive \
  -exportPath <path>/ios-export -exportOptionsPlist <path>/exportOptions.plist \
  -allowProvisioningUpdates
xcrun altool --upload-app -f <path>/ios-export/PsychoApp.ipa -t ios \
  --apiKey Y597YZ5Q6C --apiIssuer 9bc0ba73-046e-410f-9499-ecfedfebab2a
```

`exportOptions.plist`: `method = app-store-connect`, `teamID = 6D62F96H2N`,
`signingStyle = automatic`.

**`pod install` требует `RCT_NEW_ARCH_ENABLED=1`**: podspec
`@mattermost/react-native-paste-input` 2.0.1 без этой переменной прерывает
установку. На Android новая архитектура включена в `gradle.properties`.

## Экспортное соответствие

После загрузки сборка получила `processingState VALID`, но
`usesNonExemptEncryption` был пуст — Apple держит такую сборку до ответа про
шифрование. Ответ проставлен через App Store Connect API (`PATCH /v1/builds`),
а в `Info.plist` добавлен `ITSAppUsesNonExemptEncryption = false`, чтобы ответ
ехал вместе с каждой следующей сборкой. Шифрование у нас только HTTPS/TLS —
это исключение.

## Открыто

1. **Платежи на iOS.** Кошелёк и платные сессии в этой сборке выключены.
   Развилка из `001`: выпускать без платной части или строить рельс StoreKit.
2. **Trader status (DSA)** в App Store Connect → Business — без него нет
   выпуска в ЕС.
3. Карточка в App Store: тексты, скриншоты 6.9″, App Privacy, возрастной
   рейтинг, демо-аккаунт для ревью.
