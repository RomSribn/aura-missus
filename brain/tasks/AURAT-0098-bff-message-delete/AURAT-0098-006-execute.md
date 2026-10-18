# AURAT-0098-006 — Часть B: BFF выполнен (не закоммичено, ждёт ревью)

Дата: 2026-10-18. Ветка `feature/AURAT-0098-bff-message-delete` в `aura-bff`.

## Сделано по плану `001`
- **B1** `prisma/schema.prisma` + миграция `20261018120000_message_deletion`:
  `messages.deletedAt TIMESTAMP(3) NULL`, без индекса.
- **B2** `chatwoot.types.ts` — `content_attributes.deleted` в обоих wire-типах;
  доменные `ChatwootMessageDeletion` и `ChatwootMessageBatch`.
  `message-normalizer.ts` — `normalizeWebhookDeletion` / `normalizeRestDeletion`;
  удалённое никогда не становится `ChatwootMessage` (флаг, не текст).
  `webhook-events.ts` — `message_updated` → `kind: 'deletion'` только при
  `deleted === true`, не private, incoming/outgoing.
- **B3** контроллер вебхука: `deletion` → задача `delete` в `chatwoot-webhook`,
  jobId `wh-del-{conv}-{msg}`, без фильтра по направлению. Имена задач —
  константы `CHATWOOT_INGEST_JOB` / `CHATWOOT_DELETE_JOB` в `queues.ts`;
  процессор диспатчит по имени (как `presence.processor.ts`).
- **B4** `ChatService.applyDeskDeletion` → `applyDeletion` (общий с поллингом) →
  `MessagesRepository.markDeleted` → при `changed` WS `message.deleted`
  (`DeliveryService.pushMessageDeleted`, без FCM). Репозиторий: транзакция
  «найти → условный `updateMany … deletedAt: null` → удалить вложения и
  расклад»; нет строки → надгробие; P2002 на надгробии (параллельный
  `message_created`) → повтор опустошения. Ровно один из гонщиков получает
  `changed: true`.
- **B5** `listPage` фильтрует `deletedAt: null`, `cursorPosition` — нет.
  `listDeletedIdsFrom` (≥ позиции, asc, лимит 200, чужой/неизвестный id → `[]`).
  `getHistory` всегда отдаёт `deletedIds`. `findByIdempotencyKey` — как есть.
  Вложения удалённого → строк нет → 404. Расклад удалён → pick → 404.
- **B6** `listMessagesAfter` / порт `fetchMessagesAfter` → `{messages, deletions}`;
  `ReconciliationService` прогоняет `deletions` через `chat.applyDeletion`.
- **B7** тесты: webhook-events, controller, normalizer, client, chat.service
  (ветки applyDeskDeletion, порядок emit после стора, надгробие → без fanOut,
  deletedIds), reconciliation, паритет контракта v0.22.0 (`message.spec.ts`).
- **B8** README (история, WS-события, accepted events, модель доставки),
  `openapi.ts` (`deletedIds`) + `@ApiQuery deletedFrom`, `@aura/contracts#v0.22.0`
  в `package.json`/lock, `TECH-DEBT.md` #36.

## Решения по ходу
- Поллинг возвращает пачку `{messages, deletions}`, а не флаг в
  `ChatwootMessage`: удалённое не может случайно пройти в ингест как пузырь.
- Аудит читателей `messages`: кроме репозитория — только erasure
  (`deleteMany`) и pick расклада (расклад удаляется → 404).
  `hasUserMessageTo` (право на отзыв) по-прежнему учитывает удалённые сообщения
  пользователя — он писал; оставлено намеренно.
- Live-smoke на dev-Chatwoot не писался файлом — это ручная проверка в маноре.

## Гейт
`npm run lint`, `tsc --noEmit`, `npm run build` — зелёные. `jest`: 1530/1530
(в одном прогоне падал несвязанный `apple-refund.service.spec.ts`, в изоляции и
в двух повторах — зелёный: флейк).

## Открыто
- Таблица scope `AURAF-0018` (колонка BE) живёт в клоне `aura-app-manor` —
  отметить ✓ после проверки в маноре; здесь файла нет.
- После мержа, в маноре: `prisma migrate deploy`, smoke из B7 на dev.
