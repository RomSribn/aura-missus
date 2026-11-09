# AURAT-0204-005 — spec (v2, после замечаний манора; draft)

Тип: task, без фичи-родителя (продолжение `AURAT-0091` / `AURAT-0092`).

## Что делаем

Продление идущей платной сессии → приватная заметка в диалоге Chatwoot с
@упоминанием назначенного агента. В Telegram — нет. Пример:

```
Paid session extended by 10 min — now until 15:00 UTC (was 14:50 UTC).
```

Вопрос клиента (`AURAF-0020-028`) к этой заметке **не** прикладывается — он уже был в
`booked` / `started`. Общей длины блока в тексте нет: `endsAt − startsAt` не равен
`bookedMinutes` (метр пересчитывает окно от фактического старта), а `bookedMinutes`
на доставке — уже сумма всех продлений; только числа из самого нотиса.

## Как (в схеме AURAT-0092: сервис не знает каналов)

1. **Событие.** `SessionNotice.kind` += `'extended'`; поле `previousEndsAt?: number`
   (симметрично `previousStartsAt` у переноса). Минуты продления =
   `endsAt − previousEndsAt` — точно, транзакция прибавляет ровно `minutes`.
2. **Канал явно объявляет, что несёт.** В `SessionNoticeChannel` —
   `abstract carries(kind: SessionNotice['kind']): boolean`. Не «по умолчанию `true`»:
   метод базового класса с неиспользуемым `kind` валит lint
   (`@typescript-eslint/no-unused-vars`, `args: after-used`). Зато каждый канал говорит
   это явно. `DeskNoteChannel.carries(): boolean { return true; }` (меньше параметров
   допустимо). `SessionNotifier.notify` ставит задачи только каналам, у которых
   `carries(kind)`.
3. **Telegram выписывается через тип.**
   `type StaffChatKind = Exclude<SessionNotice['kind'], 'extended'>`,
   `HEADLINE: Record<StaffChatKind, string>`,
   `carries(kind): kind is StaffChatKind { return kind in HEADLINE; }`. Следующий новый
   kind не скомпилируется без явного решения «в Telegram или нет».
   В `deliver` — `if (!this.carries(notice.kind)) return;` перед `HEADLINE[notice.kind]`
   (этого требует сужение типа): задача на kind, который канал не несёт, — no-op, как
   `SessionNotifier.deliver` молча бросает задачу канала, которого больше нет.
4. **Desk.** `DeskNoteChannel`: `case 'extended'` → текст выше, `mentionAssignee` как у
   остальных. Без `previousEndsAt` (не бывает, но тип допускает) —
   `Paid session extended — now until 15:00 UTC.`
5. **Сигнатура.** `notify(session, kind, was?: { startsAt?: Date; endsAt?: Date })`:
   перенос → `{ startsAt: context.startsAt }`, продление →
   `{ endsAt: session.endsAt − minutes }` (из результата транзакции, не из
   `context.endsAt`).
6. **jobId** += `endsAt`: `notice-<channel>-<kind>-<id>-<startsAt>-<endsAt>`. Иначе второе
   продление той же сессии BullMQ молча выкинет как дубль (выполненные хранятся 24 ч).
   Для остальных kind `endsAt` в пределах события не меняется — их дедуп прежний.
   Цена: повтор события, поставленный ровно через деплой, получит новый id — один
   раз, пренебрежимо.
7. **Сервис.** `extend()`, ветка `!replayed`: `notify(session, 'extended', { endsAt: … })`
   рядом с `scheduleFinish`. Replay — без нотиса.

Отвергнуто: звать desk-канал напрямую из сервиса (ломает «сервис не знает каналов»,
дублирует очередь и ретраи); глушить `'extended'` внутри Telegram-канала (пустая
задача на каждое продление, спрятанное правило); список каналов из сервиса.

## Рамки
Только `src/modules/sessions/notices/*`, `sessions.service.ts`, их спеки и комментарии:
`src/jobs/queues.ts` (~54–55, список видов нотиса у задачи `'notice'` — дописать
extended, только desk) и шапка `session-notifier.ts` про jobId («the channel, the event
and the slot» → плюс конец окна).
`@aura/contracts` и приложение не трогаем. Завершение (досрочное / по метру) —
по-прежнему без заметки (не просили).

## Тесты (чистые)
- `DeskNoteChannel`: текст `extended` (с `was` и без), без вопроса клиента даже если он есть.
- `StaffChatNoticeChannel.carries`: `extended` — нет; остальные пять — да.
- `StaffChatNoticeChannel.deliver` с kind `extended` → no-op: `staffChat.post`,
  `advisors.findById` и `deskConversationUrl` не вызваны (выход до них), без ошибки.
- `SessionNotifier`: `extended` → только desk-задача, `previousEndsAt` в данных;
  два продления → два разных jobId; новые jobId в старых ожиданиях.
- `sessions.service.spec`: `extend` зовёт `notify(…, 'extended', { endsAt })`, replay —
  нет; перенос — `{ startsAt }`.
  **Отдельный случай с устаревшим контекстом**: в нынешней фикстуре контекст кончается
  в 08:40, а результат — 08:50 после +10, так что `context.endsAt` и
  `session.endsAt − minutes` совпадают и неправильная реализация тест пройдёт. Новый
  случай: контекст 08:40, результат `extend` 09:00 после +10 (параллельное продление
  успело раньше) → ожидается `notify(…, 'extended', { endsAt: 08:50 })`.
- Фейки каналов в `session-notifier.spec.ts` получают `carries`.
- lint + typecheck + build.

## Риски (принятые края)
- **Сбой Redis после коммита списания.** Транзакция прошла → постановка задачи упала →
  500 → клиент повторяет с тем же ключом → replay без нотиса → заметка потеряна;
  бэкстопа в `sweepDue` нет. Тот же принятый край, что у `booked` (`AURAT-0091`).
- **Повтор задачи после успешного поста** в Chatwoot с потерянным ответом → дубль
  заметки. Как у всех заметок.

## Живая проверка — манор после мёржа
Продлить ACTIVE-сессию → заметка с @упоминанием в диалоге; продлить второй раз →
вторая заметка. «Не ушло в Telegram» в маноре не наблюдаемо (нет `TELEGRAM_*` в
.env) — это доказывает юнит-тест notifier'а; вживую — только на bff-dev.
