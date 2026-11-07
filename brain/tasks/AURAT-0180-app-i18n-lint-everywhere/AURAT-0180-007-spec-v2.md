# AURAT-0180-007 — spec v2 (ждёт одобрения владельца)

Дата: 2026-11-07 · задача (строка 4 `AURAF-0023`) · P1 · слот slave-3. Заменяет `005`. Учтены все 13 замечаний
ревью `006` (номера в скобках). Замеры — прототип `.eslintrc` на `src` @ `71e03d2`. Прототип и пробники лежат в
scratchpad слота, в репозитории их нет.

## Итог разведки

Английского текста в интерфейсе нет: всё, что находит самый строгий вариант правила, — техника. Поэтому задача —
**правило-сторож** на весь `src`: поймать будущую утечку и не шуметь на технике. Переводить нечего. Хвосты `0184` —
§4–5.

## 1. Правило

Список из 31 слайса заменяется одним override `src/**/*.{ts,tsx}`.

**Вне правила:** `**/__tests__/**`, `src/test-support/**`, `**/config/locales/**`, `src/shared/config/theme.ts`
(только цвета), `**/*.generated.ts`, **`src/**/api/**`**. Сегмент `api/` — по FSD только транспорт: в нём ни одного
`t()`, а хвосты путей в шаблонах (`` `${advisorPath(id)}/sessions` ``) по виду не отличить от переводимого `'/min'`
(6). Новое по сравнению с `005`.

**Опции `i18next/no-literal-string`:**

- `mode: 'all'` и **`'should-validate-template': true`**. Флаг указывается явно: по умолчанию он `false`, а опции
  сливаются неглубоко (7). Строки проверяются везде: `.ts`, хуки, конфиги, `Alert.alert` в `onPress`, render-пропсы.
- **Разбор с типами** (`parserOptions.project` — только в этом override). Правило пропускает литерал, чей
  контекстный тип — строковый литерал. Обычно это объединения литералов (имена иконок, `variant`,
  `accessibilityRole`, `keyboardType`, `edges`, маршруты), но так же пропускается литерал, **выведенный в дженерик**:
  то, что возвращает `useCallback`, и identity-хелперы вроде `pick<T>(a: T, b: T): T` (4). Хуки закрывает селектор
  ниже; `pick<T>` — принятая дыра. Без типов — 1834 находки, с ними — 247.
- **Атрибуты проверяются все**, белого списка `include` нет.
- **Исключения** = умолчания плагина + записи ниже. Абляция: каждая запись снималась по одной на всём `src`; записи,
  без которых число находок не растёт, убраны совместным прогоном (итог тот же).

| Опция | Добавлено к умолчаниям | Без записи находок больше на |
|---|---|---|
| `callees` | `Error` (конструктор), `console\.\w+`, `i18next\.(on\|off)` | 5 / 3 / 3 |
| `object-properties` | `displayName`, `id`, `Authorization`, `transformOrigin`, `overScrollMode` | 35 / 2 / 1 / 1 / 1 |
| `jsx-attributes` | `testID`, `fill`, `stroke`, `transform`, `clipPath`, `preserveAspectRatio` | 1 / 8 / 1 / 1 / 1 / 1 |
| `words` | знаки, символы, цифры, пробелы `/^[\p{P}\p{S}\p{N}\s]+$/u` (` · — – → … ✓`) | 73 |
| | `rgb(` / `rgba(` · единица CSS `/^-?[\d.]*(?:deg\|px\|%)$/` · ISO-время `/^T\d\d:\d\d(?::\d\d)?$/` | 3 / 9 / 3 |
| | токен `/^[a-z][A-Za-z0-9]*(?:[._:=][A-Za-z0-9]*)+$/` (`photo.jpg`, `state_changed`, `key:`, `after=`) | 6 |
| | токен с дефисом **только в конце** `/^[a-z][a-z0-9-]*-$/` (`local-`, `draft-`, `aura-orb-`) | 4 |
| | `transparent` | 7 |

  Сужено по ревью (5, 6). Вызовы: вместо `\w*Error` (ловил `setError`, 44 места) — только конструктор `Error`; голых
  `on` / `off` / `get` / `set` больше нет. Шаблон пути / URL снят совсем (после выноса `api/` он не нужен); в токене
  нет `/` и внутреннего `-`, так что `'/min'`, `` `${p}/min` ``, `'e-mail'`, `` `${n} check-ins` `` ловятся.
  Сознательно **не** исключены ключ `name` (иначе прошло бы `{ name: 'Advisor' }`) и одиночные строчные слова
  (`` `${n} min` `` должен ловиться). Умолчание «ключ в UPPER_CASE» остаётся. Тема вне правила, поэтому сейчас оно
  ничего не освобождает, но значение под таким ключом закрывает селектор ниже.

**Селекторы `no-restricted-syntax`** — три дыры, которые плагин освобождает безусловно (1, 2, 4). Текст:
`/\p{L}\s+\p{L}/u` — два слова и больше; для дефолтов и хуков ещё `^\p{Lu}\p{Ll}+$` — слово с заглавной.
Ключи свойств (`Property > Literal.key`) не проверяются.

1. **UPPER_CASE.** Под `VariableDeclarator` или `Property`, чьё имя подходит под регэксп плагина `/^[A-Z_-]+$/`,
   проверяется всё поддерево: `Literal`, `TemplateElement`, `JSXText` (объекты, массивы, тернарники, шаблоны, JSX).
   Однословная константа (`const RETRY = 'Retry'`) — **принятая дыра**: однословный шаблон шумел бы на `SCREENS`
   (`'Home'`, `'All'`, `'Root'`). Сейчас селектор срабатывает в одном месте — `store-topup/config/products.ts:25`
   `STORE_NAME` («App Store» / «Google Play», бренды): там disable с причиной.
2. **Дефолты.** `AssignmentPattern` — то же поддерево: дефолты параметров и деструктуризации (`{ title = '…' }`). В
   `src` 0 срабатываний: все 15 строковых дефолтов — токены или hex.
3. **Хуки.** `CallExpression[callee.name=/^use(Callback|Memo)$/]` — то же поддерево, кроме аргументов `console.*` и
   `new …Error`. В `src` 0 срабатываний.

**Где они живут (3).** В eslintrc опции правила в override **заменяют** корневые. Поэтому корневой селектор
display-шрифта выносится в константу `DISPLAY_FONT_LINE_HEIGHT`: корень использует `[DISPLAY]`, i18n-override —
`[DISPLAY, UPPER, DEFAULTS, HOOKS]`. В корень новые селекторы класть нельзя: тесты держат UPPER-константы с текстом
(`AdvisorsScreen.test.tsx:16` и др.), а в override тесты исключены. В пробнике стиль display-шрифта без `lineHeight`
по-прежнему падает.

**Остаток — явные исключения** `// eslint-disable-next-line <rule> -- <причина>` (10 мест в 6 файлах):

- `app/i18n/dev-menu.ts` — одно на весь файл (5 строк): меню только для dev-сборок, английский намеренно;
- `features/chat/model/use-attachment-draft.ts:112, 202` — запасные имена файлов `pasted` / `file`: это данные,
  уходят на сервер;
- `features/profile-photo/model/use-profile-photo.ts:95` — MIME `image/jpeg`;
- `features/store-topup/config/products.ts:25` — `STORE_NAME`, бренды (селектор UPPER);
- `shared/lib/attribution.android.ts:78` — `fb_content_type: 'product'`, параметр SDK;
- `shared/lib/i18n/init.ts:118` — имя форматтера i18next `lowercase`.

Убирается ставшее ненужным исключение `CountryPickerSheet.tsx:56` (иначе `eslint-comments/no-unused-disable`).
`SplashScreen.tsx:59` («Aura», бренд) остаётся.

**Цена:** `eslint .` — 9–10 с → 11–13 с (два прогона).

### Пробник (прогнан на прототипе)

Два файла по 60 случаев: мой и ревьюера (`probe-0180/probe.tsx`). **Пойманы:** JSX-текст, `{'…'}`, `` `${n} min` ``,
тернарник, `accessibilityLabel` / `Hint`, `placeholder`, `Alert.alert` в `onPress` и в колбэке `.on(…)`,
`setError('…')`, `map.set(…, { label })`, `renderItem` / `ListEmptyComponent`, `{ title }`, `headerTitle`,
`tabBarLabel`, `Platform.select`, `useState('…')`, `useMemo` / `useCallback` (селектор), `as const`, `satisfies`,
шаблонный тип, `'/min'`, `` `${p}/min` ``, `'e-mail'`, `` `${n} check-ins` ``, `{ name: 'Advisor' }`, `'or'`,
дефолт параметра и деструктуризации, UPPER-объект / массив / тернарник / шаблон / JSX, `{ TITLE: '…' }`, стиль
display-шрифта без `lineHeight`. **Не пойманы (принятые дыры):** `pick<T>(c, 'a', 'b')` (литерал, выведенный в
дженерик) и `const RETRY = 'Retry'` (однословная UPPER-константа).

### Решение 1 — вариант правила

- **(а) `all` с типами** — §1. Рекомендую.
- **(б) `jsx-only` на все `.tsx`.** Дёшев только с белым списком атрибутов — а он и был дырой (`renderItem`,
  `ListEmptyComponent`, `Alert` в `onPress` снова не проверяются). Без белого списка — 371 техническая находка: нужны
  те же типы, та же цена, что у (а). И `.ts` (хуки, тексты пушей в `model/*.ts`) (б) не видит вовсе (13).

## 2. База

`npx eslint . --max-warnings 0` — код выхода 0 (8). Тест переводов (`src/app/i18n`), `tsc`, полный `jest` — зелёные.
`translate.mjs check` — без новых замечаний.

**Решение 3 (мелкое, 8):** скрипт `lint` в `package.json` → `eslint . --max-warnings 0`, чтобы предупреждение
(в том числе ненужный disable) роняло `npm run lint`. Сейчас `eslint-comments/no-unused-disable` — warn, CI и
git-хуков нет. Рекомендую — да. Без решения владельца не меняю.

## 3. Решение 2 — защита самого конфига

- **(а) Ничего.** Пробник прогоняю вручную на готовом конфиге, результат — в `execute`.
- **(б) Jest-тест**, который гонит ESLint по пробным файлам. Типизированный разбор в Jest — секунды на каждый прогон.
- **(в) Закоммиченный пробник (9).** Модуль, который никто не импортирует (Metro его не собирает), с утечками; у
  каждой — `// eslint-disable-next-line … -- probe: must stay caught`. Если конфиг ослабят, disable станет ненужным, и
  линт упадёт. Нужно решение 3 (или `no-unused-disable: error`). Цена — ~0 с и один файл. Против — исключение из
  жёсткого правила 5 (экспорт без потребителей).

Рекомендую **(в)** при «да» по решению 3: защищает от тихого ослабления (лишний шаблон слов, потерянные типы или
селектор) почти бесплатно. Иначе — (а).

## 4. Глоссарий v4 (хвост `0184`; 10)

`scripts/i18n/glossary.json`, термин `reader`, `version` 3 → 4. У каждой формы — пример, который она находит
(`glossary.test.ts`). Каждая форма проверена: канонический `use` она не ловит.

| Язык | Форма (режим) | Пример |
|---|---|---|
| fr | `lectric` (stem) | «Une lectrice peut explorer cette carte» |
| it | `lettric` (stem) | «Una lettrice può esplorare la carta» |
| it | `lettore` → **`lettor`** (stem) | «I lettori possono esplorare la carta» |
| ro | `cititoa` (stem) | «O cititoare poate explora cartea» |
| sk | `čitatel` (stem; ľ → l) | «Čitatelia môžu preskúmať kartu» |
| sl | `bralk` (stem) | «Bralka lahko razišče karto» |
| sl | `bralc` (stem) | «Vprašaj bralca o karti» |
| da | `læseren`, `læsere`, `læserne` (word) | «Læseren kan udforske kortet» и т. д. |

В локалях приложения it / sk / da этих форм нет. `læser` в датском — ещё и глагол «читает» (`home/da.ts:28`
«Læser stjernerne…»), поэтому основа `læser` не годится: добавляются только формы существительного, в режиме
`word`. Формы стоят на границе слова: `électricité`, `elettrico` не ловятся.

**Передача после мёржа (BFF-задачу открывает координатор):** BFF держит копию глоссария. `AURAT-0189` (bff
slave-3) переносит её из `src/modules/advisors/labels/glossary-avoid.spec-fixtures.ts` в
`src/common/language/*.spec-fixtures.ts`, поэтому передача — под новое место: `GLOSSARY_VERSION = 4`, шапка «Copied
from aura-app `scripts/i18n/glossary.json`, version 4», убрать абзац про local extension и пометки `/* local */`,
`lettore` → `lettor`, добавить `čitatel` и датские формы, прогнать `advisor-labels.spec`. **Веб** — заметка в
`AURAT-0177` (копии там пока нет): брать v4.

## 5. Комментарий (хвост `0184`)

`src/screens/advisor-profile/model/use-advisor-profile.ts:42` → «Opens the conversation with this advisor (no-op if it
already exists), then jumps to that thread in the Chats tab. The greeting is the thread's UI-only intro bubble — never
stored or sent.» (текст из `0184-009`).

## 6. Документы (11, 12)

- `.eslintrc.js` — комментарии override и селекторов: что вне правила и почему, как ставить исключение.
- `AURAF-0023-glossary.md` — «Копии»: BFF → v4 без local; «Версии»: строка v4 (`AURAT-0180`: женские, косвенные и
  множественные формы `reader`).
- `AURAF-0023` строка 4 — отметить линтер.
- `.claude/aura-build-rules.md`, «Translations» — пункт «`i18next/no-literal-string` … add the slice's paths when its
  move lands» заменить на: «`i18next/no-literal-string` covers all of `src` (typed, `mode: 'all'`), except tests,
  `test-support`, `config/locales`, `api/` segments, `theme.ts` and generated files; three `no-restricted-syntax`
  selectors close what the plugin skips — UPPER_CASE constants and keys, default values, `useCallback` / `useMemo`
  bodies. A technical string the patterns do not cover takes `// eslint-disable-next-line i18next/no-literal-string
  -- <reason>`; a one-word UPPER_CASE constant is not checked.»

  **Как вносить (12):** чужой незакоммиченный кусок (+20 строк, 435–454) стоит вплотную к этому пункту (455) и
  сольётся с правкой в один hunk. Поэтому строку вношу не я: координатор вносит её **после коммита того куска**.
  Если ждать нельзя — отдельным патчем через `git apply --cached` и проверкой `git diff --cached` (в нём ровно один
  изменённый пункт). Текст замены — выше.

## 7. Проверка в маноре (координатор)

Рантайм не меняется (конфиг линта, глоссарий, комментарии, disable) — без Metro и устройства:
`npm ci` → `npx eslint . --max-warnings 0` (код 0) → `npx tsc --noEmit` → `npx jest src/app/i18n` → `npx jest` →
`node scripts/i18n/translate.mjs check`.

## Соседи

`0181` / `0188` пока ничего не изменили. После мёржа `0180` правило видит **все** файлы `src`. Новая строка без
`t()` из соседнего слота уронит его линт — так и задумано. Если в их зоне линтер что-то найдёт, договариваемся через
координатора.

## Решения владельца

1. Вариант правила: **(а) `all` с типами** (рекомендую) / (б) `jsx-only`.
2. Защита конфига: (а) ничего / (б) Jest-тест / **(в) закоммиченный пробник** (рекомендую при «да» по 3).
3. `lint` → `eslint . --max-warnings 0`: **да** (рекомендую) / нет.
