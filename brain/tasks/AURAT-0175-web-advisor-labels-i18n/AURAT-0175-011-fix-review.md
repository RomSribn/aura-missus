# AURAT-0175-011 — fix: ревью кода координатора

Дата: 2026-11-07 · Ревью: координатор `slave-1-ac` (прогон в слоте зелёный; 6 замечаний, 3 отклонены). Владелец:
«передавай всё, п. 2 правь в 0175». Все три — в этой задаче.

1. **[major] Плитка в flex-ячейке не сжимается:** `article` как flex-элемент с `min-width: auto` берёт полное имя
   (`.link` nowrap) + OffChip + PriceTag → без многоточия, наезд на соседнюю колонку на Home ≤760. → `min-width: 0`
   у `.grid > li > *` в home и advisors (и в `match-page.module.css` — единообразие). Манор: 360 / 390 — имя с
   многоточием, плитки одной высоты.
2. **[minor] «Карта вытянута» — только в кэш текущего языка:** `markDailyCardDrawn.onQueryStarted` патчит одну запись
   `{ tz, language }`; записи других языков живут 60 с → вернулся на en — баннер снова зовёт тянуть, `/daily`
   повторяет ритуал. → патчить все закэшированные `getDailyCard` того же `tz`
   (`util.selectCachedArgsForQuery`); тест в `daily.test.tsx`: вытянул на de, вернул en — «Drawn today».
3. **[nit] `useCatalogLanguage` повторяет `useTranslation(); currentLanguage()` из `use-daily-card.ts`.** →
   `useCurrentLanguage()` в `shared/i18n` рядом с `currentLanguage`, экспорт из `@/shared`; оба хука через него.
