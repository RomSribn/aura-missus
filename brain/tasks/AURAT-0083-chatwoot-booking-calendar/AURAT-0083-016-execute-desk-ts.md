# AURAT-0083-016 — execute: desk.js → TypeScript + тест страницы (2026-10-12)

Владелец (merge gate после `015`): «сначала TS для desk.js».

## Сделано (aura-bff, поверх `0d4f4fa`, не закоммичено)

- `src/modules/agent-desk/client/desk.ts` — исходник виджета на TS; типы ответов
  берутся из `agent-desk.dto.ts` (`import type`) → изменение DTO на сервере
  ломает компиляцию клиента. Логика не менялась, кроме мелочей: стиль блоков
  календаря ставится через CSSOM, ошибки чтения — класс `ReadError`, поля
  ответа моста проверяются как `unknown`.
- `client/tsconfig.json` — DOM-lib, ES2022, `noEmit`; `client/compile.ts` —
  `transpileModule` с этим tsconfig → `assets/desk.js`.
- `assets/desk.js` — **сгенерирован и закоммичен** (сервер, `nest start` и тесты
  отдают одни и те же байты без второго шага сборки). Править только `.ts`,
  потом `npm run desk:build`.
- `package.json`: `typecheck` = `tsc --noEmit && tsc --noEmit -p
  src/modules/agent-desk/client`; новый `desk:build`; devDependency `jsdom`.
- `tsconfig.json` / `tsconfig.build.json` — `client/` исключён из серверной
  программы и из `dist`.
- `desk-page.spec.ts` (9 тестов): `.js` совпадает с компиляцией `.ts`; в jsdom —
  вне iframe только уведомление; запросы контекста/входа только к origin
  Chatwoot; один вход, чтение с Bearer, отрисовка (баланс, отсчёт, списки,
  календарь); чужой origin/окно игнорируются; billing off; 404; 401 сразу после
  входа — сообщение без цикла; отказ Chatwoot.
- README — раздел «Changing the page», строка в дереве модулей; комментарий в
  `agent-desk-assets.ts`.

## Решения по ходу

- `@types/jsdom` **не** ставим: он подключает DOM-lib ко всей серверной
  программе (все `@types/*` попадают в неё автоматически), и typecheck
  `chatwoot.client.ts` ломается (Buffer как BlobPart, web streams). В спеке —
  локальный интерфейс нужного среза jsdom + `require`.
- ESM-ассет в jsdom запускается как обычный скрипт: в тесте убирается
  единственный `export {};`, который TS оставляет после `import type`.

## Проверки

- typecheck (сервер + клиент), eslint `src/**/*.ts` (включая `desk.ts`),
  prettier — чисто. jest: 111 наборов / 1396 тестов — зелёные. Тест
  синхронизации проверен ручной правкой `desk.js` — падает. `nest build` —
  `assets/desk.js` и `desk.css` в `dist`, `client/` в `dist` не попадает.

Застейджено, ждёт ревью → коммит → merge gate.
