# AURAT-0147-014 — Ревью качества кода из манора (по поручению владельца)

Дата: 2026-10-31. Источник: сессия manor-70. Делаю «до тега» и «до мёржа»; «позже» — записано ниже.

## До тега `v0.27.0` (провод и semver) — делаю
2. `seasonPalettePasses` = `SeasonPalette.safeParse(p).success && checkSeasonPalette(p).every(ok)`;
   `checkSeasonPalette(Partial)` остаётся для таблицы черновика. В builder — `SeasonPalette` /
   `SeasonCopy.safeParse` вместо ручных проверок и `as`.
9. `SESSION_PRICE_CHANGED = 'session_price_changed'` (префикс домена, как `promo_code_expired`).
11. Публичный API: `compositeOver`, `relativeLuminance` — не из `index`; `ContrastColour.name` →
    `foregroundName` / `backgroundName` в результате (для таблицы бэкофиса);
    `SEASON_COPY_LIMITS` / `SEASON_COPY_PLACEHOLDERS` — `as const satisfies`; подстановки — в
    `season-copy.ts`; README («одно исключение» уже неправда).

## До мёржа — делаю
1. Правила кода витрины и длин текстов — один раз: чистые `promoBlockers`, `copyLengthBlockers`;
   ошибки полей формы из тех же блокеров; `dotted()` удалён; `private judge(...)` вместо двух
   сборок входа `checkEnable`.
3. OpenAPI берёт `SEASON_TOKENS`, `SEASON_COPY_KEYS`, `SEASON_EFFECTS`, `SEASON_COPY_LIMITS`;
   prettier-шум в 5 старых описаниях откатить.
5. `lastZonedDayKey(exclusiveEnd, zone)` в `zoned-date.ts` вместо четырёх копий; длина окна — по
   меткам дней (`shiftDateKey`), без запаса на DST.
6. Hex — один regex в контракте (`HexColor`): пресет — `SeasonPalette.strict()`, черновик и view —
   `HexColor.safeParse`, OpenAPI — тот же pattern.
7. Устаревшие комментарии (enable-check, campaign-discounts), лишний импорт
   `CampaignDiscountsModule` в `CampaignsModule`, `PriceChangedError` разнесён с комментарием
   `InsufficientFundsError`.
8. `creationKey` обязателен на создании и импорте в новую (`z.string().uuid()`), на правке — нет.
10. `discountMinor(subtotal, pct)` в `session-policy.ts`, `firstSessionDiscount` через неё;
    `BlockDiscount.kind` — `SessionDiscountKind` из контракта. При rebase на 0146 свести.
12. Миграция: `("seasonPreset" IS NULL) = ("seasonPalette" IS NULL)`; комментарий к `BETWEEN 5 AND
    70`; репозиторий читает пары без `?? ''`; `TG_OP` в сообщении триггера.

## При rebase на 0146
- `zoned-date.ts` (+ тесты) брать из 0146, свою копию хунка — убрать; `discountMinor` свести с
  версией 0146, если она её добавит.

## Позже (не в этой итерации)
4. Доменные типы — в `campaign.types.ts` (`CampaignSeason`, тексты — `SeasonCopy`);
   `ShowcasedCode` ≈ `LookedUpPromoCode` + `headline`; правило «код отключён» — из promo-codes
   (`PROMO_CODE_STATE_SELECT`, `toLookedUpPromoCode`).
13. `BILLING_ENABLED` / `CAMPAIGN_ASSETS_BASE_URL` читаются в двух сервисах → `AppConfigService.preview`;
    self-фильтр трижды → один; `overlappingWhere(from, to)` в репозитории; `findUniqueOrThrow`
    после проверки `ENABLED`.
14. `campaigns.view.ts` (≈600 строк) → `campaign-form.view.ts` + `campaign.view.ts`; литералы,
    повторяющие константы (`maxlength`, «70», «−50%»); `CAMPAIGN_NOTICES as const` один на view и
    форму; `sendEnablePage` в контроллере; `send` типизировать через `Chrome` / `SafeHtml`.
15. Тесты: синтетическая палитра — одна (фикстуры); тесты чистой логики (контраст, copy) — в пакет
    контрактов; сериализация включения под advisory-lock — в список интеграционных проверок манора.
