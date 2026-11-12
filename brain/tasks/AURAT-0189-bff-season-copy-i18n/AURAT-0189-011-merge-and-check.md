# AURAT-0189-011 — мёрж и проверка на bff-dev

Дата: 2026-11-07 · Координатор (сессия «Локализация i18n для aura-app», бывш. `slave-1-ac`).

## Мёрж

С одобрения владельца («Да, всё»): контракты — тег `v0.30.0` (`21df50d`, origin); BFF на тег, коммит слота, мёрж в
`develop` — `0410ed7` (`Merge feature/AURAT-0189-bff-season-copy-i18n`), push origin; брейн — `9035b12`, хаб `94e5a2b`.

## bff-dev

- `GET /v1/app-config?lang=de|fr|el|pl|ro` — подпись скидки на языке запроса (`Winteraktion`, `Promo d’hiver`,
  `Χειμερινές εκπτώσεις`, `Zimowa promocja`, `Reduceri de iarnă`), `labelLanguage` = язык запроса ✓.
- Тексты сезона с текстами пресета — целиком на языке запроса (de / fr / el) ✓. Живая кампания на bff-dev
  (`cmvx2uamq000801mqntajnwh9`) — со своим `heroBodyNoCode` («Cosy up with a reader tonight», не пресет) → весь набор
  английский, `copyLanguage: en` — верно по спеке (набор целиком или английский). Владелец меняет текст на пресетный;
  форма отклоняет черновой вариант «… — chat is free to start.» (54 из 50) — верно.
- Кэш app-config: `Cache-Control: public, max-age=60`, ETag по языку.

## Передача

Приложению — `AURAT-0194` (смёржена: `develop` приложения `17ae9d9`, проверка в маноре — `AURAT-0194-010`).
ИИ-перевод своих текстов кампании — `AURAT-0192` (запущена, поверх `AURAT-0191`).
