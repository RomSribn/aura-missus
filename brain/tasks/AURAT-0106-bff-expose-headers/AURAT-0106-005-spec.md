# AURAT-0106-005 — spec

Тип: task (строка `AURAF-0020-017`, колонка BE). Новой фичи нет.
Status: done 2026-10-20 (`011`).

## Что делаем

1. `src/common/web/web-origins.ts`, `webCorsOptions`: добавить
   `exposedHeaders: ['Date', 'Retry-After']` с коротким комментарием, зачем
   (часы сервера в вебе — `serverNow()`; `Retry-After` на 429). Остальное —
   origins, методы, `allowedHeaders`, `credentials: false`, `maxAge` — без изменений.
2. `src/common/web/web-origins.spec.ts`, рядом с тестами `AURAT-0102`:
   - ответ разрешённому origin несёт `Access-Control-Expose-Headers: Date, Retry-After`;
   - чужому origin и запросу без `Origin` (мобильное приложение) — заголовка нет;
   - 429 от `@fastify/rate-limit`, зарегистрированного **до** CORS, как в
     `app.setup.ts`, несёт `Access-Control-Allow-Origin`, expose-заголовок и сам
     `Retry-After` — фиксирует порядок хуков, на который мы опираемся;
   - ошибка (401) тоже несёт expose-заголовок.

Контракты, веб и приложение — без изменений. `app.setup.ts` не трогаем.

## Проверка

- Слот: `lint`, `typecheck`, `build`, unit-тесты.
- Манор после merge: `curl -i -H 'Origin: http://localhost:5173' …/v1/advisors` →
  `Access-Control-Expose-Headers: Date, Retry-After`.
- bff-dev после выкладки: в DevTools веба (`aura-web` `develop`) `Date` виден из JS,
  `AURAF-0020-017` BE ✗ → ✓.
