# AURAT-0070-008 — мёрж в `develop`

Дата: 2026-09-15 · slave-2 · `feature/AURAT-0070-bff-fcm-error-classification`

- Владелец одобрил код после просмотра в IDE и отдельно — мёрж (вопрос
  «Merge» → «Да, мёрж»).
- Коммит в ветке: `de47855` `fix(delivery): AURAT-0070 — ошибки FCM в три
  класса, повтор только по упавшим токенам` (9 файлов, +396 / −68).
- `wts-finish slave-2`: `aura-bff` `develop` `1fa9fbe..1a1003c`, пуш в origin
  прошёл. Мёрж в `develop` = деплой в окружение `development`
  (`bff-dev.aura-app.cc`). `main` не тронут (`1fa9fbe`).
- `aura-missus`: коммитов нет, как и положено на этом шаге; шаги `002`–`008`
  не закоммичены, уйдут одним коммитом при закрытии.
- Свободные слоты 3–5 обновлены на новый `develop`.

## Проверка (владелец, в `development`)

Пока ключа APNs нет — сообщение от агента пользователю, у которого есть
iOS-токен:

1. в логе BFF одна запись `error` `FCM rejected delivery: configuration or
   credentials` с `messaging/third-party-auth-error` / `ios`, без `warn`
   о временных сбоях;
2. в `bull:fcm-fanout` не прибавилось failed;
3. Android того же пользователя получает пинг один раз.

Условие: dev BFF подключён к аккаунту «Aura Dev» в production-Chatwoot
(`AURAT-0071-008`), иначе ответ агента до BFF не дойдёт.

## Дальше

Результат проверки → `009-approved` или `009-fix-*`.
