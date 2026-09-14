# AURAT-0071-002 — Проверка состояния

Дата: 2026-09-14
Слот: `slave-3`, ветка `feature/AURAT-0071-bff-chatwoot-dev-compose` в `master`
(от `develop` = `1fa9fbe`) и `missus` (от `master` = `c03cfc6`).

## Что нашлось

- Папка задачи уже есть, в ней только `001-initial.md`. Заглушку завели из
  `aura-app-manor` (brain `c03cfc6`), работа не начиналась. ID не выдавался заново.
- Запуск подтверждён владельцем в `aura-app-manor` («Да, начинаем»). Это
  разрешение взять задачу в слот, а не одобрение спеки: спеку ещё нужно показать.
- Связанные документы: `AURAS-0004` (*Environments*, *Chatwoot specifics*,
  *Deploys*), `AURAD-0015` (одно окружение `development`, прод создаётся с нуля),
  `AURAD-0005` (inbox на окружение). `AURAD-0016` (два экземпляра Chatwoot) ещё
  не записано.
- Код: `deploy/coolify/chatwoot.compose.yml` (alias `chatwoot-rails`,
  `FRONTEND_URL` зашит), `deploy/chatwoot/provision-prod.rb`.
- `origin/main` уже существует. Прод-Chatwoot, по словам `aura-app-manor`,
  переключён на него.

## Дальше

`003-understand`, затем сбор контекста: как Coolify 4.3.19 обрабатывает compose
(подстановка в `networks.*.aliases`, `FRONTEND_URL`), и что нужно
`provision-prod.rb` для dev-экземпляра.
