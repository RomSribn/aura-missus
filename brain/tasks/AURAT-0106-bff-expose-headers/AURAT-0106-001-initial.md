# AURAT-0106-001 — Initial (заглушка; исполняется в `aura-bff-manor`)

Date: 2026-10-20
Выдан в `aura-app-manor` для `AURAF-0020` (веб-клиент), бэклог — строка 017 scope
(колонка BE). Решение владельца — `AURAT-0105-006` (пробел найден при разборе чата
`AURAT-0105`, остальные пробелы BFF — строки 018–023, без ID). Продолжает `AURAT-0102`
(CORS для веба, `src/common/web/web-origins.ts`).

Что нужно: браузер веб-клиента читает заголовки ответа BFF `Date` и `Retry-After`.

- Сейчас `webCorsOptions` не задаёт `exposedHeaders` (у `@fastify/cors` по умолчанию —
  ничего), а `Date` и `Retry-After` не входят в безопасный список CORS: на кросс-доменном
  ответе `response.headers.get('Date')` в браузере — `null`. Веб читает `Date` в каждом
  ответе (`aura-web` `shared/api/base-query.ts` → `server-clock.ts`, перенос из приложения)
  и молча откатывается на часы устройства: ближайшие слоты профиля (`AURAT-0103`), дальше —
  бронь и таймер сессии.
- `exposedHeaders: ['Date', 'Retry-After']` в `webCorsOptions` — на всех ответах для
  разрешённого origin, включая ошибки (401, 404 без биллинга, 429 от rate-limit, где и
  появляется `Retry-After`): проверить, что заголовок есть и на них. Остальная политика
  (origins, методы, `allowedHeaders`, `credentials: false`, `maxAge`) не меняется;
  мобильное приложение CORS не касается.
- Тесты — в `web-origins.spec.ts` рядом с тестами `AURAT-0102`: на ответе разрешённому
  origin есть `Access-Control-Expose-Headers: Date, Retry-After`, чужому — нет; ответ 429
  тоже его несёт.

Контракты не меняются. Веб без изменений: `serverNow()` заработает сам после выкладки
(колонка UI строки 017 — «—»).

Проверка: в маноре — `curl -i -H 'Origin: http://localhost:5173'` к `/v1/advisors`, в
ответе `Access-Control-Expose-Headers: Date, Retry-After`; после выкладки на bff-dev — в
DevTools веба (`aura-web` `develop`) заголовок `Date` виден из JS. Старт — `wts-task` в
`aura-bff-manor`, спека на одобрение владельцу.
