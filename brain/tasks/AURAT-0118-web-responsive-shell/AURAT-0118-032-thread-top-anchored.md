# AURAT-0118-032 — Тред: привязка сверху и только при наборе (как Telegram Web A)

Date: 2026-10-21

## Слова владельца (проверка `dc44757`)

> отступ такой же. К тому же, когда клавиатура закрывается, страница остается на прошлом месте и
> неактивно до повторного тапа. Я посмотрел, телеграм веб работает идеально в плане чата, посмотри есть
> ли open source код его или схожих чат проектов для веба, посмотри как чат реализован там. Можешь так же
> посмотреть чатвут реализацию

## Исследование (клоны только для чтения в scratchpad)

- Telegram Web A (`Ajaxy/telegram-tt` `f67a408`): `--vh` = `vv.height + vv.pageTop` (`util/windowSize.ts`);
  поиск в чате (`MiddleSearch.tsx`) — `translateY(vv.pageTop)` + `height = vv.height` **только пока поле в
  фокусе**, иначе сброс к CSS; `MiddleColumn.tsx` — при закрытой клавиатуре и `offsetTop ≠ 0` —
  `window.scrollTo({ top: 0 })`; `body.keyboard-visible` убирает safe-area под композером.
- Telegram Web K (`morethanwords/tweb` `1da254b`): `--vh` из `innerHeight`, клавиатуру не отслеживает
  (код по visualViewport выключен), `html.is-ios { position: fixed }`; шрифт композера ≥ 16px в a11y-режиме.
- Chatwoot (`642205c`): клавиатуру не обрабатывает (виджет — iframe во весь экран).
- iOS 26: WebKit 297779 (Apple: «bottom:0 — над панелью Safari»; `offsetTop` ≈ 24 после закрытия),
  WebKit 300523 (открыт), Apple Forums 800125 (значения обновляются только после касания). Ни у кого нет
  кода под iOS 26.

## Сделано

- `chats-page.module.css` (≤ 760): `.threadOpen` — `top: calc(var(--visible-top) × var(--keyboard-up))`,
  `height: calc(100% + (var(--visible-h) − 100%) × var(--keyboard-up))`, без `bottom`: при наборе — ровно
  видимая часть сверху, без набора — полный экран из CSS.
- `use-visible-viewport.ts`: `--visible-top` (= `offsetTop`); `fullScreen` — при потере фокуса полем окно к
  началу сразу и через 100 / 300 / 600 мс (с перечиткой видимой области).
- `composer.module.css`: отступ под полосу «домой» × `(1 − --keyboard-up)` — при наборе его нет.
- Тесты хука (+3): `--visible-top`; `fullScreen` — `scrollTo(0, 0)` на blur и ещё 3 раза; без `fullScreen` —
  нет. Полный прогон 77 / 1339 — зелёный; lint, typecheck, prettier — чисто. Коммит в ветку.
- Шторки не менялись (одобрены владельцем); если привязка сверху подтвердится на треде — кандидат и для них.

Гипотеза о зазоре (низ fixed-элемента над панелью Safari, а не низ видимой области) — по словам Apple в
WebKit 297779; на устройстве не проверена.
