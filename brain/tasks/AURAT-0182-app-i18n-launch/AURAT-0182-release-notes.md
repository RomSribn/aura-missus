# AURAT-0182 — заметки релиза 37 / 1.1.0 («Что нового» в Play)

Дата: 2026-11-07. Языки — en-US + 21 язык страницы Play, коды — по таблице `AURAT-0183-006-spec-v2.md`; ga и mt Play
не поддерживает (им Play покажет en-US). Лимит Play — 500 знаков на язык; все в лимите (таблица ниже).

Как вставлять (владелец): Play Console → релиз 37 → Release notes → блок ниже целиком (Play разбирает теги языков).
**Сначала — переводы страницы `AURAT-0183`** (или одним пакетом с релизом): заметки на языке без перевода страницы Play
может не принять. Если отклонит какой-то язык — убрать его блок и переслать сообщение координатору.

Как написано:
- обращение — по таблице глоссария: «ты» в da de es et fi hu it nl pl ro sv, «вы» в bg cs el fr hr lt lv pt sk sl;
  pl — «Twój» с заглавной;
- термины глоссария (v4): advisor (Berater, conseiller, consulente…), chat (fr «discussion», pt «conversa», ro
  «conversație», el «συνομιλία», et «vestlus», hu «csevegés», lt «pokalbis», lv «saruna», sk «čet», sl «klepet»);
- «Profile → Language» — названия из приложения (`app:tabs.profile`, `app-language:row`) на этом языке; путь в
  системных настройках — обычные названия Android (у Samsung и других оболочек пункты могут называться иначе);
- fr — U+00A0 перед «:»; ro — ș ț; pt — европейский («telemóvel», «Definições»); el — «Το Aura», как в приложении;
- честная фраза про чат — во всех языках (владелец, Р4); NFC, без soft hyphen.

Вычитка носителем: не нужна по решению 7 (это не оплата / возвраты / юридический текст), но приветствуется.

## Длина (знаков, лимит 500)

```
en-US   381 ok
bg      410 ok
cs-CZ   385 ok
da-DK   401 ok
de-DE   437 ok
el-GR   473 ok
es-ES   418 ok
et      400 ok
fi-FI   434 ok
fr-FR   495 ok
hr      416 ok
hu-HU   461 ok
it-IT   427 ok
lt      421 ok
lv      390 ok
nl-NL   401 ok
pl-PL   436 ok
pt-PT   460 ok
ro      429 ok
sk      397 ok
sl      423 ok
sv-SE   407 ok
```

## Блок для Play Console

```
<en-US>
Aura now speaks your language: English and the 23 other official EU languages. The app follows your phone's language, and you can change it any time in Profile → Language (on Android 13 and later, also in Settings → Apps → Aura). Chats with advisors stay in the language your advisor writes in for now. Also: smoother chat history, unread badges, and keyboard fixes for Android 15.
</en-US>
<bg>
Aura вече говори на вашия език: английски и още 23 официални езика на ЕС. Приложението следва езика на телефона ви, а можете да го смените по всяко време в Профил → Език (от Android 13 – и в Настройки → Приложения → Aura). Засега чатовете със съветниците остават на езика, на който пише вашият съветник. Още: по-плавна история на чата, отметки за непрочетени съобщения и поправки на клавиатурата за Android 15.
</bg>
<cs-CZ>
Aura teď mluví vaším jazykem: angličtinou a dalšími 23 úředními jazyky EU. Aplikace se řídí jazykem vašeho telefonu a kdykoli ho můžete změnit v části Profil → Jazyk (od Androidu 13 také v Nastavení → Aplikace → Aura). Chaty s poradci zatím zůstávají v jazyce, ve kterém píše váš poradce. Dále: plynulejší historie chatu, označení nepřečtených zpráv a opravy klávesnice pro Android 15.
</cs-CZ>
<da-DK>
Aura taler nu dit sprog: engelsk og de 23 andre officielle EU-sprog. Appen følger telefonens sprog, og du kan til enhver tid skifte det under Profil → Sprog (fra Android 13 også under Indstillinger → Apps → Aura). Chats med rådgivere forbliver indtil videre på det sprog, din rådgiver skriver på. Desuden: mere flydende chathistorik, markeringer af ulæste beskeder og tastaturrettelser til Android 15.
</da-DK>
<de-DE>
Aura spricht jetzt deine Sprache: Englisch und die 23 weiteren Amtssprachen der EU. Die App folgt der Sprache deines Telefons, und du kannst sie jederzeit unter Profil → Sprache ändern (ab Android 13 auch unter Einstellungen → Apps → Aura). Chats mit Beratern bleiben vorerst in der Sprache, in der dein Berater schreibt. Außerdem: flüssigerer Chatverlauf, Markierungen für ungelesene Nachrichten und Tastatur-Korrekturen für Android 15.
</de-DE>
<el-GR>
Το Aura μιλά πλέον τη γλώσσα σας: αγγλικά και τις άλλες 23 επίσημες γλώσσες της ΕΕ. Η εφαρμογή ακολουθεί τη γλώσσα του τηλεφώνου σας και μπορείτε να την αλλάξετε οποιαδήποτε στιγμή από Προφίλ → Γλώσσα (από Android 13 και από Ρυθμίσεις → Εφαρμογές → Aura). Προς το παρόν, οι συνομιλίες με τους συμβούλους παραμένουν στη γλώσσα που γράφει ο σύμβουλός σας. Επίσης: πιο ομαλό ιστορικό συνομιλιών, ενδείξεις μη αναγνωσμένων μηνυμάτων και διορθώσεις πληκτρολογίου για Android 15.
</el-GR>
<es-ES>
Aura ya habla tu idioma: el inglés y las otras 23 lenguas oficiales de la UE. La app sigue el idioma de tu teléfono y puedes cambiarlo cuando quieras en Perfil → Idioma (desde Android 13, también en Ajustes → Aplicaciones → Aura). Por ahora, los chats con los asesores siguen en el idioma en que escribe tu asesor. Además: historial de chat más fluido, avisos de mensajes sin leer y arreglos del teclado en Android 15.
</es-ES>
<et>
Aura räägib nüüd sinu keelt: inglise ja veel 23 ELi ametlikku keelt. Rakendus järgib sinu telefoni keelt ja saad seda igal ajal muuta jaotises Profiil → Keel (alates Android 13-st ka jaotises Seaded → Rakendused → Aura). Vestlused nõustajatega jäävad praegu keelde, milles sinu nõustaja kirjutab. Lisaks: sujuvam vestluste ajalugu, lugemata sõnumite tähised ja klaviatuuriparandused Android 15 jaoks.
</et>
<fi-FI>
Aura puhuu nyt sinun kieltäsi: englantia ja EU:n 23 muuta virallista kieltä. Sovellus seuraa puhelimesi kieltä, ja voit vaihtaa sen milloin tahansa kohdassa Profiili → Kieli (Android 13:sta alkaen myös kohdassa Asetukset → Sovellukset → Aura). Chatit neuvojien kanssa pysyvät toistaiseksi kielellä, jolla neuvojasi kirjoittaa. Lisäksi: sujuvampi chat-historia, merkit lukemattomista viesteistä ja näppäimistökorjauksia Android 15:lle.
</fi-FI>
<fr-FR>
Aura parle désormais votre langue : l’anglais et les 23 autres langues officielles de l’UE. L’application suit la langue de votre téléphone, et vous pouvez la changer à tout moment dans Profil → Langue (dès Android 13, aussi dans Paramètres → Applications → Aura). Pour l’instant, les discussions avec les conseillers restent dans la langue de votre conseiller. Également : un historique des discussions plus fluide, des pastilles de messages non lus et des correctifs du clavier sur Android 15.
</fr-FR>
<hr>
Aura sada govori vašim jezikom: dostupna je na engleskom i na još 23 službena jezika EU-a. Aplikacija prati jezik vašeg telefona, a možete ga promijeniti u bilo kojem trenutku u Profil → Jezik (od Androida 13 i u Postavke → Aplikacije → Aura). Chatovi sa savjetnicima zasad ostaju na jeziku na kojem piše vaš savjetnik. Osim toga: glađa povijest chata, oznake nepročitanih poruka i popravci tipkovnice za Android 15.
</hr>
<hu-HU>
Az Aura mostantól a te nyelveden szól: angolul és az EU további 23 hivatalos nyelvén. Az alkalmazás a telefonod nyelvét követi, és bármikor módosíthatod a Profil → Nyelv menüben (Android 13-tól a Beállítások → Alkalmazások → Aura menüben is). A tanácsadókkal folytatott csevegések egyelőre azon a nyelven maradnak, amelyen a tanácsadód ír. Továbbá: gördülékenyebb csevegési előzmények, jelzések az olvasatlan üzenetekről és billentyűzetjavítások Android 15-höz.
</hu-HU>
<it-IT>
Aura ora parla la tua lingua: l’inglese e le altre 23 lingue ufficiali dell’UE. L’app segue la lingua del tuo telefono e puoi cambiarla quando vuoi in Profilo → Lingua (da Android 13, anche in Impostazioni → App → Aura). Per ora le chat con i consulenti restano nella lingua in cui scrive il tuo consulente. Inoltre: cronologia delle chat più fluida, indicatori dei messaggi non letti e correzioni della tastiera su Android 15.
</it-IT>
<lt>
Aura dabar kalba jūsų kalba: angliškai ir dar 23 oficialiomis ES kalbomis. Programėlė naudoja jūsų telefono kalbą, o pakeisti ją galite bet kada skiltyje Profilis → Kalba (Android 13 ir naujesnėse versijose – ir Nustatymai → Programos → Aura). Kol kas pokalbiai su patarėjais lieka ta kalba, kuria rašo jūsų patarėjas. Be to: sklandesnė pokalbių istorija, neperskaitytų žinučių žymos ir klaviatūros pataisymai Android 15.
</lt>
<lv>
Aura tagad runā jūsu valodā: angļu un vēl 23 oficiālajās ES valodās. Lietotne izmanto jūsu tālruņa valodu, un to jebkurā laikā varat mainīt sadaļā Profils → Valoda (no Android 13 arī sadaļā Iestatījumi → Lietotnes → Aura). Pagaidām sarunas ar konsultantiem paliek valodā, kurā raksta jūsu konsultants. Vēl: plūstošāka sarunu vēsture, nelasīto ziņu atzīmes un tastatūras labojumi Android 15.
</lv>
<nl-NL>
Aura spreekt nu jouw taal: Engels en de 23 andere officiële talen van de EU. De app volgt de taal van je telefoon en je kunt die altijd wijzigen via Profiel → Taal (vanaf Android 13 ook via Instellingen → Apps → Aura). Chats met adviseurs blijven voorlopig in de taal waarin je adviseur schrijft. Verder: soepelere chatgeschiedenis, badges voor ongelezen berichten en toetsenbordfixes voor Android 15.
</nl-NL>
<pl-PL>
Aura mówi teraz w Twoim języku: po angielsku i w 23 pozostałych językach urzędowych UE. Aplikacja używa języka Twojego telefonu, a zmienisz go w każdej chwili w sekcji Profil → Język (od Androida 13 także w menu Ustawienia → Aplikacje → Aura). Na razie czaty z doradcami pozostają w języku, w którym pisze Twój doradca. Poza tym: płynniejsza historia czatu, oznaczenia nieprzeczytanych wiadomości i poprawki klawiatury na Androidzie 15.
</pl-PL>
<pt-PT>
A Aura fala agora o seu idioma: inglês e as outras 23 línguas oficiais da UE. A aplicação segue o idioma do seu telemóvel e pode alterá-lo a qualquer momento em Perfil → Idioma (a partir do Android 13, também em Definições → Aplicações → Aura). Por agora, as conversas com os consultores continuam no idioma em que o seu consultor escreve. Além disso: histórico de conversas mais fluido, indicadores de mensagens não lidas e correções do teclado no Android 15.
</pt-PT>
<ro>
Aura vorbește acum limba ta: engleza și celelalte 23 de limbi oficiale ale UE. Aplicația urmează limba telefonului tău și o poți schimba oricând din Profil → Limbă (de la Android 13, și din Setări → Aplicații → Aura). Deocamdată, conversațiile cu consilierii rămân în limba în care scrie consilierul tău. În plus: istoric al conversațiilor mai fluid, indicatori pentru mesajele necitite și remedieri ale tastaturii pe Android 15.
</ro>
<sk>
Aura teraz hovorí vaším jazykom: angličtinou a ďalšími 23 úradnými jazykmi EÚ. Aplikácia sa riadi jazykom vášho telefónu a kedykoľvek ho môžete zmeniť v časti Profil → Jazyk (od Androidu 13 aj v Nastavenia → Aplikácie → Aura). Čety s poradcami zatiaľ zostávajú v jazyku, v ktorom píše váš poradca. Ďalej: plynulejšia história četu, označenie neprečítaných správ a opravy klávesnice pre Android 15.
</sk>
<sl>
Aura zdaj govori vaš jezik: na voljo je v angleščini in v 23 drugih uradnih jezikih EU. Aplikacija sledi jeziku vašega telefona, spremenite pa ga lahko kadar koli v Profil → Jezik (od Androida 13 tudi v Nastavitve → Aplikacije → Aura). Klepeti s svetovalci za zdaj ostajajo v jeziku, v katerem piše vaš svetovalec. Poleg tega: bolj tekoča zgodovina klepeta, oznake neprebranih sporočil in popravki tipkovnice za Android 15.
</sl>
<sv-SE>
Aura talar nu ditt språk: engelska och de 23 andra officiella EU-språken. Appen följer telefonens språk och du kan byta när som helst under Profil → Språk (från Android 13 även under Inställningar → Appar → Aura). Chattar med rådgivare stannar tills vidare på det språk som din rådgivare skriver på. Dessutom: smidigare chatthistorik, markeringar för olästa meddelanden och tangentbordsfixar för Android 15.
</sv-SE>
```
