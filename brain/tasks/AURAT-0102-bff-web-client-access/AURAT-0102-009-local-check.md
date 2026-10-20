# AURAT-0102-009 — local check (slave, без инфраструктуры)

2026-10-20. Владелец попросил проверить локально, что мобильные методы работают
вместе с веб-методами. Живой стек в слоте запрещён, поэтому — один процесс:
настоящий `configureApp` (helmet, rate-limit, CORS, версии, WsAdapter), глобальный
`FirebaseAuthGuard`, `BillingEnabledGuard`, настоящий `ChatGateway` на реальном
порту; клиенты — настоящие `fetch` и `ws`. Сервисы, Firebase, БД — фейки.
`WEB_ALLOWED_ORIGINS=http://localhost:5173`. Временный spec удалён после прогона.

Результат (все ок):
- Мобилка REST (без Origin, bearer): advisors 200, pricing 200, sessions 200,
  book 201, протухший токен 401; CORS-заголовков нет.
- Веб-гость: preflight 204 (ACAO = localhost:5173), advisors / pricing / slots 200,
  в сервис приходит `null`; `/v1/sessions` 401.
- Веб с токеном: pricing 200 (как пользователь), book 201 с CORS.
- Чужой сайт: ответ без ACAO.
- WS: мобилка с RN-Origin (= хост BFF) — открыт; без Origin — открыт; веб —
  открыт; чужой origin — закрыт 4403. Событие одному пользователю пришло
  одинаково во все три сокета одновременно.

Не проверено (только манор после merge): реальные Postgres/Redis/Chatwoot,
настоящие Firebase-токены, приложение на устройстве, браузер aura-web.
