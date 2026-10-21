# AURAT-0118-010 — Execute (fix 009: шторка под клавиатурой)

Date: 2026-10-21
Ветка `feature/AURAT-0118-web-responsive-shell` (slave-2). Не закоммичено — на ревью.

## Что сделано

- `shared/lib/browser/use-visible-viewport.ts` (в группе `browser/` — обёртки браузерных API; 16-й модуль
  в корне `shared/lib` Steiger не пускает, `fsd/shared-lib-grouping`): пока шторка открыта, на элементе
  слоя — `--vv-top` / `--vv-height` из `window.visualViewport` (`resize` и `scroll`); при `resize`
  (клавиатура появилась / ушла) поле в фокусе внутри — `scrollIntoView({ block: 'nearest' })`. При
  закрытии переменные снимаются; без `visualViewport` — ничего.
- `shared/ui/sheet/sheet.tsx` — `ref` на слой, хук рядом с `useModal`.
- `sheet.module.css` (≤ 760): слой — `top: var(--vv-top, 0)`, `bottom: auto`,
  `height: var(--vv-height, 100%)`; шторка — `max-height: 92%` высоты слоя (было `92dvh`). Шторка
  стоит над клавиатурой; не влезает — прокручивается внутри. Desktop не затронут (переменные
  пишутся, но применяются только на телефоне).
- Тест `shared/lib/__tests__/use-visible-viewport.test.tsx` (4): переменные выставляются, следуют за
  `resize` и `scroll`, снимаются при закрытии; поле в фокусе доводится в вид; без `visualViewport` —
  ничего.

## Проверки

lint (eslint + steiger), typecheck, prettier — чисто; `npm test` — 77 файлов, 1325 тестов, зелёные;
build — ок. Поведение на iPhone в слоте не проверить (jsdom не знает клавиатуры) — проверка владельцем в
маноре после мёржа.

## Проверка вживую

iPhone: из Book → вход: телефон с клавиатурой — шторка целиком над клавиатурой, Send code виден;
«Enter the code» — сразу над клавиатурой, без доскролла; назад к телефону; вход из шапки (Log in);
шторка без полей (Filters, Reschedule) — как раньше.

## Коммит (владелец, 2026-10-21)

Владелец проверил на iPhone — «все так же»; но dev-сервер на `:5173` запущен из манора
(`manor/master/aura-web`, develop `f5b222a`), фикса там ещё нет. Решение владельца: закоммитить фикс,
дальнейшие правки — следующими коммитами. Коммит — см. `011`.
