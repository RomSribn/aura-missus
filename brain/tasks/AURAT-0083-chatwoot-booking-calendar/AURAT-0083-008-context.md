# AURAT-0083-008 — context для v1 (2026-10-12)

Проверено по исходникам Chatwoot (`chatwoot-manor/.../master/chatwoot`, `VERSION_CW`
= **4.15.1**) и коду BFF (`develop` `6c4fec0`). Дополняет `004`.

## Chatwoot: DASHBOARD_SCRIPTS — существует

- `config/installation_config.yml:290` — `DASHBOARD_SCRIPTS`, type `code`, «loaded as
  the last item in the `<body>` tag».
- `DashboardController#set_dashboard_scripts` → `layouts/vueapp.html.erb:81-82`
  выводит значение `html_safe` на каждой странице дашборда, кроме сброса пароля
  (`sensitive_path?`). CSP-инициализатора в Chatwoot нет → inline `<script>` работает.
- **В супер-админке не правится на community:** поле есть только в
  `enterprise/.../app_configs_controller.rb` (`internal_config_options`), и тот
  делает `return super if pricing_plan == 'community'`. Ставим через `rails runner`:
  `InstallationConfig` + `GlobalConfig.clear_cache` (кэш в Redis, `DEFAULT_EXPIRY`
  = 1 день — без сброса изменение видно только через сутки).
- Значение глобально на инсталляцию → один скрипт обслуживает оба аккаунта
  (prod 1, dev 2 — один Chatwoot, `AURAD-0016`).

## Chatwoot: откуда берётся токен агента

- `dashboard/store/utils/api.js:31-36`: после логина фронт кладёт
  `JSON.stringify(response.headers)` в cookie **`cw_d_session_info`** через
  js-cookie (не HttpOnly, `SameSite=Lax`, origin `chat.aura-app.cc`). Внутри —
  devise_token_auth заголовки `access-token`, `client`, `uid`, `expiry`, …
- `devise_token_auth.rb`: `change_headers_on_each_request = false`,
  `token_lifespan = 2.months` → тройка стабильна, не ротируется на запросах.
- Скрипт из `DASHBOARD_SCRIPTS` исполняется в origin Chatwoot → читает cookie.
- `GET /api/v1/profile` (не под `/accounts/:id`) с этими тремя заголовками →
  `api/v1/models/_user.json.jbuilder`: `id`, `name`, `email`, `accounts[]{id, role,
  status, …}`, **а также `access_token` (вечный API-токен агента) и
  `pubsub_token`** → BFF не должен ни хранить, ни логировать тело ответа.

## Chatwoot: Dashboard App

- `Frame.vue`: iframe **без `sandbox`**, на `load` и на `'chatwoot-dashboard-app:
  fetch-info'` шлёт `postMessage(JSON-строка {event:'appContext', data}, '*')`;
  `currentAgent = {id,name,email}`. Подписи нет → только контекст (подтверждено).
- `DashboardApp belongs_to :user, :account`; схема: `account_id NOT NULL`,
  `user_id` nullable в БД, но `belongs_to :user` (Rails 5+ default required) →
  при создании нужен пользователь аккаунта. `content = [{type:'frame', url:'https?://…'}]`.
- `conversation.id` в API/сторе = **`display_id`** (`_conversation.json.jbuilder:29`)
  — то же число, что BFF хранит как `chatwootConversationId`.

## Хосты

- Dev-Chatwoot отдельного нет: `AURAT-0071` отменена, `AURAD-0016` — один Chatwoot
  `https://chat.aura-app.cc`, аккаунт 1 → `bff.aura-app.cc`, аккаунт 2 →
  `bff-dev.aura-app.cc`. **frame-ancestors для обоих BFF = `https://chat.aura-app.cc`.**
- `CHATWOOT_BASE_URL` в проде = `http://chatwoot-rails:3000` (внутренний alias) —
  для проверки токена годится, но для CSP не годится → нужен отдельный конфиг
  публичного origin дашборда.

## BFF (код)

- `app.setup.ts`: helmet в проде с дефолтами (`frame-ancestors 'self'`,
  `X-Frame-Options: SAMEORIGIN`) → ответ виджета должен перекрыть оба заголовка.
- Образцы: бэкофис (`/backoffice`, VERSION_NEUTRAL, `@Public()` + свой guard,
  `sendPage`, фиксированный список ассетов `BackofficeAssets`, сессии в Redis
  хэшем токена — `backoffice-auth.service.ts`).
- Обратный поиск: `ChatwootMessagingPort.resolveConversation(chatwootConvId)` →
  `{id, userId, advisorId}`.
- Сессии (`SessionsRepository`): `findActiveByConversation`,
  `findUpcomingByConversation`, `listByUser(userId, limit)`,
  `listAdvisorBusyWindows(advisorId, from, to)`, `sumBookedMinutes(convId)`.
  Конфиг сетки: `SESSION_SLOT_STEP_MINUTES`, `SESSION_BOOKING_HORIZON_DAYS`,
  `SESSION_SLOT_TIMEZONE`. `SessionsModule` экспортирует только `SessionsService`.
- Кошелёк: `WalletsRepository.getOrCreateByUserId` — **создаёт**; чистого чтения
  нет → для операторского чтения нужен `findByUserId` (нет кошелька = 0).
- `BillingEnabledGuard` прячет маршруты 404; `BILLING_ENABLED=false` по умолчанию.
- JWT-библиотек нет; есть `ioredis`, `node:crypto`.
