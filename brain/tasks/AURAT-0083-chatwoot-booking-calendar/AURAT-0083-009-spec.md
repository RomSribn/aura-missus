# AURAT-0083-009 — спека v1: виджет «Календарь бронирований» (только просмотр)

Status: **draft — ждёт одобрения владельца**
Дата: 2026-10-12. Ветка `feature/AURAT-0083-booking-calendar-v1` (slave-2).
Тип: задача (без нового AURAF — ID не минтим). Опирается на решения A/C/D из `005`,
факты — `004`, `008`.

## Что получает чаттер

Во вкладке «Aura» рядом с «Messages» в диалоге Chatwoot (Dashboard App) — страница,
которая без отдельного логина показывает по текущему диалогу:

1. **Шапка:** адвайзор диалога; баланс кошелька клиента (USD).
2. **Текущая сессия** этого диалога: статус, сколько осталось (тикает в браузере
   от `endsAt`), купленные минуты блока, всего оплачено минут в этом диалоге.
3. **Сессии клиента:** предстоящие (SCHEDULED/ACTIVE) и прошедшие (FINISHED/
   CANCELLED, последние 50) — по **всем** адвайзорам клиента, сессии с адвайзором
   этого диалога выделены.
4. **Занятость адвайзора** на горизонте бронирования (`SESSION_BOOKING_HORIZON_DAYS`,
   сейчас 14 дней): по дням — занятые интервалы; брони этого клиента выделены, чужие
   — просто «занято», без каких-либо данных о другом клиенте.

Время — в часовом поясе браузера чаттера, пояс подписан. Обновление: при открытии,
кнопкой и раз в 60 с. Ничего не меняет — кнопок нет. Предложить сессию чаттер
по-прежнему может только токеном `::SESSION::` (решение C).

При `BILLING_ENABLED=false` блоки 1(баланс)–4 заменяет строка «Платные сессии
выключены» — не 404, это инструмент, а не скрытый маршрут.

## Авторизация (решение A) — как это работает

```
Chatwoot (chat.aura-app.cc)                 iframe (bff[-dev].aura-app.cc/agent-desk)        BFF
  │  DASHBOARD_SCRIPTS: «мост»                   │
  │◄── postMessage {aura-desk:auth-request} ─────│  (targetOrigin = https://chat.aura-app.cc)
  │  проверяет event.origin ∈ {bff, bff-dev},    │
  │  event.source — один из iframe страницы,     │
  │  читает cookie cw_d_session_info,            │
  │  берёт ТОЛЬКО access-token/client/uid        │
  │─── postMessage {aura-desk:auth, …} ─────────►│  (targetOrigin = event.origin, не '*')
  │                                              │  проверяет event.origin = Chatwoot
  │                                              │── POST /agent-desk/api/session ──────────►│
  │                                              │                       GET /api/v1/profile  │──► Chatwoot
  │                                              │                       (с тройкой агента)   │
  │                                              │◄── { token, expiresAt } ───────────────────│
  │                                              │── GET …/api/… Authorization: Bearer ──────►│
```

- **Проверка у Chatwoot** (в адаптере `chatwoot/`, новый порт
  `ChatwootAgentAuthPort.verifyAgent(credentials)`): `GET {CHATWOOT_BASE_URL}/api/v1/
  profile` с заголовками агента. 200 + в `accounts[]` есть `CHATWOOT_ACCOUNT_ID`
  этого BFF со статусом `active` → агент `{chatwootUserId, role}`. Иначе 401.
  Наружу из адаптера — только наш тип; тело ответа (в нём вечный `access_token`
  агента и `pubsub_token`) **не хранится и не логируется**; тройка не хранится.
- **Своя сессия BFF:** случайный токен 32 байта, в Redis — только его хэш →
  `{chatwootUserId}`, TTL **15 минут**, не продлевается. Отдаётся телом ответа,
  живёт в памяти страницы, ходит как `Authorization: Bearer`. Без cookie → нет
  CSRF и проблем со сторонними cookie в iframe. На 401 страница повторяет
  рукопожатие (мост отдаёт свежую тройку) — для чаттера незаметно.
  Отзыв: удалённый из аккаунта / разлогиненный агент теряет доступ ≤ 15 мин.
- Обмен (`POST /agent-desk/api/session`) — rate-limit строже глобального
  (10/мин с адреса). Логи — только `chatwootUserId` и исход, без заголовков.
- `appContext` из `Frame.vue` — **только** номер диалога и `account_id` для
  подсказки «не тот аккаунт»; ничему из него сервер не доверяет.
- Прямое открытие страницы по ссылке: рукопожатие не с кем вести → «Открывается
  только из Chatwoot»; плюс `frame-ancestors` не даст встроить её никуда, кроме
  Chatwoot. Данные без сессии недоступны в любом случае.
- Доступ — любой активный агент аккаунта (сейчас все чаттеры в одном inbox).
  Проверку «агент видит этот inbox» в v1 не делаем.

## Read-эндпоинты BFF

Префикс **`/agent-desk`**, вне `/v1` (как `/backoffice`), `@Public()` для Firebase-
guard + свой `AgentDeskSessionGuard`. Ключ — `chatwootConversationId` (= `display_id`
Chatwoot), резолвится через существующий `ChatwootMessagingPort.resolveConversation`
→ `{conversationId, userId, advisorId}`; не наш диалог → 404.

| Метод | Путь | Ответ |
|---|---|---|
| POST | `/agent-desk/api/session` | `{ token, expiresAt }` — обмен тройки агента |
| GET | `/agent-desk/api/conversations/:cwId/overview` | `billingEnabled`; `advisor {id, name}`; `walletBalanceMinor` (нет кошелька → 0, **не создаём**); `currentSession {status, startsAt, startedAt, endsAt, bookedMinutes} \| null`; `paidMinutesInConversation`; `upcoming[]`, `past[]` — `{id, advisorId, advisorName, status, startsAt, endsAt, bookedMinutes, finishReason}` |
| GET | `/agent-desk/api/conversations/:cwId/advisor-calendar` | `billingEnabled`; `from`, `to` (горизонт), `slotStepMinutes`, `timeZone` (сетки); `busy[] {from, to, thisClient: boolean}` |

Сумм денег по сессиям (цена, возвраты) в v1 не показываем — не просили.

Слои: контроллеры тонкие; `AgentDeskService` собирает ответ из
`SessionsRepository` / `WalletsRepository` / `AdvisorsRepository` / порта
Chatwoot (сессии и кошелёк только читаются — правило 4 не затрагивается). Нужные
недостающие read-методы: `WalletsRepository.findByUserId` (без создания).
`SessionsModule` начнёт экспортировать `SessionsRepository` (или read-фасад в
`SessionsService` — выберу при реализации меньшее). DTO — локальные модуля:
это не контракт с приложением, в `@aura/contracts` не идут (правило 7 не про них).

## Страница виджета (решение D)

- `GET /agent-desk` — HTML без инлайна; `GET /agent-desk/assets/:name` — фикс.
  список (`desk.js`, `desk.css`, шрифты бэкофиса), как `BackofficeAssets`.
  JS — ванильный, без сборки и без внешних CDN.
- Заголовки ответа страницы/ассетов перекрывают helmet:
  `Content-Security-Policy: default-src 'none'; script-src 'self'; style-src 'self';
  font-src 'self'; connect-src 'self'; img-src 'self'; base-uri 'none';
  form-action 'none'; frame-ancestors https://chat.aura-app.cc` и **без**
  `X-Frame-Options`. `cache-control: no-store` для HTML и API, `noindex`.
- Новый env **`AGENT_DESK_FRAME_ANCESTOR`** (публичный origin дашборда Chatwoot,
  `https://chat.aura-app.cc` в обоих окружениях — `AURAD-0016`; `CHATWOOT_BASE_URL`
  — внутренний alias, для CSP не годится). Опционален: без него `/agent-desk/*`
  отвечает 404 (локальный стек без виджета). Валидируется как origin.

## Деплой-артефакты (aura-bff `deploy/chatwoot/`)

1. **`agent-desk-bridge.html`** — содержимое `DASHBOARD_SCRIPTS` (мост, ~40 строк,
   allowlist origin-ов `https://bff.aura-app.cc`, `https://bff-dev.aura-app.cc`).
2. **`install-agent-desk-bridge.rb`** — `rails runner`: записывает мост в
   `InstallationConfig DASHBOARD_SCRIPTS` (если там уже что-то есть — не затирает
   чужое, обновляет наш блок между маркерами) + `GlobalConfig.clear_cache`.
   Через UI нельзя — на community поле в супер-админке скрыто.
3. **`register-agent-desk-app.rb`** — `rails runner`, идемпотентно по
   `(account_id, title "Aura")`: `ACCOUNT_ID`, `AGENT_DESK_URL`, владелец-`user`
   (берётся первый администратор аккаунта). Prod: `ACCOUNT_ID=1
   AGENT_DESK_URL=https://bff.aura-app.cc/agent-desk`; dev: `ACCOUNT_ID=2
   …bff-dev…`.
4. `deploy/README.md` — раздел «Виджет в Chatwoot»: порядок (env BFF → деплой →
   мост → регистрация), откат (пустой маркер-блок + удалить DashboardApp).

## Решения для владельца

1. **Мост отдаёт токен и dev-BFF.** Chatwoot один (`AURAD-0016`): devise-токен
   владельца действует во **всех** его аккаунтах, включая прод-аккаунт 1 как
   администратор. Открыв виджет в dev-аккаунте 2, владелец передаст этот токен
   dev-BFF (код из `develop`). BFF его не хранит и не логирует, но риск — код
   dev-окружения. **Рекомендация:** принять (dev-аккаунт — только владелец, dev-
   BFF — наш, иначе виджет нечем проверить в манор до прода). Альтернатива: мост
   знает только `bff.aura-app.cc`, проверка сразу на проде.
2. **TTL сессии 15 мин, без cookie** — рекомендую так; скажи, если нужно иначе.

Остальное (сессии по всем адвайзорам клиента, «платные выключены» вместо 404,
браузерный часовой пояс, префикс `/agent-desk`) — мои умолчания; поправь, если не так.

## Вне объёма v1

Расписание чаттеров, «моя смена», маршрутизация/автоназначение, упоминание команды
адвайзора (ждут флоу смен); бронь/отмена/перенос за клиента (C); суммы и возвраты;
проверка доступа агента к конкретному inbox.

## Проверка

- **Slave:** unit — обмен (200/401/чужой аккаунт/неактивный, тело профиля не
  попадает в лог), guard (нет/просрочен/неверный токен), сборка overview/calendar
  (billing off, нет кошелька, нет активной сессии, чужие брони без данных клиента,
  разбиение upcoming/past), заголовки CSP/XFO; `ruby -c` скриптов; lint, typecheck,
  build.
- **Манор (после merge):** dev-аккаунт 2 — мост установлен, Dashboard App
  зарегистрирован, вкладка открывается, рукопожатие проходит, данные совпадают с
  БД; прямое открытие URL — «только из Chatwoot»; встраивание с другого origin
  блокируется.
