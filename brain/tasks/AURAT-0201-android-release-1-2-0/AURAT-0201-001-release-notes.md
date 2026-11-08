# AURAT-0201-001 — release notes: Android 1.2.0 (38)

Дата: 2026-11-08 · Платформа: Android · Трек: internal testing → production · Status: собрано, ждёт прод-BFF и политику

Владелец: «готовь PR develop → main для прод-BFF и так же aab сборку для play console» → версия — «38 / 1.2.0
(Recommended)». Правило о заметках — «нужны релиз notes с каждой такой сборкой, сохрани это в скиллах, пусть где-то в
misuse пишется» (`AURAS-0005`, скилл `aura-release`).

## Сборка

| | |
|---|---|
| Версия | `versionName` 1.2.0, `versionCode` 38 (было 1.1.0 / 37) |
| Исходник | `develop` приложения `f361616` (бамп версии; до него `2e93bbd`) |
| Команда | `npm run aab:prod` в маноре после `npm ci`: prod, оплата, языки, атрибуция Meta |
| Файл | `/private/tmp/claude-501/aura-coord/apk/aura-38-prod.aab` (66,5 МБ), SHA-256 `f7d6f864ffb10686…`; в маноре — `android/app/build/outputs/bundle/release/app-release.aab` (перезапишется следующей сборкой) |

## Что внутри (с 1.1.0 / 37)

- `AURAT-0197` — перевод чата в приложении:
  - ответ советника на языке интерфейса, «Show original», «Translating…», «Not translated»;
  - превью Home и Chats, `message.translated` и догонка;
  - карточка согласия перед первым сообщением, переключатель «Translate my chat» в профиле.
- `AURAT-0199` — догонка переводов только от `pending`.
- `AURAT-0200`:
  - кнопки внизу над системной навигацией на Android 15+ (бронирование, Review, детали сессии, перенос, онбординг), тост над таб-баром;
  - шторки с полем над клавиатурой, и на Android ≤ 14;
  - отступ карточки согласия;
  - текст согласия без «AI», «Machine-translated» на 24 языках.

## Зависимости и порядок

1. **Прод-BFF:** PR https://github.com/RomSribn/aura-bff/pull/10 (`develop` `fa65908` → `main`), деплой в Coolify. Без него карточки согласия и перевода нет. Приложение при этом работает как раньше: без `ProfileResponse.chat` ничего не показывается.
2. **Политика** §04–§06: машинный перевод чата внешним сервисом, Anthropic, передача в США по SCC. Нужна **до того, как пользователи получат 38**: с прод-BFF карточка согласия появится сразу (поправка к решению 6 `AURAI-0012`).
3. **Первый пункт «What's new»** (перевод чата) верен, только когда на проде включён перевод: `TRANSLATION_CHAT_*`, оба направления (PR #10, раздел «Включение»). В production выпускать после включения — или убрать этот пункт.

## Play Console — «What's new» (≤ 500 знаков; en-US 436, самый длинный el-GR 499)

Переведено и вычитано воркфлоу (3 переводчика + проверка). Подписи кнопок взяты из приложения, глоссарий, регистр и
типографика — по правилам «Translations». ga / mt — на en-US.

```
<en-US>
• Chat in your language: advisors' replies can be machine-translated into the language of the app. Tap "Show original" to read their own words, and turn translation off in your profile at any time.
• Before your first chat message, we now ask for your consent to use what you share there.
• Buttons at the bottom of the screen and pop-up panels no longer slide under the navigation bar or the keyboard.
• Smaller fixes and improvements.
</en-US>
<de-DE>
• Chatte in deiner Sprache: Antworten der Berater können maschinell in die App-Sprache übersetzt werden. Tippe auf „Original anzeigen“, um ihre eigenen Worte zu lesen. Die Übersetzung kannst du jederzeit im Profil ausschalten.
• Vor deiner ersten Chat-Nachricht bitten wir dich jetzt um deine Einwilligung, das zu nutzen, was du dort teilst.
• Buttons unten am Bildschirm und Pop-up-Fenster rutschen nicht mehr unter die Navigationsleiste oder Tastatur.
• Kleinere Korrekturen und Verbesserungen.
</de-DE>
<fr-FR>
• Discutez dans votre langue : les réponses des conseillers peuvent être traduites automatiquement. Touchez « Voir l’original » pour lire leurs propres mots, et désactivez la traduction à tout moment dans votre profil.
• Avant votre premier message, nous demandons désormais votre consentement pour utiliser ce que vous partagez dans la discussion.
• Les boutons en bas de l’écran et les panneaux ne passent plus sous la barre de navigation ou le clavier.
• Corrections et améliorations mineures.
</fr-FR>
<es-ES>
• Chatea en tu idioma: las respuestas de los asesores pueden llegarte con traducción automática al idioma de la app. Toca «Ver original» para leer sus propias palabras y desactiva la traducción cuando quieras en tu perfil.
• Antes de tu primer mensaje en el chat, ahora te pedimos tu consentimiento para usar lo que compartas en él.
• Los botones de la parte inferior y los paneles emergentes ya no quedan ocultos bajo la barra de navegación ni el teclado.
• Pequeñas correcciones y mejoras.
</es-ES>
<it-IT>
• Chatta nella tua lingua: le risposte dei consulenti possono arrivarti con traduzione automatica nella lingua dell’app. Tocca «Mostra originale» per leggere le loro parole e disattiva la traduzione quando vuoi nel tuo profilo.
• Prima di inviare il tuo primo messaggio in chat, ora ti chiediamo il consenso per usare ciò che condividi lì.
• I pulsanti in basso e i pannelli a comparsa non finiscono più sotto la barra di navigazione o la tastiera.
• Piccole correzioni e miglioramenti.
</it-IT>
<pt-PT>
• Converse no seu idioma: as respostas dos consultores podem surgir com tradução automática para o idioma da aplicação. Toque em «Ver original» para ler o que escreveram e desative a tradução no seu perfil a qualquer momento.
• Antes da sua primeira mensagem na conversa, pedimos agora o seu consentimento para utilizar o que lá partilhar.
• Os botões na parte inferior do ecrã e os painéis pop-up já não ficam por baixo da barra de navegação nem do teclado.
• Pequenas correções e melhorias.
</pt-PT>
<nl-NL>
• Chat in je eigen taal: antwoorden van adviseurs kunnen met machinevertaling in de taal van de app verschijnen. Tik op “Origineel tonen” om hun eigen woorden te lezen, en zet de vertaling op elk moment uit in je profiel.
• Voor je eerste chatbericht vragen we nu je toestemming om te gebruiken wat je daar deelt.
• Knoppen onderaan het scherm en pop-upvensters schuiven niet meer onder de navigatiebalk of het toetsenbord.
• Kleine correcties en verbeteringen.
</nl-NL>
<pl-PL>
• Czatuj w swoim języku: odpowiedzi doradców mogą być tłumaczone maszynowo na język aplikacji. Dotknij „Pokaż oryginał”, aby przeczytać ich własne słowa, a tłumaczenie wyłączysz w każdej chwili w swoim profilu.
• Przed pierwszą wiadomością na czacie prosimy teraz o Twoją zgodę na wykorzystanie tego, czym się tam dzielisz.
• Przyciski u dołu ekranu i wyskakujące panele nie chowają się już pod paskiem nawigacji ani pod klawiaturą.
• Drobne poprawki i ulepszenia.
</pl-PL>
<sv-SE>
• Chatta på ditt språk: rådgivarnas svar kan maskinöversättas till appens språk. Tryck på ”Visa original” för att läsa deras egna ord, och stäng av översättningen i din profil när du vill.
• Innan ditt första meddelande i chatten ber vi nu om ditt samtycke till att använda det du delar där.
• Knappar längst ned på skärmen och popup-paneler hamnar inte längre under navigeringsfältet eller tangentbordet.
• Mindre korrigeringar och förbättringar.
</sv-SE>
<da-DK>
• Chat på dit sprog: rådgivernes svar kan maskinoversættes til appens sprog. Tryk på »Vis original« for at læse deres egne ord, og slå oversættelse fra i din profil, når du vil.
• Før din første besked i chatten beder vi nu om dit samtykke til at bruge det, du deler dér.
• Knapper nederst på skærmen og pop op-paneler glider ikke længere ind under navigationslinjen eller tastaturet.
• Mindre rettelser og forbedringer.
</da-DK>
<fi-FI>
• Chattaa omalla kielelläsi: neuvojien vastaukset voidaan konekääntää sovelluksen kielelle. Napauta ”Näytä alkuperäinen”, niin näet heidän omat sanansa. Käännöksen voit poistaa käytöstä profiilissasi milloin tahansa.
• Ennen ensimmäistä chat-viestiäsi pyydämme nyt suostumustasi siihen, että käytämme siellä kertomiasi tietoja.
• Näytön alareunan painikkeet ja ponnahduspaneelit eivät enää jää navigointipalkin tai näppäimistön alle.
• Pienempiä korjauksia ja parannuksia.
</fi-FI>
<et>
• Vestle oma keeles: nõustajate vastuseid saab näha masintõlkena rakenduse keeles. Puuduta „Näita algteksti“, et lugeda nende enda sõnu, ja lülita tõlge oma profiilis igal ajal välja.
• Enne esimest vestlussõnumit küsime nüüd sinu nõusolekut, et kasutada seda, mida seal jagad.
• Ekraani allservas olevad nupud ja hüpikpaneelid ei jää enam navigeerimisriba ega klaviatuuri alla.
• Väiksemad parandused ja täiustused.
</et>
<lv>
• Saruna jūsu valodā: konsultantu atbildes var mašīntulkot lietotnes valodā. Pieskarieties pogai „Rādīt oriģinālu”, lai lasītu viņu pašu vārdus, bet tulkošanu jebkurā laikā varat izslēgt savā profilā.
• Pirms pirmās ziņas sarunā mēs tagad lūdzam jūsu piekrišanu izmantot to, ar ko tajā dalāties.
• Pogas ekrāna apakšā un uznirstošie paneļi vairs nepaslīd zem navigācijas joslas vai tastatūras.
• Sīkāki labojumi un uzlabojumi.
</lv>
<lt>
• Pokalbis jūsų kalba: patarėjų atsakymai gali būti išversti mašininiu būdu į programėlės kalbą. Palieskite „Rodyti originalą“, kad perskaitytumėte jų pačių žodžius, o vertimą bet kada galite išjungti savo profilyje.
• Prieš pirmąją žinutę pokalbyje dabar prašome jūsų sutikimo naudoti tai, kuo jame dalijatės.
• Mygtukai ekrano apačioje ir iškylantieji skydeliai nebepasislepia po naršymo juosta ar klaviatūra.
• Smulkesni pataisymai ir patobulinimai.
</lt>
<cs-CZ>
• Chat ve vašem jazyce: odpovědi poradců lze strojově překládat do jazyka aplikace. Klepnutím na „Zobrazit originál“ si přečtete jejich vlastní slova a překlad můžete kdykoli vypnout ve svém profilu.
• Před první zprávou v chatu vás nyní požádáme o souhlas s použitím toho, co v něm sdílíte.
• Tlačítka ve spodní části obrazovky a vyskakovací panely už nezajíždějí pod navigační lištu ani pod klávesnici.
• Drobné opravy a vylepšení.
</cs-CZ>
<sk>
• Čet vo vašom jazyku: odpovede poradcov môžu byť strojovo preložené do jazyka aplikácie. Ťuknite na „Zobraziť originál“ a prečítajte si ich vlastné slová. Preklad môžete kedykoľvek vypnúť vo svojom profile.
• Pred vašou prvou správou v čete vás teraz požiadame o súhlas s používaním toho, čo v ňom zdieľate.
• Tlačidlá v dolnej časti obrazovky a vyskakovacie panely sa už neskrývajú pod navigačným panelom ani pod klávesnicou.
• Drobné opravy a vylepšenia.
</sk>
<sl>
• Klepet v vašem jeziku: odgovori svetovalcev so lahko strojno prevedeni v jezik aplikacije. Tapnite »Pokaži izvirnik«, da preberete njihove lastne besede, prevajanje pa lahko kadar koli izklopite v svojem profilu.
• Pred vašim prvim sporočilom v klepetu vas zdaj prosimo za privolitev, da smemo uporabljati to, kar delite v njem.
• Gumbi na dnu zaslona in pojavna okna ne zdrsnejo več pod navigacijsko vrstico ali tipkovnico.
• Manjši popravki in izboljšave.
</sl>
<hr>
• Chat na vašem jeziku: odgovori savjetnika mogu biti strojno prevedeni na jezik aplikacije. Dodirnite „Prikaži izvornik” da biste pročitali njihove vlastite riječi, a prijevod u bilo kojem trenutku možete isključiti u svom profilu.
• Prije vaše prve poruke u chatu sada tražimo vašu privolu za korištenje onoga što u njemu podijelite.
• Gumbi na dnu zaslona i skočni prozori više ne klize ispod navigacijske trake ni tipkovnice.
• Manji popravci i poboljšanja.
</hr>
<bg>
• Чат на вашия език: отговорите на съветниците може да се превеждат машинно на езика на приложението. Докоснете „Покажи оригинала“, за да прочетете собствените им думи, а превода можете да изключите по всяко време в профила си.
• Преди първото ви съобщение в чата вече ви молим за съгласие да използваме това, което споделяте там.
• Бутоните в долната част на екрана и изскачащите панели вече не се скриват под навигационната лента или клавиатурата.
• Дребни корекции и подобрения.
</bg>
<el-GR>
• Συνομιλία στη γλώσσα σας: οι απαντήσεις των συμβούλων μπορούν να μεταφράζονται αυτόματα στη γλώσσα της εφαρμογής. Πατήστε «Προβολή πρωτοτύπου» για να δείτε τα δικά τους λόγια και απενεργοποιήστε τη μετάφραση στο προφίλ σας όποτε θέλετε.
• Πριν από το πρώτο σας μήνυμα, ζητάμε πλέον τη συγκατάθεσή σας για τη χρήση όσων μοιράζεστε στη συνομιλία.
• Τα κουμπιά στο κάτω μέρος και τα αναδυόμενα πλαίσια δεν καλύπτονται πια από τη γραμμή πλοήγησης ή το πληκτρολόγιο.
• Μικρές διορθώσεις και βελτιώσεις.
</el-GR>
<hu-HU>
• Csevegés a nyelveden: a tanácsadók válaszai gépi fordítással az alkalmazás nyelvén is megjelenhetnek. Koppints az „Eredeti mutatása” gombra, hogy a saját szavaikat olvashasd, a fordítást pedig bármikor kikapcsolhatod a profilodban.
• Az első csevegőüzeneted előtt mostantól a hozzájárulásodat kérjük ahhoz, hogy felhasználhassuk, amit ott megosztasz.
• A képernyő alsó gombjai és a felugró panelek már nem csúsznak a navigációs sáv vagy a billentyűzet alá.
• Kisebb javítások és fejlesztések.
</hu-HU>
<ro>
• Conversații în limba ta: răspunsurile consilierilor pot fi traduse automat în limba aplicației. Atinge „Arată originalul” ca să citești propriile lor cuvinte, iar traducerea o poți dezactiva oricând din profilul tău.
• Înainte de primul tău mesaj în conversație, îți cerem acum consimțământul pentru a folosi ce împărtășești acolo.
• Butoanele din partea de jos a ecranului și panourile pop-up nu mai alunecă sub bara de navigare sau sub tastatură.
• Mici remedieri și îmbunătățiri.
</ro>
```

## Перед production — проверить из internal testing

- **A50, Android 11:** сначала удалить стейджинг — у него другая подпись. Затем:
  - шторки стран, даты рождения и промокода над клавиатурой;
  - кнопки внизу.
- **Android 15+** (AVD API 36 или Pixel): кнопки «Review booking» и «Pay … & book» над навигацией.
- **С прод-BFF:** карточка согласия с новым текстом; после галочки в профиле — «Translate my chat».
- **После включения перевода:** «Machine-translated · Show original» под ответом.

## Известное

- Профиль показывает «version 1.0.0» — `APP_VERSION` зашит, бэклог (`active-work.md`).
- На A50 клавиатура закрывает кнопку на экране телефона и на вводе дня рождения — бэклог (`AURAT-0200-010`).
- Текст согласия на 23 языках ждёт вычитки носителем (юридический текст): до маркетинга в стране (`AURAI-0010`,
  решение 7).
