# AURAT-0093-017 — approved

Дата: 2026-10-17
Статус: **done** (app-часть `AURAF-0017`)

Принято владельцем. Код в `develop` (`5428c49`).

## Хвосты
- `AURAT-0094` (BFF + `aura-contracts` v0.21.0) — в работе, `aura-bff-manor`
  slave-1. До его выката приложение показывает старую строку
  «First-session credit», оффер — как только кошелёк пришлёт
  `firstSessionOffer`.
- После тега v0.21.0: поднять `@aura/contracts`, убрать локальный
  `WalletWithOffer` (`entities/wallet/api/wallet-api.ts`).
- Барьер пополнения $10 (вопрос 4 спеки) — отдельная задача, ID не выдан.
- iOS: тень/вырезы/блик купона и позиция зачёркивания проверены только на
  Android.
