# AURAT-0112-002 — Check

Date: 2026-10-20
Слот: slave-3, ветка `feature/AURAT-0112-web-home` в master и missus (от develop `79bf311`,
missus `d56516b`).

- Папка задачи есть: только `001-initial` (заглушка из `aura-app-manor`). Работы по главной нет.
- `AURAF-0020`: своей строки у главной нет; касаются 004 (Ask среди действий гостя, UI ✓ без
  Ask), 012 (Ask v1 — переход в каталог по категории; UI ✗, BE ✗) и 013 (карта дня, этап 2).
- Отложено сюда: Get started (`AURAT-0104`, шаги 005/006), Ask с причиной `ask` (там же).
- Параллельно: `AURAT-0108` (slave-1, только `001`), `AURAT-0110` (Sessions — папки в brain нет).
- `node_modules` в slave-3 нет (preflight пустой) — поставить `npm ci` перед проверками.

Дальше: understand.
