# AURAT-0083-014 — вкладка через UI вместо скрипта (2026-10-12)

Владелец по итогам `012`: убрать скрипт регистрации, описать добавление через UI.

- Удалён `deploy/chatwoot/register-agent-desk-app.rb` (не был закоммичен).
- `README.md` → *Booking widget in Chatwoot* → *Install*: шаг 1 — мост
  (`install-agent-desk-bridge.rb`, runner), шаг 2 — вкладка в UI администратором
  аккаунта: Settings → Integrations → Dashboard Apps → Configure → Add a new
  dashboard app, имя `Aura`, endpoint `https://bff.aura-app.cc/agent-desk`
  (аккаунт 1) / `https://bff-dev.aura-app.cc/agent-desk` (аккаунт 2). Откат —
  удалить приложение там же.
- `deploy/README.md` — строка скрипта убрана из дерева.
- `AURAS-0004` → *Chatwoot specifics*, пункт 3 — то же через UI.

Мост (`DASHBOARD_SCRIPTS`) остаётся — он для входа агента, не для вкладки (`012`).
Код BFF не менялся. Застейджено, ждёт ревью.
