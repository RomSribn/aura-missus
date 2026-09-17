# AURAT-0074-015 — Релиз в production и Scheduled Task

Дата: 2026-09-17
Где: манор `aura-app-manor`, сервер `37.27.199.90`.

## Релиз

С одобрения владельца `main` переведён `781957a` → `abe2039` (вместе с
`AURAT-0073`, см. её `018`). Оба деплоя — `finished`.

| Проверка | Итог |
|---|---|
| rails и sidekiq поднялись | `restarts=0`, `LOG_LEVEL=warn` у обоих |
| `Rails.logger.warn/info` | печатается только `probe-warn` |
| Логи rails и sidekiq после старта | `Started` 0, `Parameters:` 0, `with arguments` 0, `INFO` 0, похожих на телефон 0 |
| Chatwoot | `/` 200, `/api` — `queue_services ok`, `data_services ok`; alias `chatwoot-rails` у одного контейнера |
| Очереди прод-BFF | `bull:queue-retention` с планировщиком `queue-retention-sweep`, первая чистка выполнена |
| Dev не задет | `bff-dev` 200, контейнер со вчера |

Не проверено: лог после настоящего сообщения из приложения. Это пункт
*Not yet proven* в `AURAS-0004`.

## Scheduled Task dead set

Задачу `sidekiq-dead-set-7-days` (`1dr8c4gpajt6v9bbruriw3pk`) создал слот
16.09. Плановый запуск 17.09 в 03:30 UTC — `success`.

17.09 манор проверил удаление по-настоящему. В dead set положены две пробные
записи: одна возрастом 8 дней, одна свежая. Затем задача прошла через
`ScheduledTaskJob`: старая запись удалена, свежая осталась, обе пробы убраны.

**Ошибка манора:** перед этим он создал вторую такую же задачу, потому что
искал существующую только по своему имени. Дубль удалён вместе с его запуском.
Урок записан в `AURAS-0004`: перед добавлением смотреть *Scheduled Tasks*.
