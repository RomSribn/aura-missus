# AURAT-0175-019 — merge (правки `016`, `018`)

Дата: 2026-11-07 · Координатор проверил subgrid без замечаний (зазор `.root` 10px перекрывает row-gap сетки по CSS Grid 2).
Владелец: «Да, коммит и мёрж» (AskUserQuestion в слоте).

- Коммит `7813515` «AURAT-0175: advisor tiles hold longer translations» — перенос кнопок (`Button wrap`) + subgrid.
- `wts-finish slave-1`: web `develop` **`84d4b33`**, push `08a33ac..84d4b33`; slave-2…5 обновлены. Missus — «Already up to
  date», предупреждение о push missus безвредно (missus коммитится при закрытии).
- Слот на ветке; `wts-release` — после проверки владельцем и «закрываем».

## Проверить на web-dev
Пункты `014` + `/advisors` и Home, de / lt / ro / nl, 1440 / 1180 / 900 / 390 / 360, Chrome и Safari: кнопки не выходят за
плитку; в ряду верх кнопок на одной линии, тексты с одной высоты, низ общий; зазор внутри плитки 10px, между рядами —
как раньше.
