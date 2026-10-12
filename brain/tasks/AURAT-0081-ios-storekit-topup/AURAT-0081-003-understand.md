# AURAT-0081-003 — Что просит владелец

Дата: 2026-09-30

Включить рельс пополнения кошелька на iOS через StoreKit: тот же хук
`useStoreTopUp`, те же четыре продукта, тот же порядок «сервер начислил →
`finishTransaction`», привязка покупки к `purchaseAccountId` через
`appAccountToken`, выкуп через `POST /v1/wallet/top-ups/apple`
`{transactionId, productId}`, подметание незавершённых транзакций на старте.
API `react-native-iap` сверить по установленной 16.3.1, а не по памяти.

В ту же сборку: `TARGETED_DEVICE_FAMILY` → `"1"`, `CURRENT_PROJECT_VERSION` → 2.
Серверная половина — `AURAT-0082`, не эта задача.
