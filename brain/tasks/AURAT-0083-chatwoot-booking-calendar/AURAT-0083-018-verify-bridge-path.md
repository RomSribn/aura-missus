# AURAT-0083-018 — проверка в манор: шаг 1 ок, шаг 2 — скрипт не найден (2026-10-12)

- Шаг 1 ✓: `https://bff-dev.aura-app.cc/agent-desk` открывается, текст «Эта
  страница открывается только во вкладке диалога в Chatwoot».
- Шаг 2 ✗: владелец запустил `rails runner - < install-agent-desk-bridge.rb` из
  shell внутри контейнера Chatwoot → `can't open install-agent-desk-bridge.rb`.

Причина: скрипт живёт в репозитории `aura-bff`, в образ Chatwoot он не попадает
ни из какой ветки. Мёрж `develop` → `main` (гипотеза владельца) не поможет —
и выкатил бы в прод BFF. Инструкция была двусмысленной («in the rails
container»).

Исправлено (застейджено, не закоммичено): `README.md` и `AURAS-0004` — скрипт
подаётся через stdin с машины, где есть checkout `aura-bff`:
`ssh root@<host> "docker exec -i -e AGENT_DESK_ORIGINS=… $(docker ps … | grep -m1 '^rails-') bundle exec rails runner -" < deploy/chatwoot/install-agent-desk-bridge.rb`
(сервис `rails` в `deploy/coolify/chatwoot.compose.yml` → контейнер `rails-<uuid>`).

Дальше: владелец повторяет шаг 2, затем шаги 3–4.
