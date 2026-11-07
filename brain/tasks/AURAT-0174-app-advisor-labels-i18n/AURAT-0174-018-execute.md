# AURAT-0174-018 — execute: цена в строку, когда влезает

Дата: 2026-11-07 · по `017`. **Не закоммичено**, застейджено.

- `shared/ui/offer/PriceTag.tsx` — проп `wrap`: ряд с `flexWrap: 'wrap'`, `columnGap` 6, `rowGap` 0, `justifyContent`
  по `align`. Без `wrap` и при `stack` — как было; другие места `PriceTag` не тронуты.
- `screens/advisor-profile/ui/StatsCard.tsx` — `wrap` вместо `stack`, размер 18, ячейки по-прежнему к низу.
- `StatsCard.test.tsx` — `wrap` + `align="center"` + размер 18, ряд с переносом и по центру, без `stack`.

Проверки: tsc ✓ · lint ✓ · Jest — 223 набора, 3064 теста, все зелёные. Как ложится перенос — только на телефоне (Jest
раскладку не считает): на A50 в bg ожидается одна строка (≈ 97 из 123 pt), стопкой — при крупном шрифте.
