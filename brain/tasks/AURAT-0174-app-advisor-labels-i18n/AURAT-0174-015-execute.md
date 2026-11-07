# AURAT-0174-015 — execute: цена в карточке профиля, «$» везде

Дата: 2026-11-07 · по решениям `014`. Слот slave-0, та же ветка (после мёржа `013`). **Не закоммичено**, застейджено.

## Файлы

- `scripts/i18n/generate-formats.mjs` — `currencyDisplay: 'narrowSymbol'` в `usdAffixes`; комментарии.
- `src/shared/lib/i18n/formats.generated.ts` — перегенерирован (Node v22.23.0, CLDR 48.0; `--check` ✓): у всех 23
  языков «$» на месте символа — bg cs da de el es et fi fr hr hu it lt lv pl pt ro sk sl sv «1,90 $», nl «$ 1,90»,
  ga / mt «$1.90».
- `src/shared/lib/format.ts`, `features/store-topup/model/use-checkout.ts` — примеры в комментариях.
- `screens/advisor-profile/ui/StatsCard.tsx` — цена `PriceTag` `size={18}` всегда; со скидкой `stack`
  `align="center"` (зачёркнутая сверху, новая — в ряду цифр); ячейки `justifyContent: 'flex-end'`, чтобы цифры и
  подписи стояли рядами.
- Тесты: `formats-drift.test.ts` (сверка с Node — `narrowSymbol`), `format.test.ts` (fr / nl / pl / bg — «$»),
  `use-checkout.test.tsx` (nl «$ +4,00»), `ticket-content.test.ts` (fr «5 $ sur votre solde»), новый
  `StatsCard.test.tsx` (стопка при скидке, размер 18 без скидки, bg — «3,80 $» и «1,90 $»).

Не тронуты: комментарии-замеры `BookSessionScreen.tsx:302` и JSDoc `profile/config/locales/en.ts:32` («US$
1.234,56») — это обоснование ширин; с «$» места только больше.

## Проверки

tsc ✓ · lint ✓ · `npx jest --no-watchman` — 223 набора, 3064 теста, все зелёные.

## Ширина ячейки цены (A50 — 123 pt, 360 — 105 pt)

Стопка: шире всего новая цена, ExtraBold 18 — «1,90 $» 50 pt, «10,90 $» 62 pt; зачёркнутая (Hanken SemiBold 15) — ещё
уже. Запас и при крупном шрифте.

## Открыто

- Веб: та же запись «$» — отдельной задачей (номер — координатор). Пока клиенты пишут доллар по-разному.
- Решение `AURAT-0159` («как есть из CLDR») изменено владельцем — отмечено здесь.
