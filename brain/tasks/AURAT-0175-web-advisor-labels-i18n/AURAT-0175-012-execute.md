# AURAT-0175-012 — execute: правки ревью `011`

Дата: 2026-11-07 · **Не закоммичено** — застейджено, ждёт ревью владельца.

## Проверки
lint (eslint + steiger) ✓ · typecheck ✓ · `npm test` — **113 файлов, 1923 теста** ✓ · build ✓ · prettier ✓.
Мутация: патч только записи своего языка (`cached.language !== args.language`) роняет новый тест daily.

## Правки
1. `min-width: 0` у `.grid > li > *` — `pages/home/ui/home-page.module.css`, `pages/advisors/ui/advisors-page.module.css`
   и для единообразия `pages/match/ui/match-page.module.css`: карточка сжимается до ячейки, длинное имя — многоточием.
2. `entities/tarot/api/daily-card-api.ts` `markDailyCardDrawn.onQueryStarted`: `drawn = true` во всех закэшированных
   `getDailyCard` того же `tz` (`util.selectCachedArgsForQuery`), любого языка. `lifecycle.getState()` /
   `lifecycle.dispatch` — без деструктуризации (`@typescript-eslint/unbound-method`).
   Тест `app/__tests__/daily.test.tsx` «drawn in one language, drawn in all»: Home на en → de → `/daily` (ритуал,
   запись) → en → Home: «Drawn today» без нового чтения (сервер в стабе всё время отвечает «не вытянута»).
3. `shared/i18n/use-current-language.ts` — `useCurrentLanguage()` (`useTranslation()` + `currentLanguage()`), экспорт
   из `@/shared`; `use-advisors.ts` и `use-daily-card.ts` — через него, локальный `useCatalogLanguage` удалён.

## Манор (добавлено к `010`)
360 / 390: имя на плитке Home и `/advisors` — с многоточием, без наезда на соседнюю колонку и горизонтальной
прокрутки; плитки одной высоты.
