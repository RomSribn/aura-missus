# AURAT-0074-015 — Scheduled Task для dead set Chatwoot создана

Дата: 2026-09-16
Владелец: «создай Scheduled Task в Coolify сам» (после `014`, пункт 2 «не
закрыто»).
Ветка закрытия: `feature/AURAT-0074-bff-log-hygiene-close` (только brain).

## Что сделано на сервере

1. **Чтение.** В Coolify это приложение `aura-chatwoot`: id 4, uuid
   `forqvdvibl9wjec2yk0mqkeo`, `dockercompose`, ветка `main`, окружение
   `production`, team 0. Scheduled Tasks у него не было ни одной, часовой пояс
   инстанса — UTC. В Redis Chatwoot (`xqmefuyfc5ydzfdpuldbfi27`, db 0) `dead` = 0,
   `retry` = 0. Свободной памяти на хосте ~5 ГБ.
2. **Как Coolify выполняет задачу** (исходники `coolify` 4.3.19, внутри
   контейнера):
   - `ScheduledTaskJob` берёт контейнеры приложения и выбирает тот, чьё имя
     начинается с `<container>-<uuid приложения>`;
   - команду оборачивает в `sh -c '…'`, одинарные кавычки экранирует.

   Значит, в поле контейнера — имя сервиса compose `sidekiq`. Эндпоинт API
   `create` пишет поля `name`, `command`, `frequency`, `container`, `timeout`
   (по умолчанию 300), `enabled`, `team_id`, `application_id`.
3. **Ручной прогон** той же команды в `sidekiq-forqvdvibl9wjec2yk0mqkeo-…` в той
   же обёртке `sh -c`: exit 0, 6 с. Dead set = 0, записей старше 7 дней = 0 —
   удалять было нечего.
4. **Создание** через `php artisan tinker` в контейнере `coolify`: API-токена у
   инстанса нет. Выставлены ровно те поля, что пишет эндпоинт API. Перед записью
   проверено, что это `aura-chatwoot` на `dockercompose`, что задачи с таким
   именем нет и что cron валиден (`validate_cron_expression`).
   - uuid `1dr8c4gpajt6v9bbruriw3pk`, имя `sidekiq-dead-set-7-days`;
   - контейнер `sidekiq`, `30 3 * * *`, timeout 300, enabled;
   - команда
     `bundle exec rails runner 'Sidekiq::DeadSet.new.each { |job| job.delete if job.at < 7.days.ago }'`.

   Временные php-файлы удалены из контейнера.
5. **Прогон через механизм Coolify**: `ScheduledTaskJob::dispatch($task)` — то же,
   что делает эндпоинт `execute`. Выполнение `success`, 18:16:35 → 18:16:42 UTC.
   Контейнер найден по имени сервиса — открытый вопрос из `AURAS-0004` закрыт.

## Brain

`AURAS-0004`:
- в *Chatwoot specifics* — имя и uuid задачи, UTC, timeout;
- как Coolify находит контейнер и оборачивает команду;
- что задача создана через tinker и почему;
- где смотреть выполнения.

В *Not yet proven* про задачу осталось только: первый **плановый** запуск —
2026-09-17 03:30 UTC.

## Остаётся

- Релиз `develop` → `main` — чтобы `LOG_LEVEL` дошёл до Chatwoot.
- Удаление старых записей очередей BFF вживую — через сутки на `development`.
- Первый плановый запуск задачи — 2026-09-17 03:30 UTC (выполнения на её
  странице в Coolify).
