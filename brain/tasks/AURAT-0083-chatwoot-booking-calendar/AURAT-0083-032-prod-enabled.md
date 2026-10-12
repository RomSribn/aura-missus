# AURAT-0083-032 — включено в проде (2026-10-12)

После закрытия (`031`) владелец выпустил `develop` в `main` (PR #1, `73c2794`) и
включил виджет в production. Проверка по SSH (`ssh root@37.27.199.90`) и снаружи:

- прод-BFF передеплоен из `main` `73c2794`; в контейнере
  `AGENT_DESK_FRAME_ANCESTOR=https://chat.aura-app.cc`, `CHATWOOT_ACCOUNT_ID=1`,
  `BILLING_ENABLED=true`;
- `https://bff.aura-app.cc/agent-desk` → 200, CSP `frame-ancestors
  https://chat.aura-app.cc`, `img-src 'self' blob: https://assets.aura-app.cc`;
- Chatwoot передеплоен вместе с `main`: мост в `DASHBOARD_SCRIPTS` сохранился
  (`ALLOWED = [bff, bff-dev]`);
- владелец добавил в аккаунте 1 Dashboard App `Aura` →
  `https://bff.aura-app.cc/agent-desk` — «все работает».

В аккаунте 1 есть посторонний Dashboard App «Test» (не наш) — на усмотрение
владельца.

Итог: AURAT-0083 v1 работает в dev (аккаунт 2) и prod (аккаунт 1). Пункт
«prod — не включён» из `031` закрыт; хвосты из `031` остаются.
