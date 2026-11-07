# AURAT-0169-013 — правки по ревью C2 / D (координатор `slave-1-9e`)

Дата: 2026-11-06. Маркер принят без замечаний.

Сделано:
1. Длинное имя одним словом — `entities/tarot/lib/card-name-type.ts` (`cardNameType`, оценка по числу букв × 0,6 em) и
   `CARD_NAME_TYPE` в `config/card.ts`: баннер 22 → 18, `CardReveal` и просмотр 34 → 28, если самое длинное слово не влезает в
   строку. Подключено в `DailyCardBanner`, `CardReveal`, `SpreadCardViewer`. Тесты da / fi / sv / bg.
2. Просмотр центрируется в зоне под шапкой: `paddingTop = insets.top + VIEWER_CHROME_HEIGHT`, `paddingBottom = insets.bottom`.
3–4. `tarot-spread`: fr / es `youChose` — через двоеточие; `open` — «карта + кавычки» в fr es it pt bg nl ga mt ro, hu
   «„{{card}}” kártya megnyitása».
6. `tarot-spread/config/__tests__/card-name.test.ts` — правило для всех языков, кроме en / da / sv; JSDoc поправлен.

**Не сделано (лимит использования):** п. 5 — отметка языка треда в `ChatProvider.syncThread` (снимать отметку, если
устаревшая синхронизация принесла расклад на другом языке) — следующий шаг. Тест раскладки «верх карты не под шапкой» при
59/34 не добавлен. Проверка в маноре — da / fi / sv / bg.
