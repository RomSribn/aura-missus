# AURAT-0175-010 — execute

Дата: 2026-11-07 · Слот `slave-1`, ветка `feature/AURAT-0175-web-advisor-labels-i18n`. **Не закоммичено** — застейджено,
ждёт ревью владельца в IDE.

## Проверки
`npm ci` ✓ · `npm run lint` (eslint + steiger) ✓ · `typecheck` ✓ · `npm test` — **113 файлов, 1922 теста, все зелёные** ·
`build` ✓ · prettier по изменённым файлам ✓.
Мутация: `data` → `currentData` в `useAdvisors` роняет тест «no skeleton» — тест держит поведение.

## Коммит 1 — контракты и фикстуры (правило 6)
- `package.json` / `package-lock.json`: `@aura/contracts#v0.29.0` (lock → `308b95e`).
- Фикстуры с `topics`, окончательные: у всех фабрик с `specialties: ['Love']` — `topics: ['LOVE']` (как по старому
  подбору и как дал бы сервер по смыслу): `app/__tests__/{advisors,book-now,booking,chats,daily,home,live-session,psp,season,sessions}.test.tsx`;
  home SOL получает `['LOVE']` из фабрики, комментарий — «with love among the topics»; `filter-advisors.test.ts` —
  `topics: []` (специализаций нет).
- `match-advisors.test.ts` — фабрика с `topics`, каталог — персоны сида с настоящими специализациями и темами.

## Коммит 2 — код
- `shared/api/base-query.ts`: `BffRequest.language?: Language`; язык — один раз в начале `bffBaseQuery`
  (`request.language ?? currentLanguage()`), до `getIdToken`, в оба захода `performRequest`. Тесты: явный язык в `?lang`;
  смена языка во время токена и перед повтором 401 — язык исходный.
- `entities/advisor/api/advisors-api.ts`: `getAdvisors: build.query<Advisor[], Language>`, запрос с `language`.
- `entities/advisor/model/use-advisors.ts`: `useCatalogLanguage()` (`useTranslation()` + `currentLanguage()`); JSDoc
  `useAdvisors` — прежний каталог до ответа, поведение при отказе (принято, `008` §2).
- `entities/tarot/api/daily-card-api.ts`: `getDailyCard` и `markDailyCardDrawn` передают свой `language`.
- `pages/match/lib/match-advisors.ts`: `readsOn = advisor.topics.includes(topic)`; JSDoc — «topics», ссылка на BFF
  `advisor-labels.spec.ts`. `pages/match/config/match.ts`: `TOPIC_WORDS` удалён. `match/config/locales/en.ts` — JSDoc.
- CSS: `home-page.module.css`, `advisors-page.module.css` — `.grid > li { display: flex }`, `> * { flex: 1 }`;
  `advisor-tile.module.css` — `.actions { margin-top: auto }`.
- Тесты: `match-advisors.test.ts` — «specialties на de — подбор тот же» (специализации без английских слов) +
  «английское слово без темы ничего не даёт», «`topics: []` — только own», название «…among their topics»;
  `advisors.test.tsx` — новый блок «the catalog in the language on screen»: смена языка → `lang` `['en','de']`, немецкие
  роли; немецкий задержан → английские плитки, без `status busy`, потом замена; опоздавший английский не перекрывает.

Разбиение одного файла (`match-advisors.test.ts`) по коммитам: в коммит 1 — фабрика и каталог, в коммит 2 — новые
тесты и переименование; сделаю патчем при коммите, каждый коммит — зелёный typecheck.

## Строки
Новых и изменённых строк нет (только JSDoc в `en.ts`).

## В маноре после мёржа (критерий может не пройти)
- `/match` на de / lt: вопрос про любовь → «also» не пуст (Olivia, Ivan), как на en.
- Смена языка в Профиле → каталог, Home, профиль советника, сессия — роль и чипы на новом языке без перезагрузки.
- lt / ro / nl, 390 и 1440, Home и `/advisors` (плитки и список): в ряду плитки одной высоты, кнопки на одной линии,
  роль не обрезана.

## Открытое
- `AURAF-0023` — запись о `0175` в таблице шагов — при закрытии задачи.
