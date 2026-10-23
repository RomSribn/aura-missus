# AURAT-0121-004 — Context

Date: 2026-10-22

## Источники

- Хендофф: NAVIGATION §0, §2.1, §2.2, §2.3, §2.5, §3.1, §3.5, §5; README §3, §4.1, §4.4, §6, §8;
  прототип `web/web-funnel.jsx` (`FunnelMatched`, `Steps`, `QuoteCard`), `web/web.css` (≤ 760:
  `.aw-steps` скрыт, сетка 3 → 1), `web/web-auth.jsx` (ask: «Log in to send your question» /
  «We’ll match you with advisors right after.» / «See my matches»), `web/web-home.jsx` («Get
  matched»), `src/components/advisors/AdvisorCard.tsx` → `MatchCard`; `Aura Web - Mobile.html`
  («One card per row, Book session full width»).
- Brain: `AURAF-0020` строки 004, 012, 028 и Context; `AURAT-0112-005/006` (решения 2, 3, 11);
  `AURAT-0102-006` (онлайна нет); `AURAT-0107-006` (Book без поля вопроса).
- Код (`develop` `e20b3f0`), контракты `v0.23.0`, сид BFF.

## Как есть

- `router.tsx`: `{ path: ROUTES.match, element: null }`; `paths.match(q)` и `parseMatchSearch`
  в `shared/config/routes.ts` — без потребителей.
- `features/ask-question/model/use-ask-question.ts`: Ask / идея → `saveQuestion` (вкладка,
  30 мин) → `/advisors?cat=`; входа нет. Строки: eyebrow «Ask an advisor · free chat», lead «…ask
  them in a free chat.»
- `pages/advisors`: плашка вопроса «Pick an advisor and ask them in a free chat» с ×.
- `features/send-message/model/use-composer.ts`: первый чат берёт вопрос в поле и забывает его.
- `pages/home` «How Aura works» шаг 2: «Choose your advisor · …ask them in a free chat.»
- `shared/model/dialog.ts`: `AuthReason = 'book' | null`; `auth-by-phone` — строки `book` / `none`.
- Book открывается поверх любой страницы: `useOpenBookSheet` (`features/book-session`); URL
  `?book=1&slot=` пишет только на профиле.
- Booked: «{name} will be ready for you at the time you picked.» — вопроса нет.
- `shared/ui`: `CouponTicket`, `PriceTag` есть; иконка `sparkle` есть.

## Данные для подбора

- `POST /match` нет (BE ✗ строки 012). `Advisor`: `category` (LOVE / TAROT / PSYCHIC), `role`,
  `tagline`, `specialties[]` (английские строки сервера, профиль рисует их как есть),
  `ratingTenths`, `reviewsCount`, порядок каталога — серверный «Recommended»; `online` нет.
- Сид: 8 персон — LOVE 1 (marta), TAROT 2 (veronica, ivan), PSYCHIC 5. В теме Love своей
  категории меньше трёх — нужно правило добора. У ivan в specialties «Dating & relationships»,
  у sunshine — «Tarot».

## BookSessionRequest (v0.23.0)

`{ startsAt? | startNow: true, minutes, idempotencyKey }` — поля вопроса нет. Его вводит
`AURAT-0122` (BFF + contracts + доставка в Chatwoot); спеки 0122 в brain ещё нет.

## Противоречия

- Хендофф: вход перед `/match`, без free chat, вопрос в `?q=`. `AURAT-0112`: без входа, вопрос
  во вкладке → первый бесплатный чат. Владелец сейчас — за хендофф (кроме места хранения вопроса —
  решение спеки).
- Хендофф: «Online now», «No exact match online right now» — данных онлайна нет.
- Хендофф: заголовок входа «Log in to send your question» — до 0122 вопрос советнику не уходит.
