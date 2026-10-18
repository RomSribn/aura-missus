# AURAT-0097-008 — Исполнение (приложение)

Дата: 2026-10-18. Слот `slave-0`, ветка `feature/AURAT-0097-message-delete`.
Тег `aura-contracts` `v0.22.0` (`003040a`) сверен со спекой — совпадает.

## Сделано

- `package.json` / lock → `@aura/contracts#v0.22.0` (`npm install
  github:…#v0.22.0` — простой `npm install` оставлял старый коммит в lock).
- `features/chat/api/chat-api.ts` — `HistoryParams.deletedFrom`; `fetchHistory`
  отдаёт весь `HistoryResponse` (`{ messages, deletedIds }`).
- `features/chat/model/ChatProvider.tsx`:
  - `removeServerMessages(advisorId, ids)` — убирает серверные сообщения без
    следа, ничего не меняет, если таких нет; курсор `lastServerIds` не трогает
    (надгробие в BFF держит позицию);
  - `deletedServerIds` (на сессию входа, сброс при смене пользователя) —
    `message.new` и ответ отправки с удалённым id сообщение не возвращают;
    локальная копия при таком ответе уходит;
  - WS `message.deleted` → удаление; синк передаёт `deletedFrom` = самый старый
    серверный id треда (локальные копии — со `status`, пропускаются) и
    применяет `deletedIds` отдельно от merge (работает и без новых сообщений);
  - кэш вложений удалённого — `forgetAttachment(id, extensionOf(...))`.
- `screens/chat-thread/model` — `ViewerSubject.messageId`; открытый просмотр
  картинки закрывается, когда сообщения больше нет в треде (производное
  значение, без эффекта).
- `TECH-DEBT.md` #9 — удаление вынесено: у него свой канал.

## Решения по ходу

- **`spreadStore.forget` не добавлен** (был в спеке A2.6): `features/chat` не
  может импортировать `features/tarot-spread` (один слой FSD), а запись по id
  исчезнувшего сообщения никто не рендерит; стор чистится при выходе.
- **Отдельного теста на превью списка чатов нет**: превью — производное от
  треда (`use-chats.ts`), удаление проверено на уровне стора; пустой тред и так
  выпадает из списка (покрыто существующими тестами).
- Старый BFF (до `AURAT-0098`) неизвестный `deletedFrom` молча срезает
  (`ZodValidationPipe`, strip), а `deletedIds` по умолчанию `[]` — новая сборка
  безопасна и до деплоя BFF.
- Плеер голосовых/видео — `<Video>` внутри пузыря: размонтирование его
  останавливает, кода не нужно.

## Тесты

- `ChatProvider.test.tsx` — блок «a message the desk deleted»: 8 кейсов
  (живое удаление, неизвестный id без ререндера, поздний `message.new`, пустой
  тред, курсор после удаления последнего, догоняющий синк с `deletedFrom`,
  пустой тред без `deletedFrom`, очистка кэша вложений).
- `ChatProvider.send.test.tsx` — ответ отправки с удалённым id.
- `chat-api.test.ts` — `deletedFrom` в URL, дефолт `deletedIds`.
- `ChatThreadScreen.deleted.test.tsx` — просмотр закрывается.

Гейт: `npm run lint` ✓, `tsc --noEmit` ✓, `npm test` — 124 сьюта / 882 теста ✓.

## Дальше

Ревью владельца → коммит → мерж в `develop` (только с подтверждения) → живая
проверка в маноре (A6 спеки) после деплоя `AURAT-0098` на dev.
