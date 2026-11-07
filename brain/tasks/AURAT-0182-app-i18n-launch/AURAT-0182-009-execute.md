# AURAT-0182-009 — execute

Дата: 2026-11-07. Слот `slave-0`, ветка `feature/AURAT-0182-app-i18n-launch` (от `e0ed5de`). Всё застейджено, без
коммитов. По спеке `007` (одобрение — `008`).

## Приложение (`slave-0/master`)

- `package.json` — `AURA_I18N_ENABLED=true` в `aab:staging`, `apk:staging`, `aab:prod`, `apk:prod`;
  `ios:archive:prod` не тронут (iOS английский до `AURAT-0190`).
- `android/app/build.gradle` — `versionCode 37`, `versionName "1.1.0"`.
- `env/__tests__/release-commands.test.js` (новый): четыре Android-команды ставят флаг и резолвер с их окружением
  даёт `true`; `ios:archive:prod` — нет, резолвер даёт `false`. Страж «в закоммиченных `.env.*` флаги выключены»
  (`resolve.test.js`) не тронут.
- `env/README.md` — строка `AURA_I18N_ENABLED` и абзац: на каких командах включён, почему не на iOS, что Gradle делает
  с манифестом, флаг уходит после iOS. Файл и до правки не был отформатирован prettier (таблицы) — не переформатировал.
- `src/shared/config/env.ts` — комментарий у `I18N_ENABLED`.

Проверки в слоте: Jest **3174 / 3174** (234 набора; +5 новых), `npm run lint` (`--max-warnings 0`) и
`npm run typecheck` — чисто. `node env/flag.js AURA_I18N_ENABLED` с `AURA_ENV=prod AURA_I18N_ENABLED=true` → `true`,
без флага → `false` (то, что Gradle читает для оверлея манифеста). Gradle, AAB / APK в слоте не собирались.

## Workspace

- `.claude/aura-build-rules.md`, раздел Translations — только одна строка: «Until the launch task, the app runs in
  English behind `AURA_I18N_ENABLED`» → «`AURA_I18N_ENABLED` is on in the Android release commands (`AURAT-0182`);
  iOS stays English until `AURAT-0190`». Не застейджено: в файле чужие правки, коммит — за координатором.

## Brain

- `AURAT-0182-release-notes.md` — «что нового» en-US + 21 язык (коды как в `AURAT-0183`), блок для Play Console,
  длины (fr — 495 / 500, остальные ≤ 473), как вставлять, порядок со страницей 0183.
- `006-review`, `007-spec-v2`, `008-approval`, этот файл.

## Дальше (координатор, манор)

1. `wts-finish` (merge gate) → в маноре `npm ci` → staging-APK → проверка на устройствах, 13 пунктов из `007`
   → `0182-0NN-device-check.md`.
2. После проверки — строки `AURAF-0023` 001 / 003 / 004 → ✓, шаг 4 — 0182 done (`007` п. 6).
3. Прод-BFF — после 0191 и 0192, чек-лист в `007`; AAB 37 — `npm run aab:prod`, страница 0183 — до релиза или с ним.

Открытое: задачу «убрать флаг после `AURAT-0190`» ещё не выдали — ID от координатора.
