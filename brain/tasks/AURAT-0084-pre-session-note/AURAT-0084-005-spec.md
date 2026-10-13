# AURAT-0084-005 — spec (draft)

Тип: task (без новой фичи). Связь: выделено из `AURAT-0083`; рядом — `AURAF-0008`.

## Что делаем

За **5 минут** до `startsAt` каждой `SCHEDULED` сессии BFF постит в её диалог
Chatwoot приватную заметку:

```
[@<Assignee>](mention://user/<id>/<Assignee urlenc>) Paid session starts in 5 minutes — 20 min block, 14:30 UTC.
```

Без assignee (или если assignee — сервисный пользователь BFF) — тот же текст без
упоминания. Клиенту и приложению — ничего.

## Как

1. **Порт** `ChatwootMessagingPort.postPrivateNote(conversationId, content,
   options?: { mentionAssignee?: boolean })`. Адаптер при `mentionAssignee`
   читает `GET /conversations/:displayId` → `meta.assignee`, собирает mention и
   приклеивает спереди. id/имя агента не покидают модуль `chatwoot` (AURAD-0001).
   Сбой чтения assignee → бросаем (ретрай задачи), не постим «молча без упоминания».
2. **Задача** `remind` в очереди `sessions` (`SESSION_REMIND_JOB`, data
   `{ sessionId, startsAt }`):
   - ставится рядом с `scheduleActivation` (бронь и перенос): `delay =
     max(0, startsAt − 5 мин − now)`, `jobId = remind-<id>-<startsAt ms>`;
   - обработчик `SessionsService.remindIfDue` — no-op, если сессии нет, она не
     `SCHEDULED`, `startsAt` изменился (устаревшая задача после переноса) или
     `now ≥ startsAt` (сессия уже идёт — её объявит маркер «started»).
   - Процессор — одна строка в `switch` (тонкий, правило 2).
3. **Бэкстоп** в `sweepDue`: `SCHEDULED` сессии с `startsAt ∈ (now, now+5 мин]` →
   `add` той же `remind`-задачи с тем же `jobId`. Повтор в пределах 24 ч BullMQ
   дедуплицирует (хранение completed = 24 ч), поэтому без новой колонки в БД.
   Закрывает потерянные отложенные задачи и сессии, забронированные до деплоя.
4. Константа `SESSION_REMINDER_LEAD_MINUTES = 5` в коде (как политики сессий, не env).

## Что не делаем
- Упоминание команды адвайзора (ждёт смен чаттеров, `AURAT-0083`).
- Напоминание клиенту (`AURAF-0008-012`).
- Колонку `remindedAt` в БД (дедуп — через jobId; см. риск ниже).

## Тесты (чистые, в слэйве)
- `sessions.service.spec`: планирование при брони/переносе (delay, jobId);
  `remindIfDue` — постит при SCHEDULED/совпавшем startsAt; no-op на CANCELLED,
  переносе, `now ≥ startsAt`, отсутствии сессии; бэкстоп в `sweepDue`.
- `chatwoot-messaging.service.spec` / `chatwoot.client.spec`: mention при assignee,
  без assignee, assignee = сервисный агент, URL-кодирование имени.
- `processors.spec`: диспетчеризация `remind`.
Живая проверка (заметка + push у назначенного агента) — в маноре после мёржа.

## Риски / принятые края
- Если Redis потерял completed-запись раньше 24 ч, а сессия ещё в окне 5 мин,
  бэкстоп может запостить второй раз — дубль заметки, не деньги. Принимаем.
- Ретрай после частичного успеха (пост прошёл, ответ потерян) → возможен дубль
  заметки; тот же принятый край, что у маркеров (`AURAT-0008` §5).
- Push придёт, только если у агента включены уведомления о mention в Chatwoot.

## Вопрос владельцу
- Текст заметки (англ., как остальные служебные строки) — ок?
