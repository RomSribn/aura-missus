# AURAT-0091-004 — context

Код (`develop` @ `4c05461`):
- `SessionsService.book`: SCHEDULED → `scheduleActivation` + `scheduleReminder` +
  `enqueueSync`; `startNow` рождается ACTIVE → `afterActivated`.
- `afterActivated` — единая точка старта (метр `activateIfDue` и мгновенная бронь):
  `scheduleFinish` + `enqueueAnnounce('started')` (публичная activity-строка
  «Your session has started», её видит и клиент) + push в приложение.
- `remindIfDue` / `scheduleReminder` (AURAT-0084): задача `remind` в очереди
  `sessions`, `messaging.postPrivateNote(conv, text, { mentionAssignee: true })`,
  время UTC, текст англ.
- Порт `ChatwootMessagingPort.postPrivateNote` уже умеет mention — менять адаптер не нужно.
- Маркер «started» — публичный (activity), push чаттеру не даёт; поэтому нужна
  отдельная приватная заметка.

Противоречий нет.
