# AURAT-0098-001 — BFF + контракты: удаление сообщения из Chatwoot

Дата: 2026-10-18
Статус: **заведена**, исполнение — `aura-bff-manor` (ID выдан в `aura-app-manor`)
Репозитории: `aura-bff` (+ `aura-contracts` → **v0.22.0**)
Фича: `AURAF-0018` — **одобрена владельцем 2026-10-18** (`AURAT-0097-006`
решения, `AURAT-0097-007` одобрение и «отправляй bff задачу в свободный слейв»). Парная app-задача — `AURAT-0097`.
Сверено с `aura-bff` `develop` @ `3cab10c`, `aura-contracts` `v0.21.0`,
Chatwoot `4.15.1`. Факты — `AURAT-0097-004-context.md`.

## Что делает Chatwoot (коротко)
`DELETE …/messages/:id` → `update!(content: "This message was deleted",
content_type: :text, content_attributes: {deleted: true})` + удаление вложений →
вебхук **`message_updated`** на `webhook_url` API-инбокса. Без diff, без автора
удаления. Тот же `message_updated` приходит на статусы / `external_error` /
переводы — признак удаления только `content_attributes.deleted === true`.
Текст локализуется — по нему не матчить.

---

## Часть A — `aura-contracts` v0.22.0 (сначала; тег до BFF)

`src/chat.ts`, только аддитивно:
1. `WsServerEvent` += `z.object({ type: z.literal('message.deleted'),
   advisorId: z.string(), messageId: z.string() })` — `messageId` = наш cuid
   (`Message.id`), не id Chatwoot.
2. `HistoryQuery` += `deletedFrom: z.string().optional()` — наш id сообщения;
   документировать: «верни id удалённых сообщений с позицией ≥ этого».
3. `HistoryResponse` += `deletedIds: z.array(z.string()).default([])`.
4. `Message`, `MessagePushData` — **не трогать**.
5. README — абзац v0.22.0 в changelog; коммит «… (v0.22.0)», тег `v0.22.0`, push.

## Часть B — `aura-bff`

### B1. Схема (миграция Prisma)
- `messages.deletedAt TIMESTAMP(3) NULL`. Индекс не нужен на старте
  (выборки и так по `conversationId` + `chatwootMessageId`); добавить частичный
  `WHERE "deletedAt" IS NOT NULL` только если `deletedFrom`-запрос того требует.
- Жёстко строки **не удалять**: на них смотрят курсоры `after`/`before`
  клиентов (`listPage` → `cursorPosition`).

### B2. Нормализация вебхука — `modules/chatwoot/`
- `chatwoot.types.ts`: в wire-тип сообщения добавить
  `content_attributes?: { deleted?: boolean } | null`.
- `webhook-events.ts`: новая ветка `event === 'message_updated'` →
  если `content_attributes?.deleted === true`, `private !== true`,
  `message_type` ∈ {`incoming`, `outgoing`} → `{ kind: 'deletion',
  chatwootConversationId, chatwootMessageId, direction, chatwootCreatedAt }`;
  иначе `null` (статусы, `external_error` и т. п. по-прежнему 204 и мимо).
  Направление — тем же маппингом, что `message-normalizer.ts`.
- Перевернуть кейс `message_updated` в `webhook-events.spec.ts:80-89`:
  без `deleted` — по-прежнему `null`; с `deleted: true` — `deletion`;
  private / activity / template с `deleted` — `null`.

### B3. Контроллер и очередь
- `chatwoot-webhook.controller.ts`: ветка `kind === 'deletion'` ставит задачу
  `'delete'` в ту же очередь `chatwoot-webhook` с **собственным** jobId
  `wh-del-{conv}-{msg}`. Причина: выполненные `wh-{conv}-{msg}` живут 24 ч, и
  BullMQ проигнорирует `add` с тем же jobId — удаление пропало бы молча.
- **Фильтр `direction !== 'advisor'` к удалению не применять**: оператор может
  удалить и сообщение пользователя, и оно пропадает у пользователя тоже
  (решено владельцем 2026-10-18, `AURAT-0097-006`).
- `jobs/chatwoot-webhook.processor.ts`: по `job.name` → `chat.applyDeskDeletion(…)`.
  Процессор тонкий, наследует `LoggingWorkerHost` (`processors.spec.ts`).

### B4. Сервис и репозиторий — `modules/chat/`
`ChatService.applyDeskDeletion(event)`:
1. `messaging.resolveConversation(chatwootConversationId)`; неизвестный
   диалог — `warn` только с id, выход (как `ingestAgentDeskMessage`).
2. `messages.markDeletedByChatwootMessageId(conversationId, chatwootMessageId,
   fallback)` — в одной транзакции:
   - есть строка с `deletedAt IS NULL` → `deletedAt = now()`, `content = ''`,
     `sessionInvite = false`; удалить её `message_attachments` и `tarot_spreads`;
     вернуть `{ record, changed: true }`;
   - строка уже удалена → `{ changed: false }` (повтор вебхука, дубль бота);
   - строки нет (удаление обогнало приём `message_created` или поллинг) →
     **вставить надгробие** (`deletedAt` = now, `content = ''`, direction и
     `chatwootCreatedAt` из события) → `{ changed: false }`. Тогда опоздавший
     `message_created` упрётся в unique (P2002) → `inserted: false` → без пуша.
   - `idempotencyKey` оставить (повтор отправки с тем же ключом не должен
     создать дубль в Chatwoot).
3. Если `changed` — **после коммита** `delivery.emitToUser(userId,
   { type: 'message.deleted', advisorId, messageId: record.id })`. Пуша нет.
   Правило 5 (доставка из сохранённой строки) соблюдено: id берётся из записи.
4. Логи — только id, без текста (правило PII).

### B5. Чтение
- `listPage`: в выборки `after`/`before` добавить `deletedAt: null`;
  `cursorPosition` — **без** этого фильтра (курсор на удалённую строку валиден).
- `deletedFrom`: если передан, отдельным запросом — `id` строк диалога с
  `deletedAt IS NOT NULL` и `chatwootMessageId ≥ позиции deletedFrom` (порядок
  asc, верхняя граница — разумный лимит, например 200). Неизвестный
  `deletedFrom` → пустой массив, не 400. Ответ — `{ messages, deletedIds }`.
- `chat.controller.ts` / DTO-валидация `HistoryQuery` — новое поле проходит.
- `findByIdempotencyKey` (повтор отправки, когда оригинал уже удалён): отдать
  DTO как есть (`content: ''`, без вложений), Chatwoot заново не вызывать.
  Приложение уберёт его по `deletedIds` ближайшим синком (`AURAT-0097`).
- Аудит остальных читателей `messages` (`grep prisma.message`/`tx.message`):
  сейчас это только `prisma-messages.repository.ts` и erasure; проверить связи
  через `include` (сессии, отзывы, деск-виджет) — удалённые не должны нигде
  всплывать текстом.
- `GET /v1/attachments/:id` удалённого сообщения → 404 (строк вложений нет).

### B6. Реконсиляционный поллинг
- `message-normalizer.ts#normalizeRestMessage`: читать
  `content_attributes.deleted`; удалённое → признак `deleted: true` в
  `ChatwootMessage` (а не текст «This message was deleted» как контент).
- `reconciliation.service.ts`: удалённое сообщение, которого у нас нет, →
  надгробие без пуша (тот же `markDeleted…`); уже принятое и не удалённое →
  применить удаление (с `message.deleted`).
- Ограничение (в `TECH-DEBT.md`): вебхуки Chatwoot без ретраев, а поллинг
  читает только *после* последнего id. Удаление уже принятого сообщения в
  момент простоя BFF (деплой) потеряется. Бэкстоп (перечитка последних N
  сообщений активных диалогов) — не строим (решено владельцем 2026-10-18).

### B7. Тесты (jest, без БД, моки как в соседних spec)
- `webhook-events.spec.ts` — см. B2.
- `chatwoot-webhook.controller.spec.ts` — `deletion` → `add('delete', …,
  { jobId: 'wh-del-56-900' })`; удаление сообщения пользователя тоже в очередь.
- `message-normalizer.spec.ts` — REST с `deleted` → флаг, контент не «This
  message was deleted».
- `chat.service.spec.ts` — три ветки `applyDeskDeletion` (живое / уже удалено /
  нет строки → надгробие), emit только при `changed`, emit после коммита;
  `message_created` после надгробия → без `fanOut`.
- `reconciliation.service.spec.ts` — удалённое новое → без пуша; принятое → emit.
- `chat.gateway.spec.ts` / `delivery` — сериализация `message.deleted`.
- repository-тесты, если есть паттерн, — фильтр `deletedAt` и `deletedFrom`.
- Smoke (`*.smoke.spec.ts`, **только в маноре** после мержа): на dev-Chatwoot
  отправить сообщение → удалить в дашборде → WS `message.deleted`, история без
  него, `deletedFrom` его возвращает, вложение 404.

### B8. Доки
- `README.md`: список WS-событий (~448-455), «Accepted events» — +`message_updated`
  (только удаление), модель доставки (~565-571), история (~188-191) — `deletedFrom` /
  `deletedIds`.
- `src/contracts/openapi.ts` — `historyResponseOpenApi` (+`deletedIds`), query.
- `package.json` / lock → `@aura/contracts#v0.22.0` (по образцу `484ad62`).
- `TECH-DEBT.md` — запись из B6.

## Готово, когда
Гейт зелёный (lint, typecheck, unit) в слэйве; после мержа в маноре — smoke из
B7 на dev; тег контрактов `v0.22.0` запушен; деплой — по решению владельца.
Приложение (`AURAT-0097`) ждёт тег и деплой BFF на dev.
