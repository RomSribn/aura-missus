# AURAT-0075-010 — Релиз в production

Дата: 2026-09-17
Где: `aura-bff-manor`. Проверки снаружи, по HTTP. Доступа к серверу и Coolify
из этой сессии не было.

## Релиз

Владелец сказал «релизни develop в main» и подтвердил вопросом
«Release → Да, релиз». `main` переведён `abe2039` → **`d3c8ec8`**
(fast-forward, push в 13:12:21 UTC). В релизе только `AURAT-0075`: одна
аддитивная миграция `20260917120000_backoffice_operators`, новых переменных
нет, `deploy/` и `Dockerfile` не менялись.

| Время, UTC | `/backoffice/login` | `/health` |
|---|---|---|
| 13:12:31 | 404 (старый образ) | 200 |
| 13:13:38 | 502 | 502 |
| 13:13:43 | **200** | 200 |

Окно `502` — около 5 с. Это то же rolling update без healthcheck, что в
`AURAS-0004` → *Deploys*.

## Проверено снаружи (13:14 UTC)

| Проверка | Итог |
|---|---|
| `/health`, `/health/ready` | ok; `database: true`, `redis: true` |
| `GET /backoffice/login` | 200, `text/html`, `cache-control: no-store`, `x-robots-tag: noindex, nofollow`, CSP helmet (`script-src 'self'`, `form-action 'self'`), HSTS |
| Стиль и шрифт | `backoffice.css?v=d19452a0a0a5` — 200 `text/css`; `HankenGrotesk-Regular.ttf` — 200 `font/ttf` |
| Без сессии | `/backoffice` → 303 на `/reviews`; `/reviews`, `/deletions` → 303 на `/login` |
| POST входа с `sec-fetch-site: cross-site` | 403 |
| POST модерации без сессии | 303 на `/login`, ничего не выполнено |
| API устройства | `DELETE /v1/me` и `GET /v1/advisors` без токена — 401; `/docs` — 404 |
| Chatwoot | `/` 200; `/api` — `queue_services ok`, `data_services ok` |
| Dev не задет | `bff-dev` `/backoffice/login` 200 |

Миграция не смотрелась в логе: доступа нет. Но `docker-entrypoint.sh`
запускает `migrate deploy` до старта приложения, а при ошибке новый контейнер
не стартует — раз бэкофис отвечает с нового образа, миграция прошла.

## Не сделано

- **Учётка на проде не заведена** — её заводит владелец:
  `node dist/backoffice-operators.js add <login>` в терминале контейнера
  production `aura-bff` в Coolify.
- Не проверено: `restarts`, строки миграции и `warn`/`error` в логе прод-BFF;
  вход, модерация и вкладка удалений на проде (нет учётки).
