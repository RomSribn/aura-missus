# AURAT-0112-007 — Execute

Date: 2026-10-20
Ветка `feature/AURAT-0112-web-home` (slave-3). Изменения проиндексированы, не закоммичены — на
просмотр владельцу.

## Сделано (по спеке `005` и правкам `006`)

- **`pages/home`** (новый): `HomePage` — дата и приветствие по часу (`lib/greeting`, с тестом),
  Ask + купон + «How Aura works» / ближайшая сессия и два свежих чата, «Top advisors» (5 на
  широком экране, 4 до 1180 px, 2-up на телефоне), «Ask about» (три категории, счётчик по каталогу,
  тема без советников не рисуется). `model/use-home-page` собирает всё из уже существующих
  запросов. Правый стек: скелетон, пока не известно, кто это и что у него есть; «How Aura works» —
  гостю и вошедшему без сессий и чатов. Карточка сессии ведёт в чат с советником.
- **`features/ask-question`** (новый): `AskHero` + `useAskQuestion` — поле (250), темы `All · Love
  · Tarot · Psychic` (необязательны), Ask (Enter; Shift+Enter и IME — нет), 4 идеи с темой (на
  телефоне — первые три: LOVE, TAROT, PSYCHIC). Ask → вопрос во вкладку → `/advisors?cat=`. Входа
  не просит. `/#ask` → прокрутка (без анимации при reduced motion), фокус, coral-кольцо 1.4 с
  (CSS, снимается по `animationend` — таймера нет), якорь убирается `replace`.
  Отличие от спеки §6: фокус живёт в фиче (у неё ref поля), а не в `pages/home/model`.
- **Вопрос → чат** (`entities/message`): `question-draft` (`sessionStorage`, TTL 30 мин,
  `lib/question` с тестом); каталог показывает «Your question · “…”» с ×; `useComposer` берёт
  вопрос в поле первого открытого чата и забывает его (не отправляет).
- **`widgets/advisor-card`** (новый): плитка/строка с Chat free / Book и gate — поднята из
  `pages/advisors` (второй потребитель — главная); строки `actions.*` переехали в `advisor-card`.
- **`entities/session`**: `getSessions` (`GET /v1/sessions`, тег `Sessions`, бронь его
  инвалидирует), `lib/next-session` (ACTIVE первым, иначе ближайшая SCHEDULED впереди; тест),
  `useNextSession` (404 и ошибки — «нет сессии»).
- **Шапка**: Get started гостю (ссылка `/#ask`, рядом с Log in; без Firebase-ключей — только он).
- **shared**: `Chip` (визуал чипа категорий — второй потребитель), `ASK_ANCHOR`,
  `paths.home({ ask })`, `formatMonthShort`, `formatDaysAway` (`Intl.RelativeTimeFormat`),
  `REDUCED_MOTION_QUERY` (перенесён из `tarot-pick` — второй потребитель), токены `--ring-accent`,
  `--dur-ring`.
- Подписи категорий (`All/Love/Tarot/Psychic`) перенесены из `advisor-filters` в `advisor`
  (три потребителя), во всех 24 языках.
- Строки: новые namespace `home-page`, `ask-question`, `advisor-card`; дополнения `app`
  (`nav.getStarted`), `advisors` (`question.*`) — все 24 языка. Тексты по правкам владельца:
  eyebrow «Ask an advisor · free chat», в «How Aura works» нет ни «Verified», ни «encrypted»
  («Private one-to-one chats»).
- Тесты: `home.test.tsx` (13: гость, вошедший, ACTIVE, пусто → How, без биллинга, Ask с темой /
  Enter / идея, вопрос в composer без отправки, Get started), `app-shell` (Get started → `/#ask`),
  `dates`, `routes`, `question`, `next-session`, `greeting`; мок `composer.test`.

## Проверки

- `npm run lint` (eslint + steiger) — чисто; `npm run typecheck` — чисто; `npm run build` — ок;
  `prettier --check .` — чисто.
- `npm test`: 975 / 976. Падает `advisors.test.tsx` → «profile … the next 4 slots» — **не из-за
  задачи**: тест зависит от часа (слот `inHours(26)` после ~21:00 уходит на послезавтра и теряет
  подпись «Today/Tomorrow»); профиль задача не трогала. Плавающая ошибка jsdom после teardown
  (`requestAnimationFrame`) всплывает в разных файлах (`chat-sync`, `app-shell`, `tarot-picker`) —
  тоже не связана. Под нагрузкой один прогон дал таймауты в `booking`/`chats` — повтор зелёный.

## Brain

- `AURAF-0020` Context: абзац о главной (`AURAT-0112`) и фраза про ближайшую сессию из всего
  списка (без строки бэклога — владелец `006`). Строка 012 остаётся ✗ (нет `/match`).

## Открыто

- Проверка в маноре после merge (сценарии — `005`, «Проверка в маноре»).
- Плавающий тест профиля — не в этой задаче; можно поправить отдельно (часы в тесте).
