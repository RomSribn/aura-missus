# AURAT-0081-007 — Исполнение

Дата: 2026-09-30
Слот `slave-0`, ветка `feature/AURAT-0081-ios-storekit-topup`. **Не закоммичено**,
застейджено для ревью.

## aura-contracts (отдельный репозиторий, `main`, не закоммичено)

- `src/wallet.ts` — `AppleTopUpRequest {transactionId, productId}`,
  `AppleTopUpResponse` (= форма `GooglePlayTopUpResponse` под своим именем).
- `README.md` — строка `wallet` и абзац `v0.20.0`; `package.json` → `0.20.0`.
- `npm run typecheck` / `build` — чисто.
- **Коммит, тег `v0.20.0` и пуш — ждут отдельного «да».** Пока тега нет,
  в `aura-app/node_modules/@aura/contracts` подложен локальный `dist`, а
  `package-lock.json` приложения **не** обновлён: после пуша тега —
  `npm install` в слоте, и lock едет в тот же коммит.

## aura-app

| Файл | Что |
|---|---|
| `features/store-topup/api/store-topup-api.ts` | `redeemApplePurchase` → `POST /v1/wallet/top-ups/apple` |
| `features/store-topup/model/use-store-topup.ts` | `live` на Android **и** iOS; `redeemKey` — на iOS `transactionId` (не `purchaseToken`: там JWS); выкуп по платформе; подметание на iOS — `getPendingTransactionsIOS`; `requestPurchase` несёт `apple.appAccountToken = purchaseAccountId`; `DeferredPayment` не ошибка |
| `features/store-topup/config/products.ts`, `index.ts` | `STORE_NAME` — «App Store» / «Google Play»; комментарии про оба магазина |
| `features/store-topup/model/types.ts` | комментарии |
| `screens/profile/ui/TopUpSheet.tsx` | строка способа оплаты — `STORE_NAME` вместо зашитого «Google Play» |
| `screens/profile/model/use-profile.ts`, `config/constants.ts` | комментарии |
| `shared/config/env.ts`, `env/README.md` | флаг описан для обоих рельсов; `ios:archive:prod`; ловушка `.xcode.env.local` |
| `package.json` | `@aura/contracts#v0.20.0`; скрипт `ios:archive:prod` (`AURA_ENV=prod` + оба флага + `RCT_NEW_ARCH_ENABLED=1` + `xcodebuild archive` → `ios/build/Aura.xcarchive`) |
| `jest.setup.js` | мок: `getPendingTransactionsIOS`, `ErrorCode.DeferredPayment` |
| `…/__tests__/use-store-topup.test.tsx` | тест «инертен на iOS» заменён блоком `on iOS` (7 тестов); UUID вместо `wallet-acct-1` |
| `ios/PsychoApp.xcodeproj/project.pbxproj` | обе конфигурации: `TARGETED_DEVICE_FAMILY = 1`, `CURRENT_PROJECT_VERSION = 2` |

Проверки: `tsc --noEmit` — 0; `npm run lint` — чисто; `jest` — 118 наборов,
825 тестов, всё зелёное (Android-тесты рельса — без правок логики).

## Решения по ходу

- **Надпись «Google Play» в `TopUpSheet`** — вне исходных границ («экраны не
  меняются»), но на iOS это отказ ревью по 2.3.10 (упоминание чужой
  платформы). Правка — одна строка в UI + константа в конфиге слайса.
- Подметание на iOS через `getPendingTransactionsIOS` (`Transaction.unfinished`),
  а не `getAvailablePurchases` (`Transaction.all`) — точная семантика и
  заодно прогревает кэш, из которого `finishTransaction` завершает.

## Открыто

- Пуш `aura-contracts` v0.20.0 (вопрос владельцу) → `npm install` → lock.
- Покупку проверяет только TestFlight-сборка после мёржа **и** деплоя
  `AURAT-0082`; на ревью App Store — только после `AURAT-0082` в проде.
- Отозванная Apple транзакция, которую сервер отвергнет (409), останется
  незавершённой и будет тихо предлагаться при каждом запуске — так же, как на
  Play до авто-возврата. Вреда нет, отмечаю.
