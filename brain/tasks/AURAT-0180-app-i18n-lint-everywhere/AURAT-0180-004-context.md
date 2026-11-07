# AURAT-0180-004 — context

Дата: 2026-11-07. Замеры — `eslint-plugin-i18next` 6.1.5, ESLint 8.57.1, слот slave-3 @ `71e03d2`.

## Как правило работает сейчас (`.eslintrc.js:66-125`)

- `files` — 31 перечисленный путь `*.tsx`. Вне: `src/app/**`, `features/push`, `features/sign-out`, `shared/**`
  кроме `shared/ui`, все `.ts`.
- `jsx-attributes.include` — это **белый список** (`shouldSkip`: атрибут не из `include` пропускается целиком, вместе со
  всем, что в его значении). `ListEmptyComponent={<Text>…</Text>}`, `renderItem={() => <Text>…</Text>}`,
  `onPress={() => Alert.alert('…')}` правило не видит.
- `mode: 'jsx-only'` — строки вне JSX (хуки, конфиги, `.ts`) не проверяются.

## Замеры по всему `src` (без тестов, `test-support`, `config/locales`)

| Вариант | Находок | Что в них |
|---|---|---|
| нынешние опции, весь `src` | 2 | технические (`AuraTabBar`: имя иконки, `type: 'tabPress'`) |
| `jsx-only`, все атрибуты | 371 | все технические: `accessibilityRole` 75, `name` иконок 75, `edges` 26, `pointerEvents` 22, `variant` 21… |
| `all`, без типов | 1834 | технические |
| `all`, **с типами** (`parserOptions.project`) | 247 в 91 файле | технические: пути BFF, цвета темы, `displayName`, ключи списков, SVG, dev-меню, `new Error(…)` |
| `all`, с типами + исключения (прототип) | 10 | dev-меню (5), запасные имена файлов (2), `fb_content_type`, имя форматтера i18next, строка CSS-тени |

**Пользовательского английского в коде нет** ни в одном варианте — всё уже через `t()` (`0154`…`0179`). Задача
сводится к правилу, которое ловит *будущие* утечки, не мешая технике.

С типами правило пропускает строку, чей контекстный тип — литерал или объединение литералов (имена иконок, `variant`,
`accessibilityRole`, `keyboardType`, `edges`, имена маршрутов): это то, что делает `all` пригодным.

## Проверка ловли (пробный файл, удалён)

Пойманы 17 из 18: JSX-текст, `{'…'}`, `` {`${n} min`} ``, тернарник, `accessibilityLabel` / `Hint`, `placeholder`,
`Alert.alert('…')` в `onPress`, `renderItem` / `ListEmptyComponent`, `const title = '…'` и `{ title: '…' }` в хуке,
одиночное `'or'`. **Не пойман** `const LABEL = '…'` — плагин безусловно пропускает переменные в UPPER_CASE (36 таких
строковых констант в `src` — все технические).

## Прочее

- Существующие исключения: `SplashScreen.tsx:59` («Aura», бренд) — остаётся; `CountryPickerSheet.tsx:56` — при новых
  шаблонах слов станет ненужным (`eslint-comments/no-unused-disable` упадёт) — убрать.
- Время `eslint .`: ~9 с → ~12 с с типами (замер грубый, шёл параллельно с другим прогоном).
- Глоссарий: `scripts/i18n/glossary.json` v3; `glossary.test.ts` требует у каждого `avoid` пример, который он находит,
  и чтобы `avoid` не ловил канонический `use`. Новые формы в переводах приложения не встречаются (grep).
- BFF держит копию `avoid` v3 + 4 `local` формы (`glossary-avoid.spec-fixtures.ts`, «Belongs in the glossary itself
  (v4)»); веб берёт копию по `version` (`AURAT-0177`).
- Правило «Translations» в `.claude/aura-build-rules.md`: «`i18next/no-literal-string` … `error` for every slice already
  moved; add the slice's paths when its move lands» — устареет. Файл сейчас изменён в рабочей копии воркспейса другой
  сессией (`git status`: `M .claude/aura-build-rules.md`).
- Соседи (`0181` slave-0, `0188` slave-2): изменений пока нет.
