# AURAT-0082-002 — Проверка состояния

Дата: 2026-09-30
Слэйв: `slave-2`, ветка `feature/AURAT-0082-bff-apple-purchase-verification`
(master и missus), `active-work.md` уже обновлён.

## Что найдено

- Папка задачи есть, только `001-initial.md` (заведено из `aura-app-manor`
  2026-09-25, дополнено ключом 2026-09-30). Работа не начата.
- Решение: `AURAD-0017` (accepted). Опирается на `AURAD-0010` (пять правил рельса).
- Прецедент в коде: рельс Google — `AURAT-0027` (начисление), `AURAT-0077`
  (возвраты). Модули `src/modules/play/*`, `src/modules/wallet/play-*`,
  модель `PlayPurchase`.
- Половина приложения: `AURAT-0081`.

## Что изменилось с момента заведения (слова владельца, 2026-09-30)

- Контракт опубликован: `@aura/contracts` **v0.20.0** (тег на
  `github:RomSribn/aura-contracts`) — `AppleTopUpRequest {transactionId,
  productId}`, `AppleTopUpResponse` (форма = `GooglePlayTopUpResponse`).
  Зависимость бампнуть с v0.19.0 на v0.20.0.
- `AURAT-0081` смёржена в `aura-app` develop, в TestFlight (сборка 2).
  Приложение шлёт `POST /v1/wallet/top-ups/apple` с `transactionId` (не JWS),
  `appAccountToken = purchaseAccountId` кошелька, `finishTransaction` — только
  после 2xx.
- У владельца висит незавершённая песочная покупка `aura.topup.usd25` из
  TestFlight — после деплоя на dev она должна выкупиться при следующем запуске
  приложения. Это готовый первый прогон.
- Песочный тестировщик **не нужен**: TestFlight идёт в песочнице под обычным
  Apple ID (пункт «что ещё нужно от владельца» в 001 устарел).
- Требование: API библиотеки для App Store Server API проверять по
  **установленной** версии, не по памяти.

## Дальше

003 — понимание, 004 — контекст (код Play-рельса, библиотека Apple).
