# AURAT-0189-009 — execute

Дата: 2026-11-07 · Слот `aura-bff-manor` slave-3, ветка `feature/AURAT-0189-bff-season-copy-i18n`. **Не закоммичено**,
всё застейджено (master, missus, aura-contracts) — ждёт ревью координатора.

Проверки в слоте (без стека): `npm run lint` — чисто; `npm run typecheck` — чисто; `npm run build` — чисто;
`npx jest` — **158 наборов, 2122 теста, все зелёные**. Сборка и тесты идут на `@aura/contracts` v0.30.0, собранном
локально и подложенном в `node_modules` (тега ещё нет, см. ниже). `npx prisma generate` в слоте перегенерировал
клиент (он устарел относительно схемы `0184`); файлов в git это не меняет.

## aura-contracts (`/Volumes/Work/personal/ai-manors/aura-contracts`, ветка `feature/v0.30.0-season-copy-language` от `main` `54407ea`, не закоммичено, застейджено)

- `src/app-config.ts`:
  - документ модуля — «the same answer for everyone who asks in the same language (`?lang`) — cache it per language»;
  - `AppConfigSeason.copyLanguage: z.string().min(1).default('en')`; JSDoc `copy`;
  - `AppConfigDiscount.label` — JSDoc (обычный регистр; язык запроса или английский), `labelLanguage` (default
    `en`);
  - `AppConfigPromo.headline` — «The operator's own text, English. No client shows it today».
- `src/session.ts`: `SessionPriceDiscount.label` — JSDoc, `labelLanguage` (default `en`).
- `src/season-copy.ts`: `fillSeasonCopy(template, { …, amount?: string })` — готовая строка суммы выигрывает у
  `amountMinor` (решение 6); JSDoc `SEASON_COPY_KEYS`, `SEASON_COPY_LIMITS` (сервер меряет переводы на знак шире),
  `formatSeasonAmount` (английская форма).
- `package.json` → `0.30.0`; `README.md` — абзац v0.30.0, туда же JSDoc персон из `54407ea` (`AURAT-0184`). Только
  добавления, `typecheck` и `build` контрактов чистые.
- **BFF `package.json` / lock пока на `#v0.29.0`.** Порядок при мёрже (публикует координатор, с одобрения владельца):
  контракты → `main` → тег `v0.30.0` → пуш → в BFF `npm install
  @aura/contracts@github:RomSribn/aura-contracts#v0.30.0` → прогон `typecheck` / `test` → коммит BFF вместе с
  `package.json` и lock. До тега BFF на `develop` не соберётся: он пишет `copyLanguage` / `labelLanguage` и
  передаёт `amount`.

## aura-bff — файлы

**Новые**
- `src/modules/campaigns/texts/`:
  - `season-phrases.ts` — 16 фраз по (месту, английскому): 10 у пресетов (5 winter, 5 valentine), 2 названия скидки
    (`discountLabel`, отдельно от надзаголовка — el), 4 общие. Плюс `ctaWithoutCode` — кнопка без кода. `sensitive`
    — у 8 денежных фраз.
  - `bg.ts` … `sv.ts` × 23 — переводы; в шапке — обращение языка, глагол кнопки, отступления от приложения с
    причиной.
  - `index.ts` — `SEASON_TEXT_TRANSLATIONS`, правила перевода.
  - `translate-campaign-text.ts` — `phraseOf` / `translateCampaignText`: NFC, пробелы, `'` → `’`; подпись — без
    учёта регистра.
  - `app-campaign-strings.spec-fixtures.ts` — копия четырёх строк приложения (`codeTitle`, `discountTitle`,
    `discountSub`, `apply`) на 23 языках.
  - `season-texts.spec.ts`, `translate-campaign-text.spec.ts`.
- `src/modules/campaigns/localize-campaign.ts` — `seasonTextsIn` / `localizeSeasonCopy` (набор целиком, замер
  живыми значениями, кнопка без кода), `localizeDiscountLabel`, `shownLength` (сумма на знак шире —
  `widestAmount`), `TRANSLATED_COPY_LIMITS` (подзаголовок 40), `TRANSLATED_LABEL_MAX` = 22. Плюс spec.
- `src/modules/campaigns/campaign-translations.ts` — `seasonTranslationStatus` (строки формы) и `translationNotes`
  (предупреждения в обе стороны, как `copyBlockers`). Плюс spec.
- `src/common/language/text-checks.spec-fixtures.ts` — `WRONG_ADDRESS`, `QUOTE_PAIRS` и проверки
  `addressProblems` / `quoteProblems` / `wordPattern`, вынесены из `advisors/texts` без правки содержания.

**Перенесено**
- `advisors/labels/glossary-avoid.spec-fixtures.ts` → `src/common/language/` (git mv). v3 и local-формы — как были.
  Добавлено `session` (cs relace, de Session, el συνεδρίαση, et sessioon, fr session, hu munkamenet, lt sesij, sk
  relác) и `balance` (de Saldo, nl saldo) из glossary.json v3; `avoidFormsOf(language, terms)`. Подписи и персоны
  проверяют `reader` / `reading`, как раньше; сезон — все четыре. Формы v4 (`AURAT-0180`) не добавлял.

**Изменено**
- `app-config.builder.ts` — третий аргумент `language`. Сезон через `localizeSeasonCopy` с кодом / суммой /
  процентом, которые реально на показе (из любых кампаний); `copyLanguage`. Скидка — `label` + `labelLanguage`.
  `headline` — как в базе.
- `app-config.service.ts` — кэш прочитанных кампаний (тот же срок, `generation`, граница по `endsAt`); ответ
  собирается на запрос: `current(language, now)`.
- `app-config.controller.ts` — `@RequestLanguage()` + `@ApiLanguageQuery()`; комментарий «на одном языке».
- `sessions.controller.ts` / `sessions.service.ts` — pricing принимает `?lang`; `discount` на выходе — `{ kind, pct,
  label, labelLanguage }`. `priceBlock` и списание не тронуты.
- `campaign-enable-check.ts` — `EnableCheck.notes` (не блокеры). `campaign-rules.ts` — `WORST_PCT` экспортирован.
- `campaign-preset.ts` — «Вставить пресет» заполняет **пустую** подпись скидки из `ticketDiscountEyebrow`.
- `campaigns-admin.service.ts` — превью app-config на английском (`SOURCE_LANGUAGE`).
- `backoffice/views/campaigns.view.ts`:
  - под каждым текстом и подписью — «Перевод: N из 23» / «Нет перевода — все языки увидят английский»;
  - сводка: «сейчас: N языков» и «Код на всех языках — до K знаков: с кодом длиннее кнопка в hu будет без кода»;
  - блок «Другие языки — включить можно» на странице кампании и на подтверждении.
- `src/contracts/openapi.ts` — app-config «same for everyone who asks in the same language — cache it per
  language»; `copyLanguage`, `labelLanguage` (app-config и pricing); описания `copy` / `label` / `headline`.
- Спеки: `app-config.builder` (+5: de, подпись без сезона, код из соседней кампании, свой текст, ETag по языку),
  `app-config.service` (одно чтение на два языка), `app-config.controller`, `sessions.service` (+1: подпись de,
  деньги как у en), `request-language.routes` (+2: app-config, pricing, mt → en), `guest-access.smoke` (третий
  аргумент), `campaign-preset` (+1), `campaigns.view` (+3), спеки советников — на общие фикстуры.

Миграций нет, сид не меняется, английские тексты в базе не трогаются.

## Решения при исполнении

- **Глаголы кнопки** (решение 5): там, где глагол шторки приложения не оставляет места для 8 знаков, взят короче, той
  же формы кнопки по глоссарию: cs Použít, de «{code} nutzen», el Χρήση, fr Activer, ga Úsáid, hr Unesi, lt Naudoti,
  nl «{code} claimen», pl Użyj, sk Použiť, sl Unovči. **Исключение — hu** («Beváltás {code}», 7 знаков): у
  существительного на -ás короче нет. Кнопка без кода (`ctaWithoutCode`) — дословно глагол шторки приложения.
- **fr `ticketDiscountTitle`**: U+00A0 перед «%», а не U+202F, как в приложении: глоссарий (fr) говорит, что U+202F
  нет в шрифтах. Записано отличием в `fr.ts` и в spec. **Для приложения:** у него в `entities/campaign` fr стоит
  U+202F — сверить со шрифтом.
- **«Reader» без рода:** во множественном числе («наши консультанты») или без существительного (de «gemütlich
  beraten», «Liebesberatung»). Мужского по умолчанию нет. Где у языка нет рода (da, fi, hu, et, nl, sv…), —
  единственное число.
- **Free chat** — формы `free-chat` глоссария (fr «Chat gratuit», pt «Chat grátis», ro «Chat gratuit»), а не
  `chat` («discussion» / «conversa» / «conversație»): «Chat is free» — это бесплатный чат.
- **Подзаголовок скидки** меряется до 40 (как `@max` приложения), а не до 36. Остальные лимиты — как в контракте.
- Тексты переводил я (Claude) по глоссарию v3 и таблице обращения. **Носители не читали.**

## Таблицы

**Код и сумма** (из разговорника). «Код до» — сколько знаков кода помещается в кнопку (16). «Сумма до» — сколько
знаков суммы помещается в заголовок билета (22). «heroBody» — запас тела hero (50) при «$25» на знак шире, winter /
valentine.

| lang | код до | сумма до | heroBody | самое длинное слово heroTitle, w / v |
|---|---|---|---|---|
| en | 10 | 6 | 18 / 20 | answers 7 / Questions 9 |
| bg | 8 | 7 | 21 / 19 | отговори 8 / Въпроси 7 |
| cs | 9 | 6 | 22 / 19 | Dlouhé 6 / Otázky 6 |
| da | 9 | 9 | 17 / 13 | nætter 6 / spørgsmål 9 |
| de | 9 | 4 | 14 / 14 | Nächte 6 / Herzens 7 |
| el | 10 | 5 | 6 / 11 | χειμώνα 7 / Ερωτήματα 9 |
| es | 8 | 10 | 6 / 10 | Noches 6 / Preguntas 9 |
| et | 8 | 9 | 17 / 17 | vastused 8 / küsimused 9 |
| fi | 10 | 11 | 17 / 20 | Pitkät 6 / kysymykset 10 |
| fr | 8 | 6 | 7 / 5 | Longues 7 / Questions 9 |
| ga | 10 | 8 | 20 / 26 | freagra 7 / Ceisteanna 10 |
| hr | 10 | 9 | 20 / 18 | odgovori 8 / Pitanja 7 |
| hu | **7** | 6 | 19 / 15 | Hosszú 6 / kérdései 8 |
| it | 8 | 8 | 9 / 11 | lunghe 6 / Domande 7 |
| lt | 8 | 7 | 21 / 21 | aiškumas 8 / klausimai 9 |
| lv | 9 | 9 | 20 / 16 | skaidrība 9 / jautājumi 9 |
| mt | 8 | 11 | 19 / 17 | Iljieli 7 / Mistoqsijiet 12 |
| nl | 8 | 9 | 14 / 13 | nachten 7 / Vragen 6 |
| pl | 11 | 7 | 21 / 20 | Długie 6 / Pytania 7 |
| pt | 8 | 9 | 7 / 10 | Noites 6 / Perguntas 9 |
| ro | 9 | 8 | 10 / 7 | Nopți 5 / Întrebările 11 |
| sk | 9 | 6 | 22 / 19 | odpovede 8 / Otázky 6 |
| sl | 9 | 7 | 21 / 16 | odgovori 8 / Vprašanja 9 |
| sv | 9 | 8 | 15 / 14 | nätter 6 / Hjärtats 8 |

- Код: 8 знаков — везде, кроме hu (7). WINTER5, LOVE5, WINTER10 — с кодом в кнопке на всех языках, кроме hu с
  WINTER10. VALENTINE (9) — без кода в bg, es, et, fr, hu, it, lt, mt, nl, pt.
- Сумма: «$25» / «25 $» (4 с запасом) — везде. «$5.50» с запасом (6) — не помещается в de и el → там весь сезон
  английский (решение 2), бэкофис предупреждает.
- Заголовок hero: самое длинное слово — 12 знаков (mt «Mistoqsijiet»). Колонка 182 pt при Bricolage 800 20 pt
  вмещает около 15 знаков в строке, все слова помещаются. Лимит строк (26 знаков, 2 строки) — как у английского.
  **Пиксельной проверки нет** — это на устройстве (§ ниже).

**`translate.mjs`-проверка глоссария** (`checkGlossary` приложения по разговорнику, через временную папку в
scratchpad): **запретных форм 0**. Советов 43, все разобраны:
- `verification-code` × 18 — ложный: `{code}` в английском совпал со словом «code»;
- `reader` / `reading` в da, de, fi, nl, sv — составные слова (kærlighedsrådgiver, Winterdeutung, liefdesreading),
  основа внутри слова. de «Liebesberatung» — сознательно без «Berater»;
- `chat` fr / pt / ro — взята форма `free-chat`, см. выше;
- `checkout` es / hr / lt / mt и `session` ga — в строках приложения, взятых дословно (`discountSub`,
  `discountTitle`). Их задача — у приложения.

**`@sensitive` — нужна вычитка носителями** (решение 7 `AURAI-0010`, не блокирует). Все 23 языка, ни одного ревью.
Хэш — sha256 английского, 12 hex:

| фраза | английский | хэш |
|---|---|---|
| `winter.heroBody` | {amount} on us for a winter reading. | `f30decc78708` |
| `valentine.heroBody` | {amount} on us for a love reading. | `1e1fc2f83250` |
| `winter.discountLabel` | Winter sale | `edfc4fba797f` |
| `valentine.discountLabel` | Valentine’s week | `6ccdb398129e` |
| `shared.cta` | Apply {code} | `0605f23f04dc` |
| `shared.ticketCodeTitle` | {amount} on your balance | `50e0c14ed68b` |
| `shared.ticketDiscountTitle` | {pct}% OFF sessions | `6eaf6d611fc9` |
| `shared.ticketDiscountSub` | Any advisor · applied at checkout | `78a6424450f4` |

Последние три — дословно строки приложения: их ревью у приложения покрывает и сервер.

## Проверка в маноре / на bff-dev (за координатором)

По `007` §10, с поправками:
1. Сначала тег `v0.30.0` и переключение BFF (см. выше), затем мёрж. Миграций нет.
2. Кампания из пресета winter, подпись пустая → «Вставить пресет» ставит «Winter sale». Форма: «Перевод: 23 из 23»,
   «сейчас: 23 языка», «Код на всех языках — до 7 знаков: … hu …».
3. `GET /v1/app-config?lang=de|el|fr|pl|ro|mt` — как в `007` §10.2; ETag / 304 по языку.
4. `GET /v1/advisors/<id>/sessions/pricing?lang=de` — «Winteraktion», `labelLanguage: "de"`, суммы как у `en`.
5. Код VALENTINE рядом с сезоном → предупреждение; `?lang=fr` — кнопка «Appliquer», остальное по-французски.
6. Свой текст → «Нет перевода», предупреждение; `?lang=de` — весь сезон английский.
7. **На устройстве (Android):** hero 316 / 360 pt в de, fi, el, mt — заголовок в 2 строки без переноса внутри слова,
   тело без многоточия; билет fr / bg / pl — подзаголовок сжимается не меньше ~0,85. Зависит от передачи приложению
   (перечитывать app-config при смене языка).

## Открыто

- Вопрос владельцу §10.7 (тексты кампаний на bff-dev / проде) — у координатора. Отличные от пресетов фразы — в
  разговорник до мёржа или отдельной задачей.
- Передачи (номера — от координатора), по `007` §11: приложение (Android — тот же релиз, что `AURAT-0182`; плюс fr
  U+202F в `entities/campaign`), веб (после Android). Глоссарий v4 — передачей после `AURAT-0180`.
- `AURAF-0023` строка 011 (сезонные тексты, BE ✓) и раздел глоссария о копиях BFF (`src/common/language/`,
  `session` / `balance`) — обновлю после мёржа и проверки, вместе с закрытием.
