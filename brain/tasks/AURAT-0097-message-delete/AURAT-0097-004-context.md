# AURAT-0097-004 — Контекст

Дата: 2026-10-18. Сверено по коду: `aura-app` (slave-0 от `develop` @ `f097f1e`),
`aura-bff` `develop` @ `3cab10c`, `aura-contracts` `v0.21.0` (`0f35b76`),
исходники Chatwoot `4.15.1` (`chatwoot-manor/project/manor/master/chatwoot`,
ключевые файлы сверены с тегом `v4.15.1` на GitHub).

## Chatwoot 4.15.1 — что происходит при удалении

- `messages_controller.rb#destroy`: удаление **мягкое** —
  `update!(content: I18n.t('conversations.messages.deleted'), content_type: :text,
  content_attributes: { deleted: true })` + `attachments.destroy_all` (файлы
  ActiveStorage удаляются). Строка, `id`, `message_type`, `created_at` остаются.
- Срабатывает `message.updated` → вебхук `message_updated` на `webhook_url`
  API-инбокса (и агент-боту, но бот в проде `inactive`, `AURAT-0029-022`).
  В пейлоаде: `id`, `content: "This message was deleted"` (локализуется!),
  `content_attributes: {deleted: true}`, `message_type` строкой, `private`,
  `conversation` (с `id` = display id), `created_at`; ключа `attachments` нет;
  **нет** `previous_changes` и нет того, кто удалил.
- Тот же `message_updated` прилетает и на смену статуса, `external_error`,
  перевод, CSAT. Надёжный признак удаления — только
  `content_attributes.deleted === true` (не текст).
- Удалить можно **любое** сообщение диалога: исходящее оператора, входящее
  пользователя, приватную заметку. Ограничений по роли/времени в API нет.
  Активити-сообщения вебхук не шлют.
- Редактирования текста оператором в 4.15.1 нет (подтверждено и в `AURAF-0012-002`).

## BFF — сейчас

- `modules/chatwoot/webhook-events.ts:33` — обрабатывает только `message_created`
  и typing; `message_updated` → `null` → 204. Зафиксировано тестом
  `webhook-events.spec.ts:80-89` («acked and ignored»).
- Контроллер вебхука ставит в очередь `chatwoot-webhook` с
  `jobId: wh-{conv}-{msg}`; выполненные задачи хранятся 24 ч → событие удаления с
  тем же jobId BullMQ **молча проглотит**. Нужен свой jobId.
- `messages` (Prisma): нет `deletedAt`/`updatedAt`; `upsertByChatwootMessageId`
  только создаёт, существующую строку не меняет. `message_attachments` и
  `tarot_spreads` — каскад при удалении строки.
- История `listPage`: курсоры `after`/`before` — наши cuid, превращаются в
  `chatwootMessageId` той строки. **Жёсткое удаление строки сломало бы курсор**
  клиента, который на неё смотрит.
- Реконсиляционный поллинг (`normalizeRestMessage`) не знает про
  `content_attributes.deleted` → сообщение, удалённое до приёма, ляжет в базу
  с текстом «This message was deleted» и уйдёт пушем.
- Доставка: WS `message.new` / `session.updated` / `presence.update` /
  `typing.update`; FCM data-only `{type:'message.new', advisorId}`, без текста.
- Вложения проксируются из Chatwoot (`AURAD-0011`), своих копий нет; после
  удаления Chatwoot отдаёт 404 → у нас `AttachmentGoneError` → 404. Телефон
  может держать копию до суток (`Cache-Control: max-age=86400`).

## Контракты

- `Message` — strip-схема: неизвестное поле молча срезается.
- `WsServerEvent` — discriminatedUnion; приложение делает `safeParse` и
  **тихо роняет** неизвестный тип → новое событие безопасно для старых сборок.

## Приложение — сейчас

- `features/chat/model/ChatProvider.tsx`: стор — `useState<ChatThreads>` в памяти,
  без персиста. `mergeServerMessages` только дописывает; ничего не умеет убрать.
- Синк — только дельта `after=<newest id>` (вход, сокет open, foreground, FCM).
  Уже доставленное сообщение никогда не перечитывается: `TECH-DEBT.md` #9.
- Сокет живёт только в foreground → удаление, случившееся в фоне, по WS не придёт.
- Список чатов (`screens/chats/model/use-chats.ts`): превью = последнее сообщение;
  тред без сообщений из списка выпадает.
- Пуш: тело константное («sent you a new message»), id уведомления нет — текста
  удалённого сообщения в шторке нет и быть не может.
- `node_modules/@aura/contracts` в slave-0 устаревший (0.20.0 при пине v0.21.0) —
  перед работой `npm ci`.
- Тесты-образцы: `features/chat/model/__tests__/ChatProvider.test.tsx` (мок
  `BffSocket`, тесты гоняют `onEvent`).

## Вывод

Нужны три слоя: контракты (новое WS-событие + поле в истории для пропущенных
удалений), BFF (приём `message_updated`, мягкое удаление с вычисткой контента,
фильтр истории, событие клиенту, поллинг) и приложение (удаление из стора,
догоняющий синк, побочные эффекты).
