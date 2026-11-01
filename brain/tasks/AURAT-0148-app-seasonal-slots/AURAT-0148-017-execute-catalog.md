# AURAT-0148-017 — execute: скидка кампании в ценах каталога (`-015`, закрывает L-9)

Дата: 2026-11-01. Слот `slave-1`, всё в индексе, не закоммичено.

- `entities/campaign/lib/catalog-discount.ts` — `catalogDiscountOf(offerPct, discount)`: большая из живого
  оффера и живой части `discount` (гаснет по `endsAt`, при выключенном биллинге — нет, через `useCampaign`);
  ничья → кампания; суммы нет. `catalogDiscountLine`: «50% OFF First Session» / «20% OFF · Winter sale».
  Ставка — `discountedMinor` (floor, как сервер).
- `useCatalogDiscount(offerPct)` — один на экран, оффер приходит снаружи (без кросс-импорта wallet).
- Список Advisors: `AdvisorRow` (`React.memo`) получает `discountPct` числом — зачёркнутая ставка и чип
  «−20%». AdvisorProfile: `StatsCard` и чип у Book по `discountPct`, доступное имя Book — с
  `discountLine` («…, 20% OFF · Winter sale»). Чат: `SessionInviteCard` / `SessionInviteMessage` — проп
  `discount`, чип и строка «20% OFF · Winter sale — applied for you», без слов о первой сессии.
- `PriceTag` / `OffChip` не менялись — о кампании не знают.
- **Брони — сверка с вебом (AURAT-0151):** ставка /min на Book Session, Quick book и Review уже идёт от
  `ratePct` / `discountPct` цены сервера (после M-2) — при выигравшей кампании она зачёркнута по проценту
  кампании, не оффера. Ничего не менялось.
- Чип короткий «−20%», как на вебе; название кампании — в строке приглашения и в доступном имени Book.

Тесты: правило (ничья, оффер больше / меньше, оффер потрачен, кампании нет, не сумма, floor на нечётных
центах, подписи), `SessionInviteCard` для кампании, экран Advisors при кампании и потраченном оффере
($1.99 → $1.59, «−20%», нет «First Session»). `tsc` ✓, `eslint` ✓, jest 153 / 1151 ✓.

**В список проверок на устройстве (к 10 из `-013`):**
11. Каталог при winter −20 %: аккаунт с живым оффером — «−50%» и ставка вдвое; аккаунт с потраченным —
    «−20%», ставка −20 %, приглашение в чате «20% OFF · Winter sale», в брони то же по цене сервера.
