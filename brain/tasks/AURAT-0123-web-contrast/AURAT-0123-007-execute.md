# AURAT-0123-007 — Execute

Date: 2026-10-23
Ветка: `feature/AURAT-0123-web-contrast` (aura-web), база `develop` @ `280988a`. Не закоммичено —
ждёт ревью владельца в IDE.

## Что сделано

### `src/shared/config/tokens.css`

- Шапка-комментарий: любой текстовый цвет держит 4.5:1 на каждом светлом фоне (худший — paper-2),
  проверяет `contrast.test.ts`; coral и teal хендоффа — заливки.
- Новые: `--teal-ink #1e726b`, `--accent-ink #b4364b`, `--accent-ink-hover #90303f` (hover
  текстовых ссылок), `--teal-strong #008577`, `--teal-strong-hover #00756a`, `--accent-strong #da3557`,
  `--accent-strong-hover #c94459`, `--focus` (кольцо фокуса),
  `--ink-struck` и `--ink-disabled` (= `--ink-3`, по имени — где правило не требует контраста).
- Изменены: `--ink-2` `#7a7264` → `#6e665a`; `--error` → `var(--accent-ink)`; `--accent-hover`
  переименован в `--accent-strong-hover` (значение прежнее, `#c94459`), `--teal-hover` — в
  `--teal-strong-hover` (ревью `010`). Ложный комментарий про
  `--error` убран.
- Глобальное: `a` → `--accent-ink`, `a:hover` → `--accent-ink-hover`; `:focus-visible` →
  `var(--focus)` (= `--accent-ink`; на plum — gold, `010`); `.eyebrow` → `--ink-2`; `.muted-3` удалён (единственный потребитель —
  `match-card.tsx` → `muted`).

### CSS-модули (48 файлов; `/sessions` — отдельно, `008`)

| Было | Стало | Правил |
|---|---|---|
| `color: var(--teal)` | `--teal-ink` | 22 |
| `color: var(--accent)` / `var(--accent-hover)` | `--accent-ink` | 31 |
| то же в `:hover` ссылок (`.nudgeLink`, `.reset`, `.cancel`, extend `.link`) | `--accent-ink-hover` | 4 |
| `color: var(--ink-3)` | `--ink-2` | 32 |
| то же у отключённого (`.taken`, `.send:disabled`, extend `.link:disabled`, ChoiceCard `.disabled`) | `--ink-disabled` | 4 |
| зачёркнутая цена `PriceTag .struck` | `--ink-struck` | 1 |
| белый текст на `--accent` (Button primary, свой пузырь, бейджи таба / списка / match, `OffChip`, «SALE» купона, текущий шаг, выбранная дата сессии) | `--accent-strong` | 9 |
| белый текст на `--teal` (Button teal, отправка, таб длительности, точка «готово») | `--teal-strong` | 4 |
| фокус-обводки (звёзды отзыва, ползунок фильтра) | `var(--focus)` | 3 |

`Button .teal:hover` → `--teal-strong-hover` (раньше hover у teal не было). Заливки без текста (точки
онлайн, полосы баннера и фильтра, тумблер, кольцо Ask, линии шагов, орб), рамки выбора и
`accent-color` радио — без изменений. Тёмный текст на plum не попал: в `next-session-card`,
`session-detail`, `session-invite-card` новые токены — в белой части под сливовой шапкой.

### Тест — `src/shared/config/__tests__/contrast.test.ts` (43 проверки после `010`)

- Каждый текстовый токен (`ink`, `ink-2`, `teal-ink`, `accent-ink`, `accent-ink-hover`, `error`)
  × каждый светлый фон (`paper`, `paper-2`, `card`, `teal-soft`, `accent-soft`) ≥ 4.5; белый на
  `accent-strong`, `accent-strong-hover`, `teal-strong`, `teal-strong-hover` ≥ 4.5; `--focus` на
  светлых фонах и gold на plum ≥ 3 (не-текст). Значения читаются из
  `tokens.css`.
- Ни один stylesheet не красит текст или иконку (`color`, `fill`, `stroke`) `--teal`, `--accent`,
  `--ink-3` и заливками под белым (`--*-strong`, `--*-strong-hover`) — они как текст не держат
  порог (`#da3557` на paper 3.92).
- Белый текст не стоит в одном правиле с фоном `--accent` / `--teal`.
- Проверено мутацией: возврат `.reason` к `--teal` и `.badge` к `--accent` роняет оба теста.

## Проверки

- `npm run lint` — ✔ (eslint + steiger).
- `npm run typecheck` — ✔. `npm run build` — ✔.
- `npm test` — 82 файла, 1464 теста ✔. Первые прогоны падали по чужим причинам: в слоте стоял
  `@aura/contracts` 0.22.0 при lock 0.24.0 (`preflight.sh` пустой — `wts-start` не ставит
  зависимости; лечится `npm ci`), затем 3 теста `app/__tests__` (chats, live-session, psp)
  упали под нагрузкой сразу после `npm ci` — по отдельности и в повторном полном прогоне зелёные.

## Для `AURAT-0136` / `AURAT-0137` (после мёржа)

Чем красить текст:

- текст: `--ink`, `--ink-2`, `--teal-ink`, `--accent-ink` (hover ссылки — `--accent-ink-hover`),
  `--error`;
- белый текст — только на `--accent-strong` (hover `--accent-strong-hover`), `--teal-strong`
  (hover `--teal-strong-hover`), plum или ink; strong-заливки — не цвет текста;
- кольцо фокуса — `var(--focus)`; plum-поверхность ставит `--focus: var(--gold)`;
- gold-текст — только на plum; на светлом gold — звёзды рейтинга;
- `--teal`, `--accent`, `--ink-3` — только заливки и декор; зачёркнутая цена — `--ink-struck`,
  отключённое — `--ink-disabled`.

`contrast.test.ts` уронит их ветку при `color: var(--teal | --accent | --ink-3 | --*-strong)`
после слияния с develop.

## Для приложения (вопрос владельца 2026-10-23: «а получается, что теперь палитра цветов отличается от мобилки?»)

После мёржа палитры веба и приложения (`aura-app/src/shared/config/theme.ts`) расходятся в
текстовых цветах и заливках под белым текстом; бренд-заливки (фоны, мягкие плашки, точки,
полосы, plum, gold, `ink`) совпадают. Провалы контраста в приложении те же, что были в вебе
(та же палитра). Владелец выбрал перенести решение в приложение — **отдельная задача, ID выдаёт
`aura-app-manor`** (здесь не минтим). Описание для неё:

### Токены (`theme.colors`, значения — из `AURAT-0123-005/006`, проверены на 4.5:1)

| Новый / изменённый | Значение | Роль | Как в вебе |
|---|---|---|---|
| `tealInk` *(новый)* | `#1E726B` | бирюзовый текст и иконки на светлом | `--teal-ink` |
| `accentInk` *(новый)* | `#B4364B` | коралловый текст и иконки на светлом: цена оффера, ссылки, ошибки, активный таб | `--accent-ink` |
| `tealStrong` *(новый)* | `#008577` | заливка под белым текстом (кнопка teal, отправка) | `--teal-strong` |
| `accentStrong` *(новый)* | `#DA3557` | заливка под белым текстом (primary-кнопка, свой пузырь, бейджи, `OffChip`, «SALE» купона) | `--accent-strong` |
| `ink2` | `#7A7264` → `#6E665A` | вторичный текст | `--ink-2` |
| `ink3` | без изменений, но не текст | текст на `ink3` → `ink2`; `ink3` остаётся у зачёркнутой цены, отключённого, декора | `--ink-struck`, `--ink-disabled` |
| `teal`, `accent` | без изменений | только заливки и не-текст (точки, полосы, тумблеры, мягкие фоны, рамки) | так же |

Hover в приложении нет; нажатое состояние — как сейчас в приложении (не темнее strong-заливки,
иначе снова «как будто нажато» в покое — причина отказа от варианта A).

### Объём в приложении (aura-app `ec9d30b`, оценка grep по `src/`, без тестов)

- `color: colors.teal` — 23, `color: colors.accent` — 38 → `tealInk` / `accentInk`;
- `backgroundColor: colors.teal` — 8, `colors.accent` — 9 → `tealStrong` / `accentStrong` там, где
  на заливке белый текст; без текста (точки, полосы) — не трогать;
- `color: colors.ink2` — 36 (меняется значением токена), `color: colors.ink3` — 74 → `ink2`
  (кроме зачёркнутой цены и отключённого);
- прочие ссылки на `teal` / `accent` / `ink3` (иконки `color={…}`, рамки, тени) — 26 / 50 / 30:
  иконка, несущая смысл, → `*Ink`; рамка, тень, декор — без изменений;
- `GradientButton` — градиент `accent → plum` под белым текстом: начало градиента 3.26 —
  начинать с `accentStrong`;
- 71 файл с `colors.teal` / `colors.accent`.

### Проверка

Защита как в вебе — тест, который считает контраст пар токенов `theme.colors` и запрещает
`color: colors.teal | colors.accent | colors.ink3` в стилях (аналог
`aura-web/src/shared/config/__tests__/contrast.test.ts`). Визуальный образец значений —
https://claude.ai/artifact/CyMXLjXvwQ5FstbAoK3MCo.

### Хендофф

`tokens.css` дизайнера (`.claude/design_handoff_aura_web/`, мобильный — `design_handoff_aura/`)
по-прежнему со старыми значениями — обновить у дизайнера, чтобы новые экраны рисовались в
новых цветах (решение владельца, вне слотов).

## Открыто

- Абзац «Чем красить текст» в `aura-web-manor/.claude/aura-web-build-rules.md` (раздел «Design
  system») — по спеке после ревью (файл воркспейса, не репо; его читают все сессии манора).
- Живая проверка — в маноре на web-dev после мёржа.
- Приложение — та же палитра, вне задачи (решение владельца, ID — в `aura-app-manor`).
- `preflight.sh` веб-манора пустой → слоты стартуют со старыми `node_modules` (вне задачи;
  предложить `npm ci` в preflight).
