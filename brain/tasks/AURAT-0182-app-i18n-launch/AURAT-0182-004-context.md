# AURAT-0182-004 — context

Дата: 2026-11-07. Код — `slave-0/master` @ `e0ed5de`.

## Готовность переводов (проверено в слоте)

- `npm test`: **3169 / 3169**, 233 набора. Первый прогон дал 17 падений в `entities/campaign` — устаревшие
  `node_modules` слота (`@aura/contracts` 0.29.0 при `v0.30.0` в `package.json`); после `npm ci` — всё зелёное. Код
  ни при чём; заметка для манора — `npm ci` перед сборкой (память «manor node_modules stale»).
- `npm run lint` (`--max-warnings 0`, `i18next/no-literal-string` на весь `src`) и `npm run typecheck` — чисто.
- `translate.mjs check`: 35 namespace, 0 запрещённых форм глоссария (2280 советов — не ошибки).
- `translate.mjs review`: **253 ревью носителями не сделаны** — все `@sensitive` namespace (оплата, пополнение, отмена,
  удаление аккаунта…) во всех 23 языках. По решению 7 `AURAI-0010` — не блокер релиза, блокер маркетинга в стране.
- Что остаётся английским в релизе (известно, решено владельцем): ответы советников в чате (`AURAF-0024`), свои тексты
  кампаний (`AURAT-0192`), юридические страницы (NOT in scope v1); iOS-нативное — `AURAT-0190`.

## Флаг `AURA_I18N_ENABLED` сейчас

- `env/resolve.js:54` — `fallback: false`; ни в одном `env/.env.*` не задан. Тест `env/__tests__/resolve.test.js:330`
  («keeps every rollout flag off in every committed target») держит правило: флаги раскатки включает **команда
  сборки**, не коммит в `.env.*` (как `AURA_META_ATTRIBUTION_ENABLED` — только в `aab:prod` / `apk:prod`).
- Команды: `aab:staging`, `apk:staging`, `aab:prod`, `apk:prod`, `ios:archive:prod` (`package.json:12–16`).
- Читают флаг: `shared/config/env.ts:124` → `shared/lib/i18n/start.ts` (режимы `off` / `system` / `file`,
  `clearLeftoverAppLanguage` — снимает per-app язык, если сборка без флага встала поверх сборки с флагом),
  `resolve-language.ts` (`enabled`), `features/app-language/config/constants.ts:44` (`LANGUAGE_CHOICE_AVAILABLE =
  I18N_ENABLED || __DEV__` — строка Language в Profile). Нативно: `android/app/build.gradle:123` (`auraFlag` через
  `env/flag.js`) → оверлей `src/i18n/AndroidManifest.xml` (`android:localeConfig` — пункт «Язык» в настройках
  Android 13+).
- В прод-сборках строки Language не было никогда (флаг выкл., не `__DEV__`) → **ни у одного пользователя Play нет
  ни `aura-language.json`, ни per-app языка**; миграция файл → `LocaleManager` (`startFromSystem`) касается только
  тестовых телефонов (проверена в `AURAT-0181-011`).

## Версия и что в релизе

- `android/app/build.gradle`: `versionCode 36`, `versionName "1.0.11"` — это AAB в Play (`AURAT-0152-009`, подъём
  `28633b4`). С тех пор в `develop` — вся i18n (0154 … 0181, 0194, 0180) **и** не-языковые правки: история чата
  (0172), бейдж непрочитанных (0176), превью чата на главной (0179), клавиатура Android 15 (0186, 0188), падение при
  восстановлении экранов (0193). Английская версия тоже сильно изменилась (все строки через `t()`, шрифты el/bg,
  форматтеры CLDR).

## Сервер (смотрел локальные ссылки `aura-bff-manor`, fetch 2026-11-07 12:29; прод не трогал)

- Прод = ветка `main` BFF (Coolify production). `origin/main` = `64dbe4d` (2026-11-01) — **ни одной из серверных
  i18n-задач**: 0168 (маркер, `disabledLanguages`, контракты v0.28), 0171 (колода таро, `?lang`), 0173 (подписи
  советников, v0.29), 0184 (персоны), 0189 (сезонные тексты, v0.30) — все только в `develop` (`0410ed7`).
- Между `main` и `develop`: миграции (`advisor_gender`, таблица колоды таро) и сиды советников.
- Выключение языка в проде — env `DISABLED_LANGUAGES` BFF (`src/config/env.schema.ts:227`), то есть Coolify env +
  перезапуск, не релиз.
- Приложение против старого сервера деградирует в английский контент (тесты «a server older than v0.30 … — English»),
  не падает.
