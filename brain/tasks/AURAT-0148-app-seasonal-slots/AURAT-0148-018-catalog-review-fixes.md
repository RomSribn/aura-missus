# AURAT-0148-018 — правки ревью дельты каталога

Дата: 2026-11-01. Ревью манора `-015…-017`: блокеров и средних нет, мёрж разрешён после двух пунктов.
Слот `slave-1`, всё в индексе, не закоммичено.

**До мёржа — сделано**
- **Одна подпись** (L2, как на вебе `AURAT-0151`): `shared/lib/discount-copy.ts` — `firstSessionOfferTitle`
  («50% OFF First Session», теперь из одного места: `CouponTicket` и каталог) и `campaignDiscountTitle`
  («20% OFF · Winter sale»). Строка кампании в брони (Review, футер Book Session, Quick book) была
  «Winter sale · 20% off» — теперь та же «20% OFF · Winter sale», что в приглашении и на вебе.
- **Тесты на настоящей связке** (L1): Advisors — настоящий стор конфига (`useAppConfigSync`), мокнуты
  только провод и кошелёк: «−20%», $1.99 → $1.59, нет «First Session», а после `endsAt` (fake timers) —
  полная цена. AdvisorProfile — ставка в StatsCard, чип у Book, доступное имя
  «Book a session with Olivia Moon, 20% OFF · Winter sale».

Проверки: `tsc` ✓, `eslint` ✓, jest 155 / 1153 ✓.

**Позже (записано)**
- L3: правило «большая, ничья → кампания» дважды (`pick-ticket.ts`, `catalog-discount.ts`) → вид билета
  выводить из `catalogDiscountOf`.
- L4: пока кошелёк грузится (или первая загрузка упала) `offerPct = null` — человек с оффером видит «−20%»
  вместо «−50%»; не показывать скидку до `status === 'ready'` или принять.
- L5: `session-invite.ts:17` — устаревший комментарий про суффикс.
- L6: `AdvisorProfileScreen` — «50% OFF First Session» капсом в доступном имени → отдельная строка для скринридера.
- L7: `useCatalogDiscount` — `useMemo` по примитивам (`pct`, `label`), не по ссылке; лишний `renderItem` в `ChatThreadScreen`.
- L8: комментарий про округление — сервер floor-ит стоимость блока, а не ставку /min; ставка /min с floor
  может быть ниже блока / минуты меньше чем на 1 ¢ (так было и у оффера) — решать вместе с вебом.

Дальше: 11 проверок на A50 / iOS против bff-dev (`-013` + п. 11 из `-017`), коммит и мёрж — через владельца.
