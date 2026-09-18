# AURAT-0079-001 — Релиз в App Store: аккаунт, ключ APNs и что мешает дальше

Дата: 2026-09-18
Статус: **в работе**, ведёт манор `aura-app-manor` вместе с владельцем
Основа: `AURAS-0002` (Play, для сравнения), `TECH-DEBT.md` #6 (iOS без пушей),
`AURAT-0043` (iOS: entitlements, bundle id, сборка), `AURAT-0076` (релиз в Play)

## Сделано 2026-09-18

- **Аккаунт Apple Developer оплачен ($99/год) и активен.** Тип —
  **организация**, «Silvermind OÜ», **Team ID `6D62F96H2N`**. Это новая
  команда: прежняя, под которой Xcode собирал iOS в августе, — `7CP3SB86G2`.
- **Ключ APNs создан:** `Aura APNs`, **Key ID `RPFSU5KQLB`**, конфигурация
  **Sandbox & Production**, ограничение **Team Scoped (All Topics)**. Среду и
  тип ограничения после сохранения поменять нельзя, поэтому выбраны обе среды:
  `Sandbox` покрывает только сборки из Xcode, а нам нужны TestFlight и App
  Store.
- **Ключ загружен в Firebase** (`aura-2781b` → Cloud Messaging → Apple app
  configuration → **Aura (iOS)**, `cc.silvermind.aura`,
  `1:1022442840784:ios:16fa182197eb4117d734d5`) — в обе строки, development и
  production, с Key ID и Team ID.

  Файл `.p8` Apple отдаёт один раз; хранится у владельца вне репозиториев.

**Это закрывает половину `TECH-DEBT` #6**: причина, по которой на iOS не
работали пуши, устранена. Проверить вживую можно будет только на сборке под
новой командой — пока не проверено.

## Что мешает двигаться дальше

1. **Bundle id `cc.silvermind.aura` занят прежней командой `7CP3SB86G2`.**
   App ID там завёл Xcode в `AURAT-0043` (сборка с `-allowProvisioningUpdates`).
   У Apple bundle id уникален глобально, поэтому в команде организации он не
   регистрируется: «An App ID with Identifier 'cc.silvermind.aura' is not
   available».

   Пути: удалить идентификатор в старой команде (Identifiers → Remove) —
   приложение под ним не публиковалось, строка освобождается; либо обращение в
   поддержку Apple о переносе; либо другой bundle id для iOS, что тянет новое
   iOS-приложение в Firebase, замену `GoogleService-Info.plist` и схемы
   возврата.

2. **Платежей на iOS нет.** Пополнение кредитов включается только на Android
   (`Platform.OS === 'android'` в `features/store-topup/model/use-store-topup.ts`,
   библиотека Play Billing), а BFF проверяет только чеки Google
   (`POST /v1/wallet/top-ups/google`). Apple требует свой In-App Purchase.

   Развилка владельцу: выпускать iOS без платной части (скрыть кошелёк,
   пополнение и платные сессии) или строить рельс StoreKit — продукты в App
   Store Connect, покупка в приложении, проверка чека на сервере, начисление в
   тот же кошелёк. Второе по объёму — как `AURAT-0026` плюс `AURAT-0027`.

3. **Trader status (DSA)** в App Store Connect → Business. Без него приложение
   нельзя выпускать в ЕС, а именно ЕС — основной рынок (`AURAT-0076`).

4. **Team ID в проекте.** В `ios/PsychoApp.xcodeproj` зашит `DEVELOPMENT_TEAM =
   7CP3SB86G2`. Перед сборкой заменить на `6D62F96H2N`.

## Маршрут (по образцу `AURAT-0076`)

1. Освободить bundle id → зарегистрировать App ID в команде организации с
   Push Notifications.
2. Создать приложение в App Store Connect: iOS, `Aura — Psychic Reading`,
   английский (США), SKU `aura-ios-001`.
3. Trader status, App Privacy (перенести ответы Data safety), возрастной
   рейтинг 18+, демо-аккаунт для ревью (тестовый номер Firebase), экспортное
   соответствие (только HTTPS).
4. Сборка: сменить `DEVELOPMENT_TEAM`, архив с `AURA_ENV=prod`, сертификаты и
   профиль Xcode создаёт сам; TestFlight.
5. Проверка на устройстве против прода — как `AURAT-0076-002` для Android.
6. Отправка на ревью.

## Расходы

$99 в год, в общей картине — `AURAS-0004`, раздел «What the whole thing costs».
