# AURAT-0096-008 — merge

2026-10-17, с подтверждения владельца. `wts-finish slave-1`:
`feature/AURAT-0096-promo-first-session-broadcast` (`083646b`) → `develop` @ `bc38e62`,
запушено (`82be18d..bc38e62`). Missus не закоммичен — коммит при закрытии задачи.
`develop` → `bff-dev` (Coolify `development`, Chatwoot аккаунт 2). `main`/прод — не тронуты.

## Проверка на dev (в контейнере `bff-dev`, после выкатки `bc38e62`)
1. `node dist/promo-first-session.js --dry-run` — счётчики правдоподобны.
2. `node dist/promo-first-session.js --only <тестовый userId>` — на телефоне со staging-сборкой:
   пуш, персона, текст + карточка записи с «−50%»; в Chatwoot аккаунт 2 у диалога стоит
   `promo-first-50`, **assignee и статус не изменились**.
3. Полный прогон, затем повторный — `sent: 0`.
