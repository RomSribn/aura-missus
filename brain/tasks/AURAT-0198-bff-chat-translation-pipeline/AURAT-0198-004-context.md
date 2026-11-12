# AURAT-0198-004 — context

Дата: 2026-11-08 · slave-1, develop `b2c6375`, `@aura/contracts` v0.31.0 (в `node_modules` после `npm ci`).

## Источники

- `AURAI-0012` §1–§8, решения (3–7, 10 приняты; 1, 2, 8, 9 открыты), проверка стола 2026-11-07, заметки для задачи 5
  из ревью `AURAT-0197` (2026-11-08); `AURAI-0012-legal.md` — бегло (согласие v1 = галочка чата).
- `AURAT-0196-005` §8 (что оставлено конвейеру), `006`, `007`.
- `AURAT-0195-005` (контракт v0.31.0), `008`; исходник контракта — клон `aura-contracts` `main` `fa56e89`.
- `AURAT-0191-011` (модуль перевода после фиксов), `012`.
- Код BFF (ниже — что важно для спеки).

## Код — что есть

- **Модуль перевода** (`src/modules/translation`): `TranslationService.translate(profile, request, { timeoutMs })` —
  семафор → бюджет → предохранитель → адаптер → деньги; `review()` / `checkItem` (`tokens`, `empty`, `glossary`,
  `typography`). Профили — `TRANSLATION_PROFILES = ['campaign']`, env `TRANSLATION_CAMPAIGN_*`,
  `requireTranslationProfiles` в `env.schema.ts`. Порт уже умеет чат: `from: 'auto'`, `speaker`, `context`,
  `form: 'message'`; промпт Claude готов к цели `en` (`registerBlock` возвращает пусто для `en`).
- **Но перевод В `en` сейчас невозможен:** `supports()` обоих адаптеров и `enabled` в `onModuleInit` исключают
  `SOURCE_LANGUAGE`, `validateRequest` бросает `RangeError` на `to` вне `supported`. Нужна правка модуля.
- **`Semaphore.acquire()`** — без отмены: ожидание слота не ограничено. Для синхронной отправки нужен срок на ожидание.
- **Отправка** `ChatService.sendMessage`: `ensureConversation` → `recordSendLanguage` → проверка `idempotencyKey` →
  `postUserMessage` → upsert. `ChatwootClient.createIncomingMessage` шлёт JSON или multipart, `content_attributes` не
  передаёт.
- **Приём** `ingestResolved` (вебхук и сверка): `messages.create` с вложенными `attachments` / `spread` — одна
  транзакция; `inserted` — ворота fan-out. `DeliveryService.fanOut` — WS `message.new` + пинг FCM.
- **Удаление** `emptyLiveRow` — транзакция: чистит строку, вложения, расклад.
- **Сверка** `ReconciliationService.sweep` — раз в минуту, последовательно по разговорам.
- **Заглушки-подписи** — `SPREAD_FALLBACK_CONTENT` («Choose a card»), `SESSION_INVITE_FALLBACK_CONTENT`
  («Continue this reading privately») подставляются парсерами токенов, когда кроме токена текста нет. Флага
  `captionIsFallback` пока нет.
- **Язык и согласие** (`0196`): `translationActive(user)` в `profile/chat-settings.ts`, `User.chatLanguage`,
  `UsersRepository.findById / findByFirebaseUid`. `Advisor.gender` — в `AdvisorsRepository`.
- **Очереди** — `queues.ts` (`allQueueOptions`, хранение 24 ч / 7 дней), процессоры тонкие.
- **Контракт v0.31.0:** `Message.translation` (`pending | translated | failed`, `.catch(undefined)`),
  `HistoryQuery.translatedFrom` → `HistoryResponse.translations` (`.optional()`), WS `message.translated`. JSDoc
  `failed`: «сервер дозаполняет сам»; `translatedFrom` — «обычно самое старое `pending` или `failed`»; порядок
  `translations` не закреплён.

## Расхождения и что решаю в спеке

- `AURAI-0012` §1.2 предлагал писать `MessageTranslation(en, failed)` к строке человека. Задаче `desk-note` строка не
  нужна (данные — id сообщения, дедуп — `jobId`), а хранить лишнее — против минимизации (§6 п. 7). Предлагаю **не
  хранить** переводы сообщений человека в Postgres (спека §2.4).
- `AURAI-0012` §1.3 п. 6 (дозаполнение `failed` после восстановления предохранителя) конфликтует с замечанием ревью
  `0197` (вечный `failed` гоняет догонку). Варианты — решение 1 спеки.
- Превью списка разговоров у стола — оригинал (проверка стола). Поменять нельзя, не потеряв оригинал: пузырь берёт
  `translations[локаль]`, иначе первый ключ. Остаётся известным ограничением.
