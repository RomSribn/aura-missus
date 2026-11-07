# AURAT-0172-004 — context

Дата: 2026-11-06. Код — `slave-3` @ `74755ee`.

## Что есть сейчас (код — ground truth)

- `screens/chat-thread/ui/ChatThreadScreen.tsx:186-202` — обычный (не inverted) RN `FlatList`, «Today» —
  `ListHeaderComponent` (`shared:day.today`), липкость к низу — `onContentSizeChange={scrollToEnd}` (анимированный
  `scrollToEnd` на **любое** изменение размера — подгрузка сверху с ним сразу уводила бы вниз).
- `use-chat-thread.ts:46-58` — приветствие персоны (UI-only) всегда первым элементом ленты.
- `features/chat/model/ChatProvider.tsx` — `syncThread`: без курсора — новейшая страница (50), дальше `after`
  (досинхронизация) + `deletedFrom = oldestServerId(thread)`. `before` не используется. Состояние треда — только в
  памяти (на диске — только файлы вложений); «кэша треда» как отдельного хранилища нет.
- Попутно: досинхронизация `after` берёт одну страницу; если без сети пришло > 50, остаток — до следующего триггера.
- Форматтеры дат `shared/lib/dates.ts`: `relativeDay` (сегодня/завтра — вперёд, «вчера» нет), `dayMonthLabel`
  («November 4» / «4 November» / «4. listopadu», CLDR-таблицы `formats.generated.ts`). **Шаблона с годом нет** —
  генератор `scripts/i18n/generate-formats.mjs` (Node 22.23.0 / ICU 78.2 — тот же Node в слоте).
- Строки: `shared:day.today` / `tomorrow` есть, `yesterday` — нет.
- `ThreadDivider` — линия с капсом для маркеров сессии и раскладов; подпись дня в дизайне (README §экран 10) —
  отдельный центрированный «Today» 11.5 / ink-3.
- Список в треде — RN `FlatList`, не RNGH: правило 7 (legacy RNGH-списки) задачу не ограничивает, RNGH здесь не нужен.

## Контракт и BFF

- `aura-contracts/src/chat.ts:338-353` — `HistoryQuery.before` «scroll-back from the oldest visible one», страницы по
  возрастанию, `limit` ≤ 100 (по умолчанию 50).
- BFF `prisma-messages.repository.ts` `listPage`: `before` → `chatwootMessageId < pos`, `desc`, `take limit`, затем
  `reverse` → по возрастанию, без удалённых. **Проверено: работает как описано.** Надгробия удалённых хранятся, так что
  `before=<удалённый id>` — валидная позиция. Неизвестный id → `null` → **молча новейшая страница** (защита на клиенте:
  дедуп по id). `after` имеет приоритет над `before`.
- `deletedIds` — максимум 200 (`DELETED_IDS_LIMIT`) от `deletedFrom` по возрастанию.

## Параллельно

- `AURAT-0169` (slave-2) — на стадии execute/ревью, скорее всего вольётся раньше; `replaceSpreads` в коде ещё нет.
  Её спека v2: перечитывается только открытый тред, последняя страница; кто вливается вторым — подключает старые
  страницы (`AURAT-0169-007`, «Расклады в чате»).

## Противоречий нет
