# AURAT-0162-008 — review fixes

Дата: 2026-11-05. Ревью координатора (slave-1-9e: 3 ревьюера + скептики; блокеров нет). Владелец: «передай»; по
заголовкам слайдов — рекомендация координатора. Разбор: scratchpad координатора `wf0162-review.md`.

## Сделано
1. **Страна в начале фразы — с заглавной.** `CountryNames.titleOf(iso2)` (shared/lib/country-names.ts): поднимает
   только строчную первую букву (`/^\p{Ll}/u`, `toLocaleUpperCase(language)`) — греческое «Άγιος Μαρίνος» не теряет
   тон. В «нет SMS» и в строках листа; поиск и сортировка — по `nameOf` как прежде. Тесты: mt DO «Ir-Repubblika
   Dominicana», ga TR / CZ, bg IM, el SM.
2. **Ирландская h-протеза** в ключе сортировки: `h(?=[AEIOUÁÉÍÓÚ])` вместо `h-`; PH, MP теперь среди «Oileáin …».
   Перегенерировано, кейс в тесте.
3. **Юридическая строка:** pl «nasze Warunki korzystania», ga «mBeartas Príobháideachta», el «Όρους χρήσης» /
   «Πολιτική απορρήτου». Расхождения веба — в `AURAF-0023-glossary.md`.
4. **Кнопки:** hu «Kezdés», el «Έναρξη», bg «промени» (и в a11y пилюли).
5. pt подзаголовок — «…para confirmar a sua identidade.»
6. lv «Vaicājumam „{{query}}” neatbilst neviena valsts.»
7. **Заголовок экрана телефона** в 2 строки по замеру шрифта (ExtraBold 34, 331 pt): ga, hu, el, fr, pt — варианты
   координатора; в JSDoc en.ts — «≈18 символов в строке».
8. **Заголовки слайдов** в 2 строки (Bold 34, 323 pt): `@max 34`, JSDoc о замере; укорочены bg, cs, el ×2, fi, fr,
   ga ×2, hr, hu, lv, pl, pt, ro, sk, sl; U+00A0 после однобуквенного предлога (cs, sk, pl, sl). Все 72 заголовка
   замерены — 2 строки (кернинг не учтён, ±3 %).
9. **Код:** пикер не сворачивает пустой запрос; `foldForSearch` — try/catch вокруг `normalize` (как promo-code).
   VerifyOTP: «change» с `accessibilityLabel` (`changeLabel`, 24 языка), номер с U+00A0 только для показа.
   Пробел перед «change» в английском — намеренно (раньше JSX его съедал).
   Тесты: `PhoneAuthScreen.test.tsx` — ссылки юридической строки в en / de / pl (текст + URL), «нет SMS» на de и с
   заглавной на mt, `SlideItem.test.tsx` — memo-слайд перерисовывается на de. `TECH-DEBT.md` строки 1 и 12 — новая
   формулировка.

## Проверки
`tsc` — 0, `eslint .` — 0, Jest — 185 наборов / 1991 тест.

## Заметки (без кода)
- ga «Do chárta an lae», da / sv / nl «карта дня» не названием экрана Daily — вопрос носителю.
- de / es заголовок телефона на 360 dp может уйти в 3 строки — проверить на устройстве в маноре.
- Android: `normalize` через JNI вживую не проверен — в маноре (release, R8): de / pl, «osterreich», «ŁOTWA», «germany».
