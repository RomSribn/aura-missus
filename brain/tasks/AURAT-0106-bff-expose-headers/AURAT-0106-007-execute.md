# AURAT-0106-007 — execute

2026-10-20, slave-2.

## Файлы (master)

- `src/common/web/web-origins.ts` — `exposedHeaders: ['Date', 'Retry-After']` в
  `webCorsOptions` + комментарий. Остальная политика без изменений.
- `src/common/web/web-origins.spec.ts` — новый `describe` (4 теста); rate-limit
  регистрируется до CORS, как в `app.setup.ts`:
  - разрешённый origin → `Access-Control-Expose-Headers: Date, Retry-After`;
  - чужой origin → нет `Access-Control-Allow-Origin`;
  - 401 → allow-origin + expose-заголовок;
  - 429 от `@fastify/rate-limit` → allow-origin + expose-заголовок + `Retry-After`.

## Отклонение от spec `005`

В spec было «чужому origin / без Origin — expose-заголовка нет». Тест показал:
`@fastify/cors` 11.2.0 (`addCorsHeaders`) пишет `Access-Control-Expose-Headers` на
**каждый** ответ, независимо от того, разрешён ли origin. Это безвредно: браузер
смотрит на этот заголовок, только если `Access-Control-Allow-Origin` уже разрешил
странице читать ответ; чужому сайту его не выдают, мобильному приложению CORS не
нужен. Поэтому тест проверяет то, что реально закрывает доступ, — отсутствие
allow-origin; поведение плагина описано в комментарии к тесту. Своего хука ради
этих нескольких байт не пишем.

## Проверки (слот)

- `jest src/common/web` — 19/19; полный `jest` — 121 suites, 1581 тест, всё зелёное.
- `lint`, `typecheck`, `build`, `prettier --check` — чисто.

## Дальше

Ревью владельцем в IDE → коммит в feature → merge (с подтверждением) → манор
`curl -i -H 'Origin: http://localhost:5173' …/v1/advisors` → bff-dev → DevTools веба →
`AURAF-0020-017` BE ✗ → ✓.
