# AURAT-0115-004 — Context

Date: 2026-10-21

- `src/config/env.schema.ts:324` — `SESSION_SLOT_LEAD_MINUTES` `.default(30)`, `min(0)` уже
  разрешён. Читают: `sessions.service.ts` — `getAvailability` (`earliest = now + lead`) и
  `requireBookableSlot` (400 «startsAt must be at least N minutes from now»). Instant-путь
  (`startNow`) lead не применяет (`AURAD-0009`, вторая поправка) — не меняется.
- `.env.example:129` — 30; `env.schema.spec.ts:126` пинит 30; `sessions.service.spec.ts`
  задаёт 30 явно в `CONFIG` (тесты окна при заданном lead — остаются).
- `SESSION_REMINDER_LEAD_MINUTES = 5` (заметка staff за 5 мин) — другое число, не трогаем:
  при брони < 5 мин до старта задержка уже `Math.max(0, …)`.
- bff-dev вживую (2026-10-21 12:01 UTC): 12:30 `false`, 13:00 `true`, `instantAvailable: true`
  — lead там ≥ 30. Есть ли переменная в Coolify явно — из слота не видно.
- Локальный `.env` манора: 5.

Next: 005-spec.
