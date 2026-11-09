# AURAT-0203-001 — срочный выпуск Android 1.2.1 (39): падение при возврате в приложение

Дата: 2026-11-09 · Платформа: Android · Трек: production (срочно) · Status: собрано, ждёт загрузки в Play

Владелец: «в гугл консоле стоит crash rate 33%, проанализируй ошибки» (четыре группы из Android vitals) → на вопрос
координатора «Выпускаем срочный 1.2.1 (39)?» — «Да, выпускаем 1.2.1 (Recommended)».

## Причина

Все четыре группы Play vitals — одна ошибка: `IllegalStateException: Screen fragments should never be restored`
(`react-native-screens` 4.25.2).

| Группа | Версии | Пользователи / события |
|---|---|---|
| `ScreenFragment.<init>` | 36 и ещё 9 старых | 127 / 737 |
| `b9.B.<init>` | 35 и ещё 5 | 113 / 486 |
| `MainActivity.onCreate` | 38 (1.2.0) и 37 | 12 / 18 |
| `SourceFile — MainActivity.onCreate` | 38 и 37 | 5 / 8 |

- **Когда:** система пересоздаёт экран из сохранённого состояния. Чаще всего — процесс выгружен в фоне (камера или
  галерея для вложения, другое приложение, мало памяти), реже — смена размера шрифта или масштаба.
- **Почему не помог `AURAT-0193`:** там стоит `RNScreensFragmentFactory` из README библиотеки. Фрагменты он узнаёт по
  имени класса (`startsWith("com.swmansion.rnscreens")`). В релизе R8 переименовывает классы: `ScreenFragment` → `b9.B`,
  фабрика пропускала их дальше, а конструктор бросал. 0193 проверяли на debug-сборке, где имён не трогают (`003`).
- **Воспроизведено:** AVD API 36, стейджинг (R8) из `2e93bbd`. Чат → Home → `am kill` → `am start` →
  `Unable to instantiate fragment b9.B` — тот же стек, что в консоли.

## Исправление

`android/app/proguard-rules.pro`: `-keepnames class com.swmansion.rnscreens.**` с комментарием почему.

- Коммиты: фикс — `develop` `f4a47ea`; версия 39 / 1.2.1 — `8296f62`; push.
- Проверено на стейджинге (R8) с фиксом:
  - Home → `am kill` → `am start` — 3 из 3 без падения, открывается главная (как холодный старт);
  - `font_scale` 1.15 → 1.0 — без падения, процесс тот же.
- В mapping AAB: `com.swmansion.rnscreens.ScreenFragment -> com.swmansion.rnscreens.ScreenFragment`, имена
  `ScreenStackFragment` и `RNScreensFragmentFactory` тоже сохранены.

## Сборка

| | |
|---|---|
| Версия | 1.2.1 (39) |
| Исходник | `develop` приложения `8296f62` |
| Команда | `npm run aab:prod` (manor) |
| Файл | `/private/tmp/claude-501/aura-coord/apk/aura-39-prod.aab` (66,5 МБ), SHA-256 `e37e041cc29c174f…` |

Сервер не меняется: прод-BFF `cf9e715` тот же.

## Play Console — «What's new» (одна строка, до 129 знаков)

Без «Aura» в тексте — чтобы не склонять название. Термин «приложение» — как в заметках 1.2.0.

```
<en-US>
- Fixed a crash when returning to the app after your phone had closed it in the background.
</en-US>
<de-DE>
- Absturz behoben, der auftrat, wenn du zur App zurückgekehrt bist, nachdem dein Handy sie im Hintergrund geschlossen hatte.
</de-DE>
<fr-FR>
- Correction d’un plantage lorsque vous reveniez dans l’application après sa fermeture en arrière-plan par votre téléphone.
</fr-FR>
<es-ES>
- Corregido un cierre inesperado al volver a la app después de que el móvil la cerrara en segundo plano.
</es-ES>
<it-IT>
- Risolto un arresto anomalo al ritorno nell’app dopo che il telefono l’aveva chiusa in background.
</it-IT>
<pt-PT>
- Corrigida uma falha ao regressar à aplicação depois de o telemóvel a ter fechado em segundo plano.
</pt-PT>
<nl-NL>
- Crash opgelost bij terugkeren naar de app nadat je telefoon de app op de achtergrond had gesloten.
</nl-NL>
<pl-PL>
- Naprawiono awarię przy powrocie do aplikacji po tym, jak telefon zamknął ją w tle.
</pl-PL>
<sv-SE>
- Åtgärdat en krasch när du återvände till appen efter att telefonen stängt den i bakgrunden.
</sv-SE>
<da-DK>
- Rettet et nedbrud, når du vendte tilbage til appen, efter at telefonen havde lukket den i baggrunden.
</da-DK>
<fi-FI>
- Korjattu kaatuminen, kun palasit sovellukseen sen jälkeen, kun puhelin oli sulkenut sen taustalla.
</fi-FI>
<et>
- Parandatud krahh, mis tekkis rakendusse naasmisel pärast seda, kui telefon oli selle taustal sulgenud.
</et>
<lv>
- Novērsta avārija, atgriežoties lietotnē pēc tam, kad tālrunis to bija aizvēris fonā.
</lv>
<lt>
- Ištaisyta strigtis grįžtant į programėlę po to, kai telefonas ją uždarė fone.
</lt>
<cs-CZ>
- Opraven pád při návratu do aplikace poté, co ji telefon zavřel na pozadí.
</cs-CZ>
<sk>
- Opravený pád pri návrate do aplikácie po tom, čo ju telefón zatvoril na pozadí.
</sk>
<sl>
- Odpravljeno sesutje ob vrnitvi v aplikacijo, potem ko jo je telefon zaprl v ozadju.
</sl>
<hr>
- Ispravljeno rušenje pri povratku u aplikaciju nakon što ju je telefon zatvorio u pozadini.
</hr>
<bg>
- Отстранен е срив при връщане в приложението, след като телефонът го е затворил във фонов режим.
</bg>
<el-GR>
- Διορθώθηκε σφάλμα που έκλεινε την εφαρμογή όταν επιστρέφατε σε αυτήν, αφού το κινητό την είχε κλείσει στο παρασκήνιο.
</el-GR>
<hu-HU>
- Javítottuk az összeomlást, amely akkor jelentkezett, amikor visszatértél az alkalmazásba, miután a telefon a háttérben bezárta.
</hu-HU>
<ro>
- Am remediat o închidere neașteptată la revenirea în aplicație după ce telefonul o închisese în fundal.
</ro>
```

## Перед production

Internal testing → A50: открыть чат → Home → в настройках Android «Остановить» приложение нельзя (это не выгрузка),
поэтому проверка — по Play vitals: через 1–2 дня группы `MainActivity.onCreate` / `ScreenFragment.<init>` на 39 не
появляются.

Урок — память «Verify Android fixes on release (R8) builds»: исправления, которые зависят от имён классов, проверять
на минифицированной сборке.
