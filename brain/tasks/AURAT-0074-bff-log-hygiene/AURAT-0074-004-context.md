# AURAT-0074-004 — Контекст: `aura-bff` `develop` @ `781957a` и Chatwoot v4.15.1

Дата: 2026-09-16
BFF проверен по коду и опытом в черновике: минимальное Nest-приложение на тех
же `nestjs-pino` 4.6.1 / `pino-http` 10.5.0 / Fastify 5.10, настоящий HTTP и WS,
лог в память. Chatwoot сверен по исходникам коммита `5ce6e00` («Bump version to
4.15.1», `config/app.yml` → `4.15.1`) в `chatwoot-manor`; версии гемов —
rails 7.1.5.2, sidekiq 7.3.1.

## BFF: что на самом деле пишет лог запросов

Одна строка `request completed` на запрос, уровень `info`:

| Поле | Что внутри | Личное или секрет? |
|---|---|---|
| `req.url` | путь **с query-строкой** (`originalUrl`) | **Да:** `/v1/devices/<FCM-токен>` на `PUT` и `DELETE` |
| `req.query` | разобранная query | Нет: `days`, `tz`, `duration`, `after`/`before`, `limit` |
| `req.params` | не пишется: у raw-запроса их нет | — |
| `req.headers` | все, кроме `authorization`, `x-chatwoot-signature` | IP (`x-forwarded-for`) и User-Agent; политика их уже называет (бриф `AURAT-0042`, «record them in server logs») |
| `res.headers` | **все заголовки ответа** | **Да:** `content-disposition` у `GET /v1/attachments/:id` несёт **имя файла пользователя**. Проверено опытом: `filename="passport_ivan.pdf"` лёг в лог |

- **Находка сверх заглушки:** имя файла в `res.headers`. Имя даёт человек
  (`attachment-intake.ts`, `AURAT-0032`) или оператор — это содержимое переписки.
- 404 на несуществующий путь пишется так же, с полным `url`.
- **WS не пишется:** апгрейд `/ws?token=<Firebase ID token>` идёт мимо Fastify и
  middie — опыт подтвердил, токена в логе нет. Access log Traefik выключен
  (`AURAT-0042-115`, п. 2).
- Остальные параметры пути — `advisorId`, `sessionId`, `attachmentId`,
  `avatarId`, `messageId`: id с проверкой владельца, не секреты.
- Точечные `logger.*` (34 места): телефонов, имён, текстов, FCM- и ID-токенов нет.
  `token` в `chat.service`/`reconciliation` — служебная метка оператора
  (`chatter-token.ts`), не секрет. `userId` — наш UUID, не Firebase UID.
- Конфиг логгера живёт прямо в `app.module.ts:29-45`. Отдельного теста на
  содержимое лога нет; образец теста «через настоящую обработку запроса» —
  `fastify.options.spec.ts`.

## Chatwoot: `LOG_LEVEL`

| Что | Где (`5ce6e00`) |
|---|---|
| Rails: `config.log_level = ENV.fetch('LOG_LEVEL', 'info').to_sym` | `config/environments/production.rb:50` |
| **Sidekiq читает ту же переменную** своим логгером | `config/initializers/sidekiq.rb:31` |
| `Parameters:` — info | actionpack `log_subscriber.rb:20-22` |
| «Performing/Enqueued … with arguments» — info | activejob `log_subscriber.rb:23,81` |
| Регистр не важен (`upcase`); **любое неверное значение (`warning`, пусто) — `NameError`, не поднимаются ни rails, ни sidekiq** | railties `bootstrap.rb:63`, `sidekiq.rb:31` |
| Переменная больше нигде не читается; фильтр параметров переменной не управляется (только пароли/токены/ключи) | `filter_parameter_logging.rb:4-13` |

Compose: `LOG_LEVEL` сейчас не задан. `environment` якоря `x-chatwoot` общий у
`rails` и `sidekiq` (оба `<<: *chatwoot`, `environment` не переопределяют) —
одна строка покрывает оба контейнера.

### Что на `warn` остаётся (остаток)

- **Упавшая фоновая задача.** Обработчик ошибок Sidekiq по умолчанию
  (sidekiq `config.rb:43-50`) пишет на **WARN** весь job JSON, **включая `args`**
  — там могут быть телефон контакта и данные сообщения
  (`ActionCableBroadcastJob`, `EventDispatcherJob`). Пример, как задача падает:
  `ActionCableBroadcastJob` → `find_by!` по диалогу, которого уже нет
  (`action_cable_broadcast_job.rb:29`) — ровно то, что делает удаление аккаунта.
  Штатный поток на `warn` молчит, сбойный — нет.
- `AgentBots::WebhookJob` на 429/5xx пишет payload на WARN
  (`webhook_job.rb:13`). **У нас не срабатывает:** связь Agent Bot с inbox
  `inactive` намеренно (`AURAS-0004`, `provision-prod.rb:103-104`).
- Ошибки SMTP на ERROR (`application_mailer.rb:29`) — адреса **операторов**, не
  пользователей.
- 500 в запросе — FATAL: класс, сообщение, backtrace, **без параметров**.

### Что на `warn` теряется

- Строки «Started/Completed» вокруг 500 и строка ActiveJob «Error performing»
  (сама ошибка Sidekiq остаётся — см. остаток).
- **Диагностика по логу запросов в `AURAS-0004`:** раздел «Chatwoot specifics»
  («One look at the request log settles it») и строка таблицы «When it breaks»
  про «Uploaded file to key» опираются на info-строки, которых не будет.
- Загрузка контейнеров (`=> Booting`, `Listening on`, миграции) пишется в stdout
  напрямую и не теряется.

## Прочее

- `deploy/docker-compose.prod.yml` и `deploy/env/chatwoot.env.example` — AWS-дизайн
  на паузе (`deploy/README.md`, `AURAS-0003`); прод читает только
  `deploy/coolify/chatwoot.compose.yml`.
- Бриф политики (`AURAT-0042-claude-design-brief.md:507`) планировал фразу «логи
  стойки содержат тексты и телефоны». После релиза этой задачи её нужно
  пересмотреть — это бриф `aura-app-manor`, здесь не правится.

## Противоречия

`001` и `115` говорят «всё это на info». Верно для штатного потока, но не для
сбоев: у Sidekiq аргументы упавшей задачи идут на WARN. Решение владельца
принималось без этого факта — выносится в спеку.

Дальше: `005-spec`.
