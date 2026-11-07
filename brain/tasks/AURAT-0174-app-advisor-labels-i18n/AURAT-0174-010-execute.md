# AURAT-0174-010 — execute

Дата: 2026-11-07 · slave-0, ветка `feature/AURAT-0174-app-advisor-labels-i18n` (от `develop` @ `cffdbf5`).
**Не закоммичено** — застейджено, ждёт ревью владельца в IDE.

## Проверки

`npx tsc --noEmit` ✓ · `npm run lint` ✓ · `npx jest --no-watchman` — **219 наборов, 3022 теста, все зелёные** ·
`translate.mjs check` — 0 запретных форм (`typecheck`-скрипта в `package.json` нет — tsc напрямую).

## Файлы (aura-app)

- `package.json`, `package-lock.json` — `@aura/contracts#v0.29.0`.
- `entities/advisor/model/catalog-store.ts` — `load(force)`, счётчик `latest`, `latestLanguage` (`null`, пока запрос
  ждёт i18n), `followLanguage(language)`; `finally` снимает только свой `inFlight`; вытесненный запрос резолвится
  `inFlight ?? state.advisors`; `reset` обнуляет `latestLanguage`.
- `entities/advisor/model/use-advisor-catalog-sync.ts` — `onLanguageChange` → `followLanguage`; `AppState` `active` +
  `error` → `load()`.
- `screens/advisors/model/use-advisors.ts` — `useFocusEffect`: `error` → `load()`.
- `screens/write-review/model/use-write-review.ts` — `load(true)`.
- `screens/advisors/lib/filter-advisors.ts` — `foldForSearch` на обеих сторонах.
- `screens/advisors/ui/AdvisorRow.tsx` — тип и « · цена» двумя `Text` в строке (`metaLine`, тип `flexShrink: 1`).
- `screens/booking/ui/BookSessionScreen.tsx` — Б: тип своей строкой, цена (`advisorRate`) ниже, без « · » и без
  `numberOfLines`; со скидкой — как было.
- `scripts/i18n/glossary.json` — `version` 3; el `psychic` «διορατικός» / `stem` «διορατικ»; `note` — женская форма и
  почему не «μέντιουμ».
- `test-support/advisor.ts` — `topics: []` в `BASE`.
- Тесты: `catalog-store.test.ts` (+11: гонки в обе стороны, провал новейшего / старого, общий запрос при
  принудительном, повторный `load()` на готовом, `reset` посреди запроса, `followLanguage` ×3), новый
  `use-advisor-catalog-sync.test.tsx` (6: смена языка, выход / вход неизвестен, холодный старт — один запрос,
  `AppState` при `error` / `ready`), `filter-advisors.test.ts` (+9: el / lt / ro / de без диакритики и капсом,
  английское слово по немецкому типу), `AdvisorsScreen.test.tsx` (тип и цена — отдельные `Text`; фокус повторяет
  провалившееся перечитывание), `BookSessionScreen.test.tsx` (цена своей строкой без « · »).

## Брейн

- `AURAF-0023-glossary.md` — абзац о копиях (веб — `AURAT-0177`, BFF — только `avoid`, остаётся на 2) и версиях (v3).
- `investigations/AURAI-0011-app-state-rtk-query/` — заглушка (решение владельца, `006`).

## Решения по ходу

- Свёртка поиска — в самом `filterAdvisors` на каждый ввод, а не в `useMemo` по каталогу (`008` §4): персон восемь,
  кэш дороже выгоды.
- Холодный старт проверен на настоящем порядке i18n: `initAsync: false` — событие первого языка приходит до
  `i18nReady`, поэтому ожидающий запрос не дублируется.
- Таблица ширин — из `008` (замер ревью); вживую — в маноре.

## Дальше

`develop` ушёл на `76bd8aa` (`AURAT-0176`: ChatProvider, `theme.ts`, `shared/ui/index.ts`, локали) — влить перед
мёржем. Живая проверка в маноре — список `008` «Проверки». Строка 011 `AURAF-0023` — колонки остаются ✗ (слоган / био /
приветствие ждут решения 8); в плане (строка 5) — `AURAT-0174` при закрытии.
