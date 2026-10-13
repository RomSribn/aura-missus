# AURAT-0084-004 — context

## Chatwoot (исходники, chatwoot-manor)
- Приватная заметка без упоминания не уведомляет: `notifiable? = (incoming||outgoing)
  && !private`. Звук в открытом дашборде играет и так (`DashboardAudioNotificationHelper
  .js:194-196`) по фильтру агента.
- `Messages::MentionService`: заметка `private`, в content `(mention://user/ID/Name)`
  (regex `\(mention://user/(\d+)/(.+?)\)`); ID должен быть админом аккаунта или членом
  инбокса; self-mention (sender == упомянутый) пропускается. Итог — `conversation_mention`
  → web push / email по настройкам агента + агент становится participant.
- Dashboard рисует mention как `[@Name](mention://user/ID/Name)`, Name URL-кодирован.
- `GET /api/v1/accounts/:a/conversations/:id` отдаёт `meta.assignee` `{id,name,…}`.

## BFF (код)
- Очередь `sessions`, отложенные задачи: `scheduleActivation` (`sessions.service.ts:638`)
  — `delay = startsAt-now`, `jobId` с `startsAt`; устаревшие no-op по guard'у.
- `sweepDue` раз в 60 с (бэкстоп): finish → activate.
- Хранение completed-задач — 24 ч (`KEEP_COMPLETED_SECONDS`, `queues.ts:134`) →
  повторный `add` с тем же `jobId` в течение суток дедуплицируется BullMQ.
- `postPrivateNote(ourConvId, content)` в порте `ChatwootMessagingPort`; клиент
  `createPrivateNote` (`chatwoot.client.ts:331`). Нормалайзер отбрасывает любые
  private-сообщения из вебхука → заметка не дойдёт до устройства.
- Тексты для чаттеров — английские (`Card chosen: …`, маркеры `Your session has started`).
- Бронь: lead 30 мин (`SESSION_SLOT_LEAD_MINUTES`), перенос — не позже 4 ч до старта;
  `startNow` рождается ACTIVE → напоминание не нужно.
- AURAD-0001 / AURAT-0009: состав агентов «умирает в адаптере» — id/имя assignee
  не должны выходить за модуль `chatwoot`.
