# AURAT-0147-016 — Execute, часть 2: поверх 0146 (блокеры 1 и 3)

Дата: 2026-11-01. Не закоммичено, staged.

## Интеграция с 0146
- `aura-bff`: ветка перемотана на `develop` @ `6741848` (merge 0146), мои изменения наложены поверх
  без коммита. Резервная копия до слияния — локальная ветка `backup/AURAT-0147-wip-1` (удалить после
  мёржа). Конфликты: `zoned-date.ts` и его тест взяты из 0146 (третий проход `startOfZonedDay`),
  мой `lastZonedDayKey` дописан; `session-policy.ts` — `discountMinor` из 0146 (моя копия удалена),
  `discountForBooking` убран (не используется), комментарий `AURAD-0022` возвращён;
  `schema.prisma` — `PromoCode.redemptions` из 0146 + `campaigns`; `format.ts` — из 0146.
  Миграция `20261031130000_campaigns` идёт после `20261031120000_public_promo_codes`.
- `aura-contracts`: `feature/v0.27.0-campaigns` перенесена на `v0.26.0` (`98c859e`), README —
  абзацы `v0.27.0` и `v0.26.0` оба, строка `promo` из 0146. Резерв — `backup/v0.27.0-wip-1`.
- `aura-missus`: ветка перемотана на хаб `cfa9dc3` (0150), отметки `AURAF-0022` поставлены заново.
- `lastGoodDay` из 0146 теперь вызывает `lastZonedDayKey` (пятая копия «последнего дня» из ревью).

## Витрина — только публичный код (блокер 3)
- `PromoCodeLookup.findByCode` → `public` (`batch.kind = PUBLIC`); `ShowcasedCode.public`.
- `promoBlockers`: первым — `promo-not-public` («одноразовый код погасит первый же человек»); тот же
  блокер — ошибка поля на сохранении.
- `app-config` не отдаёт непубличный код.

## Порог в обе стороны (§4)
- `cheapestSessionCostMinor(lowest, blocks, campaignPct?)` — большая из −50% и скидки кампании
  (никогда не обе); `SessionPriceFloor.cheapestSessionCostMinor(pct?)` и
  `cheapestSessionCostMinorOver(from, to)` — с самой глубокой включённой скидкой на этих днях
  (`CampaignDiscounts.deepestPctOverlapping`).
- **Включение кампании** со скидкой > 50%: порог с её процентом; живые публичные коды на окне
  кампании (`PromoCodeLookup.livePublicCodes`) не дешевле порога → предупреждение со списком кодов
  и галочка «Понимаю: код оплатит сессию целиком» на подтверждении; без галочки запись отвечает 409
  с той же страницей. Порог перечитывается на записи.
- **Публичный код** (форма 0146): порог считается по сроку кода (`now … expiresAt`) с самой глубокой
  включённой скидкой — и на подтверждении, и на создании.
- `CampaignsModule` импортирует `SessionsModule` (цена порога); цикла нет: sessions →
  campaign-discounts.

## Проверки
`tsc` ✓, `eslint` ✓ (кроме старого `desk.js`), `prettier` ✓, `nest build` ✓, jest — 145 сьютов /
1943 теста ✓ (новые: витрина не публичная — форма, блокер, app-config; порог — политика, floor,
сервис включения с галочкой и без, обратная сторона в форме публичного кода; вью предупреждения).

## Осталось до мёржа (блокер 1)
1. **Тег `v0.27.0`** в `aura-contracts` — push `main` + тег, только с одобрения владельца.
2. После тега: `npm install @aura/contracts@github:RomSribn/aura-contracts#v0.27.0` в BFF
   (`package.json` + lock).
3. Ревью владельца → коммит → merge gate (`wts-finish`).
