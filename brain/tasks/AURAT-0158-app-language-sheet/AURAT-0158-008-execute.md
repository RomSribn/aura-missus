# AURAT-0158-008 — execute

Дата: 2026-11-05. slave-1, `feature/AURAT-0158-app-language-sheet`. Не закоммичено — ждёт ревью владельца в IDE.

## Файлы (aura-app)

Новый слайс `src/features/app-language/`:
- `config/language-names.generated.ts` — 24×24 имён из Node 22.23 / ICU 78.2 / CLDR 48; генератор
  `scripts/i18n/generate-language-names.mjs` (вывод стабилен под prettier).
- `config/constants.ts` — `SHEET_LANGUAGES` (English, латиница, Ελληνικά, Български), `LANGUAGE_CHOICE_AVAILABLE =
  I18N_ENABLED || __DEV__` с комментарием о причине, `LIST_HEIGHT_RATIO = 0.58`.
- `config/locales/` — пространство `app-language`, 24 языка: `row`, `title`, `untranslated`, `device`, `choose`.
- `lib/language-names.ts` (`ownName`, `nameIn`), `lib/language-options.ts` (строки листа).
- `model/types.ts`, `model/use-language-sheet.ts` — `useLanguageSheet(onClose)`, `useLanguageRow()`.
- `ui/LanguageSheet.tsx` — лист; `LanguageList` монтируется на каждое открытие и прокручивает к отмеченной строке.
- `index.ts`; тесты `config/__tests__/{language-names,constants}.test.ts`, `ui/__tests__/LanguageSheet.test.tsx`.

Профиль: `config/constants.ts` (`id`, строка `language`, тип `ProfileMenuEntry`), `model/types.ts` (+`'language'`),
`model/use-profile.ts` (фильтр по строке: promo — биллинг, language — `LANGUAGE_CHOICE_AVAILABLE`),
`ui/ProfileMenu.tsx` (ключ `id`, значение справа `numberOfLines={1}`, `accessibilityValue`),
`ui/ProfileScreen.tsx` (лист), тест `ui/__tests__/ProfileLanguage.test.tsx`.

Общие: `src/shared/index.ts` (+`I18N_ENABLED`, +`systemLanguage`), `src/app/i18n/namespaces.ts` (+`appLanguageI18n`),
`jest.setup.js` (+`__NODE_DISPLAY_NAMES__`), `.eslintrc.js` (`no-literal-string` на слайс).

## Решения по ходу

- Черновик производный (`выбрано ?? текущий`), сбрасывается в `onClosed` — верен уже на первом кадре открытия,
  без эффекта; применение — `chooseLanguage` в `onClosed`, только если выбор отличается от текущего.
- «Текущий выбор» = `'device'`, когда язык на экране = языку системы (иначе сам язык) — без чтения файла.
- Подсказка под строкой языка интерфейса не показывается (то же слово); у «Device language» — самоназвание языка
  системы.
- Подзаголовок: «Advisor profiles and tarot cards stay in English for now.» (`007`).

## Проверка

`npx tsc --noEmit` — чисто; `npm run lint` — чисто; `npx jest --no-watchman` — 176 наборов, 1597 тестов, все зелёные;
`translate.mjs check` — 0 запрещённых форм, 15 советов (падежи и сложные слова: Tarotkarten, Gerätesprache —
не ошибки).

## Открыто

- Живое — в маноре: лист на устройстве (высота списка, автопрокрутка, индикатор), el/bg шрифтами, VoiceOver
  (`radiogroup`, голос самоназваний), TalkBack.
- `systemLanguage` на iOS до шага 4 всегда `en` (бандл объявляет только en) — «Device language» там = English.
- Переводы не проверены носителями (не блокирует — не платёжные тексты).
- `shared/index.ts` и `jest.setup.js` правит и `AURAT-0159` — возможен тривиальный конфликт слияния.
