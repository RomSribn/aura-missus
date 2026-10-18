# AURAT-0097-005 — Спека: приложение (+ ссылки на фичу и BFF)

Дата: 2026-10-18. Тип: **фича + две задачи**.
- Фича: `brain/features/AURAF-0018-message-deletion/AURAF-0018-message-deletion.md`
  (scope, решения 1–4, контракт v0.22.0).
- Бекенд: `brain/tasks/AURAT-0098-bff-message-delete/AURAT-0098-001-initial.md`
  (контракты + BFF, исполняется в `aura-bff-manor`).
- Приложение — ниже (этот слот, `feature/AURAT-0097-message-delete`).

**Зависимость:** код приложения начинается после тега `aura-contracts`
`v0.22.0`; живая проверка — после деплоя BFF на dev.

---

## Задача приложения (`aura-app`, FSD)

### A0. Подготовка
- `npm ci` (в slave-0 `node_modules/@aura/contracts` устарел: 0.20.0 при пине
  v0.21.0), затем `package.json` → `github:RomSribn/aura-contracts#v0.22.0`,
  `npm install`, lock в коммит.

### A1. API — `features/chat/api/chat-api.ts`
- `HistoryParams` += `deletedFrom?: string`; в query `deletedFrom=…`.
- `fetchHistory` возвращает **весь** `HistoryResponse` (`{ messages, deletedIds }`),
  а не только `messages`; поправить всех вызывающих (`ChatProvider`, тесты).
- Тест `api/__tests__/chat-api.test.ts`: параметр уходит в URL; ответ старого BFF
  без `deletedIds` → `[]` (дефолт контракта).

### A2. Стор — `features/chat/model/ChatProvider.tsx`
1. Новый `removeServerMessages(advisorId, ids: string[])`:
   - убирает из `threads[advisorId]` сообщения с этими `id` (только серверные;
     `local-*` не трогает); если ничего не убралось — `prev` (без ререндера);
   - тред, опустевший целиком, остаётся ключом с `[]` — список чатов его и так
     не покажет (`use-chats.ts` берёт `lastMessage`);
   - **курсор `lastServerIds` не трогает**: BFF держит надгробие, `after=<id
     удалённого>` валиден. Пересчёт курсора от треда — ошибка (дельта начнёт
     повторно тянуть уже виденное).
2. Память об удалённых — `deletedIdsRef: Record<advisorId, Set<string>>`
   (в памяти, на сессию). `mergeServerMessages` отбрасывает входящие с id из
   этого множества. Закрывает гонки: `message.new`/ответ `POST` пришёл после
   `message.deleted`; повторная отправка вернула удалённый DTO (`AURAT-0098` B5).
3. WS: `case 'message.deleted': removeServerMessages(event.advisorId,
   [event.messageId])`; typing не трогать.
4. `syncThread`: передавать `deletedFrom` = id **самого старого серверного**
   сообщения треда (не `local-*`, не синтетическое приветствие — оно живёт в
   `use-chat-thread.ts`, в сторе его нет); при пустом треде не передавать.
   После ответа — `mergeServerMessages(messages)` и
   `removeServerMessages(deletedIds)`. **Важно:** сейчас
   `mergeServerMessages` выходит рано на пустом `incoming` — удаления должны
   применяться и когда новых сообщений нет (отдельный вызов, не внутри merge).
5. Отправка (`deliver`): если `dto.id` уже в `deletedIdsRef` — локальную копию
   убрать, а не заменять DTO.
6. Побочные эффекты удаления (из model, не из ui):
   - вложения удалённого — `forgetAttachment(id, extensionOf(attachment))`
     (`@/shared`, хелпер `extensionOf` из `../lib/attachment-rules`);
   - расклад — `spreadStore.forget(messageId)` (новый метод в
     `features/tarot-spread/model/spread-store.ts`, если в сторе есть запись;
     экспорт через public API слайса);
   - открытый `ImageViewer` на вложении удалённого сообщения закрывается
     (состояние `viewer` в `screens/chat-thread/model/use-chat-thread.ts` —
     сбрасывать, когда `subject` больше нет в треде).
7. Логи — без текста и id пользователя (правило 5).

### A3. UI
- По решению 1 (`AURAF-0018`) — сообщение просто исчезает. `FlatList` с
  `keyExtractor = id` сам уберёт строку; анимацию не добавлять (дизайна нет).
  Если владелец выберет плашку «Сообщение удалено» — отдельный дизайн и пункт.
- Проверить: голосовое/видео удалённого, если играло, — плеер размонтируется и
  останавливается (`AttachmentVoice`, `AttachmentVideo`), без висящего звука.
- Превью в списке чатов (`screens/chats`) — пересчитывается само от треда,
  кода не нужно; покрыть тестом.

### A4. Тесты (`npm test`, slave-гейт)
- `ChatProvider.test.tsx`:
  - `message.deleted` убирает сообщение; неизвестный id — без ререндера;
  - `message.new` с удалённым id после события — не возвращает его;
  - курсор после удаления последнего сообщения — прежний (следующий `fetchHistory`
    с `after=<удалённый>`);
  - resync (`onOpen` / foreground) с `deletedIds` убирает сообщения, в том числе
    при пустом `messages`; `deletedFrom` = самый старый серверный id;
  - удаление единственного сообщения → тред пуст.
- `ChatProvider.send.test.tsx` — ответ отправки с удалённым id не кладёт DTO.
- `screens/chats` — превью переключается на предыдущее; опустевший тред исчезает.
- `chat-thread` — открытый viewer закрывается.
- `spread-store` — `forget`.

### A5. Доки
- `TECH-DEBT.md` #9 — удаления теперь доставляются (`message.deleted` +
  `deletedIds`); правки уже доставленных сообщений — по-прежнему нет.
- Шапка `ChatProvider` / комментарий у `mergeServerMessages` — что стор теперь
  умеет убирать и почему курсор не трогается.

### A6. Проверка в маноре (после мержа, BFF на dev)
Android, bff-dev: открыть чат → удалить в дашборде ответ оператора → пропал
сразу; свернуть приложение → удалить ещё одно → развернуть → пропало; удалить
сообщение пользователя → пропало; удалить сообщение с картинкой → картинки нет,
кэш очищен; перезапуск — удалённых нет. Сборка в стор — `versionCode` ≥ 28,
решение владельца.

## Открытые вопросы владельцу
1. Исчезает без следа (рекомендую) или плашка «Сообщение удалено»?
2. Удалять и сообщения пользователя, если их удалил оператор (рекомендую — да)?
3. Потеря удаления при простое BFF (вебхуки Chatwoot без ретраев) — записать в
   TECH-DEBT (рекомендую) или сразу строить бэкстоп-перечитку?
