# AURAT-0093-005 — Спека

Дата: 2026-10-17

Тип: **фича + задача**. Спека — `brain/features/AURAF-0017-first-session-offer/AURAF-0017-first-session-offer.md`
(Status: draft). Эта задача (`AURAT-0093`) — исполнение в `aura-app`, slave-0.
Серверная часть (`aura-contracts` v0.21.0 + `aura-bff`) — отдельная задача в
`aura-bff-manor`, ID выдаётся здесь при одобрении.

Коротко:
- BFF: −50% вместо −$5, хранение то же (`sessions.creditMinor`), без миграций;
  признак `firstSessionOffer {active, pct}` в `GET /v1/wallet`; `offerPct` в
  pricing; `discountMinor` в `Session`.
- App: сущность `entities/offer` (`PriceTag`, `OffChip`, `CouponTicket`,
  `useFirstSessionOffer`), иконки `percent`/`sale`, все поверхности по
  `OFFER.md` §2 + quick book sheet + детали сессии.
- 4 открытых вопроса владельцу: возврат оффера при отмене, округление,
  продление, барьер $10-тира.

Ждём одобрения владельца.
