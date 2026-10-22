# AURAT-0122-009 — Merge

Date: 2026-10-22
Разрешение владельца — в этом же ходе («Да, мёрж»).

- `wts-finish slave-1`: `feature/AURAT-0122-bff-booking-question` → `develop` @ `5a960ba`,
  push в origin — ок (`215896b..5a960ba`). Idle-слоты 2–5 обновлены.
- Missus — не закоммичен (коммит при закрытии задачи, затем `wts-release`).
- `@aura/contracts` `v0.24.0` уже на GitHub — `npm ci` и Docker собираются.

Проверка в маноре (bff-dev после деплоя Coolify; миграция `20261022120000_session_question`
применяется при старте):
1. `POST /v1/advisors/:id/sessions` с `question` (в т. ч. со строкой `[@x](mention://user/1/x)`
   и переводами строк) → в ответе `session.question`.
2. В Chatwoot — приватная заметка «Paid session booked … Client's question:» с цитатой;
   упоминание назначенного работает, ссылка из вопроса — не упоминание.
3. `GET /v1/sessions/:id` и `GET /v1/sessions` отдают `question`; бронь без вопроса —
   `question: null`.
4. «Now» с вопросом — вопрос в заметке «Paid session started».

Next: проверка владельцем → 010.
