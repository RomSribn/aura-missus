# AURAT-0175-018 — execute: subgrid для плиток

Дата: 2026-11-07 · **Не закоммичено** — застейджено вместе с `016`, ждёт ревью владельца.

## Правка
- `pages/home/ui/home-page.module.css`, `pages/advisors/ui/advisors-page.module.css`: в `@supports (grid-template-rows:
  subgrid)` — `.grid > li { display: grid; grid-row: span 3; grid-template-rows: subgrid }`, `.grid > li > *
  { grid-row: span 3 }`. Вне `@supports` остаётся flex-растяжка (`012`).
- `entities/advisor/ui/advisor-tile.module.css`: в том же `@supports` — `.root { display: grid; grid-template-rows:
  subgrid }` (зазор 10px внутри плитки — свой, `gap` у `.root`), `.actions { align-self: start; margin-top: 0 }`.
- Итог в ряду: фото, текст (роль в 1–3 строки) и кнопки — на общих строках; все «Kostenlos chatten» ряда на одной
  линии, «Buchen» второй строкой не сдвигает соседей; низ плиток общий.
- Скрытые на Home плитки (`:nth-child(n + 5)` — `display: none`, специфичность выше) в сетку не попадают.

## Проверки
lint ✓ · typecheck ✓ · `npm test` 113 / 1923 ✓ · build ✓ · prettier ✓. Раскладку jsdom не считает — только web-dev.

## Проверить после мёржа
`/advisors` и Home, de (и lt / ro / nl), 1440 / 1180 / 900 / 390 / 360: в каждом ряду верх кнопок на одной линии,
тексты начинаются на одной высоте, низ плиток общий; зазоры внутри плитки — как раньше (10px), между рядами — как
раньше; Safari и Chrome.
