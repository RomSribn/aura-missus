# AURAT-0220-004 — Context (код `aura-bff` @ `cd0975b`)

Date: 2026-11-18

- **Сетка:** `src/modules/sessions/slot-grid.ts` — `buildSlotGrid` (UTC-якорь, шаг
  `SESSION_SLOT_STEP_MINUTES`), `fitsInterval({startsAt, minutes, advisorBusy, userBusy})`,
  `markAvailability`. Комментарий «rule 2: the grid is 24/7» — переписать.
- **Доступность:** `SessionsService.getAvailability` — `listAdvisorBusyWindows` + `listUserBusyWindows`
  → `markAvailability` и `instantAvailable`. Бронь и перенос — `requireBookableSlot` + транзакция с
  проверкой пересечения (`SlotTakenError` → 409 «That slot has just been taken»).
- **Таймзоны:** `src/common/time/zoned-date.ts` (`zonedDateKey`, `shiftDateKey`).
- **Онлайн:** `ChatwootClient` — `onlineAgentCount` (агенты `availability_status === 'online'` без
  служебного); `PresenceService` раздаёт одно значение на всех адвайзеров.
- **Агент-деск:** `src/modules/agent-desk/` — страница `GET /agent-desk`, API `agent-desk/api/*`, вход
  `POST agent-desk/api/session` (`AgentDeskAuthService`: devise-заголовки → `/api/v1/profile` → своя
  15-минутная сессия, `DeskAgent { agentId }`). Клиент — `client/desk.ts`, компилируется в `assets/`.
  `AGENT_DESK_FRAME_ANCESTOR` — CSP `frame-ancestors`.
- **Мост:** `deploy/chatwoot/install-agent-desk-bridge.rb` — `rails runner`, кладёт `<script>` между
  маркерами в `DASHBOARD_SCRIPTS`. Отвечает на `aura-desk:auth-request` **любому своему iframe** из
  `AGENT_DESK_ORIGINS` — значит iframe, вставленный самим скриптом, получает вход без изменений
  протокола. Одна установка Chatwoot на прод и dev (`AURAD-0016`, аккаунт на окружение) — пункт меню
  должен выбирать BFF по аккаунту из URL (`/app/accounts/:id/…`).
- **Chatwoot:** стоковый образ `chatwoot/chatwoot:v4.15.1`, своих коммитов в форке нет. Dashboard Apps —
  только `ConversationBox.vue`; сайдбар — `components-next/sidebar/Sidebar.vue`, SPA перерисовывает.
- **Бэкофис:** `src/modules/backoffice/` — страницы операторов (кампании, промокоды, отзывы).
