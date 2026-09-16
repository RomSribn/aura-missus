# AURAT-0074-013 — Проверка на `development`

Дата: 2026-09-16
Владелец на вопрос проверки: «проверь сам».
Как: только чтение на сервере (`docker ps`, `docker logs`, `redis-cli` на чтение;
секреты не выводились) + три неавторизованных пробных запроса к `bff-dev` с
вымышленным токеном `AURAT0074probeTokenNotReal…`. Устройство из dev-сборки и
настоящее вложение не проверялись — нет телефона и Firebase-токена.

## Деплой

Контейнер `aura-bff` (development) на образе `abe2039`, поднят 18:08 UTC. Лог
старта — 99 строк, ни одной `warn`/`error`/`fatal`.

## Лог запросов

| Запрос | Ответ | В логе |
|---|---|---|
| `PUT /v1/devices/<probe>-lower` | 401 | `"url":"/v1/devices/[redacted]"`, `"res":{"statusCode":401}` |
| `DELETE /v1/DEVICES/<probe>-upper?source=probe` | 404 | `"url":"/v1/DEVICES/[redacted]?source=probe"`, `"query":{"source":"probe"}`, `"res":{"statusCode":404}` |
| `GET /v1/attachments/aurat0074-probe` | 401 | `"url":"/v1/attachments/aurat0074-probe"`, `"res":{"statusCode":401}` |

По всему логу с момента деплоя: строк `request completed` — 4, у всех `res`
только `statusCode`, `res.headers` — 0, `content-disposition` — 0, вхождений
пробного токена — 0, путей `/devices/…` без `[redacted]` — 0. Лог 401/404 и
guard идут после pino-http, так что строка у авторизованного запроса та же.
Имя файла вживую не проверено (у 401 нет `Content-Disposition`); закрыто тем, что
`res.headers` не пишется вовсе, и тестом `http-logger.options.spec.ts`.

## Очереди (Redis `development`, db 1)

- Планировщик `queue-retention-sweep` зарегистрирован, следующий запуск через
  час.
- Первая чистка выполнилась сразу при старте: `queue-retention` completed = 1,
  failed = 0, ошибок в логе нет.
- **Записей старше срока нет ни в одной очереди** — самые старые ~2,8 ч
  (`sessions` 10 050 с): Redis `development` восстанавливался сегодня. Поэтому
  само удаление вживую не наблюдалось — нечего было удалять. Семантика `clean`
  проверена по исходникам BullMQ 5.80.1 и юнит-тестом на подделках.

| Очередь | completed | старейшая, с | за сроком |
|---|---|---|---|
| chatwoot-webhook | 2 | 9 195 | 0 |
| reconciliation | 10 | 570 | 0 |
| fcm-fanout | 2 | 9 195 | 0 |
| sessions | 153 | 10 050 | 0 |
| presence | 100 | 3 900 | 0 |
| tarot | 1 | 8 288 | 0 |
| avatar | 1 | 8 199 | 0 |
| account-erasure | 28 | 9 554 | 0 |
| contact-name | 3 | 5 522 | 0 |
| queue-retention | 1 | 177 | 0 |

Упавших записей нет ни в одной очереди.

## Не проверялось здесь

- `LOG_LEVEL` Chatwoot — после релиза `main` (`AURAS-0004` → *Not yet proven*).
- Scheduled Task dead set — не создана, панель Coolify.
- Фактическое удаление старых записей — станет видно, когда записям в
  `development` исполнятся сутки: `ZCOUNT bull:<q>:completed -inf <now−86400000>`
  должен оставаться 0.

Дальше: приёмка владельцем.
