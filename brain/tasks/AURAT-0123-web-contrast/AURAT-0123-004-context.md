# AURAT-0123-004 — Context

Date: 2026-10-23

## Источники

- `aura-web` develop `280988a`: `src/shared/config/tokens.css` — палитра хендоффа (= приложение,
  `aura-app/src/shared/config/theme.ts`, те же hex). Текстовых вариантов нет.
- Хендофф `README.md`: teal `#2BA39A` / soft; «Text contrast is 4.5:1 or more (struck prices use
  ink-3 next to a full-contrast offer price)» — зачёркнутая цена на ink-3 разрешена хендоффом.
- Правила веба: «Text contrast ≥ 4.5:1» (Accessibility), hard rule 3 — цвета только в токенах.
- Прецедент механической проверки: `shared/config/__tests__/breakpoints.test.ts` (сканирует CSS).

## Замеры (WCAG 2.x, относительная яркость)

| Текст \ фон | paper | paper-2 | card | teal-soft | accent-soft |
|---|---|---|---|---|---|
| `--teal` #2ba39a | 2.67 | 2.46 | 3.08 | 2.60 | 2.56 |
| `--accent` #ec5f73 | 2.81 | 2.60 | 3.26 | 2.74 | 2.70 |
| `--accent-hover` #c94459 (= `--error`) | 4.07 | 3.76 | 4.71 | 3.97 | 3.91 |
| `--ink-2` #7a7264 | 4.11 | 3.79 | 4.75 | 4.01 | 3.94 |
| `--ink-3` #aba191 | 2.20 | 2.03 | 2.55 | 2.15 | 2.11 |
| `--gold` #d9b26a | 1.72 | 1.59 | 1.99 | — | — |

Белый на `--teal` 3.08, на `--accent` 3.26, на `--accent-hover` 4.71. Gold и `--on-plum-*` на plum —
6.2–8.5 (держат). Комментарий в `tokens.css` «`--error` keeps 4.5:1 on paper» — неверен (4.07).

## Где цвет — текст (CSS modules)

- `color: var(--teal)` — 22 правила (19 модулей): тег причины `/match`, «You save», «Online»,
  иконки баланса / оплаты / щита, «Session live», пилюли треда, «Reviewed», ссылка в входе…
- `color: var(--accent)` — 15: активный таб, `PriceTag` (оффер), coupon eyebrow, `Button soft`,
  ссылки (`a` в `tokens.css`), «Show all», «Reset», «Cancel», слот выбранного времени.
- `color: var(--accent-hover)` — 22: ошибки, «late», eyebrow Ask, иконки на accent-soft, день
  ближайшей сессии, выбранный слот.
- Белый на заливке: `Button primary` / `teal`, свой пузырь чата (`.me`), бейджи (таб, список,
  match), `OffChip`, «SALE» купона, точки шагов, таб длительности, кнопка отправки.
- `--ink-2` — 43 правила (+ `.muted`), `--ink-3` — 39 (+ `.eyebrow`, `.muted-3`; подсказки,
  плейсхолдеры, мета, зачёркнутая цена `PriceTag`).
- Gold на светлом — только звёзды рейтинга (иконка рядом с числом — не текст).
- Заливки без текста (точки онлайн, полосы, тумблер, кольцо Ask, обводка фокуса) — не текст;
  фокус-обводка `--accent` на paper 2.81 (< 3:1 для не-текста).

## Противоречия

- Цвета хендоффа ≠ порог хендоффа: сам хендофф красит текст teal / coral. Порог (и правило
  веба) выше палитры → нужны текстовые варианты.
- Приложение — та же палитра; вне задачи (решение владельца, ID — в `aura-app-manor`).
