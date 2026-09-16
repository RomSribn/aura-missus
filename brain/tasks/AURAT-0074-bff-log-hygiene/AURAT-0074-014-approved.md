# AURAT-0074-014 — Принято

Дата: 2026-09-16
Статус: **done** (серверная часть в `develop`; продакшен — с релизом)
Владелец: «Принято» — по итогам проверки на `development` (`013`).

## Что сделано

- **Лог запросов BFF.** FCM-токен в `/devices/<token>` пишется как
  `[redacted]` — в любом месте пути и без учёта регистра. От ответа в логе
  остаётся только `statusCode`: имя файла вложения из `Content-Disposition`
  туда больше не попадает. Проверено тестом и на `bff-dev`.
- **Очереди BFF.** `age` у всех очередей: выполненные хранятся сутки, упавшие —
  7 дней. Ежечасная `queue-retention` чистит все очереди из `allQueueOptions`:
  граница — срок плюс час. Планировщик и первая чистка на `development`
  отработали.
- **Chatwoot.** `LOG_LEVEL: warn` в compose (rails + sidekiq). Runbook
  `AURAS-0004`: логи на `warn`, остаток, диагностика, dead set 7 дней через
  Scheduled Task, строки в *When it breaks* и *Not yet proven*.
- `aura-bff` `develop` @ `abe2039` (коммит `fa84be7`).

## Решения по ходу

`006`: Q1 — остаток логов Chatwoot принять и описать; Q2 — `warn` жёстко.
`008`: Q3 — сутки / 7 дней везде; Q4 — `age` + ежечасная `clean()`; Q5 — Scheduled
Task для dead set. `010`: флаг `i`, `devices%2F…` не трогать.

## Не закрыто этой задачей (отдельные шаги)

1. **Релиз `develop` → `main`** (одобрение владельца). Повезёт `AURAT-0042`,
   `AURAT-0072`, `AURAT-0073` и эту. Только тогда `LOG_LEVEL` дойдёт до Chatwoot,
   и Chatwoot перезапустится (~минута простоя чата). Проверка после релиза — в
   `AURAS-0004` → *Not yet proven*.
2. **Scheduled Task** на `aura-chatwoot` / `sidekiq` в панели Coolify — от релиза
   не зависит; команда и проверка — в `AURAS-0004` → *Chatwoot specifics*.
3. **Удаление старых записей вживую** — когда записям в Redis `development`
   исполнятся сутки: `ZCOUNT bull:<q>:completed -inf <now−86400000>` = 0.
4. **Бриф политики `AURAT-0042` §07** — `aura-app-manor` уже внёс сроки
   (`b95994a`).
