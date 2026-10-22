# AURAT-0121-007 — Execute (часть 1)

Date: 2026-10-22
Ветка: `feature/AURAT-0121-web-match` (aura-web от `develop` `e20b3f0`). Не закоммичено — на ревью.

## Сделано

**Ask → вход `ask` → `/match`** (`005` §1–§2):
- `features/ask-question`: `useAskQuestion({ initial, onAsk })` — только собирает вопрос (поле,
  темы, идеи, Enter / Shift+Enter / IME, 250); ни навигации, ни gate, ни хранилища. `AskHero`
  получает `initial` и `onAsk` от страницы (правка владельца 1).
- `pages/home/model/use-home-page.ts`: `onAsk` → `saveQuestion` → `gate({ reason: 'ask', to:
  paths.match() })`; начальный вопрос для поля — из вкладки.
- `shared/model/dialog.ts`: `AuthReason = 'ask' | 'book' | null`; `pending-sign-in` понимает `ask`.
- `auth-by-phone`: `title.ask` «Log in to see your matches», `sub.ask` «We’ll match you with
  advisors right after.», `name.continue.ask` «See my matches».

**`/match`** — `pages/match` (новый слайс):
- `ui/match-page.tsx` — ← Home, `FunnelSteps` (только desktop), `QuestionCard` с Edit (→ `/#ask`) +
  `CouponTicket`, заголовок «{n} advisors for your question» и подзаголовок по теме, карточки,
  «Not quite right? Browse all {n} advisors →»; скелетоны / ошибка с Try again / пустой каталог.
- `ui/match-card.tsx` — `MatchCard` (`memo`): фото, имя → профиль, рейтинг, tagline, teal-причина,
  `PriceTag` /min, **Book session** (имя для скринридера — «Book a session with {name}»). Free chat
  нет. Best match — первая карточка только при теме (правка 5).
- `ui/funnel-steps.tsx` — шаги, текущий `aria-current="step"`.
- `model/use-match-page.ts` — вопрос из вкладки (нет — `replace` на `/#ask`), каталог, оффер,
  Book: вошедший — шторка Book поверх `/match`, гость — gate('book') → профиль `?book=1`.
- `lib/match-advisors.ts` (+ тест) — подбор §5; `config/match.ts` — 3 карточки, слова тем, шаги.
- Router: `/match` → `MatchPage`, `handle.tab = 'home'` — в меню и таб-баре активен Home
  (`navTabOf` в `route-handle.ts`).

**Вопрос — в `entities/session`** (правка 4): `model/question-draft.ts`, `lib/question.ts` (+ тест),
`config/question.ts` перенесены из `entities/message`; хранится `{ text, topic, savedAt }`, старая
запись без темы читается с `topic: null`. `ui/question-card.tsx` — `QuestionCard` (строки
`session:question.*` — перенесены из `advisors-page` вместе с переводами). Экспорт: `loadQuestion`,
`saveQuestion`, `AskedQuestion`, `QuestionCard`.

**Убрано** (отмена `AURAT-0112` 2А / 3Б): плашка вопроса в каталоге (модель, разметка, CSS, строки
`advisors-page:question.*`), подстановка вопроса в composer (`use-composer`), `paths.match(q)` →
`paths.match()`, `MatchSearch` / `parseMatchSearch`.

**Тексты Home:** eyebrow Ask «Ask an advisor», lead «Write your question — we’ll match you with
advisors who specialise in it.», «How Aura works» шаг 2 — `how.match` «Get matched» / «Advisors who
specialise in your topic, picked for you.»

**Строки:** новый namespace `match-page` (+ `app/config/i18n.ts`, `vitest.setup.ts`); все правки —
на 24 языках (en + 23). Плюралы — по категориям языка; где согласование числа сложное (cs, et, fi,
ga, hr, hu, lt, lv, mt, pl, sk, sl) «Browse all» — «… ({{count}})»; в ga и mt заголовок — «…: {{count}}».
Back, loading, error и «Your question» — те же переводы, что уже есть в `app` / `advisors-page`.

**Тесты:** `match-advisors` (5), хранилище вопроса (5), `home.test` — блок «Ask → the matches» (10:
гость → вход `ask`, вопрос не в URL; вошедший → `/match`, порядок, причины, Best match, без Chat
free; Enter / Shift+Enter; идея; без темы без бейджа; Book → шторка над `/match`; гость → вход
`book`; Edit → поле с вопросом и темой; без вопроса → `/`; каталог без плашки), `auth-dialog`
(`ask` — заголовок и «See my matches»), `pending-sign-in` (`ask`), `routes` — без `?q=`.

## Проверки

`npm run lint` (eslint + Steiger) — без замечаний; `npm run typecheck` — чисто; `npm test` — 80 файлов,
1378 тестов, все зелёные; `npm run build` — собран. Живая проверка — в маноре после мёржа (`005` §10).

## Открыто

- Часть 2 — после `AURAT-0122` (`@aura/contracts` `v0.24.0` на bff-dev).
- Контраст teal-тега причины (teal на teal-soft) — как у остальных teal-тегов веба, не менялся.
