# AURAT-0147-015 — Execute: ревью качества кода (`-014`), пункты «до тега» и «до мёржа»

Дата: 2026-10-31. Не закоммичено, staged (BFF, missus, worktree контрактов).

## До тега `v0.27.0`
- **2.** `seasonPalettePasses` = `SeasonPalette.safeParse(p).success && все пары ok`; builder
  разбирает сезон схемами контракта (`seasonPaletteSchema`, `seasonCopySchema`), без ручных
  проверок и `as`.
- **9.** `SESSION_PRICE_CHANGED = 'session_price_changed'` (контракт, BFF, README, `AURAD-0022`).
- **11.** `compositeOver` / `relativeLuminance` — внутренние (наружу: `checkSeasonPalette`,
  `seasonPalettePasses`, `SEASON_CONTRAST_PAIRS`, `contrastRatio` — им пользуется тест контраста
  веба). `SeasonContrastResult.foregroundName` / `backgroundName` — таблица бэкофиса показывает
  имя токена или фиксированного цвета. Подстановки и лимиты — отдельный модуль `season-copy.ts`,
  `SEASON_COPY_LIMITS` / `SEASON_COPY_PLACEHOLDERS` — `as const satisfies`. Один шаблон hex:
  `HEX_COLOR_PATTERN` → `HexColor`. README пакета: два намеренных исключения из «только формы».
  `seasonPlaceholdersIn` остаётся публичным: им пользуется BFF.

## До мёржа
- **1.** `promoBlockers(promo, endsAt)` и `copyLengthBlockers(copy, codes, name)` — чистые, в
  `campaign-enable-check.ts`. Сохранение кладёт **те же блокеры** в ошибки полей
  (`FieldProblem = string | EnableBlocker`), вью формулирует их той же `blockerText`, что и
  страница подтверждения. `dotted()` удалён. `private judge()` — один вход `checkEnable` для
  страницы и для guard под замком.
- **3.** OpenAPI `app-config` строится из `SEASON_TOKENS`, `SEASON_COPY_KEYS`,
  `SEASON_COPY_LIMITS`, `SEASON_EFFECTS`, `HEX_COLOR_PATTERN`, `SESSION_DISCOUNT_KINDS`,
  `SESSION_PRICE_CHANGED`. Prettier-шум в пяти старых описаниях откачен: дифф `openapi.ts` —
  только мои правки.
- **5.** `lastZonedDayKey(exclusiveEnd, zone)` в `zoned-date.ts` (+ тест), четыре копии заменены.
  Длина окна — по меткам дней (`endsOn > shiftDateKey(startsOn, 119)`), без запаса на DST.
- **6.** Hex: пресет — `seasonPaletteSchema.strict()`, черновик и образец цвета во вью —
  `hexColorSchema.safeParse`, OpenAPI — `HEX_COLOR_PATTERN`.
- **7.** Комментарии исправлены (enable-check, campaign-discounts, campaigns.module), лишний
  импорт `CampaignDiscountsModule` из `CampaignsModule` убран, `PriceChangedError` отделён от
  комментария `InsufficientFundsError`.
- **8.** `campaignCreateFormSchema` (`creationKey: uuid`, обязателен — `POST /` и `/new/import`)
  и `campaignEditFormSchema` (без ключа); `?? randomUUID()` на создании убран.
- **10.** `discountMinor(subtotal, pct)` в `session-policy.ts`; `firstSessionDiscount` и скидка
  кампании — через неё; `BlockDiscount.kind: SessionDiscountKind` из контракта.
- **12.** Миграция: `campaigns_season_whole` связывает пресет и с текстами, и с палитрой;
  комментарий к `BETWEEN 5 AND 70`; `TG_OP` в сообщении триггера. Репозиторий читает части
  целиком, без `?? ''`.

Проверки: `tsc` ✓, `eslint` ✓ (кроме старого `desk.js`), `prettier` ✓, `nest build` ✓, jest —
144 сьюта / 1866 тестов ✓; контракты `tsc` + `tsup` ✓.

## Отложено — пункты 4, 13, 14, 15 (см. `-014` «Позже») и rebase на 0146
