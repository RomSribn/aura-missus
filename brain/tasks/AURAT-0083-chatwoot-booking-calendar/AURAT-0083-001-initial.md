# AURAT-0083-001 — initial

Дата: 2026-10-12. Слот: `slave-2`, ветка `feature/AURAT-0083-chatwoot-booking-calendar`
(master + missus). ID выдан в `aura-app-manor` (счётчик → `AURAT-0084`).

## Запрос владельца (близко к тексту)

Виджет «Календарь бронирований» для чаттеров внутри Chatwoot — Dashboard App
(размещение Conversation, iframe в правой панели диалога). Задача ведётся в
aura-bff, брейн — общий aura-missus. Открытые вопросы решаем с владельцем до спеки.

### Бриф
- Внутренний веб-сервис, встроенный в дашборд Chatwoot. Помогает чаттерам работать
  от лица разных адвайзоров и видеть брони клиента, не выходя из переписки.
- Исходники Chatwoot не трогаем. Регистрация для всех аккаунтов (бриф предлагал
  `GLOBAL_DASHBOARD_APP_URL` или `DashboardApp.create!(account_id: nil)`).
- Без логинов: страница слушает postMessage `appContext` — currentAgent (id/email),
  `custom_attributes.advisor_id` диалога, conversation.id, contact.id. Прямое
  открытие по ссылке закрыто.
- Функции: занятость выбранного адвайзора, предстоящие брони текущего клиента,
  создание брони за клиента кликом по свободному окну. Кнопок старт/стоп платной
  сессии нет — это делает бэкенд.
- Бэкенд через Application API: системные сообщения на старт/конец платной сессии;
  приватная заметка (`private: true`) за 5 минут до начала брони (звук + Web Push
  у чаттера, клиент не видит).

### Разведка из aura-app-manor (проверить по коду)
- Есть: `chatwoot-messaging.service.ts` (postActivityMessage, postPrivateNote,
  syncSessionState), sessions (статусы, предоплата, возвраты, slot-grid 24/7,
  EXCLUDE no-overlap, announce start/finish, scheduler 60с), токен `::SESSION::`,
  backoffice-авторизация (scrypt, cookie).
- Нет: заметки за 5 минут; брони от имени пользователя; авторизации агента
  Chatwoot; веб-фронтенда.
- Chatwoot: `GLOBAL_DASHBOARD_APP_URL` нет; `dashboard_apps.account_id` NOT NULL;
  Frame.vue шлёт appContext `postMessage(JSON, '*')` без подписи → не авторизация.

### Решения, нужные от владельца до спеки
- A. Авторизация оператора в виджете (кандидат: backoffice-сессия в iframe).
- B. «Расписание адвайзора» vs O1 из AURAT-0018 (24/7, без смен).
- C. Бронь за клиента: прямое списание или только предложение `::SESSION::`.
- D. Где живёт фронтенд (кандидат: отдавать из BFF, как /backoffice).

Заметка за 5 минут — независимая часть, можно выделить отдельной задачей.
