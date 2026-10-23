# AURAT-0123-012 — Approved

Date: 2026-10-23
Status: **done** — владелец проверил на web-dev: «Принято».

Итог: текст aura-web держит 4.5:1 — текстовые токены `--teal-ink`, `--accent-ink`
(`--accent-ink-hover`), `--ink-2 #6e665a`; белый — на `--accent-strong #da3557` /
`--teal-strong #008577` (hover `--*-strong-hover`); `--ink-3` не текст (`--ink-struck`,
`--ink-disabled`); `--focus` (gold на plum); `contrast.test.ts` (43 проверки). Плюс `/sessions`:
пустой стейт по центру без панели. develop `d934d3c` (код `cbb72cc`, `8d3a59f`). Правило веба —
пункт «Text colour» в `aura-web-build-rules.md`.

Дальше (вне задачи): перенос палитры в приложение — раздел «Для приложения» в `007`, ID выдаёт
`aura-app-manor`; обновить `tokens.css` хендоффа у дизайнера; `preflight.sh` веб-манора без
`npm ci`.
