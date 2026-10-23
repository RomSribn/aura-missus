# AURAT-0121-005 — Spec: `/match` — шаг выбора советника в воронке Ask

Date: 2026-10-22
Type: task (строки `AURAF-0020-012` UI, `004` — причина `ask`, `028` UI; колонка UI). Новой фичи нет.
Status: одобрена 2026-10-22 (`006`) — рекомендации 1–10 + правки владельца 1–5 (внесены ниже)

## Цель

Воронка «Get started → Ask → вход → выбор советника → Book» — как экран «1 · Matched advisors»
хендоффа (NAVIGATION §2.2, README §3, §4.1): своя страница `/match`, три советника, первый —
**Best match** (при выбранной теме), на карточке **только Book session**, без бесплатного чата. Перед `/match` гость
входит с причиной `ask`. Вопрос уходит советнику вместе с бронью — когда `AURAT-0122` (BFF)
опубликует поле в `@aura/contracts`; до этого веб этого не обещает.

Задача в двух частях (решение 9):

- **Часть 1 — сейчас.** `/match`, вход `ask`, free chat уходит с пути Ask. BFF и contracts не
  меняются.
- **Часть 2 — после `AURAT-0122`.** Bump contracts, вопрос в Book и Booked, текст входа как в
  хендоффе. Отдельный мёрж той же задачи.

Решения 1–10 — в конце, у каждого рекомендация. «Что делаем» написано по рекомендациям.

## Что отменяется из `AURAT-0112` (решения владельца 2026-10-20)

| `AURAT-0112` | Было | Станет |
|---|---|---|
| Решение 2А | Ask без входа, причины `ask` нет | Ask → gate('ask') → `/match` (NAVIGATION §2.1, §3.5) |
| Решение 3Б | Вопрос во вкладке → плашка в каталоге «…ask them in a free chat» → поле первого бесплатного чата | Вопрос во вкладке → `/match` → (часть 2) бронь. Плашка в каталоге и подстановка в composer **удаляются** |
| Решение 11 | Тексты «match», «Get matched» не пишем | Возвращаются: lead Ask, «How Aura works», вход `ask` |
| §2 Ask | Ask / идея → `/advisors?cat=` | Ask / идея → `/match` |
| Правка 4 (`006`) | Eyebrow «Ask an advisor · free chat» | «Ask an advisor» (решение 7) |

Остаётся как было: место хранения вопроса — вкладка, не URL (решение 3); темы и идеи Ask;
Get started → `/#ask`. **Free chat остаётся везде, где он есть в хендоффе:** плитки Home и
каталога, профиль, чат, rail. Убирается он только с пути Ask.

## Что делаем — часть 1

### 1. Ask → вход → `/match` (`features/ask-question` + `pages/home`)

- **Что дальше — решает страница** (правка владельца 1; AskHero хендоффа: «The parent decides
  what happens next»). `useGate` живёт в `features/require-auth`, и из `features/ask-question`
  его брать нельзя (Steiger: feature → feature). Поэтому `features/ask-question` только собирает
  вопрос: поле, темы, идеи, Enter / Shift+Enter / IME, обрезка до 250 — и отдаёт
  `{ text, topic }` в `onAsk` от родителя. Ни навигации, ни gate, ни хранилища в фиче нет.
- `pages/home/model/use-home-page.ts`: `onAsk` сохраняет вопрос и тему во вкладке (§4) →
  `gate({ reason: 'ask', to: paths.match() })`. Вошедший с именем — сразу на `/match`; гость —
  AuthFlow; вошедший без имени — шаг имени (как сейчас у `book`). Сборка без Firebase — сразу на
  `/match` (как `useGate` сейчас).
- Поле Ask при открытии Home берёт сохранённый вопрос и тему — страница передаёт их в AskHero
  как начальное значение (так работают ← Home и Edit с `/match`, NAVIGATION §2.2).
- «Finding advisors…» и искусственной задержки нет: каталог обычно уже в кэше после Home, иначе
  `/match` рисует скелетоны (решение 8).

### 2. Вход с причиной `ask` (`shared/model/dialog.ts`, `features/auth-by-phone`)

- `AuthReason = 'ask' | 'book' | null`; `authDialogParams` понимает `ask`.
- Строки (решение 6): заголовок «Log in to see your matches», подзаголовок «We’ll match you with
  advisors right after.», последняя кнопка шага имени «See my matches». Купон на шаге телефона —
  как у других причин. В части 2 заголовок становится хендоффовым «Log in to send your question».
- Resume — на `/match` (тот же механизм `to`, переживает перезагрузку, `sessionStorage` 15 мин).

### 3. Страница `/match` (`pages/match`, новая)

**Desktop (≥ 761)**, по `FunnelMatched`:

- строка: «← Home» (coral) слева, шаги справа: ✓ Your question → **2 Choose advisor** → 3 Book →
  4 Pay (пройденный — teal с галкой, текущий — coral, дальше — серые; решение 10);
- ряд: карточка вопроса (`QuestionCard` из `entities/session`, §4; иконка chat, eyebrow «Your
  question», текст вопроса в кавычках крупно, действие — ссылка **Edit**) + `CouponTicket` справа (только при активном оффере, иначе вопрос во всю ширину);
- заголовок «{n} advisors for your question» (плюралы) и подзаголовок по теме (решение 2);
- три `MatchCard` в ряд (3-up);
- внизу: «Not quite right? **Browse all {n} advisors →**» → `/advisors` (n — размер каталога).

**Телефон (≤ 760):** шагов нет (как прототип), вопрос и купон столбиком, одна карточка в ряд,
Book session во всю ширину. Таб-бар — как на Home, активен Home (решение 10).

**MatchCard** (`pages/match/ui`, по `MatchCard` хендоффа): фото во всю ширину; бейдж **Best
match** (coral) и coral-рамка 1.5 px — у первой карточки **только при выбранной теме** (правка
владельца 5; без темы подбора нет — три карточки без бейджа); имя, рейтинг ★ (n отзывов), tagline; teal-тег с
`sparkle` — причина подбора (решение 1); низ: `PriceTag` /min (зачёркнутая + офферная при
оффере, иначе обычная), кнопка **Book session** (coral, иконка календаря). **Free chat нет.**
Онлайн-точки нет (`AURAT-0102-006`). Тело карточки → `/advisors/:id`.

**Действия:**

| Элемент | Действие |
|---|---|
| ← Home, Edit | → `/` с вопросом и темой в поле Ask |
| Тело карточки | → `/advisors/:id` (там Free chat есть — как в хендоффе) |
| **Book session** | вошедший — шторка Book поверх `/match` (`useOpenBookSheet`); гость (пришёл по ссылке или вышел) — gate('book') → `/advisors/:id?book=1`, как плитка каталога |
| Browse all advisors | → `/advisors` |

**Состояния:**

- нет сохранённого вопроса (новая вкладка, прошло 30 мин, прямой заход) → `replace` на `/#ask`;
- каталог грузится — три скелетона карточек; ошибка — `EmptyState` small с Try again (как
  каталог);
- каталог пуст — `EmptyState` «No advisors available right now» + «Back to Home» (решение 5);
- в каталоге меньше трёх — сколько есть, заголовок по числу.

**Без** «Online now», «No exact match online right now» и «Your advisors are offline» — данных
онлайна нет (решение 5).

### 4. Вопрос во вкладке и его карточка (`entities/session`, решение 3)

- Хранилище **переезжает из `entities/message` в `entities/session`** (правка владельца 4): чат
  его больше не читает, а вопрос — это вопрос брони (`Session.question`, `AURAT-0122`). Читают
  его страницы Home и `/match`, в части 2 — шторка Book (`widgets/book-sheet`) и бронь.
- Хранится `{ text, topic, savedAt }` (тема добавляется; `topic` — `AdvisorCategory | null`),
  тот же ключ, 30 мин, битое значение — «нет вопроса»; старая запись без темы читается с
  `topic: null`.
- **`QuestionCard`** — сразу в `entities/session/ui` (правка владельца 4: в части 2 она нужна
  шторке Book, widget; кладём в нижний слой с первого раза, чтобы не переносить): eyebrow «Your
  question», текст, подпись (необязательна) и слот действия справа (`/match` — Edit, Book в
  части 2 — ×). Варианты `large` (`/match`) и `small` (Book) — как `QuoteCard` прототипа.
  Строки — в namespace `session` (`entities/session/config/locales`).
- Не в URL: `paths.match()` — без `?q=`; `MatchSearch` / `parseMatchSearch` удаляются (без
  потребителей — правило 5).
- Плашка вопроса в каталоге (`pages/advisors`) и подстановка в composer (`features/send-message`)
  удаляются со строками на всех 24 языках.

### 5. Подбор — `pages/match/lib/match-advisors.ts` (+ тест, решение 1)

Чистая функция `(advisors в порядке сервера, topic) → [{ advisor, reason }]`, не больше 3:

1. **Тема выбрана.** Сначала советники этой категории в порядке сервера — причина
   «Specialises in {topic}».
2. Не хватает до трёх — советники других категорий, у которых тема есть в `specialties`
   (таблица слов в `config/match.ts`: LOVE — love, relationship, breakup, reconciliation,
   soulmate, dating; TAROT — tarot, card; PSYCHIC — psychic, clairvoyan, medium, channel;
   без учёта регистра; `specialties` сервера — английские) — причина «Also reads {topic}».
3. Всё ещё не хватает — остальные в порядке сервера — причина по их категории «Specialises in
   {category}».
4. **Темы нет (All)** — первые три в порядке сервера, причина по их категории.

Best match — первая карточка, **только при выбранной теме** (п. 1–3); без темы (п. 4) бейджа
нет (правка владельца 5). Причина «под текст вопроса» не выдумывается: каждая причина —
факт из данных каталога. Сид сегодня даёт: Love — Marta, Olivia («Love & relationships»), Ivan
(«Dating & relationships»); Tarot — Veronica, Ivan, Sunshine («Tarot»); Psychic — первые три
психиков по порядку (Olivia, Sunshine, May); без темы — Olivia, Sunshine, Veronica.

### 6. Тексты Home (решение 7)

- Ask: eyebrow «Ask an advisor»; lead — хендофф «Write your question — we’ll match you with
  advisors who specialise in it.»
- «How Aura works», шаг 2: «Get matched» — «Advisors who specialise in your topic, picked for
  you.» (хендофф без «online now»). Шаги 1 и 3 — как есть.

### 7. Строки

Новый namespace `match-page` (`pages/match`); строки `QuestionCard` — в `entities/session`;
правки — `ask-question` (eyebrow, lead),
`home-page` (шаг 2), `auth-by-phone` (`ask`), удаление — `advisors-page` (плашка вопроса).
Всё на 24 языках сразу (правило 9), плюралы «{n} advisors» — по языку.

### 8. Маршрут и FSD

- `router.tsx`: `{ path: ROUTES.match, element: <MatchPage /> }`.
- `pages/match`: `ui/match-page.tsx`, `ui/match-card.tsx` (`React.memo`, стабильный
  обработчик), `ui/funnel-steps.tsx` (+ `.module.css`, всё на токенах);
  `model/use-match-page.ts` (вопрос, каталог, оффер, Book с gate, редирект без вопроса);
  `lib/match-advisors.ts`; `config/match.ts` (3 карточки, таблица слов); `config/locales/*`.
- `pages/home`: модель получает `onAsk` (сохранить → gate) и начальный вопрос для AskHero.
- `features/ask-question`: `useAskQuestion({ initial, onAsk })` — без `useNavigate`,
  `saveQuestion` и `paths.advisors`.
- `entities/session`: `model/question-draft.ts` (+ `lib/question.ts`, тест) — из
  `entities/message`; `ui/question-card.tsx`. Из `entities/message` экспорт вопроса уходит.
- Шаги воронки живут в `pages/match`, пока их рисует одна страница (поднимем в `shared/ui`,
  когда понадобятся второй — правило 3).

### 9. Тесты (Vitest)

- `match-advisors`: тема со своими ≥ 3; добор по specialties; добор по порядку; без темы —
  без Best match; каталог < 3 и пустой; регистр слов.
- хранилище вопроса: тема пишется и читается, старый формат без темы — читается с `null`,
  истёкший и битый — нет вопроса.
- Ask (`useAskQuestion`): `onAsk` получает обрезанный текст и тему, идея — свою тему; пустое /
  Shift+Enter / IME — нет вызова. Home: гость → вход с причиной `ask`, после входа `/match`;
  вошедший → сразу `/match`; вопрос не в URL.
- `/match`: три карточки, с темой первая — Best match, без темы бейджа нет; причины; **нет кнопки Free chat**; Book вошедшего
  открывает шторку над `/match`, гостя — вход; Edit / ← Home → поле Ask заполнено; без вопроса →
  `/#ask`; без оффера — купона нет, цены обычные; загрузка, ошибка, пустой каталог.
- Каталог без плашки вопроса; первый чат после Ask — поле пустое.
- `npm run lint && npm run typecheck && npm test && npm run build` — зелёные.

### 10. Проверка в маноре (после merge, против bff-dev)

Гость: `/` → Get started → вопрос + Love → Ask → вход «Log in to see your matches» → (новый)
имя → «See my matches» → `/match`: шаги, вопрос + купон −50 %, 3 советника, Marta — Best match,
причины; Ask без темы — три карточки без бейджа; зачёркнутые цены, Book session — **нет** Free chat. Book → шторка → оплата → Booked.
Edit → Home с вопросом. Browse all → каталог без плашки. Идея Tarot → свои советники.
Телефон 390: одна колонка, без шагов, Book во всю ширину. Вошедший: Ask → сразу `/match`.

## Что делаем — часть 2 (после `AURAT-0122`)

Начинается, когда `AURAT-0122` выпустит `@aura/contracts` `v0.24.0` и BFF с ним будет на bff-dev
(её §6: старый BFF принял бы бронь и молча выбросил вопрос). До этого в вебе нет ни карточки
вопроса в Book, ни обещания, что вопрос у советника.

1. Bump `@aura/contracts` до `v0.24.0` — своим коммитом.
2. Шторка Book (NAVIGATION §2.3): если во вкладке есть вопрос — `QuestionCard` (small) с подписью
   **«Shared with {name}»** (хендофф; правка владельца 2 — чаттер получает вопрос заметкой сразу
   при брони и ещё раз на старте, `AURAT-0122-005` §3) и × (убрать из брони) (решение 4). Вопрос
   уходит полем `question` в `POST /v1/advisors/:id/sessions` под тем же ключом попытки (и для
   слота, и для «Now»); после подтверждённой брони — забывается во вкладке.
3. Booked (NAVIGATION §2.5): «{name} has your question and will prepare for your session.» — по
   `Session.question` из ответа сервера (не по вкладке); `null` — текст как сейчас.
4. Вход `ask`: заголовок — «Log in to send your question» (хендофф).
5. Строки — 24 языка. Тесты: `question` в теле брони; без вопроса поля нет; повтор тем же ключом с
   тем же вопросом; × убирает; Booked по `Session.question` (строка / `null` / ответ без поля).

### Что даёт `AURAT-0122` (одобренная `AURAT-0122-005` / `006`, сверено)

- Запрос: `BookSessionRequest.question: z.string().trim().max(250).optional()` — отсутствие,
  `""` и одни пробелы = «вопроса нет» (не 400); 251+ после trim — 400. Веб шлёт поле, только
  когда вопрос есть (его `QUESTION_MAX_LENGTH` = 250 — тот же лимит).
- Ответ: `Session.question: z.string().nullable().default(null)` — **необязателен на проводе**,
  после разбора всегда `string | null`; отдаётся везде, где `Session` (бронь, перенос, продление,
  `GET /v1/sessions`, `/:id`, `active`, `session.updated`).
- Повтор с тем же `idempotencyKey` — исходная сессия с исходным вопросом; вопрос повтора не
  сравнивается и не перезаписывает.
- Чаттер видит вопрос только приватной заметкой в Chatwoot: при брони (`booked`) и на старте
  (`started`; у «Now» — только она). В тред человека вопрос не попадает — поэтому подстановка в
  composer из `AURAT-0112` и не нужна.
- Вопрос после брони не меняется; при удалении аккаунта стирается.
- Вне части 2 (по желанию владельца — отдельно): строка «Question» в детали `/sessions` —
  `AURAT-0122-005` §1 называет её потребителем `Session.question`, но в одобренный объём
  `AURAT-0121` она не входила.

## Решения (владельцу)

**1. Правило подбора и причина.** Сервера подбора нет, онлайна нет.
- А. **Категория → добор по `specialties` → добор по порядку сервера** (§5); причина — факт
  каталога: «Specialises in {topic}» / «Also reads {topic}».
- Б. Только категория, без добора: в Love сегодня будет одна карточка.
- В. Сортировка по рейтингу внутри темы вместо порядка сервера.
- **Рекомендация: А.** Б оставляет Love с одной карточкой (сид: 1 советник LOVE); В спорит с
  «Recommended» каталога и «Top advisors» Home. Причины — только то, что правда в данных.

**2. Подзаголовок под «3 advisors for your question».** В хендоффе — «Online now · specialise
in …».
- **Рекомендация:** с темой — «Advisors who specialise in {topic} come first.»; без темы — «Pick
  a topic with your question for a closer match.»

**3. Вопрос в URL или во вкладке.**
- А. **Во вкладке, как сейчас** (`AURAT-0112` §3): `/match` без параметров, переживает
  перезагрузку, не попадает в адресную строку, историю, `Referer`, логи.
- Б. Как хендофф: `/match?q=…` (ссылкой можно поделиться, текст вопроса в истории браузера).
- **Рекомендация: А.** Вопрос личный («Does he still think about me?»); делиться ссылкой на чужой
  подбор незачем. Прямой заход на `/match` без вопроса → поле Ask.

**4. Где в Book виден вопрос (часть 2).**
- А. **В любой шторке Book, пока вопрос во вкладке (30 мин)**, с × — NAVIGATION §2.3 «question
  card (if there is a question)».
- Б. Только в Book, открытой с `/match`.
- **Рекомендация: А** — человек может уйти в «Browse all» и забронировать из профиля; вопрос
  тот же. × снимает его, если бронь про другое.

**5. Пустые состояния.** «No exact match online» хендоффа держится на онлайне, которого нет.
- **Рекомендация:** при непустом каталоге пустого состояния нет (правило §5 всегда даёт до трёх);
  пустой каталог — «No advisors available right now» + «Back to Home»; ошибка — Try again.

**6. Заголовок входа до части 2.** «Log in to send your question» обещает, что вопрос уйдёт.
- А. **«Log in to see your matches»** до части 2, затем хендофф.
- Б. Сразу хендофф.
- **Рекомендация: А** — без 0122 вопрос советнику не уходит. Цена: один ключ переводится дважды.

**7. Тексты Ask.** Ask больше не ведёт в бесплатный чат.
- **Рекомендация:** eyebrow «Ask an advisor» (без «free chat» — на этом пути его нет), lead и
  шаг 2 «How Aura works» — хендофф без «online now» (§6).

**8. «Finding advisors…».**
- **Рекомендация:** не рисовать и не задерживать: Ask синхронный, пока каталог грузится — скелетоны
  на `/match`.

**9. Порядок частей.**
- А. **Часть 1 мёржится сейчас, часть 2 — после `AURAT-0122`**, в той же задаче.
- Б. Ждать 0122 и мёржить всё вместе.
- **Рекомендация: А.** Владелец видит воронку по дизайну без ожидания BFF; часть 2 — маленькая
  (Book, Booked, текст входа).

**10. Шаги и таб-бар.**
- **Рекомендация:** шаги — только desktop (на телефоне их нет и в прототипе); на `/match` таб-бар
  есть, в верхнем меню и таб-баре активен Home (прототип: `WebNav active="home"`).

## Вне задачи

Аналитика (`match_view`, `match_book`), вопрос в `/sessions`, серверный подбор (`POST /match`, BE строки 012), онлайн,
шаги на шторке Book / `/checkout`, приложение.

## После задачи (brain)

`AURAF-0020`: строка 012 — UI ✓ (подбор на клиенте, BE ✗ остаётся); 004 — пометка «Ask — с входом
`ask` (`AURAT-0121`, отменяет `AURAT-0112` реш. 2)»; 028 — UI ✓ после части 2. В Context — абзац
`AURAT-0121` со списком отменённого из `AURAT-0112`.
