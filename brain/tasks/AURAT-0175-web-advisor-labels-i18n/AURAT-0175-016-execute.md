# AURAT-0175-016 — execute: кнопки плитки переносятся

Дата: 2026-11-07 · **Не закоммичено** — застейджено, ждёт ревью владельца.

## Правка
- `entities/advisor/ui/advisor-tile.module.css` `.actions`: `flex-wrap: wrap`; `.actions > * { flex: 1 1 auto }`
  (было — растягивалась только первая). Обе кнопки на одной строке, когда влезают; иначе «Book» — своей строкой во
  всю ширину. На телефоне — столбик, как было.
- `shared/ui/button`: пропс `wrap` (`.wrap { min-width: 0; white-space: normal; text-align: center }`) — подпись
  переносится внутри кнопки, а не вылезает (на телефоне в 2 колонки «Kostenlos chatten» ≈ 160 px при ячейке ≈ 147 px).
- `widgets/advisor-card/ui/advisor-card.tsx`: обе кнопки — `wrap`.
- Строки не менялись.

## Проверки
lint ✓ · typecheck ✓ · `npm test` 113 / 1923 ✓ · build ✓ · prettier ✓. CSS в jsdom не проверяется — смотреть на web-dev.

## Проверить после мёржа
`/advisors` и Home на de (и lt / ro / nl), 1440 / 900 / 390 / 360: кнопки внутри плитки — на одной строке или
«Buchen» второй строкой, ничего не выходит за край; на телефоне длинная подпись — в две строки внутри кнопки.
