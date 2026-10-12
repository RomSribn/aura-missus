# AURAT-0083-019 — мост установлен (сессия по SSH) — 2026-10-12

Владелец: «посмотри брейны, когда-то ты уже подключался к серве, сделай так же».
Доступ — как в `AURAT-0073-016`: `ssh root@37.27.199.90`.

- Контейнер rails Chatwoot: `rails-forqvdvibl9wjec2yk0mqkeo-173802409784`
  (`chatwoot/chatwoot:v4.15.1`), единственный.
- До установки строки `DASHBOARD_SCRIPTS` в `installation_configs` не было —
  затирать нечего.
- Скрипт подан через stdin из манор-копии `aura-bff` (`develop` `b191f12`):
  `docker exec -i -e AGENT_DESK_ORIGINS=https://bff.aura-app.cc,https://bff-dev.aura-app.cc <rails> bundle exec rails runner - < deploy/chatwoot/install-agent-desk-bridge.rb`
  → `bridge installed for https://bff.aura-app.cc, https://bff-dev.aura-app.cc`.
- Проверка снаружи: `https://chat.aura-app.cc/app/login` отдаёт оба маркера
  моста и `var ALLOWED = ["https://bff.aura-app.cc","https://bff-dev.aura-app.cc"];`.

Дальше: шаг 3 (вкладка `Aura` в «Aura Dev» через UI) и шаг 4 (проверка в диалоге).
