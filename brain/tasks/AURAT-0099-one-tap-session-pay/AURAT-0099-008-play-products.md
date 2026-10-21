# AURAT-0099-008 — Лестница продуктов в Play

Дата: 2026-10-21

Владелец попросил завести продукты в Play Console для проверки и выдал
`play-billing-api@aura-2781b` право **Manage store presence** на
`cc.silvermind.aura` (до этого были только *View financial data* и *Manage orders
and subscriptions* — каталог читался, `pricing:convertRegionPrices` давал 403).

## Что сделано (Android Publisher API, ключ `~/Downloads/aura-2781b-dcd1dfc5ef14.json`)

Созданы и активированы 116 продуктов `aura.topup.usd1 … usd120` (без 10/25/50/100).
Каждый — по образцу `aura.topup.usd10`:

| Поле | Значение |
|---|---|
| Покупка | `standard`, `legacyCompatible: true`, `ACTIVE` |
| Цены | `pricing:convertRegionPrices` от **$N** — 174 региона (так ставились прежние четыре: их `newRegionsConfig.usdPrice` = $N); **US = $N − 0.01** (как у прежних: usd10 = $9.99) |
| Новые регионы | конвертированные $N / €… , `AVAILABLE` |
| Листинг | en-US «$N wallet credit» / «Adds $N.00 of credit to your Aura wallet. Use your balance to book paid chat sessions with advisors.» |
| Прочее | тег `topup`, `WITHDRAWAL_RIGHT_DIGITAL_CONTENT`, `regionsVersion` 2026/01 |

Прочитано обратно: в каталоге 120 продуктов, у каждого из 1…120 — `ACTIVE`, 174
региона, US = N·100 − 1 центов; прежние четыре не изменились (сравнение с
выгрузкой до создания байт в байт), посторонних ID нет.

## Заметки

- Курсы со времени создания прежних четырёх сдвинулись: например usd10 в DE €9.99,
  а пересчёт $10 сегодня — €10.99. Лестница вокруг 10/25/50/100 в евро поэтому
  не строго монотонна. На кредит это не влияет (кредит — N долларов от BFF).
- Патч создания — `PATCH …/applications/{pkg}/onetimeproducts/{id}` (нижний
  регистр; `oneTimeProducts/{id}` на PATCH отвечает 404), `allowMissing=true`,
  `regionsVersion.version` URL-кодирован; созданная покупка — `DRAFT`, активация
  `oneTimeProducts/{id}/purchaseOptions:batchUpdateStates`.
- Прод не затронут: приложение в сторе спрашивает только четыре прежних SKU.

## Осталось

- Владельцу: снять *Manage store presence* у `play-billing-api@` (ключ лежит в BFF).
- App Store Connect — та же лестница, не заведена.
