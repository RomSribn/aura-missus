# AURAT-0083-004 — context

Источники: код BFF (slave-2/master), исходники Chatwoot (chatwoot-manor), brain
(AURAT-0018, AURAF-0008, AURAF-0013, AURAT-0054, AURAT-0075, AURAD-0001/0002/0005/
0009/0015/0016).

## Поправки к брифу (по исходникам Chatwoot)

1. **Dashboard App — это вкладка рядом с «Messages» в центре диалога, а не правая
   панель** (`ConversationBox.vue:107-141`). iframe монтируется при открытии вкладки и
   пересоздаётся на каждый диалог (key = `chat.id-app.id`).
2. **Приватная заметка НЕ даёт Web Push.** `NewMessageNotificationService` выходит,
   если `!message.notifiable?` (= `(incoming||outgoing) && !private`). Уведомление по
   заметке — только при упоминании `(mention://user/ID/…)` / `(mention://team/ID/…)`,
   тип `conversation_mention` → web push / email по настройкам агента
   (`mention_service.rb:17-72`). **Звук** в открытом дашборде по заметке играет и без
   упоминания (`DashboardAudioNotificationHelper.js:194-196`), если фильтр агента
   (mine/unassigned/all) пропускает диалог и вкладка не в фокусе этого диалога.
3. `GLOBAL_DASHBOARD_APP_URL` нет; `dashboard_apps.account_id` NOT NULL. Регистрировать
   по аккаунту (rails runner или `POST /api/v1/accounts/:id/dashboard_apps` — политики
   на контроллере нет, хватает токена любого юзера аккаунта). URL-схема `^https?://`.
4. `appContext`: `postMessage(JSON-строка, '*')` на load и на запрос
   `'chatwoot-dashboard-app:fetch-info'`; `currentAgent = {id,name,email}`, без
   секретов; `conversation` — полный объект стора (custom_attributes, meta.sender с
   identifier, загруженные сообщения, включая приватные). Подписи нет → не авторизация.
5. Способов получить проверяемую личность агента в iframe без патча нет, кроме:
   отдельного логина; инсталляционной настройки супер-админа `DASHBOARD_SCRIPTS`
   (HTML в конец `<body>` дашборда, в origin Chatwoot — может прочитать cookie
   `cw_d_session_info` с devise-токенами агента и передать в iframe; BFF проверяет их
   вызовом `GET /api/v1/profile` к Chatwoot). Platform API — только server-to-server.

## BFF (код)

- Обратный поиск есть: `ChatwootMessagingPort.resolveConversation(chatwootConvId)`
  → `{id,userId,advisorId}`. Контакт — `User.chatwootContactId`.
- `postPrivateNote(ourConvId, content)` есть (зовут chat.service, tarot.service).
- Бронь: `SessionsService.book(auth: AuthUser /*Firebase*/, advisorId, {startsAt|startNow,
  minutes, idempotencyKey})`; блокировки advisor+wallet, 402 при нехватке, 409 занято.
  Всё под `BillingEnabledGuard` (BILLING_ENABLED). Брони «от имени» нет.
- Сетка: 24/7, шаг 30, lead 30, горизонт 14 дн, блоки 10/20/30; занятость —
  интервал `[startsAt,endsAt)`, EXCLUDE `sessions_no_overlap_per_advisor`.
- Отложенные задачи: очередь `sessions` (activate/finish/sweep/announce/sync),
  `delay` + `jobId` с `startsAt` → «за 5 минут» добавляется по образцу
  `scheduleActivation` + no-op, если сессия уже не SCHEDULED/сдвинута; плюс sweep.
- Бэкофис: SSR-шаблоны без JS, cookie `aura_backoffice` `SameSite=Lax`, Path
  `/backoffice`, `SameOriginGuard` требует `Sec-Fetch-Site: same-origin` → из iframe
  (`same-site`) POST будет отклонён. Операторы — только через CLI; по факту один
  (владелец).
- **helmet по умолчанию в проде** → `frame-ancestors 'self'` + `X-Frame-Options:
  SAMEORIGIN`: любой ответ BFF в iframe Chatwoot сейчас заблокирован. Нужен
  отдельный префикс с `frame-ancestors https://chat.aura-app.cc`.
- Нет связи чаттер↔адвайзор, нет логики assignee/team в BFF.

## Brain

- **O1** (`AURAT-0018-005-spec.md:22-24`, ратиф. `006`): сетка 24/7, смены чаттеров
  (15–24, 24–9, 9–15) — операционные, в BFF не моделируются.
- **Согласие на платную сессию**: AURAD-0002 / AURAF-0013 — «бронирует и платит
  пользователь в приложении»; чаттер только предлагает (`::SESSION::`, без времени/
  длины/цены; «цену в токен не брать никогда»). Прямая бронь чаттером = новое
  решение AURAD (ID — в aura-app-manor).
- Напоминание за 30 мин (`AURAF-0008-012`) открыто — BFF напоминаний не шлёт.
- Домены: Chatwoot `chat.aura-app.cc` (прод-аккаунт 1, dev-аккаунт 2 — один инстанс,
  AURAD-0016), BFF `bff.aura-app.cc` / `bff-dev.aura-app.cc` → **same-site**,
  cross-origin. Cookie `SameSite=Lax/None` в iframe доходит, Safari ITP не режет
  (не третья сторона). Но один инстанс Chatwoot → виджет prod-аккаунта и dev-аккаунта
  разные Dashboard App (разные URL BFF).

## Вывод для развилок

A — три реальных варианта (отдельный логин / вход учёткой Chatwoot через BFF /
`DASHBOARD_SCRIPTS`). B — без пересмотра O1 показываем занятость. C — прямая бронь
противоречит AURAD-0002/AURAF-0013. D — BFF, свой префикс с разрешённым framing.
Новая развилка E — кого будить за 5 минут (упоминание), т.к. без него нет push.
