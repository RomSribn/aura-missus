# AURAT-0170-009 — execute: правки по ревью (008)

Дата: 2026-11-06 · Не закоммичено — на ревью владельца.

1. `overflow-wrap: anywhere` — `pages/daily/ui/daily-page.module.css` `.name`, `pages/home/ui/daily-banner.module.css` `.title`, `features/tarot-pick/ui/tarot-picker.module.css` `.resultName`, `shared/ui/sheet/sheet.module.css` `.titles` (заголовок листа карты = имя карты). `hyphens: auto` не ставил — меняет перенос обычных заголовков. Проверка в маноре: da / fi / sv при 360px.
2. `useDisabledLanguages` до ответа app-config (и при ошибке) отдаёт список, сохранённый в браузере (`keptDisabledLanguages`, теперь экспорт `shared/i18n`); переключение на английский — по-прежнему только после ответа.
3. Тест guard «ничего не выключено» ждёт, пока ответ применится (сохранённый `["mt"]` исчезает), и только потом проверяет `mt`.
4. Тесты: опоздавший ответ на `en` (отложенный промис) отпущен после «Die Sonne» — на экране остаётся «Die Sonne»; `current-language.test.ts` (`pl`, `de-AT` → `de`, нет языка / `uk` → `en`); профиль — до ответа сохранённый список скрывает язык.
5. Выбор во вкладке (`chosenInTab` в `language-choice.ts`) — важнее хранилища: при заблокированном `localStorage` применение списка не откатывает выбор на язык браузера.
6. bg `tarot-pick:open` → «Отвори в цял размер: {{card}}».
7. docstring `currentLanguage` — без обещания про Профиль. Отступление от спеки 005 §1: `use-languages.ts` не переведён на `currentLanguage` — ему нужен `null`, пока язык не определён.

`typecheck` ✓, `lint` (eslint + steiger) ✓, `vitest` 1915 / 1915 ✓, `build` ✓.
