# AURAT-0083-031 — approved (2026-10-12)

Status: **done** (v1, только просмотр).

Владелец проверил на dev («Aura Dev», аккаунт 2): «проверил, все работает,
закрывай задачу».

## Что в итоге в `develop` (`aura-bff`)

- Виджет «Aura» — Dashboard App во вкладке диалога Chatwoot, страница
  `/agent-desk` из BFF, CSP `frame-ancestors` = `AGENT_DESK_FRAME_ANCESTOR`.
- Вход агента без логина: мост в `DASHBOARD_SCRIPTS` → проверка
  `/api/v1/profile` → своя сессия 15 мин (bearer, хэш в Redis).
- Только чтение: баланс клиента, текущая сессия, сессии клиента и брони
  адвайзора карточками по дням (клиент с фото/инициалами, Trial, статус,
  ссылка в диалог), две колонки на широкой вкладке, профиль адвайзора в шапке.
- Браузерный код — `client/desk.ts` (типы из DTO, свой tsconfig, jsdom-тесты);
  `assets/desk.js` собирается `npm run desk:build` и сверяется тестом.
- Деплой: `deploy/chatwoot/install-agent-desk-bridge.rb` (через stdin в
  контейнер rails); вкладка — через UI Chatwoot по аккаунту.

Мерджи: `b191f12`, `5f95460`, `ca2c5a6`.

## Состояние окружений

- dev: `AGENT_DESK_FRAME_ANCESTOR` задан, вкладка в аккаунте 2 — работает.
- Chatwoot: мост установлен для `bff.aura-app.cc` и `bff-dev.aura-app.cc`.
- **prod — не включён:** код уйдёт с релизом `develop` → `main`; затем
  `AGENT_DESK_FRAME_ANCESTOR` в прод-BFF и вкладка `Aura` в аккаунте 1
  (`https://bff.aura-app.cc/agent-desk`) — `AURAS-0004` → *Chatwoot specifics*.

## Хвосты (вне задачи, ID — в aura-app-manor)

- AURAD: как строим внутренние страницы (SSR/клиентский TS, без CDN, порог
  фреймворка) и вход агента через `DASHBOARD_SCRIPTS` (сейчас только в `005`/`010`).
- `AURAS-0004`: чек-лист при обновлении Chatwoot (cookie `cw_d_session_info`,
  протокол `Frame.vue`, `DASHBOARD_SCRIPTS`).
- Флак `src/modules/wallet/apple-refund.service.spec.ts` под нагрузкой полного
  прогона (дважды за день, повтор зелёный).
- Вне объёма v1 (ждут флоу смен): расписание чаттеров, «моя смена», сводное
  расписание всех адвайзоров, маршрутизация.
