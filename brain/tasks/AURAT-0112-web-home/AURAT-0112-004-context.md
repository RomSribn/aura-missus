# AURAT-0112-004 — Context

Date: 2026-10-20

## Источники

- Веб-хендофф: README §3 (Home: Ask 50 % + правая колонка, Daily Card, Online now 5-up, Ask about;
  гостю — «How Aura works»), §4.1, §5–§7; NAVIGATION §1.1 (Get started — без модалки: прокрутка к
  Ask, фокус, coral-кольцо 1.4 с), §2.1 (click map главной), §3.1, §4; STRUCTURE (HomeA →
  `features/home/HomePage`); `src/components/home/AskHero.tsx`; прототип `web/web-home.jsx` (HomeA,
  HomeMobile), `web/web-kit.jsx` (AskHero, NextSession, RecentChats, DailyBanner, AdvisorTile).
- Приложение (`screens/home`, разбор агентом): гостя нет; блоки — дата, «Hi, {name}» / «Hi there»
  (не по времени суток), баннер карты дня, гороскоп, **«Top advisors» — первые 3 каталога в порядке
  сервера**, «Continue your chat» (последний тред). **Ask, тем, ближайшей сессии, оффера на главной
  нет**; аналитики нет.
- Контракты v0.22.0: `AdvisorCategory = LOVE | TAROT | PSYCHIC` (Dreams нет намеренно); у `Advisor`
  нет `online` (presence — по WS); `GET /v1/sessions` — все сессии человека, новые `startsAt`
  сверху, Upcoming = `SCHEDULED` + `ACTIVE`.
- `AURAT-0102-006`: онлайн-точку гостю не показываем; вошедший — по WS. В вебе presence приходит
  только по советникам, с которыми есть разговор (`useAdvisorOnline`, `AURAT-0105-005` §2).
- `AURAT-0104-006` §2: Get started — с задачей Home; тест `app-shell` «Get started waits for Home».
- `AURAT-0107-006` §10: поля вопроса в брони нет (строка 028).

## Код aura-web (develop `79bf311`)

- `/` и `/match` — `element: null` в `router.tsx`; `pages/home` нет.
- Есть и переиспользуется: `useViewer` (имя), `useAuthStatus`, `useAdvisors` (каталог в кэше),
  `AdvisorTile`/`AdvisorRow`, `CouponTicket`, `useBookingOffer` (`features/book-session`: оффер
  вошедшего из кошелька, гостя — из pricing), `useConversations` + `ConversationList` (история по
  каждому советнику каталога), `EmptyState`, `Orb`, `useGate` (`gate`, `gateLink`), `paths`,
  `QUESTION_MAX_LENGTH = 250`, `parseMatchSearch`.
- `TileActions` + `onTileLink` (Chat free / Book с gate) — внутри `pages/advisors`; у главной —
  второй потребитель.
- `AuthReason = 'book' | null` — `ask` нет.
- Сессии: только `getSession` (поиск по id в `GET /v1/sessions`, кэш на id); списка и тега
  `Sessions` нет — вводит та задача из `AURAT-0110` / `AURAT-0112`, что влита первой.
- `node_modules` в slave-3 нет.

## Противоречия

- Хендофф: Ask → gate('ask') → `/match` (три советника, «Get matched»); в v1 `/match` нет (BE ✗),
  сопоставления «вопрос → категория» нет нигде. Тексты «we'll match you», «Get matched», «Finding
  advisors…» в v1 ложны.
- Хендофф: «Online now» (5-up); онлайна в каталоге нет, гостю он запрещён; приложение на этом месте
  — «Top advisors».
- Хендофф: «Ask about» — 4 темы (Love, Career, Dreams, Future); категорий три.
- Хендофф: Daily Card banner; карта дня — этап 2 (строка 013), кнопка без цели — против правила 5.
- Хендофф: «Good evening, {name}» (по времени суток) vs приложение «Hi, {name}».
- NextSession хендоффа — Reschedule / Details: перенос — строка 009, `/sessions` — `AURAT-0110`.

Дальше: spec.
