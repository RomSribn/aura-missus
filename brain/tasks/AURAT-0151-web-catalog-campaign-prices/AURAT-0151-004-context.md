# AURAT-0151-004 — Контекст

Дата: 2026-11-01

## Сервер (aura-bff `c8d78cf`)
- `sessions/session-discount.ts` `priceBlock`: скидка оффера `firstSessionDiscount(subtotal)` (если оффер
  доступен) и кампании `discountMinor(subtotal, pct)`; кампания выигрывает при `campaignMinor > 0 &&
  campaignMinor >= offerMinor` (ничья → кампания), иначе оффер, иначе ничего. Никогда не сумма.
- `discountMinor` = `subtotal − floor(subtotal·(100−pct)/100)` → цена со скидкой = `floor(subtotal·(100−pct)/100)`.
  У веба это уже `discountedMinor` (`shared/lib/format.ts`) — тот же floor.
- `app-config.discount` и `promo` — `null` при выключенном биллинге (контракт `v0.27.0`); `label` — строка без
  предела длины, `pct` 1…100.

## Веб (develop `302be99`)
- Цены каталога: `PriceTag` + `OffChip` в `entities/advisor` (`AdvisorRow`, `AdvisorTile`),
  `widgets/advisor-card`, `widgets/advisor-rail`, `pages/advisor` (шапка, боковая карточка, панель действий
  на телефоне), `pages/match` (`MatchCard`). Все берут `offerPct` и считают `discountedMinor(price, offerPct)`.
- `offerPct` страниц: Advisors и Match — `useSessionPricing` (оффер, как его оценил сервер; блок, который
  закрыла кампания, оффером не считается — `offerPctFromPricing`, 0149); Home, Advisor, рейл —
  `useBookingOffer` (кошелёк, если прочитан, и только когда цена его подтверждает). Значит при победе
  кампании на сервере (в т.ч. ничья) `offerPct` уже `null`.
- Тот же `offerPct` решает, какой билет показать (`useSeasonTicket`) — его менять нельзя.
- `entities/season`: `useSeason()` отдаёт живой `discount` (гаснет по своему `endsAt` по часам сервера,
  таймер уже есть). Пары «цена + билет» уже соединяются на страницах передачей `offerPct` в хук сезона
  — без кросс-импорта entities.
- `OffChip`: видимо «−50%», `aria-label` «50% off your first session» (`shared` → `offer.chipLabel`).
- В каждой странице каталога при скидке кампании уже стоит билет DISCOUNT с видимым «Winter sale ·
  20% OFF sessions».
- Шторка брони (`widgets/book-sheet`): ставка в подзаголовке — тоже от `offerPct`; итог и строка скидки
  — от сервера (0149). По просьбе — брони не трогаем.

## Противоречия
Нет. Спека `AURAT-0149-005` §4 («цены на списках скидку кампании не показывают») отменяется решением
владельца 2026-11-01.
