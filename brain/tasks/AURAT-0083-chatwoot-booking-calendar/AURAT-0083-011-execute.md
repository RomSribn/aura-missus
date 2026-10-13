# AURAT-0083-011 — execute (v1, только просмотр) — 2026-10-12

Реализовано по спеке `009` (одобрена в `010`). Изменения **не закоммичены**,
застейджены в `master` и `missus` — ждут ревью владельца в IDE.

## aura-bff — новое

- `src/modules/agent-desk/` — модуль виджета:
  - `agent-desk-auth.service.ts` — обмен тройки агента на свою сессию: порт
    Chatwoot → токен 32 байта, в Redis только хэш, TTL 15 мин; 10 отказов с адреса
    → ожидание 15 мин (успешные входы не считаются). Тройка и тело `/profile`
    нигде не хранятся и не логируются.
  - `agent-desk.guards.ts` — `AgentDeskEnabledGuard` (404 без
    `AGENT_DESK_FRAME_ANCESTOR`), `AgentDeskSessionGuard` (Bearer).
  - `agent-desk.service.ts` — `overview` / `advisorCalendar`, только чтение.
  - `agent-desk-api.controller.ts` — `POST /agent-desk/api/session`,
    `GET …/conversations/:cwId/overview`, `GET …/conversations/:cwId/advisor-calendar`.
  - `agent-desk-page.controller.ts`, `agent-desk-page.ts`, `agent-desk-assets.ts` —
    страница `/agent-desk` + `assets/desk.js`, `assets/desk.css` (ванильный JS,
    без сборки/CDN). CSP `frame-ancestors <AGENT_DESK_FRAME_ANCESTOR>`, `X-Frame-
    Options` снимается с raw-ответа (helmet ставит его в onRequest).
  - `agent-desk.dto.ts` — локальные DTO (не `@aura/contracts`).
  - тесты: `agent-desk-auth.spec.ts`, `agent-desk.service.spec.ts`,
    `agent-desk.smoke.spec.ts` (HTTP + helmet как в проде + Firebase-guard).
- `src/modules/chatwoot/chatwoot-agent-auth.port.ts` / `.service.ts` —
  `ChatwootAgentAuthPort.verifyAgent`: членство в `CHATWOOT_ACCOUNT_ID` со
  статусом аккаунта `active`; `chatwoot-agent-auth.spec.ts`.
- `deploy/chatwoot/install-agent-desk-bridge.rb` — мост в `DASHBOARD_SCRIPTS`
  (между маркерами, чужое содержимое сохраняется; `AGENT_DESK_REMOVE=1` — откат).
- `deploy/chatwoot/register-agent-desk-app.rb` — Dashboard App «Aura» по
  аккаунту, идемпотентно; владелец — первый администратор-человек аккаунта.

## aura-bff — изменено

- `chatwoot.client.ts` — `fetchSignedInProfile` (заголовки агента, 401 → null,
  возвращает только `id` + `accounts{id,status}`); `chatwoot.types.ts` — wire-типы;
  `chatwoot.module.ts` — экспорт порта.
- `sessions.repository.ts` / `prisma-sessions.repository.ts` —
  `listAdvisorBookings` (окна адвайзора с `conversationId`); `sessions.module.ts`
  экспортирует `SessionsRepository`.
- `wallets.repository.ts` / `prisma-wallets.repository.ts` — `findByUserId`
  (без создания кошелька).
- `env.schema.ts` — `AGENT_DESK_FRAME_ANCESTOR` (опционален, только origin);
  тесты в `env.schema.spec.ts`.
- `app.module.ts`, `nest-cli.json` (копирование ассетов), моки в трёх спеках.
- Документация: `README.md` (дерево модулей + раздел «Booking widget in
  Chatwoot»), `deploy/README.md`, `.env.example`, `deploy/env/bff.env.example`.

## aura-missus

- `solutions/AURAS-0004` → *Chatwoot specifics*: порядок установки (env BFF →
  мост → вкладка по аккаунтам), откат.

## Решения по ходу

- Отступления от спеки: мост встроен в `install-agent-desk-bridge.rb`, а не
  лежит отдельным `agent-desk-bridge.html` (runner читает stdin в контейнере —
  второй файл туда не попадает). Список origin-ов задаётся
  `AGENT_DESK_ORIGINS` при установке.
- Инструкция — в `AURAS-0004` (прод на Coolify), а `deploy/README.md` (там
  описан отложенный AWS-вариант) получил только строки в дереве.
- Текущая сессия = только ACTIVE сессия этого диалога; оставшееся время
  считается в браузере от `endsAt` по часам сервера (`serverNow`).
- Обнаружено: `ConfigLoader` Chatwoot при загрузке не перезаписывает уже
  заданные значения (`reconcile_only_new`), `InstallationConfig` после коммита
  сам сбрасывает кэш `GlobalConfig`.

## Проверки (slave)

- `tsc --noEmit`, `eslint src/**/*.ts`, `nest build` (ассеты в `dist`) — чисто.
- `jest`: 110 наборов / 1387 тестов — зелёные. Один раз под нагрузкой упал
  `apple-refund.service.spec.ts` (не затронут); два повторных полных прогона и
  одиночный — зелёные. Флак, к задаче не относится.
- `ruby -c` обоих скриптов; сгенерированный JS моста — `node --check`.
- jsdom-прогон во временной папке (в репо не попал): мост отвечает только
  разрешённому origin и только своему iframe, без `'*'`; виджет игнорирует
  чужие origin, проходит рукопожатие, рисует баланс, текущую сессию с отсчётом,
  списки и 15 дней календаря (включая переход на зимнее время 25.10).

## Для манор (после merge)

1. `AGENT_DESK_FRAME_ANCESTOR=https://chat.aura-app.cc` в dev-BFF, деплой.
2. Мост (`AGENT_DESK_ORIGINS=…bff.aura-app.cc,…bff-dev.aura-app.cc`), вкладка
   для аккаунта 2.
3. Проверить в «Aura Dev»: вкладка «Aura» в диалоге открывается, вход проходит,
   данные совпадают с БД; прямое открытие URL — «только из Chatwoot»; с billing
   off — «Платные сессии выключены».

Открытого нет. Дальше: ревью владельца в IDE → коммит → merge gate.
