# AURAT-0081-004 — Контекст

Дата: 2026-09-30

## Код (ground truth)

- `features/store-topup/model/use-store-topup.ts` — `live` требует
  `Platform.OS === 'android'`; `redeem` приводит к `PurchaseAndroid` и шлёт
  `purchaseToken`; подметание — `getAvailablePurchases()`; `requestPurchase`
  передаёт только `google: {skus, obfuscatedAccountId}`; ошибки кроме
  `UserCancelled` ставят `failed`.
- `api/store-topup-api.ts` — только `redeemGooglePurchase`.
- `config/products.ts`, `model/types.ts`, `shared/config/env.ts`,
  `env/README.md` — комментарии говорят «Google Play / только Android».
- Тест `the rail is inert on iOS` — закрепляет старое поведение, его придётся
  перевернуть. `jest.setup.js` мокает iap без `getPendingTransactionsIOS` и
  с `ErrorCode` только `UserCancelled`.
- `ios/PsychoApp.xcodeproj/project.pbxproj`: `CURRENT_PROJECT_VERSION = 1`,
  `TARGETED_DEVICE_FAMILY = "1,2"` — по две строки (Debug, Release).
  `Info.plist` берёт `CFBundleVersion` из `$(CURRENT_PROJECT_VERSION)`.
- Архив для TestFlight (`AURAT-0079-002`) собирался с одним `AURA_ENV=prod` —
  а в `env/.env.prod` оба флага биллинга `false`. **Сборка 1 ушла без
  кошелька вообще**; для сборки 2 флаги надо передать, как в `aab:prod`.

## react-native-iap 16.3.1 (openiap spec 3.2.1, apple 3.2.1) — проверено по `lib/typescript` и `ios/Pods/openiap`

- `PurchaseIOS.transactionId: string` — обязательное поле; `id` — тот же
  `String(transaction.id)`. `purchaseToken` на iOS — **JWS**, не id: слать его
  нельзя, сервер ждёт `transactionId`.
- `PurchaseIOS.appAccountToken?: string | null` — Apple возвращает UUID.
- Запрос: `requestPurchase({ request: { apple: { sku, appAccountToken } }, type: 'in-app' })`.
  Нативная сторона проверяет UUID и **бросает ошибку** на не-UUID
  (`StoreKitTypesBridge.swift:392-406`), а не молча теряет поле.
- `purchaseState` на iOS всегда `'purchased'` (`StoreKitTypesBridge.swift:133`).
  Ask to Buy приходит **ошибкой** `ErrorCode.DeferredPayment`
  (`'deferred-payment'`), а покупка потом — через `Transaction.updates`.
- `getAvailablePurchases()` на iOS = `Transaction.all` (незавершённые
  расходуемые туда входят). `getPendingTransactionsIOS()` =
  `Transaction.unfinished` — ровно то, что надо подмести, и заодно кладёт
  транзакцию в кэш, из которого `finishTransaction` её завершает.
- `finishTransaction({purchase, isConsumable})` на iOS ищет по `purchase.id`.
- `purchaseUpdatedListener` на iOS дедуплицирует повторы одного
  `transactionId` за соединение (`dedupeTransactionIOS`, по умолчанию true);
  незавершённые транзакции StoreKit сам присылает в `Transaction.updates`
  при старте — наш `handled` покрывает двойную доставку.

## Контракт

Прецедент `AURAT-0026-005`: схему рельса Play завела задача приложения в
`@aura/contracts` (v0.7.0), аддитивно, с тегом. Репозиторий
`aura-contracts` чистый, `main` = `v0.19.0`. Пуш тега — наружу, спрашивается
отдельно.

## Противоречия

Нет. Замечание: `001-initial` говорит «StoreKit отдаёт неподтверждённую
покупку при каждом запуске» — верно, и 16.3.1 даёт для этого отдельный вызов.
