# AURAT-0154-005 — spec (draft)

Тип: задача фичи `AURAF-0023`, шаг 1a. Только `aura-app`. В релизе видимых изменений нет: флаг
`AURA_I18N_ENABLED` выключен во всех целях, язык всегда `en`. Основание — `AURAI-0010`.

## Что меняется

1. **Зависимости.** `i18next` 26.5.3 и `react-i18next` 17.1.0 — как у веба. Dev: `make-plural` 8.1.0 (только для
   генератора и теста), `eslint-plugin-i18next` 6.1.5.
2. **Языки — `shared/config/languages.ts`.** `LANGUAGES` (en + 23, порядок и коды как у веба), `Language`,
   `SOURCE_LANGUAGE`, `TranslatedLanguage`. Единственный источник списка.
3. **Ядро — `shared/lib/i18n/`** (порт веба с изменениями под Hermes):
   - `namespace.ts`:
     - `Translation<Source>` с плюралами — как у веба;
     - `I18nNamespace` с синхронным загрузчиком `() => Translation<Source>` для каждого языка (`Record` —
       язык без файла не компилируется);
     - в слайсе: `de: () => (require('./de') as typeof import('./de')).default`.
   - `plural-rules.ts`:
     - сгенерированный шим `Intl.PluralRules` на 24 языка (`scripts/i18n/generate-plural-rules.mjs` из
       `make-plural` 8.1.0; генерируются только нужные функции);
     - ставится, только если `Intl.PluralRules` нет;
     - подключается первой строкой `index.js`.
   - `init.ts` — синхронный старт:
     - `initAsync: false`, ресурсы `en` + стартовый язык, `supportedLngs`, `load: 'languageOnly'`,
       `fallbackLng: 'en'`;
     - `react: { useSuspense: false, transSupportBasicHtmlNodes: false, defaultTransParent: Text }`;
     - смена языка: `addResourceBundle` для каждого пространства, затем `changeLanguage` (тоже синхронно).
   - `language.ts`:
     - `detectLanguage(tags)` — порт веба;
     - язык системы — языковая часть `Intl.DateTimeFormat().resolvedOptions().locale`;
     - выбор — файл `Documents/aura-language.json` `{ language, osLanguage }`, запись атомарная, как
       `config-cache.ts`;
     - правило «последнее изменение побеждает»: если системный язык сменился после выбора, выбор сбрасывается;
     - `chooseLanguage(language | 'device')`;
     - `ensureI18n()` — повторный вызов безопасен, работает и вне React (headless-пуш).
   - `pseudo.ts` — псевдоязык для `__DEV__`: акценты, текст длиннее на 40%, скобки; `{{…}}` и `<теги>` не трогает.
4. **Флаг.** `AURA_I18N_ENABLED` (по умолчанию `false`) идёт через `env/resolve.js` и попадает в `I18N_ENABLED`
   (`shared/config/env.ts`), как `AURA_BILLING_ENABLED`, с описанием в `env/README.md`.
   - Выключен: язык всегда `en`, файл и система не читаются.
   - Включён: работает правило из п. 3.
5. **Слой app.**
   - `app/i18n/namespaces.ts` — единственный реестр пространств, общий для приложения и Jest; единственное
     исключение из запрета глубоких импортов, только к `config/locales`.
   - `I18nGate` в `app/providers` ждёт `ensureI18n()` до первого рендера; с выключенным флагом — мгновенно.
   - В `__DEV__` — пункты меню разработчика «i18n: next language» и «i18n: pseudo». Действуют при любом флаге,
     живут только в памяти, в файл не пишут.
6. **Первый потребитель — весь `shared/ui`** (≈ 24 строки):
   - BottomSheet «Close», DobField, купоны и билеты (`CouponTicket`, `CampaignTicket`, `TicketShell`),
     `ResendTimer`, `StarPicker` (плюрал `stars_one` / `_other` и формы языков), подпись доступности `PriceTag`;
   - пространство `shared` во всех 24 языках. Строки, совпадающие с английским `shared` веба, берут его
     переводы; остальные переводятся в регистре веба;
   - английский текст не меняется ни на символ;
   - вёрстка: корешок билета (74pt, «CODE» / «SALE») и однострочные подписи не обрезают длинные переводы
     (`adjustsFontSizeToFit` / вторая строка);
   - регистр букв — только `toLocaleUpperCase` / `toLocaleLowerCase` с языком, без `textTransform` на
     переведённом тексте этих компонентов.
7. **Типы.** Расширение i18next (`ResourceNamespaceMap` / `CustomTypeOptions`), как у веба: `t('key')`
   типизирован, неверный ключ не компилируется.
8. **Jest — `jest.setup.js`:**
   - сохранить ссылку на родной `PluralRules` (для теста шима);
   - удалить то, чего нет в Hermes: `PluralRules`, `DisplayNames`, `RelativeTimeFormat`, `ListFormat`, `Locale`,
     `Segmenter`, `NumberFormat.prototype.formatToParts`, `DateTimeFormat.prototype.formatRange`;
   - подключить шим и синхронно поднять `en` из реестра;
   - пропущенный ключ или подстановка роняют тест.
9. **Тесты:**
   - шим совпадает с ICU Node: 24 языка × 0…2100 и дроби, плюс набор категорий;
   - полнота переводов (порт `i18n.test.ts` веба с усилениями): ключи, пустые строки, `{{…}}`, теги `<…>`,
     формы множественного числа по данным шима, NFC, румынские ș/ț без седили, запрещённые символы
     (U+00AD, U+2010, U+2011, U+02BC), перевод = английскому (со списком исключений: Aura, бренды);
   - выбор языка: флаг, файл, смена системного языка, детектор, повреждённый файл;
   - псевдоязык;
   - каждый `src/**/config/locales/index.ts` есть в реестре.
10. **Линтер.** `i18next/no-literal-string` выключен глобально, `error` для `src/shared/ui/**`: текст в JSX и
    строковые пропсы `accessibilityLabel`, `placeholder`, `title`.
11. **Правила.** Раздел «Translations» в `.claude/aura-build-rules.md`:
    - раскладка `config/locales/`, загрузчики и ловушка с импортом;
    - `t()` не вызывать на уровне модуля;
    - форматирование — только через `shared/lib` с явным языком; запреты Intl (`AURAI-0010` § Implementation
      Notes);
    - греческие заглавные, ș/ț, NFC;
    - регистр «ты/вы» как у веба; не согласовывать с родом пользователя;
    - новая строка — сразу через `t()` во всех 24 языках. Если у слайса ещё нет `config/locales`, его заводят;
      полный перенос слайса — его отдельная задача.

## Не входит

- Форматтеры, даты, деньги, общие фразы, `AuthError`, пуши, SMS — шаг 2 (shared + app).
- Строка Language и лист, названия языков 24×24, страны — шаг 2 и задача «вход».
- Шрифты el/bg — шаг 1c.
- Нативные объявления (`CFBundleLocalizations`, `localeFilters`…) — задача запуска.
- Остальные слайсы.

## Проверка

- **Slave:** `npm run lint` (0 / 0), `npx tsc --noEmit`, `npm test` (все 159 файлов и новые тесты зелёные).
  Релизный бандл Android (`npx react-native bundle --dev false`) — до и после, размер записать.
- **Манор, dev-сборка** (меню разработчика):
  - купон, билет, StarPicker, ResendTimer на de, fr, pl, lt и псевдоязыке — ничего не обрезано;
  - el / bg пока системным шрифтом — это ожидаемо;
  - с выключенным флагом всё как раньше.
