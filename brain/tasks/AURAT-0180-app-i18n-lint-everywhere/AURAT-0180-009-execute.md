# AURAT-0180-009 — execute

Дата: 2026-11-07 · slave-3, `feature/AURAT-0180-app-i18n-lint-everywhere` от `71e03d2`. По спеке v2 (`007`) и решениям
владельца (`008`). Всё застейджено, коммитов нет.

## Файлы (aura-app)

| Файл | Что |
|---|---|
| `.eslintrc.js` | Корневой селектор display-шрифта вынесен в константу `DISPLAY_FONT_LINE_HEIGHT`. Добавлены `I18N_SELECTORS` (UPPER_CASE, дефолты, `useCallback` / `useMemo`). Вместо списка из 31 слайса — один override `src/**/*.{ts,tsx}`: с типами, `mode: 'all'`, `should-validate-template`, исключения по спеке (умолчания плагина + измеренные записи), `no-restricted-syntax` = `[DISPLAY, …I18N_SELECTORS]` |
| `package.json` | `lint` → `eslint . --max-warnings 0` (решение 3) |
| `src/app/i18n/lint-probe.tsx` | **новый**, пробник (решение 2в): 31 disable `-- probe: must stay caught`, его никто не импортирует |
| `scripts/i18n/glossary.json` | v4: `avoid` `reader` — fr `lectric`; it `lettore` → `lettor`, + `lettric`; ro `cititoa`; sk `čitatel`; sl `bralc`, `bralk`; da `læseren`, `læsere`, `læserne` (`word`) |
| `src/app/i18n/dev-menu.ts` | disable на файл: меню только для dev-сборок, английский намеренно |
| `src/features/chat/model/use-attachment-draft.ts` | 2 disable: запасные имена файлов `pasted` / `file` — данные |
| `src/features/profile-photo/model/use-profile-photo.ts` | disable: MIME `image/jpeg` |
| `src/features/store-topup/config/products.ts` | disable `no-restricted-syntax`: `STORE_NAME`, бренды |
| `src/shared/lib/attribution.android.ts` | disable: `fb_content_type`, параметр SDK |
| `src/shared/lib/i18n/init.ts` | disable: имя форматтера `lowercase` |
| `src/screens/phone-auth/ui/CountryPickerSheet.tsx` | снят ставший ненужным disable |
| `src/screens/advisor-profile/model/use-advisor-profile.ts` | комментарий `:42` — текст из `0184-009` |

Brain: `AURAF-0023-glossary.md` («Копии»: локальное расширение BFF вошло в v4; «Версии»: строка v4),
`AURAF-0023` строка 4 (линтер — код готов).

## Исключение из жёсткого правила 5

`src/app/i18n/lint-probe.tsx` — экспорты без потребителей. Это сознательно, по решению владельца (`008`): экспорты
нужны только для того, чтобы утечки не были неиспользуемыми переменными. Отмечено в шапке файла.

## Проверки (слот)

- `npx eslint . --max-warnings 0` → код 0. `npm run lint` → код 0.
- `npx tsc --noEmit` → код 0.
- `npx jest src/app/i18n` → 4 набора, 983 теста — зелёные (глоссарий v4: каждая форма находит свой пример и не ловит
  канонический `use`).
- `npx jest` → 226 наборов, 3089 тестов — зелёные. В конце предупреждение Jest «A worker process has failed to exit
  gracefully» — к этой задаче не относится (тесты не менялись).
- `node scripts/i18n/translate.mjs check` → «35 namespace(s): 0 avoided form(s), 2280 piece(s) of advice». Вывод
  совпадает с выводом на глоссарии v3 построчно (`diff` пуст).
- **Пробник, мутации.** Конфиг ослаблялся девятью способами — каждый раз линт падает (ненужный disable →
  warning → `--max-warnings 0`):

  | Мутация | Итог |
  |---|---|
  | без типов | 2 ошибки |
  | `mode: 'jsx-only'` | 14 предупреждений |
  | `should-validate-template: false` | 3 |
  | старый белый список `jsx-attributes.include` | 3 |
  | широкий токен (`/`, внутренний `-`) и шаблон пути | 4 |
  | callee `\w*Error`, `set\w*` | 1 |
  | без селектора UPPER | 4 |
  | без селектора display-шрифта в override | 1 |
  | без селектора хуков | 1 |

- **`develop` @ `0ea88d0` (`AURAT-0188`) + этот diff** (`git archive` в scratchpad, без коммитов и worktree):
  `eslint . --max-warnings 0` → код 0. В коде `0188` находок нет.

## Попутная находка (не исправлял)

Корневой guard display-шрифта (`AURAT-0012` / `0025`) ищет `fontFamily: <…>.display`. Но с `AURAT-0045` стили пишут
`fontFamily: fontFace('display', 700)`, и селектор не срабатывает **ни на одном** стиле приложения: guard мёртв.
Пробник проверяет только, что селектор по-прежнему действует внутри override (`face.display`). Чинить ли его
(селектор ещё и на `CallExpression[callee.name='fontFace'][arguments.0.value='display']`) — отдельная задача, решает
владелец.

## Текст для `.claude/aura-build-rules.md` (вносит координатор)

Раздел «Translations». Пункт «`i18next/no-literal-string` (`.eslintrc.js` overrides) is `error` for every slice already
moved; add the slice's paths when its move lands.» заменить на:

```
- `i18next/no-literal-string` covers all of `src` (typed, `mode: 'all'`, every
  attribute), except tests, `test-support`, `config/locales`, `api/` segments,
  `theme.ts` and generated files. Three `no-restricted-syntax` selectors close
  what the plugin skips: text under an UPPER_CASE name, in a default value, in a
  `useCallback` / `useMemo` body. A technical string the patterns do not cover
  takes `// eslint-disable-next-line i18next/no-literal-string -- <reason>`.
  Not checked: a one-word UPPER_CASE constant, a literal passed through a
  generic helper. `src/app/i18n/lint-probe.tsx` holds leaks that must stay
  caught; `npm run lint` is `--max-warnings 0`, so a weakened rule fails it.
```

Вносить после коммита чужого незакоммиченного куска (строки 435–454), иначе — `git apply --cached` и проверка
`git diff --cached`.

## Передача после мёржа

- **BFF** (задачу открывает координатор; копия переезжает в `src/common/language/*.spec-fixtures.ts` — `AURAT-0189`):
  `GLOSSARY_VERSION = 4`; шапка «Copied from aura-app `scripts/i18n/glossary.json`, **version 4**»; убрать абзац
  «Plus one local extension (AURAT-0184)…» и пометки `/* local */`; it `lettore` → `lettor`; добавить sk `čitatel`,
  da `læseren` / `læsere` / `læserne` (`word`); прогнать `advisor-labels.spec`.
- **Веб** — заметка в `AURAT-0177`: брать копию v4.

## Проверка в маноре (координатор)

Рантайм не меняется — без Metro и устройства: `npm ci` → `npx eslint . --max-warnings 0` (код 0) →
`npx tsc --noEmit` → `npx jest src/app/i18n` → `npx jest` → `node scripts/i18n/translate.mjs check`.

## Соседи

Код `0188` в `develop` правило проходит. `0181` (slave-0) ещё не в `develop`: после мёржа `0180` его строки без `t()`
уронят линт — так и задумано.
