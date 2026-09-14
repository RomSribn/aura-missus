# AURAT-0071-007 — Исполнение

Дата: 2026-09-14
Слот: `slave-3`, ветка `feature/AURAT-0071-bff-chatwoot-dev-compose`.
Изменения проиндексированы, **не закоммичены** — ждут просмотра владельцем.

## Файлы (`aura-bff`)

### `deploy/coolify/chatwoot.compose.yml`

- `FRONTEND_URL: ${CW_FRONTEND_URL:-https://chat.aura-app.cc}`
- `aliases: ['${CW_RAILS_ALIAS:-chatwoot-rails}']`
- Комментарии:
  - шапка: два приложения Coolify из одного файла (prod ← `main`,
    dev ← `develop`), таблица двух переменных и их умолчаний, что обязан задать
    dev и что случится, если забыть alias; почему один файл, а не копия;
    Postgres/Redis — «того же окружения», вместо `aura_bff` — «the BFF's
    database»;
  - Redis: «db 1 for that environment's BFF»;
  - `FRONTEND_URL`: зачем он у каждого экземпляра свой;
  - webhook: публичный хост BFF своего окружения (`bff.` / `bff-dev.`);
  - R2: у каждого экземпляра свой бакет;
  - alias: свой у каждого экземпляра, `CHATWOOT_BASE_URL` BFF того же окружения
    называет его; почему `${…}` в alias безопасен (по коду Coolify 4.3.19) и
    почему `:-`, а не `:?`.

### `deploy/chatwoot/provision-prod.rb`

- `AURA_WEBHOOK_URL` обязателен: без него или с пустым значением —
  `abort` до обращения к базе. Умолчание `http://bff:3000/…` убрано.
- Шапка: скрипт провижинит **одну установку**; команда для dev-экземпляра через
  `docker exec -i -e AURA_WEBHOOK_URL=https://bff-dev.aura-app.cc/webhooks/chatwoot
  -e AURA_INBOX_NAME=Aura …`; для прода — другой webhook и отсылка к
  `AURAS-0004`; аккаунт создаётся в UI заранее. Пункт 2 переписан: webhook
  публичный и обязательный.
- Guard против `Aura (dev)` сохранён, сообщение и комментарий объясняют: это
  тестовый inbox в прод-установке, на dev нужно другое имя.

`src/` не менялся.

## Проверка в слоте

| Проверка | Результат |
|---|---|
| `docker compose config`, пустой `.env`: до правки vs после | **побайтно совпадает** — прод не изменился |
| то же с `CW_RAILS_ALIAS=chatwoot-dev-rails`, `CW_FRONTEND_URL=https://chat-dev.aura-app.cc` | отличаются ровно alias → `chatwoot-dev-rails` и 3× `FRONTEND_URL` → `https://chat-dev.aura-app.cc` |
| `ruby -c provision-prod.rb` | `Syntax OK` |
| скрипт без Rails: `AURA_WEBHOOK_URL` не задан / пустой | `refusing: AURA_WEBHOOK_URL is required …` |
| `AURA_INBOX_NAME='Aura (dev)'` | `refusing: … that is the test inbox` |
| корректные env | guard'ы пройдены, дальше `uninitialized constant Account` (Rails нет — ожидаемо) |

`lint`/`build` BFF не запускались: TypeScript не затронут.

## Для манора (после мёржа в `develop`)

1. Создать dev-приложение Chatwoot (Docker Compose, ветка `develop`,
   `/deploy/coolify/chatwoot.compose.yml`, домен rails →
   `https://chat-dev.aura-app.cc`), свои `CW_*`: dev-Postgres/Redis, **свой
   `SECRET_KEY_BASE` и ключи AR-шифрования**, бакет R2.
2. **До первого деплоя**: `CW_RAILS_ALIAS=chatwoot-dev-rails` (добавить
   руками), `CW_FRONTEND_URL=https://chat-dev.aura-app.cc` (заменить
   засеянный прод-домен).
3. После деплоя: `docker network inspect coolify` — у `chatwoot-rails` ровно
   один контейнер (прод), у `chatwoot-dev-rails` ровно один (dev). Только
   потом провижинить.
4. Провижининг dev командой из шапки скрипта. dev-BFF:
   `CHATWOOT_BASE_URL=http://chatwoot-dev-rails:3000` и значения из вывода
   скрипта.
5. Прод-BFF отвечает; `chat-dev.aura-app.cc` открывается.

## Открыто

- `AURAS-0004` не правился (решение `006`): абзац про `CW_RAILS_ALIAS` /
  `CW_FRONTEND_URL` добавить в конце задачи поверх свежего `missus`, если
  `aura-app-manor` не сделает этого в рамках `AURAD-0016`.
