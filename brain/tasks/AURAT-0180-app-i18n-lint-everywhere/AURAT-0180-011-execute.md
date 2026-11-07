# AURAT-0180-011 — execute (фиксы ревью кода `010`)

Дата: 2026-11-07 · slave-3. Всё застейджено, коммитов нет.

## Что сделано

1. **Селектор хуков** (`.eslintrc.js`, `I18N_SELECTORS[2]`): `:not(CallExpression[callee.object.name='console'] *)`
   и `:not(NewExpression[callee.name=/Error$/] *)` — комбинатор потомка, так что аргумент, собранный шаблоном или
   конкатенацией, больше не даёт ложного срабатывания. В пробнике — обратный случай без disable:
   `useCallback(() => console.warn(`Upload failed with ${code}`))`.
2. **Токен:** `/^[a-z][A-Za-z0-9]*(?:(?:[._:=][A-Za-z0-9]+)+[:=]?|[:=])$/` — внутренние сегменты непустые, токен
   может закончиться только на `:` или `=`. `` `${n} min.` `` и `'e.g.'` теперь ловятся. По `src` — 0 новых находок
   (`photo.jpg`, `state_changed`, `key:`, `after=`, `probe:change` проходят). В пробнике —
   `` `${count} min.` ``.
3. **Глоссарий:** объём v4 не меняю. Кандидаты **v5** (отдельной задачей, с согласия владельца; тогда же — в передачу
   BFF), формы `reader`, до которых не дотягивают основы v4: sv `läsarn-` (läsarna), fi `lukijo-` (lukijoilta), ga
   `léitheora` (родительный), el `αναγνωστ` без ударения (αναγνωστών), da `læserens` / `læseres` / `læsernes` (`word`).
   Проверка ревьюера: примеры находятся, канонический `use` не ловится, в локалях приложения форм нет.
4. **Дыры — полный список** (шапка пробника, текст для build-rules ниже); селектор UPPER расширен:
   `Property[key.value=/^[A-Z_-]+$/]` (ключ в кавычках) и `AssignmentExpression[left.property.name=/^[A-Z_-]+$/]`
   (`copy.TITLE = '…'`). По `src` — 0 срабатываний; в пробнике — оба случая (ключ в кавычках — `'EMPTY-TITLE'`:
   кавычки у `'TITLE'` Prettier снял бы).
5. **Шапка пробника:** «ослабь конфиг — директива станет ненужной; потеряй типы — утечки, которые типы пропускали,
   станут ошибками; в обоих случаях `npm run lint` падает. Строки без директивы должны оставаться чистыми: на них падает
   слишком широкий селектор».
6. **Prettier:** `require` `i18nDefaults` — первой строкой, над комментарием шапки; `npx prettier --check
   .eslintrc.js src/app/i18n/lint-probe.tsx` — чисто.

## Находка на `develop` @ `68f0333` (0188, 0193, 0181)

`git archive 68f0333` + diff 0180 (scratchpad, без коммитов): одна находка — `src/shared/lib/i18n/native-locales.ts:71`
(`0181`) `language === 'pt' ? 'pt-PT' : language`, языковой тег BCP 47, техника. Файл `0181` не трогаю. Закрыл
шаблоном слов в конфиге: `/^[a-z]{2,3}(?:-[A-Z][a-z]{3})?-(?:[A-Z]{2}|\d{3})$/` — тег с регионом (`pt-PT`,
`zh-Hant-TW`, `es-419`). Регион обязателен и пишется заглавными, поэтому `'e-mail'`, `'check-ins'`, `'en'`
не подходят. В дереве слота запись пока ни на что не срабатывает: она для кода `0181`. После этого `develop` + 0180 →
`eslint . --max-warnings 0` → 0. Если координатор предпочтёт disable в файле `0181` при мёрже — шаблон убрать.

## Проверки (слот)

- `npx eslint . --max-warnings 0` → 0; `npm run lint` → 0; `npx tsc --noEmit` → 0.
- `npx jest src/app/i18n` → 983/983. Полный Jest не перепрогонял: менялись только конфиг линта и пробник, которые
  Jest не читает; в `009` — 226 / 3089.
- Пробник: 34 disable `-- probe: must stay caught`. Мутации — 12, каждая роняет линт:

  | Мутация | Итог |
  |---|---|
  | без типов | 2 ошибки |
  | `mode: 'jsx-only'` | 15 предупреждений |
  | `should-validate-template: false` | 4 |
  | старый `jsx-attributes.include` | 3 |
  | широкий токен (`/`, внутренний `-`) и путь | 5 |
  | callee `\w*Error`, `set\w*` | 1 |
  | прежний шаблон токена (`min.`) | 1 |
  | без селектора UPPER | 6 |
  | UPPER без `key.value` / присваивания | 2 |
  | без селектора display-шрифта в override | 1 |
  | селектор хуков с `>` вместо потомка | 1 ошибка |
  | без селектора хуков | 1 |

- `develop` @ `68f0333` + diff 0180: `eslint . --max-warnings 0` → 0 (с шаблоном BCP 47).

## Текст для `.claude/aura-build-rules.md` (заменяет вариант из `009`; вносит координатор)

```
- `i18next/no-literal-string` covers all of `src` (typed, `mode: 'all'`, every
  attribute), except tests, `test-support`, `config/locales`, `api/` segments,
  `theme.ts` and generated files. Three `no-restricted-syntax` selectors close
  what the plugin skips: text under an UPPER_CASE name (constant, key, member
  assigned to), in a default value, in a `useCallback` / `useMemo` body. A
  technical string the patterns do not cover takes
  `// eslint-disable-next-line i18next/no-literal-string -- <reason>`.
  Not checked: a one-word UPPER_CASE constant, an all-caps word ('OK', 'NEW'),
  a literal passed through a generic helper, the arguments of console / i18next
  calls and `new Error(…)`. `src/app/i18n/lint-probe.tsx` holds leaks that must
  stay caught; `npm run lint` is `--max-warnings 0`, so a weakened rule fails it.
```

Вносить после коммита чужого незакоммиченного куска (строки 435–454), иначе — `git apply --cached` и проверка
`git diff --cached`.
