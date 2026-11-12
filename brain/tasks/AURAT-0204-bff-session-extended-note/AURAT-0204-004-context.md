# AURAT-0204-004 — context

Проверено по коду (`slave-1/master`, develop `fa65908`):

- `SessionsService.extend()` (`sessions.service.ts` ~438): ветка `!replayed` —
  `scheduleFinish` + `enqueueSync` + `pushUpdate`; нотиса нет. Replay (до транзакции —
  `findExtendReplay`, внутри — `replayed: true`) ничего не ставит.
- Конвейер (`AURAT-0092`): `SessionNotifier.notify(session, kind, previousStartsAt?)` →
  по задаче `notice` на **каждый** канал из `SESSION_NOTICE_CHANNELS`; `desk`
  (`DeskNoteChannel`, `postPrivateNote(…, { mentionAssignee: true })`) — всегда,
  `staff-chat` (`StaffChatNoticeChannel` → Telegram) — если есть конфиг. Выбора каналов
  по kind сейчас нет.
- `StaffChatNoticeChannel.HEADLINE: Record<SessionNotice['kind'], string>` — новый kind
  без строки не скомпилируется; это и есть точка, где решается «Telegram или нет».
- jobId `notice-<channel>-<kind>-<id>-<startsAt>`; `KEEP_COMPLETED_SECONDS = 24 ч`
  (`jobs/queues.ts`). У продления `startsAt` не меняется → **второе продление той же
  сессии BullMQ отбросил бы как дубль**. Подтверждено. `endsAt` растёт с каждым
  продлением; у остальных kind в пределах одного события он не меняется (`started`
  ставится один раз — только при `transitioned`; reschedule меняет оба времени).
- Транзакция `extendLocked` (`prisma-sessions.repository.ts` ~454):
  `endsAt = session.endsAt + minutes`, `bookedMinutes += minutes` — под локом.
  Значит «было до» = `result.endsAt − minutes` точно; `context.endsAt` читается до
  транзакции и устаревает при двух параллельных продлениях. Подтверждено.
- `activate` пересчитывает `endsAt` от фактического старта (~678), поэтому
  `endsAt − startsAt ≠ bookedMinutes` — в тексте только числа из самого нотиса.
- Процессор (`jobs/sessions.processor.ts`) просто зовёт `notifier.deliver` — валидации
  kind в данных задачи нет; новый kind проходит без правок.
- Спеки: `session-notifier.spec.ts` проверяет jobId (`…-${SLOT}`) — обновить;
  `sessions.service.spec.ts` ~993 проверяет `notify(…, 'rescheduled', context.startsAt)` —
  обновить под новую сигнатуру.

Противоречий между брифом манора и кодом нет.
