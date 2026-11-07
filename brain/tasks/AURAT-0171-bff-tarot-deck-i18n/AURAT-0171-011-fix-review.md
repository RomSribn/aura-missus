# AURAT-0171-011 — правки по ревью кода и переводов

Дата: 2026-11-06

Ревью пришло через координатора (`slave-1-9e`; владелец: «передавай сразу двоим»): код в порядке; переводы — 1
важное, 5 средних, 5 мелких; код — 4 мелких. Отчёт: `wf-code-0171-review.md` (scratchpad координатора).

## Переводы (исходные JSON → генерация TS заново, отпечатки не менялись — английский тот же)

- **fi `major-18-moon`** (карта дизайна): «tulla tunnetuksi» («стать известным») → «Jokin haluaa ensin tulla
  koetuksi ja vasta sitten ymmärretyksi. …».
- **fr / it `major-17-star`** (карта дизайна): приказ → приглашение — «Cette journée vous invite à faire
  confiance…», «La giornata di oggi ti invita a fidarti…»; el `major-17-star` — «κι ας μη βλέπετε ακόμη…».
- **pl `major-20-judgement`**: «Zrób to dziś, zamiast dalej ją w sobie nosić»; de `major-20-judgement` — «Es ist
  Zeit, ehrlich zu dir zu sein, …».
- **el `major-12-hanged-man`**: Surrender «Παράδοση» (= «Традиция», как у Иерофанта) → «Αποδοχή».
- **hr / sl** Care у Императрицы и Королевы Кубков: «Briga» → «Njega», «Skrb» → «Skrbnost»; «Briga» / «Skrb»
  остались у Девятки Мечей (Worry).
- Ключевые слова: lt / lv Timing → «Tinkamas metas» / «Īstais brīdis»; nl `pentacles-05` Asking → «Om hulp vragen».
- fr / pl `pentacles-05`, es `swords-queen` — формулировки ревью.
- **Не принято:** lt Presence у Королевы Жезлов («Charizma» → «Artumas» / «Buvimas čia»). В этой карте presence —
  умение занимать пространство («Užimate daugiau vietos, nei manote»); «Artumas» — близость, «Buvimas čia» —
  «быть здесь»; «Charizma» ближе к смыслу. Оставлено.

## Артикль у старших (замечание 6)

Поле `majorsTakeArticle` убрано из `TarotDeckTranslation` (никто не читал — правило 8). Шапка каждого файла пишет
артикль с исключениями: nl «yes, except Kracht, Gerechtigheid, Matigheid», da — Styrke, Retfærdighed, Mådehold,
ga — Roth an Fhortúin; sv — у всех («Styrkan»). `009` поправлен.

## Код

- `src/common/language/request-language.routes.spec.ts` — новый: три маршрута по HTTP с моками сервисов и
  настоящим пайпом: `?lang=de` → `'de'` у карты дня и `pick` (язык — из query, не из тела); `pick` и история с
  `?lang=mt` при выключенном `mt` → `'en'`; история с `?lang=fr` → `'fr'`, без `lang` → `'en'`.
- `tarot.service.spec`: «tells the chatter in English» → «hands the chatter’s note no language» — задача
  `spread-picked` уходит ровно с `{ conversationId, cardId }`.
- `tarotCardOpenApi` — «ordinary letter case in every language; capitals by the language’s rules, not a text
  transform».
- README — `POST /v1/tarot/spread/:messageId/pick?lang=`.

## Проверки

Самопроверка всех правленых языков — OK; `npm run lint`, `typecheck`, `build` — чисто; `jest` — 151 набор,
2 016 тестов, все зелёные (включая тест колоды с отпечатками).
