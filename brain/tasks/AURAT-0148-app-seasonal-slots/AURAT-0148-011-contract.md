# AURAT-0148-011 — переход на `@aura/contracts` `v0.27.0`

Дата: 2026-11-01. `package.json` `#v0.25.0` → `#v0.27.0`, lock — `8699e32` (коммит тега).

- **C1 / B5:** локальная копия контракта удалена (`lib/season-contrast.ts`, `lib/fill-copy.ts`, схемы в
  `model/app-config.ts`). Остался один файл `api/parse-app-config.ts`: разбор **по частям** схемами
  контракта (`AppConfigSeason` / `AppConfigPromo` / `AppConfigDiscount`) + `seasonPalettePasses` (P1–P20,
  композит с округлением — как у сервера и веба). Тексты — `fillSeasonCopy` контракта (без значения
  плейсхолдер остаётся, как у сервера). `SEASON_EFFECTS` / `SeasonEffect` — из контракта.
- Типы ответа — `AppConfigResponse` контракта (`copy.cta` — обязательная строка).
- Тесты контраста переехали в разбор (`P17`, `P20` → нет сезона); числа пар — забота контракта.
