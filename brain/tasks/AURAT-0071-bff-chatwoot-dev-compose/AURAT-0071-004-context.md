# AURAT-0071-004 — Контекст

Дата: 2026-09-14

## Источники

- `deploy/coolify/chatwoot.compose.yml` (develop `1fa9fbe`): alias
  `chatwoot-rails` и `FRONTEND_URL: https://chat.aura-app.cc` зашиты. Остальное
  приходит через `CW_*`.
- `deploy/chatwoot/provision-prod.rb`: ищет inbox по имени, по умолчанию
  `Aura (prod)`, и отказывает только при `AURA_INBOX_NAME == 'Aura (dev)'`. Бот
  называется всегда `Aura BFF Bot`, service User по умолчанию
  `bff@aura.internal`. Webhook по умолчанию `http://bff:3000/…` — адрес, который
  никогда не работал. Пункт 2 шапки (внутренний webhook,
  `SAFE_FETCH_ALLOW_PRIVATE_NETWORK`) устарел.
- `AURAS-0004`: *Deploys*, *Environments*, *Chatwoot specifics*, *When it
  breaks*. `AURAD-0015`.
- Исходники Coolify **v4.3.19** (`33f4539`), прочитаны в scratchpad.

## Как Coolify 4.3.19 разворачивает compose — по коду

1. **`networks` сервиса переносится как есть.** В `applicationParser`
   (`bootstrap/helpers/parsers.php`, ~стр. 970–980) для формы-словаря
   `networks: { coolify: { aliases: [...] } }` выполняется
   `$networks_temp->put($key, $network)`: значение копируется целиком, со
   строками `${…}` Coolify ничего не делает. Затем `Yaml::dump` пишет файл.
   Экранирование `$` (`escapeDollarSign`) касается только labels.
2. **Подстановку делает Docker Compose.** `deploy_docker_compose_buildpack`
   (`app/Jobs/ApplicationDeploymentJob.php`, ~стр. 783–905) вызывает
   `docker compose --env-file <workdir>/.env … -f <compose> pull` и `… up -d`.
   Раскрытие `${VAR:-default}` по всему файлу, включая aliases, делает сам
   Compose.
3. **В `.env` попадают все runtime-переменные приложения из панели**
   (`generate_runtime_environment_variables`, фильтр `is_runtime`), в том числе
   заведённые вручную. Шаг `build` читает build-time `.env`. При `:-default`
   отсутствие переменной там безвредно. `:?` там опасен: сборка может упасть,
   даже если runtime-значение задано.
4. **Переменные в `environment:` Coolify заводит сам.** Для
   `KEY: ${VAR:-default}` делается `firstOrCreate(VAR, default)`
   (`parsers.php` ~1044–1063): переменная появляется в панели со значением по
   умолчанию и не перезаписывается, если уже есть. Переменные, упомянутые
   **только** в `aliases`, Coolify не заводит: их добавляют руками.
5. **Один `${…}` на строку**, как уже записано в compose, выполняется.

## Проба без запуска

Копия compose с `aliases: ["${CW_RAILS_ALIAS:-chatwoot-rails}"]` и
`FRONTEND_URL: ${CW_FRONTEND_URL:-https://chat.aura-app.cc}`,
`docker compose config` (Compose v5.1.4):

| `.env` | alias | `FRONTEND_URL` |
|---|---|---|
| пустой | `chatwoot-rails` | `https://chat.aura-app.cc` |
| `CW_RAILS_ALIAS=chatwoot-dev-rails`, `CW_FRONTEND_URL=https://chat-dev.aura-app.cc` | `chatwoot-dev-rails` | `https://chat-dev.aura-app.cc` |

## Что следует

- Параметризация одного файла проверяется чтением кода и `docker compose config`
  без живого Coolify. Условие заглушки выполнено.
- Коллизия alias не приводит к тихой утечке данных. Экземпляры — разные
  установки с разными базами и токенами, поэтому запрос не в тот экземпляр
  получает 401. Прод при этом всё равно частично ломается.
- `provision-prod.rb` подходит для dev-экземпляра без правки кода, если задать
  `AURA_INBOX_NAME` (не `Aura (dev)`) и `AURA_WEBHOOK_URL`.
- Риск конфликта в `missus`: `aura-app-manor` параллельно ведёт этап 1 и
  `AURAD-0016` и, скорее всего, правит `AURAS-0004` → *Environments*.
