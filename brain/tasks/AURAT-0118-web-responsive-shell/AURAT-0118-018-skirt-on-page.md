# AURAT-0118-018 — Подол шторки на странице, а не в fixed-слое

Date: 2026-10-21

## Проверка владельца (`672820d`)

> не рисует

На скриншоте ниже края шторки страница **резкая** — не размыта: обрезан и fixed-скрим (`inset: 0`). При
открытой клавиатуре iOS 26 ниже видимой области не рисует ничего fixed (ни слой, ни его потомков) —
только саму страницу (ср. Apple Developer Forums 800798 «Safari will not render position: fixed content
below the browser controls»).

## Сделано

- `use-visible-viewport.ts`: третья переменная `--visible-bottom` = `visualViewport.pageTop + height` —
  где кончается видимая часть в координатах страницы.
- `sheet.tsx`: портал — обёртка без позиционирования (несёт переменные хука); внутри — fixed-слой (как
  было) и подол `.skirt`.
- `sheet.module.css` (≤ 760): подол — `position: absolute` на странице, `top: calc(var(--visible-bottom) −
  1px)`, `height: calc(100lvh − var(--visible-h))` (≈ высота клавиатуры; при закрытой — почти 0, за низом
  экрана), `z-index: 99` (под слоем 100), фон `--paper`, без указателя. `overflow: visible` у слоя и
  подол внутри слоя (`017`) убраны.
- Тесты: хук — `--visible-bottom` (прокрутка 1200 + панорама iOS → 1937px); шторка — подол сосед слоя,
  `aria-hidden`.
- Проверки: lint, typecheck, prettier — чисто; полный прогон — зелёный. Коммит в ветку.
