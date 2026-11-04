# AURAT-0155-005 — spec (draft)

Тип: задача фичи `AURAF-0023`, шаг 1b. aura-app + brain. Видимых изменений в приложении нет (кроме возможной
правки нескольких переводов `shared`, которые английский пользователь не видит — флаг выключен). Веб только
читаем. Основание — `AURAI-0010` §5, §9, Recommendation 1b; замеры — `004-context.md`.

## Зачем
Шаги 2–3 переводят ≈ 550 строк в 7–9 задачах параллельными слотами. Без общего словаря «session» станет то
«séance», то «session», кнопки в болгарском — то «Опитай», то «Опитайте», а приложение заговорит иначе, чем
веб. Глоссарий, таблица обращения и память переводов делают перевод в каждой задаче одинаковым и проверяемым.

## Что делаем

### 1. Глоссарий — `scripts/i18n/glossary.json` (aura-app)
Один файл данных — и для переводчика, и для проверки. ≈ 85 терминов × 23 языка. Запись:

```json
{ "id": "session", "en": "session", "match": "\\bsessions?\\b",
  "note": "запланированный предоплаченный приватный чат (SESSIONS_BOOKING.md); не «сеанс связи»",
  "web": "sessions-page:title",
  "tr": { "fr": { "use": "séance", "avoid": ["\\bsessions?\\b"] }, "hu": { "use": "konzultáció" }, … } }
```

- `use` — каноническая форма (лемма; для языков с падежами — именительный, переводчик склоняет);
  `avoid` — только явно неверные варианты (регулярки), которые встречались или напрашиваются; `note` — смысл и
  ловушки.
- Термины (английский, группами):
  - **люди**: advisor, psychic, reader (если встретится), client;
  - **сессии и бронь**: session, private session, first session, free chat, book (глагол), booking (сущ.),
    time slot, reschedule, cancel (a session), cancellation, extend, end a session, upcoming, past, live /
    in progress, starts soon, ended, minute / min, per minute;
  - **чат**: chat, message, voice note, photo, video, file, attachment, online, busy, offline, anonymous;
  - **деньги**: balance, top up, price, credit, promo code, coupon, discount («% OFF»), sale, welcome offer,
    applied, checkout, pay, payment, refund, charge, store purchase, receipt; App Store, Google Play — не
    переводятся;
  - **контент**: daily card, tarot, tarot card, deck, draw (a card), reading, horoscope, zodiac sign, daily
    ritual, seasonal offer, specialisations (love, career…), match (подбор консультанта);
  - **аккаунт**: profile, account, sign in, sign out, phone number, verification code, date of birth, name,
    email, notifications, settings, language, device language, delete account, Privacy Policy, Terms, support;
  - **отзывы**: review, rating, star, leave a review;
  - **частые фразы** (должны быть одинаковыми везде): Try again, Go back, Continue, Done, Close, Cancel, Save,
    Edit, Something went wrong, Check your connection.
- Источник перевода: перевод веба, если он ровный; при дрейфе выбираю так: (а) вариант из навигации и
  заголовков (его видят чаще всего); (б) иначе — большинство на вебе; (в) законные пары остаются двумя
  записями (существительное «Booking» и глагол «Book», плюральные формы, род объекта «Keep it»). Терминов, которых
  нет на вебе (top up, store, voice note, horoscope, ritual, anonymous…), перевожу сам в регистре таблицы п. 2.
  Ревью носителей — по решению владельца 7 (не блокирует; деньги / возвраты / отмена / удаление — до маркетинга).

### 2. Таблица обращения — в `glossary.json` (`register`) и в brain
По 23 языкам: обращение в тексте («ты» / «вы») — как уже записано в build rules — плюс **форма кнопки** и
пример. По вебу: инфинитив — cs sk lt lv fr pt es de nl; существительное — el hu; императив ед. ч. — bg hr sl it
pl ro; одна форма императива — da sv fi et mt ga.

**Болгарский (и так же hr, sl):** в предложениях — «Вие / ваш»; кнопка-команда — краткий императив ед. ч.
(«Опитай отново», «Резервирай сесия», «Затвори»), как в системных интерфейсах на этих языках. Это то, что веб
делает в большинстве мест и что уже стоит в `shared` приложения; «смешение» на вебе — кнопки в форме «-йте»
(«Опитайте отново», «Резервирайте сесия»), а не «ти» в тексте (в тексте «ти» не встречается ни разу).

### 3. Память переводов — `scripts/i18n/web-tm.mjs` (aura-app)
Без новых зависимостей: читает `src/**/config/locales/*.ts` веба через `typescript` (уже в devDependencies) и
`vm`, как `generate-plural-rules.mjs` читает `languages.ts`. Путь к вебу — `--web <dir>` или `AURA_WEB_DIR`
(путей рабочей машины в репо нет).

- `lookup "<English>"` — 23 перевода и источник `<web ns>:<key>`; тип совпадения: `exact` или `normalized`
  (пробелы, `...` ↔ `…`, прямой / типографский апостроф, имена плейсхолдеров — `{{advisor}}` ↔ `{{name}}`
  по порядку, в ответе — имена приложения).
- `scan <slice>/config/locales/en.ts` — по каждому ключу приложения: совпадение, источник, переводы; плюралы —
  группой (`x_one` / `x_other` ↔ все формы языка у веба). Вывод JSON (`--out`), разложен по языкам, чтобы
  переводчик вставил найденное в `<lang>.ts` и перевёл остальное.
- В `lookup` и `scan` — предупреждение, если у веба для той же английской строки несколько переводов или
  перевод веба содержит `avoid` из глоссария: «не копировать — взять форму глоссария».
- `check [пути]` — отчёт по `config/locales` приложения: `avoid`-формы и (совет, не ошибка) отсутствие `use`-формы
  там, где английский содержит термин (на падежных языках — по основе, поэтому только отчёт).

### 4. Проверка — `src/app/i18n/__tests__/glossary.test.ts` (Jest, блокирует)
- `glossary.json` целый: у каждого термина 23 языка, `use` не пустое, NFC, без U+00AD, румынский — ș/ț, у
  `register` — 23 языка.
- Во всех пространствах из `I18N_NAMESPACES`: если английский ключа совпадает с `match` термина, перевод не
  содержит `avoid` этого языка. Ложных срабатываний нет по построению: `avoid` — только явные ошибки.

### 5. Сверка `shared` приложения
Прогоняю `check` по `src/shared/config/locales/`; что расходится с глоссарием — правлю в переводах (английский
не меняется). Ожидаю 0–5 правок.

### 6. Документы
- brain: `features/AURAF-0023-app-localization/AURAF-0023-glossary.md` — как переводить в приложении: таблица
  обращения (23 строки), решения по дрейфу (вариант и причина), как пользоваться `web-tm.mjs`; ссылка на правила
  «Translations» (не дублирую). Расхождения веба — списком для будущей задачи в `aura-web-manor`.
- `.claude/aura-build-rules.md`, «Translations»: две строки — «термины — `scripts/i18n/glossary.json`
  (Jest проверяет `avoid`), готовые переводы веба — `node scripts/i18n/web-tm.mjs scan …`».
- `AURAF-0023`: строка 1b → done после слияния.

## Не входит
- Правка переводов веба (дрейф передаю списком).
- Перенос строк слайсов (шаги 2–3), форматтеры, шрифты (`AURAT-0156`).
- Ревью носителями.

## Проверка
`npm run lint`, `npx tsc --noEmit`, `npx jest` (новый тест + `translations.test.ts`); прогон `web-tm.mjs scan`
на `shared` и на одном файле `config/copy.ts` для замера доли совпадений. Стек не нужен.

## Нужно решение владельца
1. **Болгарский (и hr, sl):** текст на «Вие», кнопки — императив ед. ч. («Опитай отново»). *Рекомендую.*
   Альтернатива — везде «-йте» («Опитайте отново»): вежливее, но длиннее и расходится с вебом и системой.
2. **Где глоссарий:** данные в aura-app (`scripts/i18n/glossary.json`) + блокирующий Jest-тест на `avoid`,
   описание и решения — в brain. *Рекомендую.* Альтернатива — только в brain (markdown, 85 × 24 — читать
   тяжело, проверить машиной нельзя).
