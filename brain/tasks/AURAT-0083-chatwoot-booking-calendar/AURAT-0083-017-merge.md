# AURAT-0083-017 — merge (2026-10-12)

Владелец подтвердил merge. `wts-finish slave-2`:

- `aura-bff`: `feature/AURAT-0083-booking-calendar-v1` (`0d4f4fa`, `37846ca`) →
  `develop` в манор, merge `b191f12`; push `6c4fec0..b191f12 develop -> develop`
  — успешно. Idle-слейвы 4, 5 обновлены.
- `aura-missus`: коммитов нет (ожидаемо) — шаги задачи и правка `AURAS-0004`
  остаются незакоммиченными до закрытия задачи.

Слот остаётся на ветке. Дальше — проверка в манор (dev-аккаунт 2):
1. dev-BFF: `AGENT_DESK_FRAME_ANCESTOR=https://chat.aura-app.cc`, деплой из
   `develop`; `https://bff-dev.aura-app.cc/agent-desk` напрямую → 200 и
   «открывается только во вкладке диалога в Chatwoot».
2. Мост: `install-agent-desk-bridge.rb` с `AGENT_DESK_ORIGINS=https://bff.aura-app.cc,https://bff-dev.aura-app.cc`
   в контейнере rails `aura-chatwoot`.
3. Вкладка: в «Aura Dev» Settings → Integrations → Dashboard Apps → `Aura`,
   `https://bff-dev.aura-app.cc/agent-desk`.
4. Диалог в «Aura Dev» → вкладка «Aura»: вход без логина, данные совпадают с БД
   (при billing off — «Платные сессии выключены»).
