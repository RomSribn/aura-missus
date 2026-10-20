# AURAT-0102-011 — verify (манор, живой стек)

2026-10-20. Манор `develop` @ `4bc1504`. Docker Desktop запущен; `docker compose
up` — Postgres + Redis + BFF (миграции + сид). Порт 3000 занят чужим Vite
(LogCluster RITA UI) — BFF поднят на **3010** через временный override в
scratchpad, репозиторий не менялся. В `.env` манора добавлено
`WEB_ALLOWED_ORIGINS=http://localhost:5173`. Chatwoot dev (`aura-cw-dev`) лежит
7 недель — не поднимался: изменённые пути его не требуют.

REST:
- Мобилка (без Origin): каталог 200 (8 персон, без ACAO); `/v1/sessions`,
  `/v1/advisors/olivia/messages` без токена и с плохим — 401; pricing с плохим
  токеном — 401 (не гость). helmet-заголовки на месте.
- Веб (`Origin: http://localhost:5173`): preflight 204 с ACAO/методами/
  заголовками/max-age 600; каталог 200 + ACAO; pricing гостю — реальные цены
  с оффером −50%; availability гостю — 48 слотов, 21 свободен, instant true;
  `/v1/sessions` гостю 401 (с ACAO — браузер прочитает); плохой токен 401.
- Чужой origin: ответ и preflight без ACAO.
- Гостевые запросы пользователей не создают: `users` 7 → 7.

WS (`/ws?token=<не настоящий>`): без Origin, RN-style Origin = хост BFF и
веб-origin — проходят проверку Origin и закрываются `4401` на токене; чужой
сайт — `4403 forbidden origin` до токена.

Не проверено: пути с настоящим Firebase-токеном (открытый сокет, бронь, чат) и
всё, что идёт в Chatwoot, — нужен реальный вход (приложение / веб) и dev Chatwoot.
Покрыто in-process проверкой `009` и юнит-тестами.
