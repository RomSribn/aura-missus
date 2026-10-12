# AURAT-0086-010 — execute (fix 009)

Дата: 2026-10-12. Застейджено, не закоммичено — ждёт ревью.

- `desk-attributes.ts`: константа `DESK_ATTRIBUTE_DEFINITIONS` → функция
  `deskAttributeDefinitions(advisorNames)`; `advisor_name` теперь `list` со значениями —
  имена каталога (без дублей, в порядке каталога).
- `AdvisorsRepository.listAllNames()` (+ Prisma: все строки `advisors`, включая
  неактивные, `sortOrder, id`). Моки репозитория в трёх спеках дополнены.
- `DeskSetupService` берёт имена из каталога; существующее `text`-definition на dev
  будет выровнено в `list` (`updated: advisor_name`).
- Тесты: список имён/дедуп; превращение `text` → `list`; новый адвайзор в каталоге →
  `updated`. README: после изменения каталога перезапускать `desk:setup`.
- Проверки: typecheck ✔, lint ✔, jest 1462/1462 ✔.

После мержа на dev: деплой → `node dist/desk-setup.js`, ожидается
`label paid-session: unchanged`, `0 created, 1 updated (advisor_name), 8 unchanged` →
в фильтре «Advisor» — выпадающий список персон.
