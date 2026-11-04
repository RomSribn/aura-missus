# AURAT-0155-007 — spec, ред. 2 (по ревью `006`)

Заменяет `005`. Решения владельца из `006` приняты: bg / hr / sl — текст на «Вие» / «vi», кнопка — императив
ед. ч.; глоссарий — данные в aura-app + Jest. Ниже — что изменилось по 7 пунктам ревью и полная спека.

## Что изменилось
| # ревью | Было | Стало |
|---|---|---|
| 1 | `avoid` и `match` — регулярки с `\b` | слова / основы + режим `word` / `stem`; шаблон собирает одна функция: границы `(?<![\p{L}\p{M}\p{N}])…(?![\p{L}\p{M}\p{N}])`, флаги `iu`, обе стороны в NFC; у каждого `avoid` есть `example`, тест проверяет, что шаблон его находит |
| 2 | «ложных срабатываний нет по построению» | убрано: `avoid` — только явные ошибки; сработал тест — решает человек (поправить перевод или уточнить `avoid`) |
| 3 | — | метка `@sensitive` в `en.ts` + журнал ревью носителями `scripts/i18n/native-review.json` с хэшем текста; отчёт `review` |
| 4 | — | соглашение: JSDoc в `en.ts` — контекст, `@max N` — лимит; `translations.test.ts` проверяет лимит во всех языках; первые лимиты — в `shared` (корешок билета) |
| 5 | плейсхолдеры «по порядку» | сопоставление по порядку в английском, замена в переводе по имени; разное число / набор — не совпадение |
| 6 | — | строка в `AURAF-0023` и в документе глоссария: веб берёт `glossary.json` копией с полем `version`, второго не ведёт |
| 7 | match, нет spread / Now / invite | + tarot spread, «Now» (моментальная сессия), приглашение в приватную сессию; − match |

Один скрипт вместо `web-tm.mjs`: `scripts/i18n/translate.mjs` с подкомандами `lookup`, `scan`, `check`,
`review` — общий разбор файлов локалей и шаблонов терминов.

## Что делаем

### 1. Глоссарий — `scripts/i18n/glossary.json` (aura-app)
Вне `src` — в бандл не попадает. Поля: `version` (растёт при любой правке перевода термина), `register`, `terms`.

```json
{ "id": "session", "en": "session", "match": { "text": "session", "mode": "stem" },
  "note": "запланированный предоплаченный приватный чат (SESSIONS_BOOKING.md)",
  "web": "sessions-page:title",
  "tr": {
    "fr": { "use": "séance",
            "avoid": [{ "text": "session", "mode": "stem", "example": "Votre session commence" }] },
    "hu": { "use": "konzultáció" } } }
```

- `use` — каноническая форма (лемма; на падежных языках переводчик склоняет). `avoid` — явно неверные варианты:
  `word` — целое слово, `stem` — слово, начинающееся с основы («сеанс» ловит «сеансът»). `example` —
  обязательная строка, на которой шаблон должен сработать.
- Термины (английский, группами, ≈ 85):
  - **люди**: advisor, psychic, client;
  - **сессии и бронь**: session, private session, first session, free chat, «Now» (моментальная сессия),
    invitation to a private session («Continue this reading privately»), book (глагол), booking (сущ.), time slot,
    reschedule, cancel (a session), cancellation, extend, end a session, upcoming, past, live / in progress,
    starts soon, ended, minute / min, per minute;
  - **чат**: chat, message, voice note, photo, video, file, attachment, online, busy, offline, anonymous;
  - **деньги**: balance, top up, price, credit, promo code, coupon, discount («% OFF»), sale, welcome offer,
    applied, checkout, pay, payment, refund, charge, store purchase, receipt; App Store, Google Play — не
    переводятся;
  - **контент**: daily card, tarot, tarot card, tarot spread, deck, draw (a card), reading, horoscope, zodiac
    sign, daily ritual, seasonal offer, specialisations (love, career…);
  - **аккаунт**: profile, account, sign in, sign out, phone number, verification code, date of birth, name,
    email, notifications, settings, language, device language, delete account, Privacy Policy, Terms, support;
  - **отзывы**: review, rating, star, leave a review;
  - **частые фразы**: Try again, Go back, Continue, Done, Close, Cancel, Save, Edit, Something went wrong, Check
    your connection.
- Выбор при дрейфе веба: (а) вариант навигации и заголовков; (б) иначе большинство на вебе; (в) законные пары —
  две записи (сущ. «Booking» / глагол «Book», род объекта «Keep it»). Термины, которых нет на вебе (top up,
  store, voice note, horoscope, ritual, anonymous, spread, «Now»…), перевожу сам в регистре таблицы п. 2.
- Веб берёт этот файл копией с `version` в своей задаче и второго не ведёт (записываю в `AURAF-0023` и в
  документ глоссария).

### 2. Таблица обращения — `register` в `glossary.json` и в brain
23 языка: обращение в тексте (как в build rules), форма кнопки, пример. Инфинитив — cs sk lt lv fr pt es de nl;
существительное — el hu; императив ед. ч. — bg hr sl it pl ro; одна форма императива — da sv fi et mt ga.
bg / hr / sl: в предложениях «Вие» / «vi», кнопка — императив ед. ч. («Опитай отново», «Pokušaj ponovno»,
«Poskusi znova»).

### 3. Шаблоны терминов — одна функция
`termPattern({ text, mode })` в `scripts/i18n/terms.mjs`: NFC, экранирование, границы
`(?<![\p{L}\p{M}\p{N}])` слева всегда, справа — `(?![\p{L}\p{M}\p{N}])` для `word`, ничего для `stem`; флаги `iu`.
Ей пользуются и `translate.mjs`, и Jest-тест (тот же файл, импорт из теста). Проверяемые тексты тоже в NFC.

### 4. Контекст и лимиты — соглашение в `en.ts`
- JSDoc над ключом — контекст для переводчика (где стоит, что рядом); так уже пишут в `shared`.
- `@max N` — лимит длины: символы (code points, NFC) без `{{…}}` и `<тегов>`. `translations.test.ts` разбирает
  `en.ts` каждого пространства (TypeScript AST, файл находит тот же обход `src`) и проверяет лимит в 24 языках.
- Первые лимиты — в `shared`: корешок билета («CODE» / «SALE», 74pt). Узкие места слайсов (`DateStrip` 58pt,
  однострочные кнопки) ставят задачи шагов 2–3 при переносе — правило в «Translations».

### 5. Ревью носителями — `@sensitive` + `scripts/i18n/native-review.json`
- Метка `@sensitive <тема>` (payment, refund, cancellation, account-deletion, legal) — в JSDoc ключа или над
  `export const en` (всё пространство).
- Журнал: `{ "reviews": [{ "ns", "lang", "by", "date", "hash" }] }`; `hash` — sha256 от пар «английский +
  перевод» чувствительных ключей этого пространства в этом языке. Правка текста меняет хэш — отметка устаревает.
- `node scripts/i18n/translate.mjs review` — какие пары (пространство, язык) не проверены или устарели. Не
  блокирует (решение владельца 7: нужно до маркетинга в стране); тест проверяет только целостность журнала
  (известные язык и пространство, дата, формат хэша).

### 6. Память переводов — `translate.mjs lookup | scan`
Читает `src/**/config/locales/*.ts` веба через `typescript` (уже в devDependencies) и `vm`. Путь — `--web <dir>`
или `AURA_WEB_DIR`.
- `lookup "<English>"` — 23 перевода и источник `<web ns>:<key>`; совпадение `exact` или `normalized`
  (пробелы, `...` ↔ `…`, апострофы, имена плейсхолдеров).
- Плейсхолдеры: английские сопоставляются по порядку (`{{advisor}}` ↔ `{{name}}`), в переводе заменяются по
  имени — перевод может их переставить. Разное число или повтор, который не сводится однозначно, — не
  совпадение. Теги `<amount>` — так же.
- `scan <slice>/config/locales/en.ts` — по каждому ключу: совпадение, источник, переводы; плюралы группой
  (`x_one` / `x_other` ↔ все формы языка у веба). JSON (`--out`) по языкам.
- Предупреждение, если у веба для той же английской строки несколько переводов или его перевод содержит
  `avoid`: «не копировать — взять форму глоссария».

### 7. Проверка глоссария — `src/app/i18n/__tests__/glossary.test.ts` (Jest, блокирует)
- Файл целый: 23 языка у каждого термина и в `register`, `use` не пустое, NFC, без U+00AD, румынский — ș/ț,
  у каждого `avoid` есть `example`, и шаблон его находит.
- Во всех пространствах `I18N_NAMESPACES`: где английский ключа совпал с `match`, перевод не содержит `avoid`
  этого языка. Сработало — решает человек.
- `translate.mjs check [пути]` — тот же разбор отчётом плюс совет (не ошибка): нет `use`-формы там, где
  английский содержит термин.

### 8. Сверка `shared`
`check` по `src/shared/config/locales/`; расхождения с глоссарием правлю в переводах (английский не меняется),
ставлю `@max` на корешок билета.

### 9. Документы
- brain: `features/AURAF-0023-app-localization/AURAF-0023-glossary.md` — таблица обращения, решения по дрейфу,
  как пользоваться `translate.mjs`, журнал ревью, правило копии для веба; расхождения веба — списком для задачи в
  `aura-web-manor`.
- `.claude/aura-build-rules.md`, «Translations»: термины — `glossary.json`; готовые переводы веба —
  `translate.mjs scan`; JSDoc-контекст и `@max N`; `@sensitive`.
- `AURAF-0023`: строка про копию для веба; 1b → done после слияния.

## Не входит
Правка переводов веба (список передаю), перенос строк слайсов, форматтеры, шрифты (`AURAT-0156`), само ревью
носителями.

## Проверка
`npm run lint`, `npx tsc --noEmit`, `npx jest` (новый тест + `translations.test.ts`); `translate.mjs scan` на
`shared` и одном `config/copy.ts` — доля совпадений; `review` — пустой отчёт (чувствительных строк ещё нет).
Стек не нужен.
