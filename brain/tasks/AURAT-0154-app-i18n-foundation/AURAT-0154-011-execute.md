# AURAT-0154-011 — execute (fix 010)

2026-11-04, slave-1, та же ветка. Staged, не закоммичено.

- `src/app/i18n/dev-menu.ts` (новый) — `addI18nDevMenu()`: после пункта меню разработчика сообщение
  «i18n → de» / «i18n → pseudo» (Android — `ToastAndroid`, iOS — `Alert`), при ошибке «i18n: failed». Только
  dev-сборки, поэтому английский без перевода. Повторный вызов пункты не дублирует.
- `src/app/i18n/start.ts` — меню вызывается оттуда.
- `src/shared/lib/i18n/start.ts` — `startI18n(namespaces, options)` пробрасывает `strict` в init.
- `jest.setup.js` — тесты стартуют через `startI18n(…, { strict: true })`, тот же путь, что в приложении. Иначе
  `chooseLanguage` в тесте ждал бы старта, которого не было.
- `src/app/i18n/__tests__/dev-menu.test.ts` — оба пункта: язык сменился (`bg`: «Затвори»; pseudo:
  `[Çļöšé~~]`), сообщение показано, повторная регистрация не дублирует пункты. На реальных таймерах:
  глобальные фейковые держат планирование i18next.

Проверки: `jest --no-watchman` — 165 наборов, 1283 теста, все зелёные; `eslint .` — 0 / 0; `tsc` — чисто.

Наблюдение: после отключения диска завис и watchman (Metro в маноре писал «recrawl»), Jest висел до запуска
тестов. С `--no-watchman` всё работает. Для манора: если Metro начнёт тормозить, выполнить
`watchman watch-del-all` (или перезапустить watchman).
