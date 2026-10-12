# AURAT-0081-005 — Спека

Дата: 2026-09-30
Тип: **задача** (отдельной фичи не заводим — это вторая ветка рельса
`AURAF-0010`; после исполнения строка iOS добавляется в её таблицу).
Статус: **draft, ждёт одобрения**

## 1. Контракт — `@aura/contracts` v0.20.0 (аддитивно)

В `aura-contracts/src/wallet.ts`:

- `AppleTopUpRequest = { transactionId: string.min(1), productId: string.min(1) }` —
  ни суммы, ни bundle id, ни JWS (по `AURAD-0017` §2: сервер спрашивает Apple
  сам). `transactionId` — ключ идемпотентности.
- `AppleTopUpResponse` — та же форма, что `GooglePlayTopUpResponse`
  (`entryId, balanceMinor, currency, creditedMinor, replayed`), отдельным
  именем, чтобы рельсы могли разойтись без ломки.

Коммит + тег `v0.20.0` + пуш в `github.com/RomSribn/aura-contracts` —
**отдельный вопрос владельцу** перед пушем. `AURAT-0082` берёт ту же версию.

## 2. Приложение — `features/store-topup`

- `api/store-topup-api.ts`: `redeemApplePurchase(claim)` →
  `POST /v1/wallet/top-ups/apple`, парсинг обеими схемами, как у Google.
- `model/use-store-topup.ts`:
  - `live`: `Platform.OS === 'android' || Platform.OS === 'ios'`, остальные
    условия (флаг, кошелёк, `purchaseAccountId`) — без изменений.
  - `redeem` разветвляется по `purchase.store`/платформе:
    - Android — как было (`purchaseToken`, `purchaseState`);
    - iOS — `transactionId` из `PurchaseIOS` (не `purchaseToken`: на iOS там
      JWS), ключ дедупликации в `handled` — `transactionId`.
    Порядок тот же: сервер → `walletStore.setBalance` → `finishTransaction
    ({purchase, isConsumable: true})`. Отказ сервера — без `finish`.
  - Подметание на старте: Android — `getAvailablePurchases()`; iOS —
    `getPendingTransactionsIOS()` (`Transaction.unfinished`).
  - `requestPurchase`: `request: { google: {skus, obfuscatedAccountId},
    apple: {sku, appAccountToken: purchaseAccountId} }`.
  - `ErrorCode.DeferredPayment` (Ask to Buy) — **не** ошибка, как отмена:
    покупка придёт позже через `Transaction.updates`.
- Комментарии «только Google Play / Android» в `products.ts`, `types.ts`,
  `shared/config/env.ts`, `env/README.md` — поправить на оба магазина.
- `jest.setup.js`: в мок iap — `getPendingTransactionsIOS`,
  `ErrorCode.DeferredPayment`.

## 3. Тесты (jest)

Тест «рельс на iOS инертен» заменяется на iOS-набор:

- покупка на iOS уходит на `/apple` с `transactionId` и `productId`, баланс
  кладётся в `walletStore`, потом `finishTransaction`;
- отказ сервера → `finishTransaction` не вызван, `failed = true`;
- незавершённая транзакция из `getPendingTransactionsIOS` выкупается при
  монтировании; `getAvailablePurchases` на iOS не зовётся;
- та же транзакция дважды (подметание + слушатель) → один выкуп, один finish;
- `requestPurchase` получает `apple.appAccountToken = purchaseAccountId`;
- `DeferredPayment` не ставит `failed`;
- нет `purchaseAccountId` → рельс `unavailable` и на iOS.

Android-тесты остаются как есть и должны пройти без правок.

## 4. iOS-проект (в ту же сборку)

`project.pbxproj`, обе конфигурации: `TARGETED_DEVICE_FAMILY = 1;`,
`CURRENT_PROJECT_VERSION = 2;`. `MARKETING_VERSION` остаётся `1.0.0`.

## 5. Сборка 2 — флаги

Сборка 1 собрана с одним `AURA_ENV=prod`, а в `.env.prod` оба флага `false` —
кошелька в ней нет. Для сборки 2 архив собирается с
`AURA_ENV=prod AURA_BILLING_ENABLED=true AURA_STORE_BILLING_ENABLED=true`.
Предлагаю закрепить это npm-скриптом `ios:archive:prod` рядом с `aab:prod`
(команда из `AURAT-0079-002`), чтобы флаги нельзя было забыть.

## Проверка

В слоте: `npm run lint`, `npx tsc --noEmit`, `npm test`. Покупку в слоте
проверить нельзя — только TestFlight-сборкой после мёржа и после деплоя
`AURAT-0082`.

## Зависимость и риск

С включённым биллингом сборка 2 **продаёт**. Пока нет `AURAT-0082`, выкуп
падает, транзакция остаётся у Apple незавершённой (безопасно — ничего не
списано без начисления, повторится при следующем запуске). Но **на ревью
App Store сборку отдавать только после деплоя `AURAT-0082` в прод**: ревьюер
купит в песочнице, и без начисления это отказ по 2.1.

## Вне границ

Экраны, `TECH-DEBT` #2, серверная часть, уведомления о возвратах.
