# AURAT-0092-005 — spec (v2, после ответов владельца)

Тип: task. Продолжение `AURAT-0091`.

## Что делаем

Каждое событие платной сессии (booked / rescheduled / cancelled / started) уходит в
служебный чат Telegram отдельным сообщением — в дополнение к заметке в Chatwoot.
Пример:

```
📅 Booked · Mia · 20 min
Oct 18, 14:30 UTC
Open in desk → https://chat.aura-app.cc/app/accounts/2/conversations/123
```

(rescheduled: `Oct 19, 10:00 UTC (was Oct 18, 14:30 UTC)`; started: `until 14:50 UTC`.)
Только имя персоны, длительность, время и ссылка на диалог — **никаких** данных
клиента (правило 3: Telegram — внешний сервис).

## Архитектура

Сейчас сервис сессий сам знает и *что* произошло, и *как* это сказать в Chatwoot.
Разделяем это по принципам SRP / OCP / DIP:

```
sessions.service ──(событие)──▶ SessionNotifier ──▶ job 'session-notice' × N каналов
                                                       │
                                processor ─▶ SessionNotifier.deliver(channel, notice)
                                                       │
                     ┌─────────────────────────────────┴───────────────┐
              DeskNoteChannel (Chatwoot)                 TelegramChannel
              рендер + mentionAssignee                   рендер HTML + ссылка
                     │                                          │
           ChatwootMessagingPort                         TelegramBotPort
           (модуль chatwoot)                             (модуль telegram, новый)
```

1. **Доменное событие** `SessionNotice` (value object, модуль `sessions`): `kind`,
   `sessionId`, `startsAt`, `endsAt`, `previousStartsAt?`. Что произошло — без слов
   и без провайдера. Перекладывается в данные задачи (JSON, переживает Redis).
2. **Абстракция канала** (владеет ею `sessions` — DIP: высокий уровень задаёт
   интерфейс, адаптеры его реализуют):
   ```ts
   export abstract class SessionNoticeChannel {
     abstract readonly name: string;               // 'desk' | 'telegram' — ключ задачи
     abstract deliver(notice: SessionNotice, context: SessionWithContext): Promise<void>;
   }
   ```
   Каждый канал сам решает, как сказать (рендер — ответственность канала, не сервиса).
3. **Реализации** (`src/modules/sessions/notices/`):
   - `DeskNoteChannel` — нынешний `deskNote` + `postPrivateNote(…, mentionAssignee)`,
     переносится из сервиса без изменения поведения/текстов;
   - `TelegramNoticeChannel` — рендер HTML (экранирование), имя персоны из
     `AdvisorsRepository`, ссылка из нового `ChatwootMessagingPort.deskConversationUrl`,
     отправка через `TelegramBotPort`.
4. **Реестр каналов** — мульти-провайдер `SESSION_NOTICE_CHANNELS`
   (`useFactory`): desk всегда, telegram — только если задан конфиг (как
   `AppStoreApi | null` в `apple.module`). Новый канал = новый класс + строка в
   фабрике, сервис не трогается (OCP).
5. **`SessionNotifier`** (оркестратор, модуль `sessions`): `notify(session, kind,
   previousStartsAt?)` ставит **по задаче на канал** — `session-notice`
   `{ channel, notice }`, `jobId = notice-<channel>-<kind>-<id>-<startsAt>`.
   Отдельная задача на канал = независимые ретраи: упал Telegram — заметка в
   Chatwoot не дублируется. `deliver(data)` — находит канал по имени, грузит
   контекст сессии (нет сессии / канал выключен → no-op), вызывает `channel.deliver`.
   `SessionsService` вызывает `notifier.notify(...)` вместо `enqueueDeskNote`.
6. **Модуль `telegram`** (новый адаптер, как `chatwoot` — диалект Bot API не выходит
   наружу):
   - `TelegramBotPort` (`abstract class`): `sendMessage(chatId, html): Promise<void>`;
   - `TelegramBotClient`: `fetch` `POST /bot<token>/sendMessage`, `parse_mode: HTML`,
     `disable_web_page_preview`; 429 → ошибка с `retry_after` (BullMQ ретраит);
     токен **не** попадает в логи и тексты ошибок (URL с токеном не логируем).
7. **Конфиг** (`env.schema.ts`), всё-или-ничего через `superRefine`:
   `TELEGRAM_BOT_TOKEN`, `TELEGRAM_SESSION_CHAT_ID` (строка, `-100…` для групп).
   Не заданы → канал не зарегистрирован, Telegram молчит (локальный стек, тесты).
8. **Совместимость задач в полёте**: задачи `desk-note`, поставленные до деплоя,
   обрабатывает тот же `DeskNoteChannel` (одна ветка в процессоре; убрать в
   следующем релизе — отмечу в TECH-DEBT).
9. Ссылка на диалог: `ChatwootMessagingPort.deskConversationUrl(conversationId)` →
   `<AGENT_DESK_FRAME_ANCESTOR>/app/accounts/<id>/conversations/<displayId>` или
   `null` (нет origin) — тогда сообщение без ссылки. Сборка URL Chatwoot остаётся в
   модуле `chatwoot` (правило 1).

## Что не делаем
- Telegram-уведомления о чём-то кроме этих событий; приём сообщений из Telegram.
- Упоминание чаттеров в Telegram (их Telegram-аккаунтов мы не знаем).
- Отдельный чат/топик на адвайзора (если нужно — `message_thread_id` позже).

## Тесты (чистые)
- `SessionNotifier`: по задаче на каждый зарегистрированный канал, jobId; `deliver`
  — маршрут по имени, no-op без сессии и для неизвестного/выключенного канала.
- `DeskNoteChannel`: тексты и `mentionAssignee` (перенос тестов из `AURAT-0091`).
- `TelegramNoticeChannel`: четыре рендера, HTML-экранирование имени, без ссылки при `null`.
- `TelegramBotClient` (fetch замокан): тело запроса, 429/ошибка → бросает, токен
  не в сообщении ошибки.
- `env.schema`: половина Telegram-конфига → отказ загрузки.
- `sessions.service.spec`: вызовы `notifier.notify` во всех четырёх местах.
Живая проверка — в маноре (бот, добавленный в группу, переменные в env).

## За владельцем (до проверки в маноре)
- Создать бота у @BotFather, добавить в группу, узнать `chat_id`; положить
  `TELEGRAM_BOT_TOKEN` / `TELEGRAM_SESSION_CHAT_ID` в env dev (и prod при выкатке).

## Решения владельца (006)
1. Напоминание «за 5 минут» (`AURAT-0084`) — тоже в Telegram. Становится пятым видом
   события `starting-soon`: задача `remind` остаётся триггером со своими проверками
   (SCHEDULED, тот же `startsAt`, ещё не началась) и бэкстопом в `sweepDue`, но вместо
   прямого `postPrivateNote` зовёт `notifier.notify(…, 'starting-soon')` — дальше общий
   путь по каналам. Текст в Chatwoot не меняется.
2. Ссылка «Open in desk» — нужна.
