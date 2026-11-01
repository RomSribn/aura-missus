# AURAT-0148-012 — execute, этап 2 (§6: скидка кампании в брони, 409 `session_price_changed`)

Дата: 2026-11-01. Слот `slave-1`, всё в индексе, не закоммичено.

**Подписи скидки** — `features/booking/lib/block-discount.ts`: `blockDiscountOf(block, userOfferPct)` →
`offer` / `campaign` / `flat` / `none` по `blocks[].discount.kind` (строка; `first_session` → offer,
`campaign` → своя подпись, неизвестное → нейтральное «−$X»); без поля (старый BFF) — прежнее правило.
`pricingDiscountOf` — скидка выбранного блока, иначе первого со скидкой; `discountLineOf` —
«Welcome offer · 50% off» / «Winter sale · 20% off» (без подписи — «Seasonal sale»).
- `useBookingConfirm` → `BookingPrice` получил `discount`, `discountLine`, `discountPct`; `offerPct` — только
  у оффера (welcome-билет). Review: строка скидки и зачёркнутый итог — по `discountLine` / `discountPct`.
- `useBooking`: `offerPct` (билет) и новый `ratePct` (зачёркнутая ставка /min и карточки длительности);
  `DurationPicker` — проп `discountPct`. Quick book: то же (`ratePct` в `QuickBookSheet`).
- Итог: при скидке кампании нигде нет «First Session» и welcome-билета, ставка — со скидкой кампании.

**Цена поменялась** — бронь (слот, «сейчас», Quick book) шлёт `expectedCostMinor = costMinor` показанного
блока. 409 с кодом `SESSION_PRICE_CHANGED` → ошибка `priceChanged` («The price just changed — check it and
confirm again.»), исход `priceChanged`, ключ попытки сброшен, цена перечитывается (свой `fetchPricing`
или `onPriceChanged` → `quick.refresh`), кошелёк перечитывается (оффер мог смениться). Обычный 409 —
по-прежнему «слот занят». После оплаты через стор — уведомление checkout `priceChanged`: деньги на
балансе, проверить новую цену и подтвердить снова.

Тесты: правило скидки (все виды, старый BFF, неизвестный kind, выбор блока), подпись кампании в
`useBookingConfirm`, `expectedCostMinor` в запросе, 409 `session_price_changed` (перечитана цена, без
списания), обычный 409. `tsc` ✓, `eslint` ✓, jest 151 / 1135 ✓.

Живая проверка (манор, после мёржа 0147 и 0148): бронь при кампании −20% и при −70% с живым оффером;
выключение кампании при открытом Review → 409 → новая цена; экраны 67–80.
