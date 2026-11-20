# AURAT-0090-004 — Контекст

Дата: 2026-11-20. Код приложения — `aura-app` `develop` `6b429d2`; BFF — `develop` `ffb3c58` (прод с
2026-11-18), только чтение.

## Лимитер BFF
- `src/app.setup.ts:29` — `@fastify/rate-limit` `{ max: 120, timeWindow: '1 minute' }`, глобально,
  ключ — `req.ip` (`trustProxy: 1`, `fastify.options.ts`). Бюджет — **на IP**, не на человека.
- 129 отказов за одну минуту значат, что с этого IP за ту минуту ушло ≈ 250 запросов. Один телефон
  даёт столько только при многих выходах на передний план подряд — **или** за одним IP (CGNAT
  мобильного оператора) сидят несколько человек. Из кода не различить: нужен разбор логов той
  минуты по IP / uid (в спеке — вопрос к манору).

## Веер 1 — активные сессии
- `features/paid-session/model/use-active-sessions.ts`: `fetchActiveSession(advisorId)` на каждый
  тред с сообщениями (`Object.keys(threads)` в `screens/chats/model/use-chats.ts`). Повод: маунт,
  каждый `useFocusEffect` вкладки чатов, каждый `AppState → active`. Дубли гасит только
  `inFlightFor` (пока тот же список в полёте).
- Комментарий «BFF has no sessions-list read» устарел: `GET /v1/sessions` (BFF
  `sessions.controller.ts`) — все сессии пользователя по всем советникам, `startsAt desc`, предел
  `SESSIONS_PAGE_LIMIT = 100`, за тем же `BillingEnabledGuard` (404 при выключенном биллинге — та же
  ветка `serverEnabled`). `Session` в контракте несёт `advisorId` и `status`; `getActive` в BFF —
  это `status: 'ACTIVE'` по диалогу, то есть ровно то же, что `status === 'ACTIVE'` в списке.
  В приложении уже есть `fetchSessions()` (`entities/session`), его зовут экраны Sessions,
  Session detail, Reschedule.
- Предел 100: активная сессия имеет `startsAt ≤ now`, раньше неё в списке только будущие брони
  (окно 14 дней, свои окна не пересекаются). Вытеснить её могут лишь ≥ 100 будущих броней — на
  практике не бывает. **Нового эндпоинта не нужно.**

## Веер 2 — история чатов (больше первого: 74 из 136)
- `features/chat/model/ChatProvider.tsx`: `syncAllThreads` — `syncThread` на **каждого советника
  каталога** (8), даже без диалога (BFF отвечает пустой страницей, но запрос и бюджет тратятся).
  Причина та же — нет `GET /v1/conversations` (BFF `TECH-DEBT #12`).
- `syncThread` не проверяет, идёт ли уже чтение этого треда — каждый вызов = новый запрос.
- Поводы sweep'а:
  - старт с восстановленной сессией: эффект `userUid` (строка ~789) + эффект «каталог приехал»
    (~762) + `socket.onOpen` (~797) — до **3 sweep'ов = 24** запроса;
  - каждый выход на передний план: `AppState → active` зовёт `syncAllThreads` напрямую (~849)
    **и** `socket.start()`, чей `onOpen` зовёт его ещё раз — **2 sweep'а = 16** запросов;
  - каждый реконнект сокета — ещё sweep.
- Плюс к этому `AppState → active` в `use-active-sessions` — ещё до 8. Итого **≈ 24 запроса на
  каждый выход на передний план** при 8 тредах; 5 возвратов в минуту — и лимит исчерпан.
- Раунды `deletedFrom` / `translatedFrom` догоняют лишь при полной странице — в норме их нет.

## Обработка 429 сейчас
- `shared/api/bff/http-client.ts` → `BffApiError(429, code, retryAfterSeconds)`, повтора нет.
  `Retry-After` читается (промокоды, `AURAT-0143`). История ловит ошибку молча (`firstSync:
  'failed'`), активные сессии — «нет пилюли»; экран брони / кошелёк показывают ошибку.

## BFF для варианта со списком диалогов
- `ConversationsRepository.listAdvisorIdsByUser` уже есть (`AURAT-0009`, для presence); эндпоинта
  нет сознательно — его форма «решение, совместное с вкладкой чатов» (TECH-DEBT #12).
- `findConversation` по (user, advisor) — это и есть то, что сейчас 8 раз делает sweep.

## Противоречий нет
001 предлагал новый `GET /v1/sessions/active` — не нужен, хватает существующего списка.
