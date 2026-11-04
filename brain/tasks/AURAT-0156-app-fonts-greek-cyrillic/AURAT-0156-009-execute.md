# AURAT-0156-009 — execute

Дата: 2026-11-05. slave-0, `feature/AURAT-0156-app-fonts-greek-cyrillic`. По `007-spec-v2` и мелочам из `008`.
Не закоммичено, всё в индексе — на ревью владельцу.

## Файлы (aura-app)

- `scripts/fonts/`:
  - новое: `build_fonts.py`, `fit.py`, `merge.py`, `transplant.py`, `verify.py`, `sources.py`,
    `exemplars.py`, `sources.json`, `requirements.txt`, `README.md`;
  - сгенерированное: `exemplars.json` (буквы CLDR 48.2 для 24 языков).
- 7 TTF в `src/shared/assets/fonts` и `android/app/src/main/assets/fonts` — пересобраны:
  726 → 852 КБ (Bricolage 134–137 КБ, Hanken 101–106 КБ).
- `src/shared/assets/fonts/OFL-Commissioner.txt` — новый.
- `ios/PsychoApp.xcodeproj/project.pbxproj` — +4 строки (OFL-Commissioner как ресурс, по образцу
  OFL-HankenGrotesk).
- `android/` и `ios/link-assets-manifest.json` — новые sha1 и запись OFL-Commissioner.
- `src/shared/config/__tests__/fonts.test.ts` — чтец TTF (`cmap` 4/12, `hhea`, `head`, `name`) и проверки:
  - буквы CLDR всех 24 языков + U+00A0 U+202F U+2212 U+2010 U+2011 в каждом лице;
  - name ID 6 = имя файла;
  - `NATURAL_LINE` по `hhea`;
  - android-копии побайтно равны;
  - `OFL-Commissioner.txt` на месте.
- `src/app/i18n/__tests__/translations.test.ts` — из `FORBIDDEN` убраны U+2010 / U+2011.
- `.gitignore` — `scripts/fonts/.cache/`, `scripts/fonts/__pycache__/`.

Вне aura-app: строка «Fonts cover all 24 languages» в `.claude/aura-build-rules.md`, раздел Translations
(workspace-репозиторий). Не застейджено: этот файл сейчас правит и 1b.

## Решения по ходу

- Исходники — из git: `git show 5f8d55f:<path>` (коммит, где шрифты появились) + sha256 каждого
  (`008`, мелочь 3).
- Манифесты react-native-asset скрипт обновляет сам. `npx react-native-asset` в проекте не установлен, а
  `npx` скачал бы непривязанную версию. Поэтому запись OFL в `project.pbxproj` добавлена вручную, по образцу
  существующей.
- OFL-Commissioner — как два прежних OFL: в `src/…/fonts`, в iOS-ресурсах и манифестах. Android-копии нет и у
  прежних OFL: react-native-asset копирует в Android только шрифты.
- Найдена и исправлена ошибка запасного варианта `hankenGreek.use = "donor"`: имя `uni0394` совпало со
  старым Δ Hanken. Теперь новому глифу дописывается `.aura`. Основная сборка от этого не изменилась.

## Проверено

- `build_fonts.py` проверяет перед записью и падает, если:
  - изменился хоть один исходный глиф, `hmtx`, `fpgm`/`prep`/`cvt`/`gasp`, hhea/OS/2-метрика, имя,
    `head.modified` или прежний lookup GSUB/GPOS;
  - не хватает буквы CLDR.
- Все 7 лиц прошли.
- `--check` после записи: «Up to date». В чистом venv только из `requirements.txt` — тоже «Up to date»:
  побайтно воспроизводимо.
- `npx tsc --noEmit` — 0 ошибок. `npm run lint` — чисто. `npx jest` — 165 наборов, 1294 теста, все зелёные.
- Негативная проверка: исходный `HankenGrotesk-Regular.ttf` из `5f8d55f` валит покрытие el/bg и проверку
  android-копий. Файл возвращён.
- Рендер HarfBuzz + FreeType с итоговых файлов: el/bg во всех начертаниях, «Το Aura» кернится, латиница как
  была.

## Открыто

- Взгляд дизайнера на греческий Hanken из апстрима.
- Манор после merge: iOS-симулятор и Android, список из `007` § «Проверка».
- `AURAF-0023-006` остаётся ✗, пока это не проверено в маноре.
