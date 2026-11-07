# AURAT-0171-009 — execute, этап 1: колода на 23 языках + язык в сборке DTO

Дата: 2026-11-06 · Статус: этап 1 готов; этап 2 (резолвер `?lang`, маршруты, Swagger) ждёт мёржа `AURAT-0168` в
`develop`. Не закоммичено.

## Файлы (aura-bff)

Новые:
- `src/modules/tarot/deck-translations/deck-translation.ts` — типы: `TarotCardText`, `TarotCardTranslation`
  (+ `source` — отпечаток английского), `TarotDeckTranslation` (`majorsTakeArticle`, `suits`, `ranks`, `cards`).
- `src/modules/tarot/deck-translations/<lang>.ts` × 23 — в шапке: артикль у старших да/нет, масти, ранги.
- `src/modules/tarot/deck-translations/index.ts` — `TAROT_DECK_TRANSLATIONS`, правила перевода.
- `src/modules/tarot/deck-translations/deck-translations.spec.ts` — 11 проверок на все языки (§4 спеки v2).
- `src/modules/tarot/localize-card.ts` (+ `.spec.ts`) — `localizeCard(card, language)`, тип `DeckLanguage`.

Изменены:
- `tarot-card.dto.ts` — `toTarotCardDto(card, base, language)`, `language` обязателен, внутри — `localizeCard`.
- `tarot.service.ts` — `getDailyCard` / `pickSpreadCard` с `language`; оба пути `pick` идут через `toDto`;
  `announceSpreadPick` — английский из записи.
- `chat.service.ts` — `toDto` / `toSpreadDto` с `language`; `getHistory` — язык запроса; отправка, вебхук, сверка,
  маркеры — `'en'`.
- `tarot.controller.ts`, `chat.controller.ts` — **временно** передают `'en'`; в этапе 2 — `@RequestLanguage()`.
- `tarot.service.spec.ts` (+6 тестов: карта дня, уже выданный день, `pick` первая запись и повтор, тот же
  `imageUrl`, заметка чаттеру — английская), `chat.service.spec.ts` (+4: история переведена, без перевода →
  английский, нераскрытый — без карты, сокет — английский).

Временное до этапа 2 (не мёржится в таком виде): `TranslatedLanguage` — локальный союз из 23 кодов, `DeckLanguage`,
литерал `'en'` → контрактные `Language` / `SOURCE_LANGUAGE` после влития `develop`.

## Проверки

- `tsc --noEmit`, `eslint src/modules/tarot src/modules/chat` — чисто; `jest src/modules/tarot src/modules/chat` —
  25 наборов, 411 тестов, все зелёные.
- Отрицательная проверка отпечатка: испорченный `source` у `de major-00-fool` → тест падает с
  «translated from older English — re-translate, then source: '2e6a90e985f9'»; файл восстановлен.

## Как переводили

6 агентов по 3–4 языка, бриф с правилами спеки, самопроверка тем же набором правил, что в спеке (скрипт — в
scratchpad, в репо не идёт). Затем **обратный перевод** `daily` всех 23 языков на английский — другими агентами,
без доступа к английскому оригиналу, буквально по времени и модальности.
- Английская проверка на предсказания (`you will`, `shall`, `going to`, `promise`, `guarantee`) по обратным переводам:
  срабатывания — только `swords-02` в 8 языках («Let today be the day when you will look at it» — придаточное при
  «пусть», повторяет английское «Let today be when you look at it»; не прогноз) и `et swords-02` «is going to cost
  you» → **исправлено** на «maksab sulle juba praegu» (английский: «is costing you»).
- «Пограничное», общее для всех языков, повторяет **одобренный английский**: `major-10-wheel` «already turning»,
  `major-21-world` «finishing well», `swords-09` «watch it shrink», `swords-10` «Nothing more can fall from here»,
  `cups-09` «something you wanted, and got». Не трогали.
- hu `major-16-tower` «leomlik» (законченный вид — «рухнет сегодня») → «omladozik» («осыпается»).
- По замечаниям обратного перевода исправлено ≈ 85 фраз во всех языках: кальки («Aujourd’hui vous invite», «slow
  the sentence»), согласование (bg «се искат», lt «pasvirę», lv «vieglāks», hr «današnjeg dana»), смысловые сдвиги
  (it `major-02`, hu `major-15`, mt `major-11`, lv `major-20`), прогрессив вместо простого настоящего (es, pt).

## Длины — для 0169 / 0170 (проверка в маноре)

Английский: name 19 («Knight of Pentacles»), keywords 36, daily ≤ 160. Лимиты: keywords ≤ 48 (две строки на 360 pt —
решение владельца через координатора), daily ≤ 220, имена без предела.

| язык | артикль у старших | самое длинное name | зн. | самые длинные keywords | зн. | max daily |
|---|---|---|---|---|---|---|
| bg | да (суффикс) | Колелото на съдбата | 19 | Устойчивост · Предпазливост · Издръжливост | 42 | 146 |
| cs | нет | Sedmička pentáklů | 17 | Završení · Celistvost · Dosažení cíle | 37 | 128 |
| da | да (суффикс) | Ypperstepræstinden | 18 | Modstandskraft · Forsigtighed · Udholdenhed | 43 | 151 |
| de | да | Das Rad des Schicksals | 22 | Unzufriedenheit · Aufmerksamkeit · Langeweile | 45 | 146 |
| el | да | Ακόλουθος των Νομισμάτων | 24 | Ανησυχία · Σκέψεις της νύχτας · Ανακούφιση | 42 | 148 |
| es | да | La Rueda de la Fortuna | 22 | Preocupación · Pensamientos nocturnos · Alivio | 46 | 143 |
| et | нет | Karikate kuninganna | 19 | Stabiilsus · Toimetulek · Meisterlikkus | 39 | 133 |
| fi | нет | Pentaakkelien kuningatar | 24 | Valmistuminen · Kokonaisuus · Perille pääsy | 43 | 140 |
| fr | да | La Grande Prêtresse | 19 | Inquiétude · Pensées nocturnes · Soulagement | 44 | 146 |
| ga | да | Ceathair na gClaíomh | 20 | Aitheantas · Féinmhuinín · Dul chun cinn | 40 | 179 |
| hr | нет | Četvorka pentakla | 17 | Ravnoteža · Žongliranje · Prilagodljivost | 41 | 143 |
| hu | да | Az Akasztott ember | 18 | Kiegyensúlyozottság · Együttérzés · Nyugalom | 44 | 141 |
| it | да | La Ruota della Fortuna | 22 | Preoccupazione · Pensieri notturni · Sollievo | 45 | 140 |
| lt | нет | Pentaklių septynetas | 20 | Ramybė · Išsipildęs noras · Pasitenkinimas | 42 | 142 |
| lv | нет | Pentaklu septiņnieks | 20 | Apmierinātība · Vēlēšanās · Piepildījums | 40 | 136 |
| mt | да | Is-Saċerdotessa l-Kbira | 23 | Tranżizzjoni · Pass ’il quddiem · Kalma | 39 | 129 |
| nl | да | Koningin van Pentakels | 22 | Helderheid · Onafhankelijkheid · Eerlijkheid | 44 | 142 |
| pl | нет | Dziewiątka Kielichów | 20 | Zatrzymywanie · Bezpieczeństwo · Kurczowy chwyt | 47 | 147 |
| pt | да | Cavaleiro de Espadas | 20 | Preocupação · Pensamentos noturnos · Alívio | 43 | 136 |
| ro | да (суффикс) | Cavalerul de Pentacluri | 23 | Îngrijorare · Gânduri de noapte · Ușurare | 41 | 139 |
| sk | нет | Sedmička pentaklov | 18 | Zavŕšenie · Celistvosť · Dosiahnutie cieľa | 42 | 128 |
| sl | нет | Devetica pentaklov | 18 | Ravnovesje · Žongliranje · Prilagodljivost | 42 | 127 |
| sv | да (суффикс) | Stavarnas Drottning | 19 | Motståndskraft · Försiktighet · Uthållighet | 43 | 137 |

«Да (суффикс)» — артикль приклеен к слову (bg «Глупакът», da «Narren», ro «Nebunul», sv «Döden»): для фраз с
`{{card}}` это то же, что артикль. Исключения (уточнено ревью, `011`): в nl и da у Strength / Justice / Temperance
артикля нет и в традиции («Kracht», «Styrke»), в ga — у «Roth an Fhortúin»; в sv артикль у всех трёх («Styrkan»).

## Выбор, где традиций несколько (на ревью носителями — желательно)

- Pentacles: de Münzen, fr Deniers, es Oros, it Denari, pt Ouros, pl Denary, el Νομίσματα, fi Pentaakkelit, et Mündid,
  sv Mynt; остальные — «Pentacles» в своей форме (Pentakels, Pentákly, Pentakli…).
- Page: de Bube, es Sota, it Fante, pt Valete, fr Valet, nl Page, sv Knekt, da Knægt; славянские / балтийские — «паж».
- Старшие: fr — названия Райдера–Уэйта (Le Magicien, Le Hiérophante, La Tour), но «Le Mat» по брифу; it — La Papessa /
  Il Papa (принятые в Италии), не Sacerdotessa / Ierofante.
- **ga и mt** — опубликованной традиции колоды на этих языках нет, имена — собственная передача агента; mt — первый
  кандидат на ревью носителем.
- pl / cs / sk / sl `cups-09` — «одно из ваших желаний уже исполнилось» (чтобы не выдать род прошедшим временем) —
  утверждение о читателе сильнее английского «something you wanted, and got»; не прогноз.

## Дальше

Этап 2 — после мёржа `AURAT-0168`: влить `develop`; `TranslatedLanguage` от контрактного `Language`; резолвер
(`src/common/language/*`, черновик готов); `@RequestLanguage()` / `@ApiLanguageQuery()` на трёх маршрутах; смоук с
заглушкой `ConfigService` по ключу; Swagger `tarotCardOpenApi`; реэкспорт `LANGUAGE_QUERY_PARAM`. Затем — ревью в IDE.
