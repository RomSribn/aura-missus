# AURAF-0023 — глоссарий и как переводить приложение

Источник: `AURAT-0155` (шаг 1b), решения владельца 2026-11-04 (`AURAT-0155-006`). Правила языка и типографики —
`.claude/aura-build-rules.md`, раздел «Translations» (здесь не дублируются). Этот документ — для задач переноса
строк (шаги 2–3) и для веба.

## Где что лежит (aura-app)

| Файл | Что |
|---|---|
| `scripts/i18n/glossary.json` | 96 терминов × 23 языка (`use`, необязательные `stem` и `avoid`), таблица обращения `register`, `version`. Единственный источник |
| `scripts/i18n/translate.mjs` | `lookup`, `scan` — память переводов веба; `check` — глоссарий по переводам приложения; `review` — что ждёт носителя |
| `scripts/i18n/terms.js`, `locales.js` | общий код скрипта и Jest: шаблоны терминов, чтение `config/locales`, заметки `en.ts`, хэш ревью |
| `scripts/i18n/native-review.json` | журнал ревью носителями |
| `src/app/i18n/__tests__/glossary.test.ts` | Jest: глоссарий цел, каждое `avoid` находит свой пример и не ловит `use`, ни один перевод не содержит `avoid`, журнал ревью цел |
| `src/app/i18n/__tests__/translations.test.ts` | + лимиты `@max` во всех языках |

**Правка термина** — здесь, `version` + 1. Копии:
- **веб** своей копии пока не держит — принятие глоссария вебом (копия по `version`, проверка `avoid`) — `AURAT-0177`;
- **BFF** держит только запретные формы `reader` / `reading` — для подписей советников (`AURAT-0173`) и текстов
  персон (`AURAT-0184`): `src/modules/advisors/labels/glossary-avoid.spec-fixtures.ts` (`GLOSSARY_VERSION` = **3**
  с `AURAT-0184`, «re-copy when its version changes»). Плюс **локальное расширение** — женские `reader`, которых не
  ловят основы глоссария: fr `lectric`, it `lettric`, ro `cititoa`, sl `bralk` (помечены `local`; кандидат в v4).
  Перекопировать, когда меняется `avoid`.

**Версии.** v2 — `AURAT-0155` (96 терминов). **v3** — `AURAT-0174`, 2026-11-07: el `psychic` «διορατικός» (женская
«διορατική») вместо «μέντιουμ» — это `medium`, и у персон выходило «Μέντιουμ · Μέντιουμ». `avoid` не менялись, поэтому
копия BFF осталась на 2 и верна. el-строки приложения правки не потребовали (onboarding уже «διορατικούς»).

## Порядок перевода слайса

1. В `en.ts` — JSDoc над каждым ключом, где место неочевидно (где стоит, что рядом); `@max N` на узких местах
   (чип даты 58pt, корешок билета 74pt, однострочная кнопка, плашка); `@sensitive <тема>` на оплате, возвратах,
   отмене, удалении аккаунта, юридических текстах (над `export const en` — всё пространство).
2. `node scripts/i18n/translate.mjs scan src/<slice>/config/locales/en.ts --web <aura-web> --out /tmp/scan.json` —
   по каждому ключу: найден ли у веба (`exact` / `normalized`), источник `<ns>:<key>`, 23 перевода с
   плейсхолдерами приложения. Предупреждения:
   - «do not copy» — перевод веба содержит форму, которую глоссарий запрещает; берётся `use` глоссария;
   - «the web words this N ways» — у веба для этой строки разные переводы; выбрать по глоссарию.
3. Остальные строки — перевести самому: термины из глоссария (`use`, склоняя), форма кнопки и обращение — по
   таблице ниже.
4. `npx jest src/app/i18n` (полнота, плюралы, `@max`, `avoid`), `node scripts/i18n/translate.mjs check src/<slice>/config/locales`
   — советы (нет канонической формы там, где английский содержит термин; на падежных языках советы бывают
   ложными — решает переводчик).
5. Сработал `avoid` в тесте — не обязательно ошибка: поправить перевод или сузить `avoid` (тогда — с новым
   `example`). Решает человек.

`lookup "<English>"` — то же для одной строки. Замер: у трёх `config/copy.ts` (write-review, daily-card,
promo-code) веб покрывает 36 из 40 строк; у `shared` — 11 из 24 (у веба нет подписей доступности и билетов).

## Обращение и форма кнопки

Кнопка — команда; предложение, заголовок-инструкция, подпись доступности — текст, в регистре языка.

| Язык | Обращение | Кнопка | Пример кнопки | Пример предложения |
|---|---|---|---|---|
| bg | «вы» — Вие / ваш | императив ед. ч. | Опитай отново | Натиснете, за да приложите. |
| cs | «вы» — vy / váš | инфинитив | Zkusit znovu | Zadejte kód. |
| da | «ты» — du / din | императив | Prøv igen | Indtast koden. |
| de | «ты» — du / dein | инфинитив | Erneut versuchen | Gib den Code ein. |
| el | «вы» — εσείς / σας | существительное | Κράτηση συνεδρίας | Εισαγάγετε τον κωδικό. |
| es | «ты» — tú / tu | инфинитив | Reservar sesión | Introduce el código. |
| et | «ты» — sina / sinu | императив | Proovi uuesti | Sisesta kood. |
| fi | «ты» — sinä / sinun | императив | Yritä uudelleen | Syötä koodi. |
| fr | «вы» — vous / votre | инфинитив | Réessayer | Saisissez le code. |
| ga | «ты» — tú / do | императив | Bain triail eile as | Cuir isteach an cód. |
| hr | «вы» — vi / vaš | императив ед. ч. | Pokušaj ponovno | Unesite kôd. |
| hu | «ты» — te / -d | существительное | Újrapróbálás | Add meg a kódot. |
| it | «ты» — tu / tuo | императив ед. ч. | Riprova | Inserisci il codice. |
| lt | «вы» — jūs / jūsų | инфинитив | Bandyti dar kartą | Įveskite kodą. |
| lv | «вы» — jūs / jūsu | инфинитив | Mēģināt vēlreiz | Ievadiet kodu. |
| mt | «ты» — int / tiegħek | императив | Erġa’ pprova | Daħħal il-kodiċi. |
| nl | «ты» — je / jouw | инфинитив | Opnieuw proberen | Voer de code in. |
| pl | «ты» — Ty / Twój | императив ед. ч. | Spróbuj ponownie | Wpisz kod. |
| pt | «вы» — você (подразумевается) / o seu | инфинитив | Tentar novamente | Introduza o código. |
| ro | «ты» — tu / tău | императив ед. ч. | Încearcă din nou | Introdu codul. |
| sk | «вы» — vy / váš | инфинитив | Skúsiť znova | Zadajte kód. |
| sl | «вы» — vi / vaš | императив ед. ч. | Poskusi znova | Vnesite kodo. |
| sv | «ты» — du / din | императив | Försök igen | Ange koden. |

Особенности (полностью — `register.*.note` в JSON):
- **bg, hr, sl** (решение владельца): предложения на «Вие» / «vi», местоимение со строчной в середине фразы;
  кнопка — краткий императив ед. ч. («Затвори», «Spremi», «Shrani»), никогда «-йте» / «-jte».
- **el**: кнопки — отглагольные существительные; повелительное на «-στε» — только где существительного нет
  («Δοκιμάστε ξανά», «Γράψτε κριτική»); никогда неформальное «-ε». Текст под `uppercase` — уже заглавными, без
  ударений.
- **hu**: кнопки — существительные на -ás/-és («Foglalás», «Mentés»), не императив.
- **pl**: «Twój», «Ciebie» — с заглавной, как на вебе; прошедшее время, выдающее род (-łeś/-łaś), не
  использовать.
- **pt** — европейский португальский (telemóvel, ecrã, «Introduza»). **es** — испанский Испании, без «vosotros».
- **fr**: U+00A0 перед ? ! : ; » и после « (не U+202F — его нет в шрифтах).
- **ro**: только ș / ț с запятой.

## Решения по дрейфу веба

Выбор: (а) вариант навигации и заголовков; (б) иначе большинство на вебе; (в) законные пары — две записи.

| Термин | Решение | Почему |
|---|---|---|
| chat (разговор), fr / pt / ro | «discussion» / «conversa» / «conversație»; «chat» — только в названии продукта «chat gratuit» / «chat grátis» / «chat gratuit» (`free-chat`) | (а): вкладка веба — «Discussions» / «Conversas» / «Conversații»; веб и сам различает продукт и разговор |
| reader | слово консультанта (или «таролог»), не «читатель» — запрет во всех 23 языках | «A reader can explore…» на вебе в ga переведено «léitheoir» (читатель книги) |
| session, el | «συνεδρία»; запрет — «συνεδρίαση» (заседание), целым словом | основа «συνεδρίασ» ловила родительный «συνεδρίας» — пойман прогоном по вебу |
| session, de / fr / cs / sk / lt / et / hu | Sitzung, séance, sezení, sedenie, seansas, seanss, konzultáció; запрет — Session, session, relace, relácia, sesija, sessioon, munkamenet | (б) — так веб пишет везде |
| balance, de / nl | Guthaben / tegoed; запрет — Saldo / saldo | (а) |
| book (глагол) vs booking (сущ.) | две записи: кнопка «Резервирай» / шаг «Резервация» | (в) |
| book, lt | «Užsisakyti»; запрет — «Rezervuoti» | (б) |
| done, es / lt | «Listo» / «Atlikta»; запрет — «Hecho» / «Gerai» | (б) |
| edit, da | «Rediger»; запрет — «Redigér» | (б) — вариант с ударением встречается один раз |
| try again, bg / hr / sl / hu | кнопка — «Опитай отново», «Pokušaj ponovno», «Poskusi znova», «Újrapróbálás»; в предложении «Опитайте отново по-късно.» — правильно | правило обращения; поэтому запрета нет, только таблица |
| Keep it | род объекта (сессия / аккаунт) — разные переводы законны | (в) |
| reading | у каждого языка своё слово консультации (fr «consultation», de «Deutung», lt «būrimas»…); запрет — fr «lecture», de «Lesung» | чтение текста ≠ гадание |
| top up, store, voice message, horoscope, ritual, spread, «Now», anonymous, block | переведено в задаче — у веба этих строк нет | — |

Режим `match` у кнопок и ярлыков (Save, Close, Book, Now, Online…) — `exact`: термин сопоставляется, только если
строка целиком им и является («You save $5» — не кнопка «Save»).

## Открытые вопросы к носителям

Записаны в `glossary.json` полем `open`; `translate.mjs lookup` / `scan` предупреждают, где термин встречается.
- **block** — решить до шагов про деньги и бронь. На экране это пакет оплаченных минут («Choose a block», «A started
  block can’t be refunded»). Сейчас el — «πακέτο λεπτών», остальные — буквально «блок», а это местами двусмысленно
  (ro «bloc» — многоквартирный дом, it «blocco» — блокировка, pl «blok» — блокнот или дом, bg «блок» звучит
  странно). Кандидат — везде «пакет минут»: de «Minutenpaket», fr «forfait», it «pacchetto», es «paquete»,
  ro «pachet», pl «pakiet», bg «пакет». Решение — владельца или носителей; правка — одна запись, `version` + 1.
- **reading** — el «ανάγνωση», ro «citire», hr «čitanje», sl «branje» дословны. Рядом с «таро» привычно, отдельное
  «Reading with {name}» может читаться как «чтение текста». Не блокируется.

Прочее, отложенное: `@max 9` на корешке билета — длина самого длинного нынешнего перевода, не расчёт ширины;
поднимать после проверки на устройстве. Когда `AURAT-0156` добавит в шрифты U+202F, французское правило можно
перевести на узкий неразрывный пробел перед ? ! : ;.

## Ревью носителями

`@sensitive <тема>` в `en.ts` → `node scripts/i18n/translate.mjs review` печатает пары «пространство · язык» без
ревью или с устаревшим (правка английского или перевода меняет хэш). После ревью — запись в
`scripts/i18n/native-review.json`: `{ "ns", "lang", "by", "date": "YYYY-MM-DD", "hash" }` (хэш — из отчёта).
Не блокирует сборку; нужно до маркетинга в стране (решение владельца 7). Сейчас чувствительных строк нет — их
пишут задачи шага 3 (деньги, профиль и аккаунт).

## Расхождения веба — для задачи в aura-web-manor

Найдено прогоном глоссария и сравнением дублей (`AURAT-0155-004`); править в вебе отдельной задачей, по
глоссарию:
- ga «léitheoir» → «comhairleoir»: `daily-page:bridge.text`, `write-review:lead`;
- es «Hecho» → «Listo»: `cancel-session:done.close`, `delete-account:done`; lt «Gerai» → «Atlikta»: те же ключи;
- da «Redigér» → «Rediger»: `match-page:edit`;
- bg / hr / sl кнопки в «-йте» / «-jte»: «Опитайте отново», «Резервирайте сесия», «Изтеглете днешната карта»,
  «Izvucite današnju kartu», «Izvlecite današnjo karto» — на кнопках → ед. ч.;
- hu «Próbáld újra» → «Újrapróbálás»;
- fr / pt / ro «Ouvrir le chat», «Abrir chat», «Deschide chatul» и «chat» в значении разговора → discussion /
  conversa / conversație (≈ 20 строк: `home-page:session.open`, `session-detail:openChat`, `write-review:errors.openChat`…);
- lt «Rezervuoti seansą» → «Užsisakyti seansą»; it «Prenota sessione» / «Prenota la sessione», ro «Rezervă sesiune» /
  «sesiunea» — к одному виду;
- «Browse advisors» двумя глаголами в bg, el, et, fr, lt, sk;
- sl «dobroimetje» в `extend-session:topUp` / `me-page:balance.topUp` при «Stanje» в заголовке.
- `auth-by-phone:phone.legal` (`AURAT-0162`): ссылки называют документы не так, как их страницы и глоссарий —
  pl «nasz Regulamin» → «nasze Warunki korzystania», ga «bPolasaí Príobháideachais» → «mBeartas Príobháideachta»;
  el «Όρους Χρήσης» / «Πολιτική Απορρήτου» → «Όρους χρήσης» / «Πολιτική απορρήτου» (как заголовки страниц).
  (pl: «Regulamin» — привычное юридическое имя; если владелец выберет его — поменять заголовок страницы и глоссарий,
  но ссылка и страница должны совпасть.)
- `app:nav.getStarted` (`AURAT-0162`): hu «Kezdjük» → «Kezdés», el «Ξεκινήστε» → «Έναρξη» (кнопка — отглагольное
  существительное); `auth-by-phone:code.change` bg «промяна» → «промени» (кнопка — ед. ч. повелительного).
- `daily-page` (`AURAT-0164`, приложение взяло экран почти целиком): `ask` — кнопка, а у веба повелительное
  наклонение везде: bg «Попитайте съветник» → «Попитай съветник», hr «Pitajte» → «Pitaj savjetnika», sl «Vprašajte» →
  «Vprašaj svetovalca», el «Ρωτήστε έναν σύμβουλο» → «Ερώτηση σε σύμβουλο», hu «Kérdezz egy tanácsadót» →
  «Tanácsadó megkérdezése», инфинитив в cs / sk / lt / lv / fr / pt / es / de / nl («Zeptat se poradce», «Berater
  fragen»…); `title` ga «Do chárta don lá» → «Do chárta an lae» (термин), da / sv «Dit / Ditt dagens kort» → «Dagens
  kort»; el `title` рисуется капсом — «Η ΚΑΡΤΑ ΤΗΣ ΗΜΕΡΑΣ ΣΑΣ».
- `advisor-page:specialties` (`AURAT-0164`): sl «Področja», lt «Specializacija» (ед. ч.), sv «Specialområden» — у
  глоссария «Specialnosti», «Specializacijos», «Specialiteter»; `write-review:title` bg «Напишете отзив» → «Остави
  отзив», el «Γράψτε μια κριτική» → «Γράψτε κριτική» (термин `leave-review`).
- Профиль и удаление аккаунта (`AURAT-0163`): pt — мужской род в обращении к пользователю (правило «не согласовывать
  с родом»): `auth-by-phone:name.sub` «…vão tratá-lo pelo nome» → «…vão dirigir-se a si pelo nome», `delete-account:
  kept.text` «…sem nada que o identifique» → «…sem dados que permitam a sua identificação»; fr `delete-account:title`
  — обычный пробел перед «?» → U+00A0; `delete-account:keep` — кнопка: hu «Megtartom» → «Megtartás», el «Να
  παραμείνει» → «Διατήρηση»; el подписи полей (`user.fields` / `me-page:account`) рисуются капсом — проверить, пишутся
  ли они на вебе заглавными без тонов.
- Глоссарий **v2** (`AURAT-0164-008`): `away` — нейтральные формы (пол советника неизвестен), исключения по ширине —
  в `note` терминов `book`, `rating`, `free-chat`. Вебу — взять копию v2.
