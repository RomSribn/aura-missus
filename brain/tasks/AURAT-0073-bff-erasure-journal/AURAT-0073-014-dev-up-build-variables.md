# AURAT-0073-014 — Dev поднялся; переменные ушли в сборку образа

Дата: 2026-09-16

## Деплой development

- `RomSribn/aura-bff:develop`, `COOLIFY_FQDN='bff-dev.aura-app.cc'`, коммит
  `d54b07d`, образ пересобран.
- 17:57Z: `bff-dev /health` → 200 `{"status":"ok"}`, `GET /v1/me` без токена →
  401. Проверка окружения при старте прошла, значит все четыре
  `ERASURE_JOURNAL_*` дошли до контейнера.
- Rolling update снова снял старый контейнер меньше чем через секунду после
  старта нового (подтверждает находку `013`).

## Проблема: переменные отмечены как Build Variable

В логе деплоя Coolify дописал в Dockerfile `ARG ERASURE_JOURNAL_*=<значение>`
во все стадии и передал их как `--build-arg`. Docker предупредил
`SecretsUsedInArgOrEnv`. Это ловушка 2 из `AURAS-0004`:
- секрет вписан в метаданные образа
  `mtnsnawmogikfwm0uvl1g1yc:d54b07d…` (`docker history`);
- секрет открытым текстом лежит в логе деплоя в панели Coolify.

Сборке эти переменные не нужны. Ключ ещё и был в чате сессии, так что правильно
перевыпустить секрет, а не просто снять галочки.

## Что делает владелец

1. Coolify `development` → `aura-bff`: снять Build Variable у всех четырёх
   `ERASURE_JOURNAL_*`.
2. Cloudflare → R2 → токен `aura-erasure-journal-storage` → перевыпустить
   секрет (Roll). Новое значение в `ERASURE_JOURNAL_SECRET_ACCESS_KEY`; в чат не
   присылать.
3. Redeploy development. В логе не должно быть `ARG ERASURE_JOURNAL_` и
   `SecretsUsedInArgOrEnv`.
4. Проверить production `aura-bff`: если там есть `ERASURE_JOURNAL_*`, удалить
   (`013`).
5. По желанию: `docker image prune` на сервере, чтобы убрать старый образ.
   После перевыпуска секрет в нём уже ничего не открывает.

Затем проверка в маноре по `005`.
