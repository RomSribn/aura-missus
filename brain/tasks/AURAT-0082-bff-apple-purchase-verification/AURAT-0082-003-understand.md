# AURAT-0082-003 — Понимание

Дата: 2026-09-30

Сделать серверную половину StoreKit в BFF — зеркало рельса Google:
(1) `POST /v1/wallet/top-ups/apple` `{transactionId, productId}` — спросить
App Store Server API (прод → при промахе, включая `401` от прода, песочница),
проверить подпись JWS до корня Apple, `bundleId`, продукт в общей таблице тиров,
`appAccountToken = purchaseAccountId`, consumable и не отозвана, идемпотентно по
`transactionId`, одна запись в журнал; (2) приём App Store Server Notifications
V2: `REFUND` → компенсирующая запись, `REFUND_REVERSED` → обратно.

Контракт — из `@aura/contracts` v0.20.0. Библиотеку Apple — проверять по
установленной версии. Первый прогон — висящая покупка `usd25` из TestFlight
после деплоя на dev (в маноре, после мёржа).
