# AURAT-0095-004 — Контекст

Дата: 2026-10-17

## Diff `aura-contracts` v0.20.0..v0.21.0 (один коммит `0f35b76`)
- `src/wallet.ts`: новая схема `FirstSessionOffer = { active: boolean, pct: int 1..100 }`
  (+ тип), `WalletResponse.firstSessionOffer: FirstSessionOffer.optional()`.
  **Совпадает байт-в-байт** с локальным `.extend()` в `wallet-api.ts`
  (тот же `z.number().int().min(1).max(100)`, тот же `optional`).
- Смысл по контракту: `active` — ответ сервера (true до сессии, использовавшей
  оффер; возвращается при полной отмене); `pct` — для формулировок, суммы — из
  `SessionPricing`. Это ровно то, что делает app: `firstSessionOfferPct =
  active ? pct : null`, а цены/экономия берутся из `creditMinor`/`costMinor`.
- `src/session.ts`: только комментарии — `creditMinor` теперь документирован как
  «скидка первой сессии, `subtotal − cost`, имя осталось от $5». Схема та же.
  App уже трактует `creditMinor > 0` как «оффер применён» (`use-booking`,
  `use-booking-confirm`, `DurationPicker`, `QuickBookSheet`) — согласовано.
- README, `package.json` version — без влияния.

## Код app
- `WalletWithOffer` (схема + тип) используется только в `wallet-api.ts`
  (`fetchWallet`); снаружи слайса не экспортируется. Стор/хук читают
  `wallet.firstSessionOffer?.active/pct` — с контрактным типом компилируется так же.
- `zod` в app `^3.25.76`, peer контрактов `^3.23.0` — ок.
- В `slave-1/master/node_modules` лежит устаревший `@aura/contracts` 0.14.0
  (lock — 0.20.0): перед гейтами нужен `npm install`.

## Противоречий нет.
