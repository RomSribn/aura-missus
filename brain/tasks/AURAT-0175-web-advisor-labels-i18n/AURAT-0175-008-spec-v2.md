# AURAT-0175-008 — spec v2: веб — подписи советников на языке запроса

Дата: 2026-11-07 · Status: **done** 2026-11-07 (`020-approved.md`)
Заменяет `005-spec.md`. Фича `AURAF-0023` строка 011 · Сервер `AURAT-0173` (done, BFF `167f0b9`, уже на bff-dev) ·
Контракты `v0.29.0` (тег на GitHub есть). Глоссарий — `AURAT-0177`, не здесь.

**Срочность:** web `develop` выкатывается на web-dev, BFF 0173 там уже стоит → у неанглоязычных посетителей web-dev
«also» на `/match` пуст сейчас. Прода веба нет.

## Что получится
- `/match`: советник другой категории попадает в «also» по `Advisor.topics`, на любом языке.
- Смена языка перечитывает каталог: тип и специализации — на новом языке во всём вебе без перезагрузки. Пока ответ
  идёт — прежние подписи, без скелетона. Ответ на старом языке ложится под ключ старого языка (язык ключа и `?lang`
  на проводе — один и тот же, §2).
- Плитки советников в ряду — одной высоты, кнопки на одной линии, как бы ни переносилась роль (§5).
- Новых строк нет.

## 1. Коммит контрактов (правило 6) — пин и фикстуры
- `package.json` / `package-lock.json`: `@aura/contracts` → `github:RomSribn/aura-contracts#v0.29.0`.
- В том же коммите — все типизированные фикстуры `Advisor` с `topics` (в выходном типе поле обязательно, без них
  коммит не компилируется), **сразу с окончательными значениями** — темы так, как их дал бы сервер по специализациям
  фикстуры, никогда «по категории»:
  - `topics: []` — где фикстура не участвует в подборе: `const MIA` в `app/__tests__/{booking,season,psp,book-now}.test.tsx`,
    фабрики `{chats,sessions,daily,live-session,advisors}.test.tsx`, `features/advisor-filters/lib/__tests__/filter-advisors.test.ts`
    (если у фикстуры специализации, по которым сервер дал бы тему, — эта тема; проверю каждую);
  - `app/__tests__/home.test.tsx`: SOL (TAROT, `specialties: ['Love']`) — **`topics: ['LOVE']`** явно; комментарий
    у ожидания «Also reads on love & relationships» — «with love among the topics»;
  - `pages/match/lib/__tests__/match-advisors.test.ts` — фабрика с `topics`, каталог — по §3.
- Коммит кода фикстуры не трогает (кроме новых тестов §3–4).

## 2. Язык в ключе кэша — и тот же язык на проводе
- `shared/api/base-query.ts`: `BffRequest` (объектная форма) получает необязательное `language?: Language`.
  `bffBaseQuery` определяет язык **один раз в начале** — `request.language ?? currentLanguage()` — до
  `await getIdToken()`, и `performRequest` (оба захода, и повтор после 401) берёт его аргументом, а не читает
  `currentLanguage()` сам. Тест в `base-query.test.ts`: явный `language` идёт в `?lang`; язык, сменившийся во время
  получения токена, и повтор после 401 — с исходным языком.
- `entities/advisor/api/advisors-api.ts`: `getAdvisors: build.query<Advisor[], Language>`,
  `query: (language) => ({ url: '/v1/advisors', language })`. JSDoc — зачем язык в ключе (как `daily-card-api.ts`).
- `entities/tarot/api/daily-card-api.ts`: `dailyCardUrl` → объект с `language: args.language` — то же окно закрыто и
  у карты дня. `markDailyCardDrawn` — тоже свой `language` (ответа с текстом у него нет, но язык один).
- `entities/advisor/model/use-advisors.ts`: внутренний `useCatalogLanguage()` — `useTranslation()` (подписка на смену
  языка) + `currentLanguage()`; `useAdvisors` / `useAdvisor` передают его в `useGetAdvisorsQuery`. Публичный API слайса
  не меняется.
- Пока каталог на новом языке грузится — RTK Query отдаёт прежний `data` (последний результат хука); экран не
  мигает, подписи меняются по ответу.
- **Отказ запроса на новом языке — принято:** смонтированные экраны остаются `ready` со старыми подписями, без ошибки
  и без повтора (следующая смена языка или перезагрузка перечитает); только что открытый экран — как любой отказ
  каталога сегодня: ошибка и Try again. Записать это в JSDoc `useAdvisors`.
- Тег `Advisors` (`write-review`) инвалидирует все языковые ключи.

## 3. Подбор по `topics`
- `pages/match/lib/match-advisors.ts`: `readsOn = advisor.topics.includes(topic)`; JSDoc `MatchReason` и `rankAdvisors`
  — «among their topics (`Advisor.topics`, `AURAT-0173`)» вместо «specialties».
- `pages/match/config/match.ts`: `TOPIC_WORDS` удаляется. Паритет со старым подбором держит BFF —
  `src/modules/advisors/labels/advisor-labels.spec.ts` (копия `TOPIC_WORDS`); в JSDoc `readsOn` — ссылка туда.
- `pages/match/config/locales/en.ts`: JSDoc `reason` — «the topic is among their topics». Строки не меняются.
- `match-advisors.test.ts`: каталог — персоны сида с настоящими специализациями и темами (olivia LOVE·PSYCHIC,
  sunshine TAROT·PSYCHIC, veronica TAROT·PSYCHIC, may PSYCHIC, marta LOVE, ivan LOVE·TAROT); ожидания — прежние;
  название теста — «…with the topic among their topics». Новые: специализации на de — подбор тот же; `topics: []`
  (старый сервер) — только «own».

## 4. Тесты приложения (`app/__tests__/advisors.test.tsx`, как `daily.test.tsx`)
- смена языка перечитывает каталог: второй `/v1/advisors` с `lang=de`, на экране немецкая роль;
- **немецкий ответ задержан — английские плитки на месте, скелетона нет; пришёл — заменил** (закрепляет `data`, а не
  `currentData`);
- ответ на старом языке, отпущенный после нового, не перекрывает немецкий;
- «один запрос каталога» остаётся зелёным.
- `npm ci`, `npm run lint`, `typecheck`, `test`, `build`.

## 5. Плитки одной высоты
Переведённая роль с «· N reviews» на 390 — 2–3 строки (lt 184 px, ro 177, nl 171 при тексте ~140), на 1440 — 2;
кнопки Chat free / Book уезжают на разную высоту. Правка CSS в этой задаче:
- `pages/home/ui/home-page.module.css` и `pages/advisors/ui/advisors-page.module.css` (`.grid`): `.grid > li
  { display: flex }`, `.grid > li > * { flex: 1 }` — как `match-page.module.css`;
- `entities/advisor/ui/advisor-tile.module.css`: `.actions { margin-top: auto }`.
- **Критерий в маноре (может не пройти):** на lt / ro / nl, 390 и 1440, Home и `/advisors` (плитки и список) — в
  ряду плитки одной высоты, кнопки на одной линии; роль не обрезана. Не прошло — правка здесь же.

## 6. Выкатка
Сразу за сервером `0173` (он уже на bff-dev). Веб с `topics` переживает и старый сервер (`[]` → «also» пуст).

## 7. Не здесь
`tagline` / `bio` / `greeting` (решение 8); глоссарий веба — `AURAT-0177`; `aura-app` / `aura-bff`.
