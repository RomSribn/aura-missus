# AURAT-0115-007 — Execute

Date: 2026-10-21
Slave: `slave-1`, `feature/AURAT-0115-bff-slot-lead-zero` (не закоммичено, staged).

## Изменено (`aura-bff`)

- `src/config/env.schema.ts` — `SESSION_SLOT_LEAD_MINUTES` `.default(0)`; комментарий: поправка
  `AURAD-0009`, почему окно, равное шагу, закрывает ближайший слот всегда, чем предупреждён
  чаттер (заметка `booked` сразу, `starting-soon` за 5 мин), 5 — названный компромисс.
- `.env.example` — `SESSION_SLOT_LEAD_MINUTES=0` с тем же объяснением.
- `src/config/env.schema.spec.ts` — умолчание 0.
- `src/modules/sessions/sessions.service.spec.ts` — `buildService(settings)` (конфиг читается в
  конструкторе); блок «with no lead time»: в 09:09 слот 09:30 доступен, 09:00 — нет; бронь на
  09:30 проходит, на 09:00 — 400. Тесты окна при явном lead 30 не тронуты.

Контракты, клиенты, instant-путь — без изменений.

## Проверка в слоте

`lint`, `typecheck`, `build` — чисто. `jest` — 1619/1620 в полном прогоне: падает
`backoffice-auth.spec.ts` (93 с под нагрузкой, к сессиям не относится), отдельно — 20/20;
`sessions.service.spec.ts` + `src/config` — 188/188.

## Для манора / владельца после мёржа

- Coolify `development` и `production`: `SESSION_SLOT_LEAD_MINUTES` удалить или выставить 0 —
  явно заданная переменная перебивает умолчание.
- Проверка: `GET /v1/advisors/olivia/sessions/availability?days=1&tz=UTC&minutes=10` на bff-dev —
  ближайший будущий слот сетки `available: true` (если свободен).

Next: ревью владельцем в IDE → коммит → merge gate.
