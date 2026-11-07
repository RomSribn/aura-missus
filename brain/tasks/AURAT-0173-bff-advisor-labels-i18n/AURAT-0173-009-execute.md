# AURAT-0173-009 — execute

Дата: 2026-11-07 · Слот `slave-1`, ветка `feature/AURAT-0173-bff-advisor-labels-i18n`. **Не закоммичено** — ждёт ревью
владельца в IDE.

## Проверки

`npm run typecheck` ✓ · `npm run lint` ✓ · `npm run build` ✓ · `npm test` — **153 набора, 2044 теста, все зелёные**.
Сборка и тесты — на `@aura/contracts` v0.29.0, собранном локально и подложенном в `node_modules` (тега ещё нет, см. ниже).

## aura-contracts (`/Volumes/Work/personal/ai-manors/aura-contracts`, ветка `feature/v0.29.0-advisor-labels-i18n`, не закоммичено)

- `src/advisor.ts`: `Advisor.topics: z.array(AdvisorCategory).default([])` (ответ v0.28 парсится как «тем нет»); JSDoc
  `role` / `specialties` — на языке запроса.
- `package.json` → `0.29.0`; `README.md` — абзац v0.29.0 (в него же уходит JSDoc `TarotCard.name` из `3f12472`).
- **BFF `package.json` / `package-lock.json` ещё на `#v0.28.0`:** переключить на `#v0.29.0` можно только после пуша
  тега (lock пинит sha). Порядок при коммите: контракты → `main` → тег → **пуш (с одобрения)** → `npm install
  @aura/contracts@github:RomSribn/aura-contracts#v0.29.0` в BFF → коммит BFF.

## aura-bff — файлы

**Новые**
- `prisma/migrations/20261107120000_advisor_gender/migration.sql` — `CREATE TYPE "AdvisorGender"`, `ADD COLUMN "gender"`
  (nullable). Только добавляет.
- `src/common/language/translated-language.ts` — `TranslatedLanguage` (переехал из колоды).
- `src/modules/advisors/labels/`:
  - `advisor-label-terms.ts` — `ADVISOR_ROLE_TERMS` (10), `ADVISOR_SPECIALTY_TERMS` (34, с `topics`),
    `ROLE_TERM_SEPARATOR`;
  - `advisor-label-translation.ts` — тип файла языка (`GenderedTerm` = строка | `{ female, male }`, `sameAsEnglish`);
  - `translate-labels.ts` — `translateAdvisorLabels` (чистая), `advisorTopics`;
  - `glossary-avoid.fixture.ts` — запретные формы `reader` / `reading` из глоссария aura-app **v2**, сопоставление как
    в `terms.js`;
  - 23 файла языков, `index.ts` (`ADVISOR_LABEL_TRANSLATIONS`);
  - `advisor-labels.spec.ts`.
- `src/modules/advisors/localize-advisor-labels.ts` — `en` как есть, иначе словарь языка.
- `src/modules/advisors/advisors.seed-chain.spec.ts` — сид → `advisorUpsert().create` → `toRecord` → `toDto`.

**Изменённые**
- `prisma/schema.prisma` — `enum AdvisorGender`, `Advisor.gender AdvisorGender?`.
- `advisor-seed.data.ts` — `gender` у строки сида (обязательное): F — olivia, sunshine, veronica, may, marta;
  M — labsang (владелец, по фото), alisher, ivan.
- `advisors.repository.ts` — `AdvisorGender`, `AdvisorRecord.gender`; `prisma-advisors.repository.ts` — `toRecord`
  проецирует `gender`, экспортирован для теста цепочки.
- `advisors.service.ts` — `list(language)` без значения по умолчанию; `toDto` переводит `role` / `specialties`,
  считает `topics` от английского; `gender` в DTO не уходит.
- `advisors.controller.ts` — `@RequestLanguage()` + `@ApiLanguageQuery()`; комментарий о публичности уточнён.
- `src/contracts/openapi.ts` — описания `role` / `specialties`, новое `topics` (в `required`).
- `desk-attributes.ts` — описание `advisor_role`: «Persona title in English; the client sees it in their language.
  Set by Aura.»; `agent-desk.service.ts` — комментарий `profileOf`. Значения desk / Chatwoot — английские, без изменений.
- Колода: `deck-translations/index.ts` и её spec импортируют `TranslatedLanguage` из `common/language`.
- Тесты: `advisors.service.spec` (de-переводы, род, прочие поля без изменений, `topics` одинаковы, нет `gender`),
  `advisors.controller.spec` (`?lang` → сервис), `request-language.routes.spec` (каталог: `de` / без / `mt` → `en`),
  `guest-access.smoke.spec` (гость `?lang=de` → 200, `list('de')`; заглушке `DISABLED_LANGUAGES: []`),
  `seed.spec` (`gender` в create и update), `contracts/advisor.spec` (`topics` в DTO сида), фейк в `reviews.service.spec`.

## Перевод

- 23 языка × 10 терминов типа (с родовыми формами) + 34 специализации. de — сам; остальные — 6 агентов по брифу, у
  каждого файла прогон проверки (те же правила, что потом закрепил `advisor-labels.spec.ts`).
- Глоссарий v2 — по нему (`psychic`, `medium`, `tarot`, запретные `reader` / `reading` — 0 нарушений). Отступления:
  **el** psychic → «Διορατικός / Διορατική» (в v2 = medium, дало бы «Μέντιουμ · Μέντιουμ»); **ga** «Síceach» вместо
  «duine síceach» (короче для строки роли).
- Родовые формы — 19 языков; et / fi / hu / ga — одна форма на всё; da / sv — почти всё одной формой.
- Места, где переводчики сомневались (для ревью носителями, не блокеры): da «Kortlægger» (также «картограф»); hu
  Channeler «Csatorna» при чипе «Channeling»; sv Channeler-заимствование при чипе «Kanalisering»; ga — несколько
  неологизмов (Cainéalóir, Meánaíocht); mt — итальянизмы (Kartomanti, Medjanità); lv / et / lt — Clairsentience и
  Channeler на основе заимствований; el Clairsentience «Διαίσθηση» (= «интуиция»); el Channeler — заимствование «Channeler» (после ревью `010`; «Διάμεσος» = «медиум»).

## Длина — для клиентов (HankenGrotesk-Regular, метрики из `aura-app` шрифта)

Самая длинная собранная роль по языку; «+ цена» — со строкой « · $3.20/min» (англ. формат цены, локальный длиннее на
несколько pt). Бюджеты из ревью: список (13pt, роль + цена в одной строке) — **216pt**; Home `TopAdvisorRow` (12.5pt,
с рейтингом) — **118pt**.

| язык | самая длинная роль | 13pt | + цена | 12.5pt | самый длинный чип (13pt) |
|---|---|---|---|---|---|
| en | Astrologer · Card Reader | 147 | 217 | 141 | Quantum energy healing (142) |
| lt | Ekstrasensė · Čenelingo praktikė | 192 | 261 | 184 | 175 |
| ro | Clarvăzătoare · Medium · Tarot | 184 | 253 | 177 | 177 |
| nl | Helderziende · Medium · Tarot | 178 | 247 | 171 | 174 |
| pl | Jasnowidzka · Medium · Tarot | 176 | 245 | 169 | 186 |
| et | Selgeltnägija · Meedium · Taro | 176 | 246 | 169 | 178 |
| it | Veggente · Medium · Tarocchi | 174 | 244 | 167 | 157 |
| da / el | … · Medium · Tarot | 168 | 238 | 162 | 138 / 184 |
| cs / sk | Jasnovidka · Médium · Tarot | 167 | 236 | 160 | 166 / 174 |
| de | Hellseherin · Medium · Tarot | 166 | 235 | 159 | 141 |
| bg | Ясновидка · Медиум · Таро | 165 | 234 | 158 | 201 |
| fi / hr | … | 163 | 232–233 | 156–157 | 161 / 186 |
| fr | Astrologue · Cartomancien | 157 | 226 | 151 | 170 |
| ga | Astralaí · Fáistineoir cártaí | 153 | 223 | 147 | 184 |
| sl | Jasnovidka · Channelerka (Sunshine) | 151 | 221 | 146 | 178 |
| hu | Szerelem & párkapcsolat | 147 | 216 | 141 | 154 |
| es / pt | Vidente · Médium · Tarot | 145 | 215 | 140 | 170 / 161 |
| lv / mt | … | 139 | 208–209 | 133–134 | 175 / 167 |
| sv | Synsk · Medium · Tarot | 135 | 204 | 130 | 140 |

Вывод: английский уже на пределе (217 / 216, на Home 141 / 118 — уже обрезается). В большинстве языков роль + цена в
одну строку не влезает → **разделить роль и цену на два `Text`** (`AdvisorRow`, `BookSessionScreen`) обязательно. Чипы
переносятся — самый длинный 201pt при ширине ~290pt.

## Передача — `AURAT-0174` (приложение), `AURAT-0175` (веб); номера выдал координатор `slave-1-ac`

- **Приложение — `AURAT-0174`:** каталог подписан на `onLanguageChange` + `generation` (как `use-daily-card-sync.ts:22`); роль и цена —
  два `Text`; `glossary.json` v3 — el `psychic` «Διορατικός / Διορατική»; поиск по переведённому типу — так и нужно.
- **Веб — `AURAT-0175`:** язык в аргументе `getAdvisors` (как `daily-card-api.ts:9-18`); подбор по `topics` вместо `TOPIC_WORDS`
  (паритет закреплён тестом BFF). `topics` по умолчанию `[]` → веб с `topics`, ушедший раньше BFF, временно не находит
  «also»; веб с `TOPIC_WORDS` после BFF — тоже. Поэтому **BFF и веб — в одном окне: BFF, сразу за ним веб.**
- **Чаттерам:** «Клиент видит тип и специализации советника на своём языке; в desk и в Chatwoot они по-английски».
- **Манор:** после мёржа — `npm run desk:setup` (новое описание `advisor_role`), migrate + seed дважды.

## Открытое

- Пуш контрактов v0.29.0 (`main` + тег) — с отдельного одобрения владельца, до коммита BFF.
- Ревью носителями — желательно (список сомнений выше), не блокер.
