# AURAT-0101-001 — Initial (заглушка; исполняется в `aura-web-manor`)

Date: 2026-10-20
Выдан в `aura-app-manor` для `AURAF-0020` (веб-клиент), этап 1, фазы 1 и 3
плана `AURAI-0007`. Решения — `AURAD-0019`.

Что нужно: каркас `aura-web` на `develop`, на котором строятся все экраны.

- Vite + React 19 + TypeScript strict, React Router (data router), Redux Toolkit +
  RTK Query, `@aura/contracts` тем же тегом, что у app/bff (сейчас `v0.22.0`), zod.
- Tooling: ESLint flat config + `no-restricted-imports` (как в aura-app) + Steiger,
  Prettier, Vitest + Testing Library, `@/` alias (tsconfig + Vite + Vitest),
  скрипты `lint / typecheck / test / build`.
- `shared`: `config/tokens.css` (из хендоффа, 1:1, с телефонной шкалой отступов),
  `config/breakpoints.ts`, `config/routes.ts`, `config/env.ts`; `api/base-api.ts`
  (без эндпоинтов) + `base-query.ts` (Firebase ID token, повтор на 401,
  `ACCOUNT_DELETED`, серверные часы) + `ws-client.ts`; ui-атомы — Sheet, Field,
  Toggle, IconButton, EmptyState (орб), Icon (36 иконок).
- `app`: провайдеры (store, router, Firebase), layouts (desktop / phone), dialog
  host, GuestGate-guard.
- Без экранов и без бизнес-слайсов — они идут отдельными задачами.

Вне задачи: деплой и CI (отдельной задачей), Playwright (появится с первым экраном).
Старт — `wts-task` в `aura-web-manor`, спека на одобрение владельцу.
