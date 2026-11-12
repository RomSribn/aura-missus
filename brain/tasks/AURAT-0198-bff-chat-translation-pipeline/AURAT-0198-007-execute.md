# AURAT-0198-007 — execute

Дата: 2026-11-08 · slave-1, ветка `feature/AURAT-0198-bff-chat-translation-pipeline` (develop `b2c6375`).
По спеке `005` (одобрена в `006`: решения 1–5 — рекомендации, дневного лимита нет). Всё застейджено, коммитов нет,
платных вызовов нет (тесты — моки и `FakeTranslator`), стек не запускался.

## Что сделано

**Модуль перевода (`AURAT-0191`)**
- Профиль `chat`: `TRANSLATION_PROFILES = ['campaign', 'chat']`, `readTranslationConfig`, env `TRANSLATION_CHAT_*`
  (по умолчанию `off`, effort `low`, thinking `off`, таймаут 6000, параллельность 4), правила «всё или ничего» и
  отказ `fake` в проде — в `requireTranslationProfiles`.
- Выключатели `TRANSLATION_CHAT_TO_DESK` / `TRANSLATION_CHAT_REPLIES` (`envBool('false')`).
- Цель `en`:
  - `supports()` у Claude и у фейка — все `LANGUAGES`;
  - `supported` профиля — минус `DISABLED_LANGUAGES`;
  - `en → en` по-прежнему `RangeError`.
- `Semaphore.acquire(signal?)` — отмена снимает ждущего из очереди.
- `translate(…, { totalMs })` вместо `waitSignal` из спеки — уточнение по ходу. Срок покрывает ожидание слота и
  вызов вместе:
  - слот не освободился вовремя → `timeout` со стоимостью 0;
  - после ожидания осталось меньше 1 с (`MIN_CALL_MS`) → `timeout` без вызова: оборванный вызов списал бы худшую
    оценку (`0191-011`);
  - иначе таймаут вызова = `min(таймаут, остаток)`.

**Данные**
- `MessageTranslation` + enum `MessageTranslationStatus`, `Message.translations`.
- Миграция **файлом** `prisma/migrations/20261108120000_message_translations/migration.sql`. SQL сгенерирован
  офлайн `prisma migrate diff` (старая схема → новая), сверка совпала. Для этого нужен фиктивный `DATABASE_URL`: без
  него CLI Prisma 7 молча выдаёт пусто.
- `MessagesRepository`:
  - `MessageRecord.translation` (только у советника);
  - `MessageUpsert.translation` — вложенный create `PENDING`;
  - `listTranslationsFrom` — старые первыми, без удалённых, предел;
  - `findForTranslation`, `listContextBefore`;
  - `settleTranslation` — условно `WHERE status = PENDING`;
  - `listStalePendingTranslations`, `markTranslationRequeued`;
  - `emptyLiveRow` удаляет перевод в транзакции удаления.

**Конвейер (`src/modules/chat`)**
- `chat-translation.rules.ts` — чистые правила: условия, `hasWords`, контекст, ключ кэша, текст заметки, DTO.
- `ChatTranslationService`:
  - `forDesk` (никогда не бросает);
  - `enqueueDeskNote` / `deskNote`;
  - `replyLanguage`, `enqueueReply`, `translateReply`;
  - `watch` (сторож).
- `ChatService`:
  - отправка: перевод после раннего выхода по ключу, `deskTranslation` в пост, `desk-note` при сбое;
  - приём: `captionIsFallback` из `toUpsert`, `pending` в том же create, сначала fan-out, потом задача;
  - история: `translatedFrom` → `translations`;
  - `toDto` → `translation`;
  - `DELETED_IDS_LIMIT` → `CATCH_UP_LIMIT` (200).
- `ReconciliationService.sweep` → `chatTranslation.watch()` в своём `try/catch`.
- `ChatModule` импортирует `TranslationModule`, `AdvisorsModule` и очередь.

**Очередь** `chat-translation` (`queues.ts`, в `allQueueOptions`)
- `reply`: 5 попыток от 10 с, `jobId` — `tr-<id>`, у перезапуска сторожем — `tr-<id>-r`.
- `desk-note`: 3 попытки от 30 с, `dn-<id>`.
- `ChatTranslationProcessor`:
  - тонкий, передаёт сервису `lastAttempt`;
  - `worker.concurrency` берёт из `TRANSLATION_CHAT_CONCURRENCY` при старте приложения.

**Стол (адаптер `chatwoot`)**
- Порт `postUserMessage(…, deskTranslation?)`.
- Клиент:
  - JSON — `content_attributes: { translations: { en } }`;
  - multipart — `content_attributes` JSON-строкой.

**Доставка** — `pushMessageTranslated`: WS `message.translated`, без FCM.

**OpenAPI** (`openapi.ts`, контроллер)
- `messageTranslationOpenApi` в `Message.translation`.
- `HistoryResponse.translations`: старые первыми, предел 200, «только читает».
- Параметр `translatedFrom`.
- Явно записано: **клиент запросить перевод не может**, перевод запускает только сервер.

**Контракты** — клон `/Volumes/Work/personal/ai-manors/aura-contracts`, ветка `feature/AURAT-0198-translation-jsdoc`
от `main` `fa56e89`, застейджено без коммита. Изменён только JSDoc `src/chat.ts`:
- «только сервер запускает перевод, клиент — нет»;
- `pending` — единственный меняющийся статус;
- **`failed` окончателен**;
- `translatedFrom` — самое старое `pending`;
- `translations` — старые первыми, предел 200;
- `message.translated` — окончательный.

`typecheck` и `build` пакета — ок. Тег не нужен, коммит в `main` — координатор.

**Документы**
- `README.md`: `?lang` на отправке и перевод для стола; `translatedFrom`; событие WS; раздел «Chat translation».
- `deploy/env/bff.env.example`: блок `TRANSLATION_CHAT_*` и выключатели с предложением Haiku 5.5 / $20.
- `AURAF-0024`: шаг 5 в плане. BE ✓ — после мёржа и проверки в маноре.

## Файлы

- **Новые:**
  - `src/modules/chat/chat-translation.{rules,service}.ts` + спеки;
  - `src/jobs/chat-translation.processor.ts` + спека;
  - миграция.
- **Изменённые:**
  - `prisma/schema.prisma`, `README.md`, `deploy/env/bff.env.example`;
  - `src/config/env.schema{,.spec}.ts`;
  - `src/contracts/{message,openapi}.ts`;
  - `src/jobs/{jobs.module,queues}.ts`;
  - `chat/{chat.controller,chat.module,chat.service,messages.repository,prisma-messages.repository,reconciliation.service}.ts`
    + спеки `chat.service`, `reconciliation.service`;
  - `chatwoot/{chatwoot-messaging.port,chatwoot-messaging.service,chatwoot.client}.ts` + спека клиента;
  - `delivery/delivery.service.ts`;
  - `translation/{claude/claude.translator,fake.translator,semaphore,translation-config,translation.service}.ts`
    + спеки `semaphore`, `translation.service`;
  - `campaigns/campaign-translation.spec-fixtures.ts` — профиль `chat` (`off`): сервис теперь требует оба профиля.

## Проверки (слот, без стека)

- `prisma validate` / `generate` — ок.
- `npm run lint` — чисто, `npm run typecheck` — чисто, `npm run build` — ок.
- `jest` — **184 / 184 наборов, 2570 / 2570 тестов**. Новых тестов около 130:
  - правила — 30;
  - сервис конвейера — 61, из них сквозной на настоящем `TranslationService` с `FakeTranslator`: `[en] …` для стола,
    `[de] …` для ответа;
  - `ChatService` — 14;
  - семафор — 4;
  - модуль: цель `en`, `totalMs` — 4;
  - env — 7 (и chat-ключи в тесте «пустые строки»);
  - процессор — 5;
  - клиент стола — 2;
  - сверка — 1.
- Форматирование:
  - `prettier --write` по папкам задел чужие файлы и чужие строки — откачено;
  - в моих файлах остались только мои правки;
  - `translation.service.ts` и `claude.translator.ts` были не отформатированы ещё до задачи, новых расхождений я не
    добавил.

## Только в маноре после мёржа

1. `prisma migrate deploy`.
2. Локальный стек манора: `TRANSLATION_CHAT_PROVIDER=fake`, `NODE_ENV` не `production`, оба выключателя `true`,
   пользователь с согласием и `chatLanguage=de`. Проверить:
   - пузырь стола `[en] …` и «View original»;
   - уведомление агенту;
   - ответ `pending → translated` по WS;
   - история с `translatedFrom`;
   - удаление столом снимает перевод.
3. На bff-dev `fake` запрещён (`NODE_ENV=production`): живая проверка там — только с ключом (решение 9), с одобрения
   владельца.

## Открытое

- Правка сообщения столом по-прежнему не обрабатывается — перевод не меняется (`AURAI-0012` §1.4).
- Превью списка разговоров у стола — оригинал (ограничение Chatwoot).
- Приложению — малая задача «якорить догонку только на `pending`» (решение 1 А). Её выдаёт координатор после мёржа.
- Контракты: коммит JSDoc в `main` — координатор.
