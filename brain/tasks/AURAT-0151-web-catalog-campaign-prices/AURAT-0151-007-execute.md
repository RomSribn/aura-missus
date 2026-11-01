# AURAT-0151-007 — Выполнение

Дата: 2026-11-01
Ветка: `feature/AURAT-0151-web-catalog-campaign-prices` (от develop `302be99`), не закоммичено — на ревью.

## Что сделано
- **Правило** — `entities/season/lib/price-discount.ts` `priceDiscount(offerPct, campaign)`: большая из
  оффера и кампании, ничья → кампания, как `priceBlock` сервера. Хук `usePriceDiscount(offerPct)`
  (`entities/season/model`) берёт живой `discount` из `useSeason()` (гаснет по `endsAt`), отдаёт один
  стабильный объект (`useMemo`) — memo-строки не перерисовываются.
- **Тип `PriceDiscount`** `{ pct, label }` — в `shared/lib/format.ts` рядом с `discountedMinor` (отдельный
  модуль поднял бы `shared/lib` до 16 модулей — Steiger против).
- **`OffChip`** — необязательный `label`: чип «−20%», `aria-label` и `title` «20% OFF · Winter sale».
  Новый ключ `shared` → `offer.chipCampaignLabel` на всех 24 языках — переводы той же строки
  `book-session` → `total.campaign` (0149), слово в слово.
- **Цены** — `discount` вместо `offerPct` в `AdvisorRow`, `AdvisorTile`, `AdvisorCard`, `MatchCard`;
  считают его модели `use-advisors-page`, `use-home-page`, `use-match-page`, `use-advisor-page` (шапка,
  боковая карточка + чип, панель на телефоне), `AdvisorRail`, и **`use-book-sheet`** (ставка в
  подзаголовке шторки — правка владельца `-006`). Итог и строка скидки брони не тронуты.
- `offerPct` остался там, где он про оффер: билеты, «How Aura works», `/match` `withOffer`, чат, сессии.

## Проверки
- `price-discount.test.ts` — 6 тестов (нет / оффер / кампания / большая из двух / ничья / floor 199 → 159).
- `app/__tests__/season.test.tsx`, блок «Catalog prices under a campaign» — 6 тестов: оффер потрачен +
  кампания 20 % (199 ¢ → зачёркнуто $1.99, $1.59, чип с именем и `title`); оффер больше — как прежде;
  ничья 50 = 50 → кампания; ничего — без зачёркивания; кампания гаснет по `endsAt` без перезагрузки;
  **шторка брони при кампании и потраченном оффере — ставка зачёркнута к −20 %** ($2.00 → $1.60).
- Мутационная проверка: с выключенной кампанией в `priceDiscount` падают 4 из 6 новых сценариев.
- `lint` (eslint + Steiger) ✓, `typecheck` ✓, `npm test` 107 файлов / 1884 теста ✓, `build` ✓.

## Документы
- `AURAF-0022` строка 007 — дописано про `AURAT-0151` (в работе).

## Открыто
- Нет. Проверка в маноре против bff-dev после мёржа (winter −20 % «Winter sale»: аккаунт с оффером, с
  потраченным, гость).
