# AURAT-0106-004 — context

- `src/common/web/web-origins.ts` — `webCorsOptions` без `exposedHeaders`;
  `@fastify/cors` 11.2.0 по умолчанию `exposedHeaders: null` → заголовка
  `Access-Control-Expose-Headers` нет. `Date` и `Retry-After` не входят в безопасный
  список CORS (там только `Cache-Control`, `Content-Language`, `Content-Length`,
  `Content-Type`, `Expires`, `Last-Modified`, `Pragma`) → в браузере `null`.
- `src/app.setup.ts` — `rateLimit` (120/мин) регистрируется **до** `cors`. Проверено
  пробой на установленных Fastify / плагинах: `@fastify/rate-limit` вешает свой хук на
  маршрут (`onRoute` → route-level `onRequest`), а CORS — глобальный `onRequest`, он
  выполняется раньше. Поэтому 429 от rate-limit несёт `Access-Control-Allow-Origin` и
  expose-заголовок, `Retry-After` там ставит сам плагин. 401 и 500 — тоже несут
  (заголовки ставятся в `onRequest` и переживают ошибку). Порядок регистрации менять не
  нужно.
- Preflight тоже отдаёт `Access-Control-Expose-Headers` (плагин ставит его на любой
  CORS-ответ) — безвредно, браузер смотрит его только на фактическом ответе.
- `aura-web` (только чтение): `shared/api/base-query.ts:75` и `bff-file.ts:13` читают
  `response.headers.get('Date')` → `server-clock.ts` `recordServerTime`; при `null` —
  тихий выход, офсет 0. `Retry-After` веб сейчас не читает — открываем впрок (так
  записано в `AURAT-0105-006` и `AURAF-0020-017`).
- `retry-after` также ставят `backoffice-sign-in` и `agent-desk-api` — это не веб-клиент,
  их CORS не касается (те origin не в allowlist).
- Противоречий не найдено.
