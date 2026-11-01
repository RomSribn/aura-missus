# AURAT-0149-004 — context

Дата: 2026-10-31

## Источники

| Источник | Что взято |
|---|---|
| `AURAI-0009` §4 «Web», §8 (high) | `data-theme` до первого рендера, тени на токенах, контраст на каждую тему, `/promo/:code` → вход `promo` → погашение; код в URL — только публичный |
| `AURAT-0147-007-spec-v2` + `-010` (bff-manor slave-2, high, ещё не смёржено) | форма `GET /v1/app-config`: `season{campaignId, preset, endsAt, palette(17), art{hero,ticket}, copy(9 ключей), effect}` / `promo{campaignId, code, headline, amountMinor, endsAt}` / `discount{campaignId, label, pct, endsAt}`; публичный, `max-age=60` + ETag; `promo`/`discount` = null без биллинга; `SessionPricing.blocks[].discount{kind, pct, label}`; `fillSeasonCopy`, `formatSeasonAmount` в контракте |
| `aura-contracts.worktrees/v0.27.0-campaigns` (черновик, не тег) | `src/app-config.ts` пока **до** правки `-010` (3 ключа `copy`, нет `amountMinor`); `src/season-contrast.ts` — `SEASON_CONTRAST_PAIRS` P1–P18, `checkSeasonPalette`; `SessionPriceDiscount` |
| `SEASONAL.md` + `prototype/seasonal.{jsx,css}` + `presets/*.json` + `effects/*.svg` (high, сдача принята в `AURAT-0150`) | пять мест; **веб-колонки hero уже есть** (≥761: 200 px, арт 200, заголовок 30, CTA 40; ≤760 = как приложение 164); логика «один билет» (`ticketKind`); частицы (14, сид, `@keyframes season-fall`); шторка промокода; движение и reduced motion; палитры обоих пресетов |
| `AURAT-0146` (high) | публичные коды `A–Z0–9{4,20}`, погашение тем же `POST /v1/wallet/promo-codes/redeem`; контракт `v0.26.0` меняет только комментарии — веб гасит vanity-коды без правок (`code: min 1 max 64`) |

## Код веба (develop `7bafbfe`) — что есть

- **Старт:** `app/main.tsx:17` рендерит после `initI18n`; API до рендера не читается. Публичный эндпоинт — `extraOptions: { public: true }`.
- **Токены:** один `:root` в `tokens.css`; `[data-theme]` нигде нет. Коралловый rgba зашит в `--shadow-orb-accent` и `--shadow-coupon`. `contrast.test.ts` читает только первый `:root`.
- **Места:**
  - билет — `shared/ui/coupon-ticket` (`pct | null`, «{pct}% OFF First Session»), 8 мест: Home side, Advisors, Advisor aside, Match, `/me` Account и Coupons, Book sheet (вариант со `savingMinor`), шаг телефона во входе;
  - орб — у веба нет сплэша; коралловый орб — в логотипе шапки (`app-layout.module.css:31-42`), бирюзовый `Orb` — пустые состояния / booked / checkout (бирюзу сезон не трогает);
  - Daily banner — `pages/home/ui/daily-banner` (плам 160°, золото, `--on-plum-2` = белый 0.72); `DailyHero` хендоффа — это он же; страница `/daily` — отдельная плам-сцена;
  - навигация — один `<nav>` в `app-layout`, активный: desktop — иконка `--accent-ink` на `--card`, телефон — иконка и подпись `--accent-ink` на баре `card 94%` поверх paper;
  - Home: greeting → ряд `.hero` (Ask | side) → DailyBanner → …; место hero по `SEASONAL.md` — между greeting и рядом.
- **Вход:** `AUTH_REASONS = ['ask','book','daily']` (`shared/model/dialog.ts:83`), строки `title/sub/name.continue.<reason>` × 24 языка; `useGateOnArrival(active, reason)` открывает вход по приходу; после входа диалог уходит на `to`.
- **Промокод (`AURAT-0145`):** `features/redeem-promo-code` — инлайн-поле в `/me` → Coupons, `apply()` читает внутреннее состояние (кода «снаружи» нет), отказы и тексты на 24 языках. Шторки промокода нет; `DialogKind` без `promo`.
- **Цена брони:** `offerPctFromPricing` считает любой `creditMinor` «первой сессией» → при скидке кампании веб напишет «50% OFF First Session» (известное ограничение 0147 §3).
- **Контракты:** `package.json` — `v0.25.0`, установлен `0.24.0` в слоте → `npm ci` перед сборкой.

## Противоречия / уточнения

- `AURAI-0009` говорит «`[data-theme="winter"]` в `tokens.css`», решение владельца — палитра данными. Значит пресетных блоков в CSS нет: значения ставятся переменными `--season-*` на `<html>`, а `[data-season]` — только флаг «сезон включён».
- Контекст манора: «веб-экраны hero дизайнер не делал» — экранов нет, но размеры веба есть в `SEASONAL.md` §1 и `seasonal.css` (`.season-hero.web`). Беру их.
- `SEASONAL.md` §0 раскладывает `season{preset, code, codeValue, discount}`; сервер — `season/promo/discount` (`-010` п. 3). Веб идёт за сервером.
- Тексты сезона с сервера — только английские (контракт: «en; i18n — позже»).
