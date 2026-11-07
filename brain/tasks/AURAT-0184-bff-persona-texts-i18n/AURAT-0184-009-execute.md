# AURAT-0184-009 — execute

Дата: 2026-11-07 · Слот `slave-1`, ветка `feature/AURAT-0184-bff-persona-texts-i18n`. **Не закоммичено** — ждёт ревью
владельца в IDE. Спека — `007-spec-v2.md`, решения 1А / 2А / 3А (`008`).

## Проверки

`npm run typecheck` ✓ · `npm run lint` ✓ · `npm run build` ✓ · `npm test` — **154 набора, 2067 тестов, все зелёные** (после `010`).
Spec текстов проверен порчей: незакрытые кавычки (de), пробел вместо U+00A0 (fr), строчные «ci» / «twoje» (pl), «Hellseher»
у Olivia (de) — все пойманы; женские `reader` — отдельным тестом.

## aura-bff — файлы

**Новые**
- `src/modules/advisors/texts/`:
  - `advisor-text-translation.ts` — `AdvisorTexts`, `AdvisorTextTranslation` (`source` по полю = sha256 от
    `${gender}|${English}`, 12 hex), `AdvisorTextsTranslation`;
  - 23 файла языков (`Record` по `id` персоны; в шапке — обращение языка и заметки переводчика), `index.ts` —
    `ADVISOR_TEXT_TRANSLATIONS` и правила перевода;
  - `advisor-texts.spec.ts` — полнота, отпечатки (английский + род), NFC / U+00AD / U+02BC / U+202F / двойные пробелы,
    `\n` как в английском, не равно английскому, длины (90 / 320 / 1,6×), кавычки языка с балансом по закрывающему
    знаку, ro ș ț, fr U+00A0, запретные формы глоссария v3 (+ женские), обращение, род по терминам `0173`, живость
    исключений; женские `reader` ловятся;
  - `advisor-texts.spec-fixtures.ts` — `WRONG_ADDRESS` по языку (целые слова, `cased`, pl окончания -łeś / -łaś),
    `QUOTE_PAIRS`, `ALLOWED` (пуст — исключений не понадобилось). Вне `dist`.
- `src/modules/advisors/localize-advisor.ts` (переименован из `localize-advisor-labels.ts`) — `localizeAdvisor(advisor:
  Pick<AdvisorRecord, 7 полей>, language)` → `{ role, specialties, tagline, bio, greeting }`; персона без перевода →
  английские тексты. **Точка для `AURAI-0012`.**

**Изменённые**
- `advisors.service.ts` — `toDto` берёт все пять полей из `localizeAdvisor`.
- `labels/glossary-avoid.spec-fixtures.ts` — v3, женские формы `local` (fr `lectric`, it `lettric`, ro `cititoa`, sl `bralk`).
- `labels/index.ts` — комментарий el: не отступление, а v3; `labels/translate-labels.ts` — имя функции.
- `advisors.controller.ts` — комментарий о публичности: язык — и подписи, и тексты.
- `src/contracts/openapi.ts` — `tagline` / `bio` / `greeting` на языке запроса; `greeting` — «never stored or sent».
- `README.md` — «Response language» и `GET /v1/advisors`.
- Тесты: `advisors.service.spec` (тест «wait for decision 8» → «прочие поля как у en»; блок AURAT-0184: de-тексты,
  род Ivan, неизвестная персона → английский, en как есть), `advisors.seed-chain.spec` (тексты через цепочку сид →
  `toDto`).

## aura-contracts (`/Volumes/Work/personal/ai-manors/aura-contracts`, ветка `feature/AURAT-0184-persona-texts-jsdoc`, не закоммичено)

`src/advisor.ts` — JSDoc `tagline` / `bio` / `greeting` (на языке запроса; приветствие — пузырь клиента, не хранится и
не отправляется). Схема не меняется, без тега. Коммит → `main` → **пуш — с отдельного одобрения**; BFF от него не
зависит (`#v0.29.0` остаётся).

## Перевод

- de — сам; остальные 22 — 6 агентов по общему брифу (правила `007` §4, род персон, `register`, термины `0173` языка,
  общие фразы), у каждого — прогон spec до чистоты. Исключений (`ALLOWED`) не понадобилось. Одна ошибка была в spec, не
  в переводе: в nl обе пары кавычек закрываются «”» — баланс считается по закрывающему знаку.
- Выборочно вычитал сам: приветствия Olivia и слоганы Ivan во всех 23 языках, немецкий целиком.
- Общие фразы (Veronica / May; May / Alisher) — сверены агентами скриптом: одинаковы, у May и Alisher отличаются только
  формы рода.
- Незаконченная фраза Sunshine («I feel if you contact me with an open mind and give me the chance to bring…») —
  достроена минимально: «если вы обратитесь… и дадите мне шанс, я смогу принести…» во всех 23 языках (после ревью
  `010`: de / fr / it / es / pt / lt / lv / et / fi сначала читали «give» как приказ клиенту; hu был достроен сразу —
  «hozhatok»).
- Сомнения для носителей — ниже, по языкам (не блокер). Ревью `010` закрыло большинство как «оставить» (см. ниже);
  исправлены pt «curadora», ro «psihice», fr «Mort imminente», nl «opgetild», et Marta, sl «obrnila», кальки de / nl,
  cs / sk May. Наименее уверенные языки — mt и ga (неологизмы).

## Ширина слогана — для веба (самое узкое место: `AdvisorRow` на телефоне)

HankenGrotesk-Regular 13px, метрики из шрифта приложения, без кернинга. Колонка текста при ширине 375 и полях 16px:
375 − 32 − 2×14 (padding) − 2 (рамка) − 76 (фото) − 2×14 (gap) − 92 (цена) ≈ **117px**. Клиенты не обрезают —
слоган переносится; в английском уже 4 строки, в переводах 4–5. Глифы всех текстов есть в шрифте.

| язык | самый длинный слоган | знаков | ширина 13px | строк в 117px |
|---|---|---|---|---|
| en | 30 years reading, from a long line of psychics and mediums (olivia) | 58 | 344 | 4 |
| bg | На прага на смъртта на четири – оттогава виждам през завесата (alisher) | 61 | 390 | 4 |
| cs | Rozená jasnovidka – andělská říše, jasnovidectví a channeling (sunshine) | 61 | 356 | 4 |
| da | 30 års læsninger – fra en lang slægt af clairvoyante og medier (olivia) | 62 | 358 | 4 |
| de | 30 Jahre Deutungen, aus einer langen Ahnenreihe von Hellsehern und Medien (olivia) | 73 | 450 | 6 |
| el | Θεραπευτικοί συντονισμοί από απόσταση, εργασία με τσάκρα και αύρα (may) | 65 | 421 | 5 |
| es | Al borde de la muerte a los cuatro años: desde entonces veo a través del velo (alisher) | 77 | 454 | 5 |
| et | 30 aastat ennustusi, pärit pikast selgeltnägijate ja meediumide suguvõsast (olivia) | 74 | 428 | 5 |
| fi | 30 vuotta tulkintoja – pitkästä selvänäkijöiden ja meedioiden suvusta (olivia) | 69 | 397 | 4 |
| fr | 30 ans de consultations, issue d’une longue lignée de voyants et de médiums (olivia) | 75 | 444 | 5 |
| ga | Gar don bhás ag ceithre bliana d’aois — ag féachaint tríd an bhfial ó shin (alisher) | 74 | 422 | 5 |
| hr | Rođena vidovnjakinja – svijet anđela, vidovitost i kanaliziranje (sunshine) | 64 | 354 | 5 |
| hu | Született látnok – angyali birodalom, tisztánlátás és channeling (sunshine) | 64 | 363 | 4 |
| it | Nata veggente – mondo angelico, chiaroveggenza & canalizzazione (sunshine) | 63 | 385 | 4 |
| lt | Buriu jau 30 metų – kilusi iš senos ekstrasensų ir mediumų giminės (olivia) | 66 | 382 | 4 |
| lv | Četru gadu vecumā tuvu nāvei – kopš tā laika redzu cauri plīvuram (alisher) | 65 | 386 | 4 |
| mt | Sintonizzazzjonijiet ta’ fejqan mill-bogħod, ħidma fuq iċ-ċakras u l-awra (may) | 73 | 410 | 5 |
| nl | 30 jaar readings, uit een lang geslacht van helderzienden en mediums (olivia) | 68 | 402 | 4 |
| pl | 30 lat wróżenia – z wielopokoleniowego rodu jasnowidzów i mediów (olivia) | 64 | 394 | 4 |
| pt | Harmonizações energéticas à distância, trabalho com chakras e aura (may) | 66 | 401 | 4 |
| ro | Născută clarvăzătoare – tărâmul îngerilor, clarviziune și channeling (sunshine) | 68 | 387 | 5 |
| sk | Rodená jasnovidka – anjelská ríša, jasnovidectvo a channeling (sunshine) | 61 | 357 | 4 |
| sl | Rojena jasnovidka – angelsko kraljestvo, jasnovidnost in channeling (sunshine) | 67 | 388 | 4 |
| sv | 30 år av läsningar – från en lång släkt av synska och medier (olivia) | 60 | 345 | 4 |

## Ручная проверка и заметки переводчиков (по группам)

(a) Olivia «Be prepared to know and change anything you want», (b) Alisher «Ask me what you've been afraid to ask», (c) пять вопросов Marta — обращение языка, без рода клиента; партнёр — «он».

## da / sv — clean
- da: reader → rådgiver, Psychic Reader → clairvoyant (label), reading → læsning; P.K. → poltergeistvæsener; card reading → kortlægning (label). Сомнения: «kortlægning» = ещё «картирование»; прилагательное «clairvoyante» (по ярлыку «Clairvoyant rådgivning») — тяжеловато; «læge» вместо «hele» (heal) у Marta.
- sv: rådgivare, synsk (label), läsning; poltergeistväsen; kortläggning (label — сильнейшее сомнение: «картирование»); Aunt → moster (выбор материнской стороны, в английском не сказано); Empath → «empatisk».
- Ручная: da (a) Vær klar til at få alt at vide og ændre alt, hvad du ønsker. (b) Spørg mig om det, du har været bange for at spørge om. (c) »Finder vi sammen igen?« »Hvad føler han for mig?« »Er han min sjæleven?« »Skal jeg blive i dette forhold?« »Hvilke muligheder har jeg fremover?«
  sv (a) Var beredd på att få veta och förändra allt du vill. (b) Fråga mig det du har varit rädd för att fråga. (c) ”Kommer vi att bli tillsammans igen?” ”Vad känner han för mig?” ”Är han min själsfrände?” ”Ska jag stanna i den här relationen?” ”Vilka möjligheter har jag framöver?” — klar / beredd / bange / rädd не изменяются по роду.
- Общие фразы — идентичны (одна строка). Слоганы: da 62, sv 60.
## fr / it / es / pt — clean
- reader → fr conseillère, it consulente, es asesora, pt consultora; Psychic Reader → voyante / veggente / vidente / vidente; reading → consultation / lettura / lectura / leitura; P.K. → «poltergeist».
- pt: клиент никогда не местоимение o/a (ajudá-lo/-la выдаёт род) — lhe, si, consigo, или глагол клиенту.
- Veronica «results that leave one uplifted…» — во всех четырёх без прилагательных о человеке.
- Сомнения: fr Olivia «lignée de voyants et de médiums» — обобщающий мужской мн. ч.; es/pt «juntos» у Marta (партнёр «он» → мужской мн. ч. верен при любом роде клиента); fr Labsang «je l’ai sans doute déjà côtoyé de près»; fr Ivan «clairsentient»; es Ivan «un empático»; pt Healer — «curadora».
- Ручная (a) fr Préparez-vous à tout savoir et à changer tout ce que vous voulez. · it Preparati a sapere e a cambiare tutto ciò che vuoi. · es Prepárate para saber y cambiar todo lo que quieras. · pt Prepare-se para saber e mudar tudo o que quiser.
  (b) fr Demandez-moi ce que vous aviez peur de demander. · it Chiedimi ciò che hai avuto paura di chiedere. · es Pregúntame lo que te ha dado miedo preguntar. · pt Pergunte-me aquilo que tem tido medo de perguntar.
  (c) fr « Allons-nous nous remettre ensemble ? » « Que ressent-il pour moi ? » « Est-il mon âme sœur ? » « Dois-je rester dans cette relation ? » « Quelles sont mes options pour la suite ? » · it Torneremo insieme? / Che cosa prova lui per me? / È lui la mia anima gemella? / Devo restare in questa relazione? / Quali sono le mie opzioni per il futuro? · es ¿Volveremos a estar juntos? / ¿Qué siente él por mí? / ¿Es él mi alma gemela? / ¿Debo seguir en esta relación? / ¿Qué opciones tengo de cara al futuro? · pt Vamos voltar a estar juntos? / O que é que ele sente por mim? / Ele é a minha alma gémea? / Devo ficar nesta relação? / Que opções tenho daqui para a frente?
- Общие фразы: хвост Veronica/May идентичен; May/Alisher — отличаются только начальные причастия рода (formée/formé…), сверено программно. Слоганы: fr 75, it 63, es 77, pt 66.
## pl / cs / sk / sl — clean
- reader → pl doradczyni, cs poradkyně, sk poradkyňa, sl svetovalka; Psychic Reader → jasnowidzka / jasnovidka (label); reading → pl wróżba / wróżyć, cs/sk výklad, sl branje; P.K. → poltergeisty.
- psychic (прил.): «psychic activations and protection» — по ярлыку (Ochrona energetyczna…); «matters spiritual, psychic…» — pl parapsychicznych, cs/sk jasnovideckých, sl jasnovidnih (буквальное psychiczny = «психический»).
- Сомнения: «Kendra» — со строчной и склоняется; «inner planes» — wewnętrzne płaszczyzny / vnitřní pláně / vnútorné roviny / notranje ravni; Ivan «Intuitive, Empath and Clairsentient» — перестроено («одарённый интуитивный эмпат, наделённый яснознанием»); sl «мы» в будущем — мужской мн. ч. → двойственное число «poiščiva» / «začniva» в приветствиях Olivia и May; cs/sk/sl «člověk» — обобщённое «one», не клиент.
- Ручная (a) pl Przygotuj się, by poznać i zmienić wszystko, czego pragniesz. · cs Připravte se na to, že poznáte a změníte cokoli, co si přejete. · sk Pripravte sa na to, že spoznáte a zmeníte čokoľvek, čo si želáte. · sl Pripravite se, da spoznate in spremenite karkoli želite.
  (b) pl Zapytaj mnie o to, o co strach Ci było zapytać. · cs Zeptejte se mě na to, na co se dosud bojíte zeptat. · sk Opýtajte sa ma na to, na čo sa doteraz bojíte opýtať. · sl Vprašajte me tisto, kar vas je bilo strah vprašati. — безличное «strach było» / настоящее «bojíte» вместо причастия с родом.
  (c) pl „Czy znowu będziemy razem?” „Co on do mnie czuje?” „Czy on jest moją bratnią duszą?” „Czy zostać w tym związku?” „Jakie mam możliwości na przyszłość?” · cs „Budeme zase spolu?“ „Co on ke mně cítí?“ „Je on mou spřízněnou duší?“ „Mám v tom vztahu zůstat?“ „Jaké mám možnosti do budoucna?“ · sk „Budeme opäť spolu?“ „Čo on ku mne cíti?“ „Je on moja spriaznená duša?“ „Mám v tom vzťahu zostať?“ „Aké mám možnosti do budúcnosti?“ · sl „Bova spet skupaj?“ „Kaj on čuti do mene?“ „Je on moja sorodna duša?“ „Naj ostanem v tem odnosu?“ „Kakšne možnosti imam za naprej?“
- Общие фразы: хвост идентичен (скрипт); May/Alisher — только формы рода (wyszkolona/wyszkolony; prošla/prošel; prešla/prešiel; izšolana/izšolan). Слоганы: pl 67, cs 61, sk 61, sl 67.
## hr / bg / el / hu — clean
- reading → hr čitanje, bg гадаене, el ανάγνωση, hu jóslás; reader → savjetnica / съветничка / (η) σύμβουλος / tanácsadó; P.K. → hr psihokinetički entiteti, bg полтъргайст същности, el ψυχοκινητικές οντότητες, hu poltergeist-entitások.
- hr / el: фразы о клиенте — без причастий и прилагательных при «vi» / «εσείς» («Pripremite se», «Ετοιμαστείτε»).
- Незаконченная фраза Sunshine — hr / bg / el / hu достроены главным предложением («могу…», hu «hozhatok»); после `010` — так же во всех языках.
- Сомнения: hr Ivan «jasnoosjećajnik» (редкое), «Kendra» → «kendri», Marta «duhovna vodilja»; bg «интуитив», «експертка», «духовна водачка»; el — Clairsentience в ярлыке «Διαίσθηση» = «интуиция», поэтому Intuitive → «ενορατικός»; Empath не «εμπαθής» (по-гречески «враждебный») → «με ενσυναίσθηση»; adeptship → «μύστης»; «κόουτς / κόουτσινγκ»; hu — рода нет, Látnok для обоих.
- Ручная (a) hr Pripremite se da saznate i promijenite sve što želite. · bg Бъдете готови да научите и да промените всичко, което пожелаете. (мн. ч. прилагательного без рода) · el Ετοιμαστείτε να μάθετε και να αλλάξετε ό,τι θέλετε. · hu Készülj fel, hogy megtudj és megváltoztass bármit, amit csak szeretnél.
  (b) hr Pitajte me ono što vas je dosad bilo strah pitati. · bg Попитайте ме онова, което сте се страхували да попитате. · el Ρωτήστε με ό,τι φοβόσασταν να ρωτήσετε. · hu Kérdezd meg tőlem, amit eddig nem mertél megkérdezni.
  (c) hr „Hoćemo li ponovno biti zajedno?“ „Što on osjeća prema meni?“ „Je li on moja srodna duša?“ „Trebam li ostati u ovoj vezi?“ „Koje su moje mogućnosti od sada nadalje?“ · bg „Ще се съберем ли отново?“ „Какво изпитва той към мен?“ „Той ли е моята сродна душа?“ „Да остана ли в тази връзка?“ „Какви са възможностите ми занапред?“ · el «Θα ξαναβρεθούμε μαζί;» «Τι νιώθει εκείνος για μένα;» «Είναι εκείνος η αδελφή ψυχή μου;» «Να μείνω σε αυτή τη σχέση;» «Ποιες είναι οι επιλογές μου από εδώ και πέρα;» · hu „Újra együtt leszünk?” „Mit érez irántam?” „Ő a lelki társam?” „Maradjak ebben a kapcsolatban?” „Milyen lehetőségeim vannak a jövőre nézve?”
- Общие фразы: хвост идентичен; May/Alisher — только род (obučena/obučen, обучена/обучен, εκπαιδευμένη/εκπαιδευμένος). Слоганы: hr 64, bg 61, el 65, hu 64.
## lt / lv / et / fi — clean
- lt: reader → patarėja, reading → būrimas, psychic (прил.) → ekstrasensinis; Healer → gydūnė (gydytoja = врач); «jūs» со строчной. lv: konsultante, zīlēšana, gaišredzības; medijs одинаков для обоих родов. et: nõustaja, ennustus; predictions → ettekuulutused (чтобы ennustus значило только сеанс). fi: neuvoja, tulkinta, selvänäkö-; притяжательные суффиксы вместо «sinun».
- Сомнения: lt «gydūnė», «koučingas / koučeriu», Sunshine «ekstrasensės darbas»; Aquarian Foundation и White Eagle Lodge — по-английски, «Teosofų draugija», «Plejados»; lv «Mana tante ir pieredzējis medijs» (мужской по роду существительного medijs), «iekšējās plaknēs», «Teosofiskās biedrības»; et «suhtecoachingut / suhtecoachiks», «lahkuminekuvalu tervendaja»; fi «hienotunteinen» (confidential о Marta), Ivan «intuitiivikko, empaatikko ja selvätuntija».
- Ручная (a) lt Pasiruoškite sužinoti ir pakeisti viską, ką norite. · lv Sagatavojieties uzzināt un mainīt visu, ko vēlaties. (глагол вместо pasiruošęs/-usi, gatavs/gatava) · et Ole valmis teada saama ja muutma kõike, mida soovid. · fi Ole valmis tietämään ja muuttamaan mitä tahansa haluat.
  (b) lt Klauskite manęs to, ko iki šiol bijojote paklausti. · lv Jautājiet man to, ko līdz šim baidījāties jautāt. · et Küsi minult seda, mida oled kartnud küsida. · fi Kysy minulta sitä, mitä olet pelännyt kysyä.
  (c) lt „Ar vėl būsime kartu?“ „Ką jis man jaučia?“ „Ar jis – mano giminingoji siela?“ „Ar man likti šiuose santykiuose?“ „Kokios mano galimybės ateityje?“ · lv „Vai mēs atkal būsim kopā?“ „Ko viņš pret mani jūt?“ „Vai viņš ir mans dvēseles radinieks?“ „Vai man palikt šajās attiecībās?“ „Kādas ir manas iespējas turpmāk?“ · et „Kas me saame uuesti kokku?“ „Mida ta minu vastu tunneb?“ „Kas ta on mu hingesugulane?“ „Kas peaksin selles suhtes jääma?“ „Millised on mu võimalused edaspidi?“ · fi ”Palaammeko yhteen?” ”Mitä hän tuntee minua kohtaan?” ”Onko hän sielunkumppanini?” ”Pitäisikö minun jäädä tähän suhteeseen?” ”Mitä vaihtoehtoja minulla on jatkossa?” — et / fi: «ta» / «hän» не различают «он» (неизбежно).
- Общие фразы: хвост идентичен (с вводным словом выровнено «The most important» / «Most importantly»); May/Alisher — только род (išmokyta/išmokytas, apmācīta/apmācīts); et / fi дословно. Слоганы: lt 66, lv 65, et 74, fi 69.

## de / nl / ro / mt / ga — clean

- de (сам): reader → Beraterin, reading → Deutung; P.K. → Poltergeist-Wesen. nl: reader → adviseur (одна форма для
  женщины), reading → reading; psychic (прил.) → paranormaal («psychisch» = психический); P.K. → poltergeistentiteiten.
  ro: consilieră, citire; psychic (прил.) → extrasenzorial(e) (после `010`; «psihic» = психический); P.K. → entități
  poltergeist. mt: konsulenta (женская от konsulent), qari; P.K. → entitajiet poltergeist. ga: comhairleoir, léamh;
  P.K. → aonáin poltergeist; Theosophy Society, Aquarian Foundation, White Eagle Lodge — по-английски (устоявшихся
  ирландских форм нет).
- Сомнения для носителей: ro «Universitatea Cabalistă din Ierusalim», «format ca adept al Cercului Interior»; **mt**
  (наименее уверенный) — «qari», «kuxjenza», «Il-kies dejjem nofsu mimli», «imżejjen b'mod inkredibbli», «mastru
  fil-fejqan kwantiku», «nissintonizza», «jiċċarġjak enerġetikament»; **ga** — «tionscanta» (initiated), «siúl amach»
  (dating), «Ollscoil Chabálach Iarúsailéim», «adept den Chiorcal Istigh», «plánaí inmheánacha», «seanchineálacha
  Jung», «ionbhách» (empath), «discréideach», «na chakraí» (мутация?); nl «Bijna-doodervaring op mijn vierde»,
  «paranormale activaties».
- Ручная (a) de Sei bereit, alles zu erfahren und alles zu verändern, was du willst. · nl Wees bereid om alles te weten
  te komen en alles te veranderen wat je wilt. · ro Pregătește-te să afli și să schimbi orice îți dorești. (возвратный
  глагол, не «pregătit/ă») · mt Ħejji ruħek biex issir taf u tibdel kull ma trid. («ruħek» нейтрально, не «lest/lesta»)
  · ga Bí réidh chun aon rud is mian leat a fháil amach agus a athrú. («réidh» не изменяется)
  (b) de Frag mich, was du dich bisher nicht zu fragen getraut hast. · nl Vraag me wat je nooit durfde te vragen. · ro
  Întreabă-mă ce ți-a fost teamă să întrebi. (безлично) · mt Staqsini dak li kont tibża’ tistaqsi. · ga Cuir orm an
  cheist a raibh eagla ort í a chur.
  (c) de „Werden wir wieder zusammenkommen?“ „Was empfindet er für mich?“ „Ist er mein Seelenverwandter?“ „Soll ich in
  dieser Beziehung bleiben?“ „Welche Möglichkeiten habe ich für die Zukunft?“ · nl “Komen we weer bij elkaar?” “Wat
  voelt hij voor mij?” “Is hij mijn zielsverwant?” “Moet ik in deze relatie blijven?” “Welke mogelijkheden heb ik voor
  de toekomst?” · ro „Vom fi din nou împreună?” „Ce simte el pentru mine?” „Este el sufletul meu pereche?” „Ar trebui
  să rămân în această relație?” „Ce opțiuni am de acum înainte?” · mt “Se nerġgħu nkunu flimkien?” “X’iħoss hu
  għalija?” “Hu r-ruħ ġemellata tiegħi?” “Għandi nibqa’ f’din ir-relazzjoni?” “X’għażliet għandi minn issa ’l
  quddiem?” · ga “An mbeimid le chéile arís?” “Cad a mhothaíonn sé i mo leith?” “An é m’anamchara é?” “Ar cheart dom
  fanacht sa chaidreamh seo?” “Cad iad mo roghanna as seo amach?” — глаголы клиента без рода; «Seelenverwandter» /
  «zielsverwant» — о нём.
- Общие фразы: хвост Veronica / May идентичен; May / Alisher — только род (ro pregătită/pregătit, mt imħarrġa/imħarreġ),
  сверено скриптом. Слоганы: de 73, nl 68, ro 68, mt 73, ga 74.

## Ревью `010`: сомнения, которые оставляем

da / sv «kortlægning / kortläggning» (устоялось в гадании), sv «moster», da «læge», da «clairvoyante»; fr «lignée de
voyants…», «côtoyé de près», «clairsentient»; es / pt «juntos»; es «un empático»; el «Διαίσθηση» (решение ярлыка
`0173`), «με ενσυναίσθηση»; «kendra» строчными, «inner planes», sl двойственное число, cs / sk / sl «člověk»; hr
«jasnoosjećajnik», «duhovna vodilja»; bg «интуитив», «експертка», «духовна водачка», «Експертизата ми»; lt «gydūnė»,
«koučingas»; lv «pieredzējis medijs»; et «suhtecoaching»; fi «hienotunteinen»; повтор «later … later» в pl / cs / sk /
bg / et / fi — стиль. (В отчёте pl / cs / sk / sl у Ivan «яснознание» — описка: в тексте ярлык Clairsentience языка.)

## Передача (номера — от координатора)

- **Приложение:** строка `untranslated` уже убрана (`AURAT-0185`). Устаревший комментарий
  `screens/advisor-profile/model/use-advisor-profile.ts:42` «Seeds the thread with the advisor's greeting» → «Opens the
  conversation with this advisor (no-op if it already exists), then jumps to that thread in the Chats tab. The greeting
  is the thread's UI-only intro bubble — never stored or sent.» Глоссарий **v4**: `avoid` `reader`, которых не ловят
  основы — женские fr `lectric`, it `lettric`, ro `cititoa`, sl `bralk` и sl мужские косвенные `bralc` (bralca, bralcu). По-английски до `AURAF-0024`
  остаются только ответы чаттеров — нужна ли об этом строка, решит владелец.
- **Веб:** ничего (слоган переносится; ширина — таблица выше).
- **`AURAI-0012`:** точка — `localizeAdvisor(advisor, language)`; приветствие сейчас идёт за языком интерфейса, чаттер
  его не видит.
- **Чаттерам** (в заметки): клиент видит слоган, био и приветствие советника на своём языке; в desk — английский.
- **Манор после мёржа:** миграций нет, сид не меняется; проверка — `007` §7.
- Документы: `AURAF-0024` строка 004 — BE ✓; `AURAF-0023-glossary.md` — копия BFF v3 + локальные женские формы.
