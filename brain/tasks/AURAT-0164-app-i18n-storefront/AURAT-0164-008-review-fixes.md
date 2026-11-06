# AURAT-0164-008 — review fixes

Дата: 2026-11-06. Ревью координатора (slave-1-9e: 3 ревьюера + скептики; разбор — scratchpad координатора
`wf0164-review.md`). Владелец: «передавай отмашку в 0164, по кнопкам решение б, можно не делать 0167 а сделать прямо
в этой задачи» — две общие правки (п. 2, 3) здесь, номер 0167 не выдаётся.

## Сделано
1. **Кнопки профиля советника — панель переносится (решение «б»).** `shared/ui/button`: подпись — `flexShrink: 1`,
   `textAlign: 'center'` (длинная переносится по пробелу вместо выхода за край; однострочные — без изменений);
   новый проп `stretch` — кнопка заполняет высоту родителя (Animated.View, Pressable, контейнер; у градиентной —
   `flexGrow` у заливки). В `AdvisorProfileScreen` обе кнопки `stretch`: панель растёт до высокой подписи, обе одной
   высоты. Переводы lt / lv / hu / ga / hr — полные. bg Book «Резервирай» (одно слово шире места на 360) →
   «Запази час». JSDoc `en.ts`: ≈ 84 / 107 pt текста с обводкой 1,5 pt, `freeChat` `@max 20`.
2. **`minimumFontScale` под Fabric не работает** (сверено: `RCTTextLayoutManager.mm:246`, `TextLayoutManager.kt:1002` —
   только `minimumFontSize`, по умолчанию 4 pt; из JS не задаётся). Проп убран в `CampaignTicket`, `TicketShell`,
   `SegmentedControl`, `DateStrip`, `StatsCard` — с комментарием, что порога нет и держит его `@max`; JSDoc
   `CampaignTicket` и `campaign:discountSub` исправлены; тест `offer.test.tsx` больше не ждёт проп. `StatsCard` —
   `maxFontSizeMultiplier={1.3}`.
3. **Греческий капс в shared:** `day.inDays` el → «ΣΕ {{count}} ΗΜΕΡΑ» / «ΗΜΕΡΕΣ», JSDoc — «write it in capitals
   already». Остальные строки shared, что рисуются капсом (`offer.welcome`, `ticket.*`), уже заглавными.
4. **Переводы:** mt `stats.perMinute` «Kull min» («кто угодно») → «Kull minuta»; el away → «Εκτός σύνδεσης · απαντά σε
   ~1 ώρα». Строка автора: «·» — отдельный Text внутри имени («Anonymous ·»), `reviews.verified` — «Verified client»
   во всех 24: при переносе бейдж начинает строку без точки.
5. **Глоссарий v2** (`scripts/i18n/glossary.json`): `away` — нейтральные формы (cs / sk «Mimo», el «Εκτός σύνδεσης»,
   fr «Indisponible», hr «Nije tu», pl «Poza siecią», ro «Nu e online», sl «Ni na spletu»; mt «Assenti» не родовое —
   оставлено) с пометкой «пол советника неизвестен»; исключения по ширине — в `note` терминов `book` (ga, bg),
   `rating` (mt), `free-chat` (de, el, ga, hu, sl).
6. **Код:** `PhaseCopy` без `export`; счётчик отзывов — `formatDecimal` (в `StatsCard` и в `Stars`: «(1.240)»).
   «Роль · цена/мин» в `AdvisorRow` — **осознанная склейка данных** (роль — серверная, цена — форматтер, «/min» —
   `shared:price.perMinute`): своих слов в ней нет, ключ из одних подстановок совпал бы с английским во всех 23.
7. **Тесты на немецком** (переключение после монтирования, хелперы `switchLanguage` / `backToEnglish`): Advisors
   (заголовок, чипы, placeholder, «1,99 $/Min.», фильтр «Hellsehen», пустой список), скидка в строке — a11y
   «1,59 $/Min., vorher 1,99 $», Home (приветствие, секции, баннер, гороскоп без даты, лист), BirthDateSheet (подписи
   по порядку, ошибки, «Speichern»), профиль советника (статистика, присутствие, кнопки, a11y), ReviewsHeader,
   ReviewCard (точка у имени), Daily card (нарратив, мост, черновик, ошибка). Панель кнопок en / lt: обе `stretch`,
   подписи без `numberOfLines`, с переносом по центру. Крупный системный шрифт Jest не проверяет (нет раскладки) —
   на устройстве.

## Проверки
`tsc` — 0, `eslint .` — 0, Jest — 187 наборов / 2165 тестов, `translate.mjs check` — 0 запретных форм.

## Проверить в маноре
- Панель кнопок профиля: lt / lv / hu / ga на 360–393 pt и крупный системный шрифт (~1,3) — две строки по центру,
  кнопки одной высоты, иконка чата по центру; en и de — без изменений.
- Остальное из `007` (псевдоязык, баннер Daily, строка Reviews, статистика, лист даты рождения).
- Общие файлы: `shared/ui/button`, `shared/ui/offer` (AURAT-0166), `DateStrip` (AURAT-0165), `namespaces.ts`,
  `.eslintrc.js`, `shared/config/locales/*`, `translations.test.ts`, `glossary.json` (AURAT-0163) — конфликт решает
  задача, которая мёржит позже.
