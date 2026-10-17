# AURAT-0091-005 — spec (v2, после ответов владельца)

Тип: task (без новой фичи). Образец: `AURAT-0084`.

## Что делаем

Две новые приватные заметки в диалог Chatwoot с @упоминанием assignee (без assignee
или если это сервисный пользователь — без упоминания; ровно как в `AURAT-0084`):

| Событие | Когда | Текст (англ., UTC) |
|---|---|---|
| Бронь | `book` создал SCHEDULED-сессию | `Paid session booked — 20 min block, Oct 18, 14:30 UTC.` |
| Перенос | `reschedule` | `Paid session rescheduled — 20 min block, now Oct 19, 10:00 UTC (was Oct 18, 14:30 UTC).` |
| Отмена | `cancel` (переход в CANCELLED) | `Paid session cancelled — 20 min block, Oct 18, 14:30 UTC.` |
| Старт | сессия стала ACTIVE (метр или мгновенная бронь) | `Paid session started — 20 min block, until 14:50 UTC.` |

Заметка за 5 минут (`AURAT-0084`) остаётся как есть. Итого на запланированную
сессию: бронь → за 5 мин → старт (три отдельные заметки). На мгновенную
(`startNow`) — только «started» (бронь и старт — один момент, две заметки подряд
были бы шумом).

## Как

1. **Задача** `desk-note` в очереди `sessions` (`SESSION_DESK_NOTE_JOB`), data
   `{ sessionId, kind: 'booked'|'rescheduled'|'cancelled'|'started', startsAt,
   endsAt, previousStartsAt? }` — время события фиксируется в данных задачи, а не
   перечитывается: заметки — журнал событий, каждая говорит, что было в тот момент.
   `jobId = desk-note-<kind>-<id>-<startsAt ms>` — повтор постановки (ретрай,
   replay идемпотентной брони) не даёт дубля; повторный перенос — новая заметка.
2. Постановка:
   - `booked` — в `book`, ветка SCHEDULED (рядом с `scheduleReminder`); не на replay.
   - `rescheduled` — в `reschedule` (старое время — из контекста до переноса).
   - `cancelled` — в `cancel`, только при `transitioned`.
   - `started` — в `afterActivated` (обе точки старта сразу, без дрейфа).
3. Обработчик `SessionsService.postDeskNote`: no-op, если сессии нет; иначе
   `messaging.postPrivateNote(conv, text, { mentionAssignee: true })`. Без проверок
   статуса — это журнал (отменённая через минуту бронь даст обе заметки: «booked»
   и «cancelled», как и было). Процессор — одна строка в `switch` (правило 2).
4. Адаптер Chatwoot не меняется.

## Что не делаем
- Заметку на продление / завершение (не просили).
- Бэкстоп в `sweepDue` для этих заметок: постановка идёт сразу в запросе/задаче
  метра, отложенных задач нет — терять нечего, кроме сбоя Redis в момент
  постановки (тот же край, что у маркеров).
- Упоминание команды адвайзора (ждёт смен чаттеров, `AURAT-0083`).

## Тесты (чистые)
- `sessions.service.spec`: `book` SCHEDULED ставит `desk-note booked`, мгновенная —
  только `started`, replay — ничего; `reschedule` → `rescheduled` со старым/новым
  временем; `cancel` → `cancelled` (и ничего, если не transitioned);
  `activateIfDue` → `started`; `postDeskNote` — четыре текста, mention, no-op без
  сессии.
Живая проверка (заметки + push у назначенного агента) — в маноре после мёржа.

## Риски
- Ретрай после частичного успеха (пост прошёл, ответ потерян) → дубль заметки;
  тот же принятый край, что `AURAT-0084` / маркеры.

## Решения владельца (006)
- Мгновенная бронь — только «started».
- Добавить заметки на перенос и отмену.
