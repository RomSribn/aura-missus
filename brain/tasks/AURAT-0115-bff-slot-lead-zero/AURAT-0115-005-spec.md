# AURAT-0115-005 — Spec

Date: 2026-10-21
Тип: task (`AURAF-0008`, правило `AURAD-0009`).

1. `env.schema.ts`: `SESSION_SLOT_LEAD_MINUTES` `.default(0)`; комментарий — почему 0
   (поправка `AURAD-0009`: ближайший слот сетки — следующая её точка; чаттера о старте
   предупреждает заметка staff, а не окно).
2. `.env.example`: `SESSION_SLOT_LEAD_MINUTES=0` с тем же объяснением.
3. Тесты: `env.schema.spec.ts` — умолчание 0; `sessions.service.spec.ts` — при lead 0 в 09:09
   ближайший слот 09:30 доступен, бронь на него проходит, прошедший 09:00 — 400; тесты окна при
   явном lead 30 остаются.
4. Клиенты и контракты — без изменений.

После мёржа: владелец выставляет/удаляет переменную в Coolify (`development`, `production`);
проверка — `availability` на bff-dev отдаёт ближайший слот `available: true`.

Next: 006-approval.
