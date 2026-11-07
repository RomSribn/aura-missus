# AURAT-0180-005 — spec (draft, ждёт ревью координатора и одобрения владельца)

Дата: 2026-11-07 · Тип: задача (без отдельной фичи; строка 4 `AURAF-0023`) · P1 · слот slave-3.
Контекст и замеры — `004-context.md`.

## Итог разведки

Английского текста в интерфейсе **нет**: даже самый строгий вариант правила (все строки, все атрибуты, весь `src`)
находит только технику. Поэтому задача — **правило-сторож** на весь `src`, которое поймает будущую утечку и не будет
шуметь на технике. Переводить нечего; хвосты `0184` — отдельные пункты 4–5.

## 1. Правило — одно на весь `src`

Вместо списка из 31 слайса — один override `src/**/*.{ts,tsx}`:

- **Вне правила:** `**/__tests__/**`, `src/test-support/**`, `**/config/locales/**`, `src/shared/config/theme.ts`
  (только цвета), `*.generated.ts`.
- **`mode: 'all'`** — строки везде, не только в JSX: `.ts`, хуки, конфиги, `Alert.alert` в `onPress`, render-пропсы
  (`renderItem`, `ListHeaderComponent` / `ListFooterComponent` / `ListEmptyComponent`).
- **Типы (`parserOptions.project` только в этом override).** С ними правило пропускает строку, чей тип — литерал или
  объединение литералов: имена иконок, `variant`, `accessibilityRole`, `keyboardType`, `edges`, маршруты. Именно это
  делает `all` пригодным: 1834 находки без типов → 247 с типами. Цена — ~3 с к `eslint .` (9 → 12 с, замер грубый).
- **Атрибуты: проверяются все.** Белого списка `include` больше нет (он и был дырой: всё, что внутри атрибута не из
  списка, правило не видело). Исключены только технические: `testID`, `nativeID` и геометрия SVG.
- **Исключения по категориям** (списки — §1a, каждая запись подтверждена абляцией: без неё растёт число находок):
  вызовы (`new Error(…)`, `console.*`, `bffRequest`…), ключи объектов (стили, заголовки HTTP, `displayName`, `id` /
  `key` / `path`…), шаблоны слов (знаки и цифры, пути и URL, цвета, единицы CSS, ISO-время, технический токен —
  одно слово со строчной буквы, сшитое `. _ : / = -`: `local-`, `photo.jpg`, `auth/unknown`).
- **Дыра UPPER_CASE.** Плагин безусловно пропускает `const LABEL = '…'`. Закрываю селектором `no-restricted-syntax`:
  константа в UPPER_CASE, чья строка — два слова и больше (`/\p{L}\s+\p{L}/u`). Сейчас таких 0 (36 строковых UPPER
  констант — все технические).
- **Остаток — явные исключения с причиной** (`// eslint-disable-next-line i18next/no-literal-string -- <причина>`):
  - `app/i18n/dev-menu.ts` — на файл: меню только для dev-сборок, английский намеренно;
  - `features/chat/model/use-attachment-draft.ts` — запасные имена файлов `pasted` / `file` (имя файла — данные, уходит
    на сервер);
  - `shared/lib/attribution.android.ts` — `fb_content_type: 'product'` (параметр SDK);
  - `shared/lib/i18n/init.ts` — имя форматтера i18next `lowercase`.

  Итого 9 строк в 4 файлах (dev-меню — 5 из них, одним комментарием на файл).
- Убираю ставшее ненужным исключение `CountryPickerSheet.tsx:56` (иначе `eslint-comments/no-unused-disable`).
  `SplashScreen.tsx:59` («Aura», бренд) остаётся.

### 1a. Списки исключений

Каждый список = умолчания плагина + записи ниже. Абляция: каждая запись снята по одной на всём `src`, оставлены те,
без которых растёт число находок (перекрывающиеся — проверены совместным прогоном; итог — 9).

| Опция | Добавлено к умолчаниям | Что покрывает |
|---|---|---|
| `callees.exclude` | `\w*Error`, `super`, `console\.\w+`, `on`, `off`, `get`, `set` | сообщения разработчика, события, заголовки и параметры запроса |
| `object-properties.exclude` | `displayName`, `id`, `Authorization`, `transformOrigin`, `overScrollMode` | 35 `displayName`, `pressAction.id`, `Bearer …`, стили |
| `jsx-attributes.exclude` | `testID`, `nativeID`, `fill`, `stroke`, `transform`, `clipPath`, `preserveAspectRatio` | тестовые id, геометрия SVG |
| `words.exclude` | знаки / символы / цифры / пробелы (`· — – → … ✓`); имя класса ошибки (`…Error`); путь или URL (`/v1/…`, `?token=`, `file://…`); hex-цвет; `rgb(` / `rgba(`; единица CSS (`0deg`, `px`, `%`); ISO-время (`T12:00:00`); технический токен (одно слово со строчной, сшитое `. _ : / = -`); `transparent` | 64 + 13 + 5 + 3 + … находок |

Умолчание плагина «ключ в UPPER_CASE» (`object-properties`) — 5770 находок без него (маршруты `SCREENS`, токены темы):
остаётся.

Сознательно **не** исключены ключ `name` (поймал бы `{ name: 'Advisor' }`) и одиночные строчные слова (`` `${n} min` ``
должен ловиться). Пробник на готовом наборе: `name: 'Advisor'`, `` `${n} min` ``, `'Cancel'` — пойманы; `'deg'` —
пропущен (единица CSS), `const LABEL = '…'` — закрывает селектор выше.

### Отвергнуто

- **`jsx-only` на все `.tsx` + расширенный `include`.** Дёшево, но `.ts` и строки вне JSX остаются невидимыми — то,
  что заглушка просит закрыть.
- **Отдельный Jest-тест на строки в `.ts`.** Это переизобретение правила, хуже по точности.

## 2. База

`eslint .` — 0 ошибок и 0 предупреждений. Тест переводов (`src/app/i18n`), `tsc`, полный `jest` — зелёные.
`translate.mjs check` — без новых замечаний.

## 3. Правило защищено от ослабления? — нет, сознательно

Тест, который гонит ESLint по пробным файлам, требует типизированного разбора в Jest (секунды на каждый прогон).
Пробный файл из `004` (17 из 18 утечек ловятся, 18-я — UPPER_CASE, теперь закрыта) прогоню вручную на готовом конфиге и
запишу результат в `007`. Если владелец хочет постоянный тест — скажет.

## 4. Глоссарий v4 (хвост `0184`)

`scripts/i18n/glossary.json`, термин `reader`, `version` 3 → 4. Новые `avoid` (`stem`), как в BFF:

| Язык | Форма | Пример (должен находиться — `glossary.test.ts`) |
|---|---|---|
| fr | `lectric` | «Une lectrice peut explorer cette carte» |
| it | `lettric` | «Una lettrice può esplorare la carta» |
| ro | `cititoa` | «O cititoare poate explora cartea» |
| sl | `bralk` | «Bralka lahko razišče karto» |
| sl | `bralc` | «Vprašaj bralca o karti» |

Ложных срабатываний нет: формы стоят на границе слова (`électricité`, `elettrico` не ловятся); в переводах
приложения их нет. **Передача после мёржа:** BFF — перекопировать `avoid` v4 и снять пометки `local`
(`glossary-avoid.spec-fixtures.ts`, `GLOSSARY_VERSION`); веб — взять копию v4 (`AURAT-0177`).

## 5. Комментарий (хвост `0184`)

`src/screens/advisor-profile/model/use-advisor-profile.ts:42` — текст из `0184-009`: «Opens the conversation with this
advisor (no-op if it already exists), then jumps to that thread in the Chats tab. The greeting is the thread's UI-only
intro bubble — never stored or sent.»

## 6. Документы

- `.eslintrc.js` — комментарий override: правило на весь `src`, как ставить исключение.
- `.claude/aura-build-rules.md`, «Translations»: пункт «`i18next/no-literal-string` … add the slice's paths when its
  move lands» → «`i18next/no-literal-string` covers all of `src` (typed, `mode: 'all'`); a technical string the patterns
  do not cover takes `// eslint-disable-next-line i18next/no-literal-string -- <reason>`». В рабочей копии воркспейса
  этот файл уже изменён другой сессией — правлю только этот пункт; коммит — за координатором.
- `AURAF-0023` строка 4 — отметить линтер.

## 7. Проверка в маноре (координатор)

Рантайм не меняется (конфиг линта, глоссарий, комментарии) — без Metro и устройства:
`npm ci` (после мёржа зависимости в маноре устаревают) → `npm run lint` (0) → `npx tsc --noEmit` →
`npx jest src/app/i18n` → `npx jest` → `node scripts/i18n/translate.mjs check`.

## Соседи

Сейчас `0181` / `0188` ничего не изменили. После мёржа `0180` правило увидит **все** файлы: новая строка из соседнего
слота без `t()` уронит его линт — для них это и есть цель. Если в их зоне линтер что-то найдёт, договариваемся через
координатора.

## Решения владельца

1. Вариант правила — `all` с типами (рекомендую) или `jsx-only` на все `.tsx`.
2. Постоянный тест на сам конфиг — не делаю (рекомендую), или делаю.
