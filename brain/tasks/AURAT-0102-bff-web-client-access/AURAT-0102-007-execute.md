# AURAT-0102-007 — execute

2026-10-20. Сделано по спеке `005` в `slave-2`, не закоммичено (staged на ревью).

## Код (`aura-bff`)

- `src/config/env.schema.ts` — `WEB_ALLOWED_ORIGINS` (CSV origin'ов, пробелы и
  хвостовые `/` срезаются, путь или мусор → отказ загрузки; не задан → `[]`).
- `src/common/web/web-origins.ts` — `webCorsOptions` (точные origin, методы
  `GET/POST/PUT/PATCH/DELETE`, заголовки `Authorization, Content-Type`, без
  credentials, `maxAge` 600) и `isAllowedWsOrigin` (нет Origin / в allowlist /
  тот же хост, что `Host`).
- `src/app.setup.ts` — `@fastify/cors` регистрируется только при непустом списке.
  Зависимость `@fastify/cors@^11.2.0` — та же версия, что уже стояла
  транзитивно у `@nestjs/platform-fastify` (в lock одна строка).
- `src/modules/delivery/chat.gateway.ts` — проверка Origin до токена, чужой →
  `close(4403, 'forbidden origin')`.
- `@OptionalAuth()` (`common/decorators/optional-auth.decorator.ts`) +
  `@OptionalUser()` (`current-user.decorator.ts`); `FirebaseAuthGuard` пропускает
  такой маршрут без `Authorization`, с заголовком — проверка как раньше.
- `advisors.controller.ts` — `GET /v1/advisors` `@Public()`.
- `sessions.controller.ts` / `sessions.service.ts` — availability и pricing
  `@OptionalAuth()`; `auth: AuthUser | null`; гость — без `ensureUser`, без своей
  занятости, цена с оффером. `BillingEnabledGuard` на месте.
- Документация: `README.md` (каталог, `/ws` 4403, availability/pricing, раздел
  «Browsers»), `.env.example`, `deploy/env/bff.env.example`.

## Тесты

Новые: `web-origins.spec.ts` (CORS через настоящий Fastify + `isAllowedWsOrigin`),
`guest-access.smoke.spec.ts` (настоящие глобальный гард и billing-гард: гость
читает ровно каталог, слоты и цену, приходит в сервис как `null`; протухший
токен → 401; `/v1/sessions` гостю → 401; без биллинга → 404), плюс кейсы в
`env.schema`, `firebase-auth.guard`, `chat.gateway`, `sessions.service`.
`typecheck`, `lint`, `build` — ок; jest — 121 suites / 1577 tests, все зелёные.
(Перед прогоном пришлось `prisma generate`: клиент в слоте был устаревшим.)

## Brain

- `AURAF-0020`: BE ✗ → ✓ в строках 001 и 002, контекст обновлён.
- `@aura/contracts` не менялся, тега нет.

## Открыто / за владельцем

- `WEB_ALLOWED_ORIGINS` в env dev/prod — когда будут веб-домены.
- Firebase Authorized domains для веб-доменов; App Check — по желанию.
- Живая проверка в маноре: preflight `OPTIONS` с веб-origin, `/ws` из браузера
  (allowlist) и из приложения (Origin = хост BFF), гостевые `GET` без токена.
