# AURAT-0157-002 — check

Дата: 2026-11-05. Слот: `aura-app-manor` slave-1, ветка `feature/AURAT-0157-app-i18n-shared-layer` от `develop` @
`a2350f8` (глоссарий 0155 уже там). Отдельного missus-worktree в слоте нет — шаги пишутся в общий brain манора.

Найдено:
- Папка задачи — только `001-initial.md` (записан 2026-11-04, до слота; «ждёт свободного слота» устарело).
- `AURAF-0023` — шаг 2 = эта задача + `AURAT-0158` (строка Language и лист, ждёт слота).
- `AURAT-0154` done (`40d0ee7`): ядро i18n, пространство `shared` (весь `shared/ui`), `discount-copy.ts` уже зовёт
  `i18next.t` из `shared/lib`. Форматтеры и общие фразы явно отнесены к шагу 2.
- `AURAT-0155` done (`a2350f8`): глоссарий, `translate.mjs scan|check|review`, `@max` / `@sensitive`.
- `AURAT-0156` в slave-0 (шрифты el/bg) — его файлы и строку `FORBIDDEN` в `translations.test.ts` не трогаю.

Следующее: 003 — что нужно сделать.
