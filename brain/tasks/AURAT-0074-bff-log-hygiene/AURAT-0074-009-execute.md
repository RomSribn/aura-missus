# AURAT-0074-009 — Исполнение `005` + `007`

Дата: 2026-09-16
Где: `slave-3`, ветка `feature/AURAT-0074-bff-log-hygiene`. Не закоммичено, всё
застейджено для ревью.

## `aura-bff`

### Лог запросов (`005` §1)

| Файл | Что |
|---|---|
| `src/common/logging/http-logger.options.ts` (новый) | `httpLoggerOptions(env)`: уровень, `redact` двух заголовков, `pino-pretty` для development — перенесены из `app.module.ts`. Новое: сериализатор `req` меняет `/devices/<сегмент>` в `url` на `/devices/[redacted]` (в любом месте пути, query-строка остаётся); сериализатор `res` оставляет только `statusCode` |
| `src/common/logging/http-logger.options.spec.ts` (новый) | Настоящие `DevicesController` и `AttachmentsController`, Fastify с `fastifyServerOptions`, `nestjs-pino` пишет в память. `PUT`/`DELETE /v1/devices/:token` — токена нет нигде в строке, `url` = `/v1/devices/[redacted]`, `authorization` нет; 404 на `/v2/devices/<token>?source=app` — токена нет, query на месте; скачивание вложения — имени файла нет в строке, `res` = `{ statusCode: 200 }`, пользователь файл с именем получает |
| `src/app.module.ts` | `pinoHttp: httpLoggerOptions(NODE_ENV)` |

**Контрольный прогон:** без сериализаторов все 4 теста падают — тест ловит
именно утечку.

### Сроки в очередях (`007`)

| Файл | Что |
|---|---|
| `src/jobs/queues.ts` | `KEEP_COMPLETED_SECONDS` (сутки), `KEEP_FAILED_SECONDS` (7 дней) с объяснением ленивости `age`; `age` рядом с `count` у всех 9 очередей; очередь `queue-retention` (attempts 1, свои `age`); `QUEUE_RETENTION_SWEEP_JOB`, `QUEUE_RETENTION_SCHEDULER`; `allQueueOptions` — единый список очередей. В комментарии: `jobId` схлопывает дубли, пока запись хранится, — так было и со `count`, производители защищены базой |
| `src/jobs/queue-retention.service.ts` (новый) | `sweep()`: для каждой очереди `clean(сутки, ∞, 'completed')` и `clean(7 дней, ∞, 'failed')`; строка в лог — только счётчики и имя очереди, только если что-то удалено; ошибка Redis валит джобу |
| `src/jobs/queue-retention.processor.ts` (новый) | Тонкий: `sweep` → сервис, иное имя → warn |
| `src/jobs/queue-retention.scheduler.ts` (новый) | `upsertJobScheduler` раз в час; не при `NODE_ENV=test`. Шаблон наследует `defaultJobOptions` очереди — проверено в `bullmq` 5.80.1 (`Object.assign({}, this.jobsOpts, …)`) |
| `src/jobs/jobs.module.ts` | `BullModule.registerQueue(...allQueueOptions)`; провайдер `RETAINED_QUEUES` собирает все очереди по `getQueueToken`; сервис, процессор, планировщик |
| `src/jobs/queues.spec.ts` (новый) | `allQueueOptions` совпадает со всеми `*QueueOptions` из `queues.ts`; у каждой очереди `age` = общие сроки |
| `src/jobs/queue-retention.service.spec.ts`, `queue-retention.scheduler.spec.ts` (новые) | Сроки и «без лимита» на каждой очереди; ошибка пробрасывается; раз в час; ничего под `test` |

### Chatwoot и документация

| Файл | Что |
|---|---|
| `deploy/coolify/chatwoot.compose.yml` | `LOG_LEVEL: warn` в `x-chatwoot` → `environment` с комментарием: что пишется на info, читают rails и sidekiq, не ручка панели, `NameError` на неверном значении, остаток — упавшие задачи. Разбор YAML (Ruby, со слиянием якоря): `LOG_LEVEL=warn` у `rails` и `sidekiq`, `Logger::WARN` = 2 |
| `README.md` | `common/` — опции лога; `jobs/` — планировщики; абзац «What stays behind»: сроки очередей и граница «+ час», что пишет лог запросов |

## `aura-missus`

`brain/solutions/AURAS-0004-hetzner-coolify-production.md`:

- *Redis* — абзац о сроках очередей BFF и dead set Chatwoot;
- *Chatwoot specifics* — пункт «Logs at `warn`»: что пропало; `NameError`;
  остаток (упавшие задачи на WARN, SMTP, 500 без параметров, Agent Bot);
  диагностика без лога запросов;
- там же — dead set 7 дней: приложение `aura-chatwoot`, контейнер `sidekiq`,
  `30 3 * * *`, команда `Sidekiq::DeadSet … job.delete if job.at < 7.days.ago`
  (удаление во время `each` Sidekiq 7.3.1 поддерживает — `JobSet#each` сдвигает
  offset), проверка перед сохранением;
- ловушка с загрузкой вложений: «request log settles it» и «Uploaded file to key»
  переписаны под `warn`;
- *When it breaks* — две строки: `NameError` у обоих контейнеров; «нужно
  увидеть запрос» → воспроизвести, не поднимать уровень;
- *Not yet proven* — `LOG_LEVEL` ждёт релиза `main`, задача Coolify не создана,
  поле контейнера проверить в панели.

## Проверки в слоте

- `npm run lint` — чисто;
- `tsc --noEmit` — чисто;
- `jest` — **82 набора, 1 023 теста, все зелёные** (было 1 015; `app.module.spec`
  поднимает граф с новыми провайдерами);
- `npm run build` — ок;
- prettier на изменённых файлах — чисто (45 старых файлов репо prettier не
  проходят и не трогались).

## Отклонения от спеки

- `005` §1.4: тест «путь без секрета остаётся» — это `/v1/attachments/att-42` в
  тесте скачивания и query-строка в тесте 404; отдельного теста нет.
- `007` §3: тест планировщика — на прямом вызове `onApplicationBootstrap`
  с подделками (так же проверяются процессоры), а не через граф.
- Логирование сервиса чистки: только имя очереди и счётчики — в спеке не
  оговаривалось, нужно для проверки в маноре.

## Передано

`aura-app-manor` (сессия `manor-b8`) получил сроки и остаток по логам Chatwoot
для брифа `AURAT-0042` §07, с оговоркой «действуют после релиза».

## Открыто

- Scheduled Task в Coolify создаётся руками в панели (манор/владелец) — от
  релиза не зависит.
- Бриф политики `AURAT-0042` правит `aura-app-manor`.

Дальше: ревью владельца в IDE → коммит в ветку → мёрж в `develop` (одобрение).
