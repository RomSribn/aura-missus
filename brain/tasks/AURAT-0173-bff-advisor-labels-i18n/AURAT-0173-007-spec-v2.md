# AURAT-0173-007 — spec v2: тип и специализации советника на языке запроса

Дата: 2026-11-07 · Статус: **draft — ждёт одобрения владельца**
Заменяет `005-spec.md`: решения владельца 1А / 2А / 3А и 8 замечаний ревью (`006-review.md`).
Фича: `AURAF-0023` строка 011 (часть «подписи советников») · Образец: `AURAT-0171` · Резолвер: `AURAT-0168-007` §2.
Репо: `aura-bff` + `aura-contracts` (§6). Цифры и места в коде — `004-context.md`.

## Что получится

- `GET /v1/advisors?lang=de` → у каждого советника `role` и `specialties` по-немецки (Olivia — «Hellseherin · Medium»,
  Ivan — «Astrologe · Kartenleger»; примеры, окончательные слова — в переводе). `name`, `tagline`, `bio`, `greeting`,
  цена, рейтинг, отзывы — без изменений (слоган / био / приветствие ждут решения 8).
- Новое поле `topics: AdvisorCategory[]` — темы, на которые советник читает по своим специализациям, **без языка**
  (решение 4). Для подбора на вебе.
- Без `lang`, с неизвестным кодом, `DE`, двумя `lang` или выключенным языком — английский.
- **Клиенты уже шлют `?lang`** (приложение — `0169`, веб — `0170`). Поэтому выкатка сервера сразу переводит подписи
  на вебе и в приложении при включённом флаге языков. Кэш каталога у обоих клиентов язык не учитывает — см. §8
  «Порядок выкатки».
- Чаттеры видят английский: атрибут Chatwoot `advisor_role` и профиль советника в desk.

## 1. Словарь терминов (решение 2 — А)

- `role` в данных и в базе — одна строка («Psychic Reader · Medium»). При сборке ответа режется по « · », каждый
  термин переводится, собирается через « · ». `specialties` — по элементу.
- Ключ — английский термин ровно как в сиде. Английские списки — константы `ADVISOR_ROLE_TERMS` (10) и
  `ADVISOR_SPECIALTY_TERMS` (34); языковой файл — `Record` по ним: забытый термин не соберётся. Правка английского
  термина = новый ключ, поэтому отпечатки, как в колоде, не нужны.
- Каждая специализация в английском словаре несёт свои темы: `{ topics: AdvisorCategory[] }` (§5).
- Термин без перевода во время работы (советник, добавленный в обход сида) — английский; ответ не ломается.
  Страховка, не план: тест не выпустит такой сид.

## 2. Род (решение 1 — А)

- Prisma: `enum AdvisorGender { FEMALE MALE }`, колонка `advisors.gender AdvisorGender?` — nullable; миграция только
  добавляет тип и колонку (деплой без простоя). Контейнер делает migrate → seed → listen, сид пишет род при каждом
  деплое, так что пустое значение бывает только у советника, записанного в обход сида: тогда мужская форма — базовая
  в глоссарии.
- `AdvisorSeedRow.gender` — обязательное. **Протягиваю через явную проекцию:** `AdvisorRecord.gender`
  (`advisors.repository.ts`), `toRecord` (`prisma-advisors.repository.ts`); фейки `AdvisorRecord` в спеках sessions /
  reviews / agent-desk получают поле.
- Род **не уходит** ни в `AdvisorDto`, ни в `DeskAdvisor` / `DeskAdvisorProfile`.
- Термин в языковом файле — строка (одна форма: Medium, Tarot, все формы в et / fi / hu) или `{ female, male }`. Обе
  формы обязательны всегда.
- Род персон: женщины — Olivia, Sunshine, Veronica, May, Marta; мужчины — Alisher, Ivan; **Labsang Devi — спрашиваю
  у владельца по фото** (`https://assets.aura-app.cc/avatar/labsang.jpeg`).

## 3. Перевод

- Устоявшиеся названия в каждом языке, не дословно (Card Reader: de «Kartenleger(in)», fr «cartomancien(ne)»,
  es «cartomante»).
- **Глоссарий приложения v2:** `psychic` (человек) — мужская форма оттуда, женская — от неё; `medium`; `tarot`
  (it «tarocchi», bg «таро», et / lt / lv «taro»); **`reader` и `reading`** — никогда «читатель» / «чтение»
  (de «Leser» / «Lesung», fr «lecteur» / «lecture», nl «lezer», sv «läsare», lt «skaitytoj», ga «léitheoir», mt
  «qarrej»…): Card reading — fr «cartomancie», Psychic reading — fr «voyance» и т. п.
- **el `psychic` — «Διορατικός / Διορατική»,** не «μέντιουμ» из глоссария v2 (там psychic = medium, и у Veronica было
  бы «Μέντιουμ · Μέντιουμ · Ταρό»). Правка `glossary.json` aura-app (v3) — в передачу.
- Синонимы допустимы: Psychic Reader, Psychic и Clairvoyant могут быть одним словом в языке (de «Hellseher(in)»),
  Clairvoyance и Psychic reading — словом категории PSYCHIC приложения (de «Hellsehen», fr «Voyance», pl
  «Jasnowidzenie», el «Διόραση»). Нельзя одно: повтор внутри одной персоны (§5).
- Категории приложения (`AURAT-0164`): LOVE de «Liebe» / fr «Amour» → «Love & Relationships» / «Love &
  relationships» начинаются с того же слова.
- Оформление: каждый термин с заглавной, дальше — обычный регистр языка; «&», как в английском; без точек и кавычек.
  Не `@sensitive`.
- Метод — как в `0171`: перевожу сам, агентами по несколько языков параллельно, потом сверяю глоссарий, категории,
  повторы по персонам и длины.

## 4. Код

- `src/modules/advisors/labels/` — `advisor-label-terms.ts` (английские списки, темы специализаций, типы), `<lang>.ts`
  × 23, `index.ts` — `ADVISOR_LABEL_TRANSLATIONS: Readonly<Record<TranslatedLanguage, …>>`.
- `TranslatedLanguage` переезжает из `tarot/deck-translations/index.ts` в `src/common/language/` (два пользователя);
  колода импортирует оттуда.
- `localizeAdvisorLabels({ role, specialties, gender }, language) → { role, specialties }` — чистая: `en` → как
  есть; язык → по словарю, форма по роду; неизвестный термин → английский; порядок сохраняется.
- `advisorTopics(specialties) → AdvisorCategory[]` — объединение тем английских специализаций, в порядке
  `ADVISOR_CATEGORIES` контракта; неизвестный термин тем не даёт.
- **Единственная точка** — `AdvisorsService.toDto(advisor, language)`; `list(language: Language)` — без значения по
  умолчанию. `topics` считается там же, от английского.
- `AdvisorsController.list(@RequestLanguage() language)` → `languageOrDefault(…)`; `@ApiLanguageQuery()`. Маршрут
  публичный: ответ зависит от запроса, не от того, кто спрашивает — комментарий над контроллером уточняю.
- **Desk остаётся английским, тексты поправляю:** описание атрибута `advisor_role` (`desk-attributes.ts`) —
  «Persona title in English; the client sees it in their language. Set by Aura.»; комментарий `profileOf`
  (`agent-desk.service.ts`) — то же по смыслу. Новое описание дойдёт до Chatwoot со следующим `npm run desk:setup`
  (в маноре, §8).
- Не трогаю: `findById` (бронь), Chatwoot-значение `advisor_role` (английское).
- HTTP-кэша и ETag у `/v1/advisors` нет; `lang` в URL — серверу делать нечего.

## 5. Темы для подбора на вебе (решение 4)

Веб (`pages/match`) ранжирует советников других категорий по английским словам внутри `specialties`. После выкатки
слова перестанут находиться — уровень «also» молча опустеет у всех неанглийских посетителей.

- **А (рекомендую).** `Advisor.topics: AdvisorCategory[]` — язык-независимое поле в контракте. Темы термина задаются в
  английском словаре сервера; **на старте — ровно то, что сегодня находит веб** (тест держит паритет с копией
  `TOPIC_WORDS` веба: LOVE — Love & relationships, Breakups, Reconciliation, Soulmates, Dating & relationships;
  TAROT — Tarot, Card reading; PSYCHIC — Mediumship, Clairvoyance, Channeling, Psychic reading, Psychic protection).
  Веб убирает `TOPIC_WORDS` и читает `topics`. Это изменение схемы → контракты **v0.29.0** с тегом (решение 3).
- **Б.** Веб ранжирует по отдельному чтению каталога с `?lang=en`. Сервер и контракт не меняются, но у веба второй
  запрос и второй кэш, а знание «какие слова — какая тема» остаётся на клиенте.

## 6. Контракт и Swagger (решение 3)

- **При 4А:** `aura-contracts` **v0.29.0** — `Advisor.topics: z.array(AdvisorCategory)` + JSDoc `role` / `specialties`
  («in the request language (`lang`), English by default»); в версию уходит и уже лежащий в `main` JSDoc
  `TarotCard.name` (`3f12472`). Ветка → `main` → тег → пуш — **с отдельного одобрения владельца**; BFF ставит
  `@aura/contracts#v0.29.0` (без тега на GitHub `npm ci` и Docker не соберутся). Решение 3А «без тега» здесь не
  работает: схема меняется.
- **При 4Б:** как решено — JSDoc коммитом в `main` без тега, пуш с одобрения.
- BFF `advisorOpenApi`: `role` / `specialties` — «на языке запроса», `topics` — описание и `enum`.
- `src/contracts/advisor.spec.ts`: DTO проходит схему; ключа `gender` в нём нет.

## 7. Тесты (чистые, без БД)

**Словарь, на все 23 языка:**
- каждый термин `ADVISOR_ROLE_TERMS` / `ADVISOR_SPECIALTY_TERMS` есть, лишних нет; нет пустых, пробелов по краям,
  « · » внутри; первая буква заглавная; `female` ≠ `male`;
- совпадение с английским — только из явного списка на язык (Tarot, Medium…);
- длина термина: `role` ≤ 28, специализация ≤ 32;
- **запретные формы глоссария** `reader` / `reading` / `psychic` / `medium` (`avoid`, копия из `glossary.json` v2 с
  номером версии) — сопоставление по началу слова, как `aura-app scripts/i18n/terms.js`;
- NFC; нет U+00AD и U+02BC; ro — ș ț.

**По персонам — `ADVISOR_SEED` × 23 языка, с родом:**
- каждая `role` режется на известные термины, каждая специализация известна, `gender` есть;
- **внутри персоны** в собранной `role` и в списке чипов нет повторов (между персонами совпадения допустимы);
- собранная `role` ≤ 36 знаков (английские — до 24); ширина в pt — в таблице `execute` (§9).

**Темы:** паритет `topics` специализаций с копией `TOPIC_WORDS` веба (`config/match.ts`); `advisorTopics` — порядок,
без повторов, неизвестный термин.

**Код:**
- `localizeAdvisorLabels`: `en`; женская и мужская формы; `gender: null` → мужская; неизвестный термин → английский;
- цепочка `ADVISOR_SEED` → `advisorUpsert(…).create` → `toRecord` → `toDto('de')`: у Olivia женская форма, у Ivan —
  мужская (ловит род, потерянный в проекции); `advisorUpsert` пишет `gender`;
- `advisors.service.spec`: `list('de')` — `role` / `specialties` переведены, `topics` — как у `en`, `tagline` / `bio` /
  `greeting` — английские; `list('en')` — как сейчас;
- `request-language.routes.spec`: `GET /v1/advisors?lang=de` → `de`; без параметра и `?lang=mt` → `en`;
- `guest-access.smoke.spec`: гостевой `GET /v1/advisors?lang=de` → 200, в `list` — `de`; заглушке `ConfigService` —
  `DISABLED_LANGUAGES: []`;
- desk и `advisor_role` — английский путь, тесты desk с новым описанием.
- `npm run lint`, `typecheck`, `build`, `test`.

## 8. Порядок выкатки и проверка

1. Контракты v0.29.0 (при 4А) — тег до мёржа BFF.
2. **Веб — до сервера или вместе с ним:** подбор на `topics` (при 4А — веб, терпимый к отсутствию поля, может уйти
   первым) и язык в ключе кэша каталога. Иначе в день выкатки — пустой «also» и смешанные языки после смены языка.
3. **Приложение** — в проде безопасно, пока флаг языков выключен; его правка — до включения флага.
4. BFF. В маноре: migrate + seed дважды подряд — без ошибок и дублей; `GET /v1/advisors?lang=de` (Olivia — женская,
   Ivan — мужская), `?lang=el` (нет «Μέντιουμ · Μέντιουμ»), `?lang=it` («tarocchi»), без `lang` и `?lang=mt` при
   `DISABLED_LANGUAGES=mt` — английский; `topics` одинаковы во всех языках; гостем без входа — 200;
   `npm run desk:setup` → описание `advisor_role` в Chatwoot новое; новый разговор — `advisor_role` по-английски;
   desk — профиль по-английски.

## 9. Передача клиентам (номера — от координатора)

- **Приложение:** каталог подписан на `onLanguageChange` (`shared/lib/i18n/on-language-change.ts`, как
  `use-daily-card-sync.ts:22`), поднимает `generation` и перезагружается — опоздавший ответ на старом языке не ляжет.
  Роль и цена — в два `Text` в `AdvisorRow` и `BookSessionScreen`, чтобы обрезалась роль, а не цена. Места роли:
  `AdvisorRow`, `TopAdvisorRow`, `BookSessionScreen`, `SessionHero`. Поиск по `${name} ${role}` ищет по переведённому
  типу — так и нужно. `glossary.json` v3: el `psychic` — «Διορατικός / Διορατική».
- **Веб:** язык в аргументе `getAdvisors` (как `daily-card-api.ts:9-18`); подбор — по `topics` (4А) или по чтению
  `?lang=en` (4Б); места роли — session-detail, advisor-page.
- Таблица из `execute`: самая длинная собранная роль по языку, ширина в pt шрифтом строки (HankenGrotesk 13pt в
  списке, 12.5pt на Home), с ценой там, где она в той же строке.
- Чаттерам (строкой в заметки, как в `0171`): клиент видит тип и специализации на своём языке; в desk и Chatwoot — по-
  английски.
- Категория-чип (LOVE / TAROT / PSYCHIC) — по-прежнему перевод приложения.

## Не здесь

`tagline`, `bio`, `greeting` — решение 8; сезонные тексты; клиентский код; язык в Chatwoot и desk.

## Решения владельца

1. Род — **А** (решено). **Открыто:** пол Labsang Devi (по фото).
2. `role` — **А** (решено).
3. Контракты — при 4А: **v0.29.0 с тегом** (`topics` + JSDoc), пуш с одобрения; при 4Б — **А** как решено.
4. Подбор на вебе: **А** `topics` в контракте (рекомендую) / **Б** веб читает каталог второй раз с `?lang=en`.
