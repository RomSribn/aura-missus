# AURAT-0154-007 — execute

2026-11-04, slave-1, `feature/AURAT-0154-app-i18n-foundation`. 64 файла (+2944 / −48), всё staged, не закоммичено.

## Что сделано (по пунктам спеки `005`)

1. **Зависимости.** `i18next` 26.5.3, `react-i18next` 17.1.0. Dev-зависимости: `make-plural` 8.1.0, `eslint-plugin-i18next` 6.1.5.
2. **Языки** — `src/shared/config/languages.ts`: `LANGUAGES` (24, как у веба), `Language`, `SOURCE_LANGUAGE`, `TranslatedLanguage`, `isLanguage`.
3. **Ядро — `src/shared/lib/i18n/`:**
   - `namespace.ts` — тип `Translation` от веба, синхронный загрузчик;
   - `plural-rules.generated.ts` — сгенерирован скриптом `scripts/i18n/generate-plural-rules.mjs`, только 24 функции;
   - `plural-rules.ts` — `AuraPluralRules`, `installPluralRules`, `pluralCategoriesOf`;
   - `init.ts` — синхронный init; форматтер `{{x, lowercase}}`; `<Trans>` без HTML-узлов и всегда внутри `Text`;
   - `detect-language.ts`, `language-store.ts` (`Documents/aura-language.json`, атомарная запись), `resolve-language.ts` (флаг, «последнее изменение побеждает»);
   - `start.ts`: `startI18n`, `i18nReady`, `isI18nReady`, `currentLanguage`, `chooseLanguage`, `previewPseudoLanguage`;
   - `pseudo.ts`.
4. **Флаг `AURA_I18N_ENABLED`.** Проходит через `env/resolve.js` и `I18N_ENABLED` в `env.ts`, описан в `env/README.md`, покрыт тестами env. Во всех целях `false`.
5. **Слой app:**
   - `app/i18n/namespaces.ts` — реестр пространств;
   - `app/i18n/start.ts` — `startAppI18n` и меню разработчика;
   - `app/providers/I18nGate.tsx` — обёртка вокруг дерева в `App`;
   - `index.js` — `startAppI18n()` первой строкой, до headless-обработчиков.
6. **`shared/ui` на `t()`**, пространство `shared` (24 языка, 27 ключей): BottomSheet, DobField, `CouponTicket`, `CampaignTicket`, `TicketShell` (корешок `numberOfLines={1}` + `adjustsFontSizeToFit`, `minimumFontScale` 0.6), PriceTag, ResendTimer, StarPicker (плюралы). Переводы веба (`shared`, `auth-by-phone`, `write-review`) взяты, где совпадает английский; остальные переведены в регистре веба. Английский текст не изменился — все прежние тесты зелёные без правок.
7. **Типы.** `ResourceNamespaceMap` (i18next 26): `t()` типизирован.
8. **Jest — `jest.setup.js`:**
   - из Intl удалено то, чего нет в Hermes; родной `PluralRules` сохранён в `__NODE_PLURAL_RULES__`;
   - синхронный `en` в строгом режиме: пропущенный ключ или подстановка роняют тест;
   - в мок `react-native-fs` добавлен `DocumentDirectoryPath`.
9. **Тесты:**
   - `plural-rules.test.ts` — 24 языка × 2 117 значений против ICU 78.2, 0 расхождений;
   - `language.test.ts`, `pseudo.test.ts`;
   - `app/i18n/__tests__/translations.test.ts` — ключи, пустые строки, `{{…}}`, теги, формы плюрала, NFC, ș/ț, запрещённые символы, «равно английскому» (`SAME_AS_ENGLISH`), реестр против диска, реестр импортирует только `config/locales`, `i18next.options.ns`.
10. **Линтер.** `i18next/no-literal-string` = `error` для `src/shared/ui/**` (проверено пробным файлом, что срабатывает). Исключение глубоких импортов — только для `app/i18n/namespaces.ts`. Сгенерированный файл — в `ignorePatterns`.
11. **Правила.** Раздел «Translations» в `.claude/aura-build-rules.md` (репозиторий workspace).

## Отступления от спеки

- `ensureI18n` разделён на `startI18n` + `i18nReady` / `isI18nReady`. Так первый кадр с выключенным флагом не ждёт ни такта.
- Пункт меню «next language» идёт через настоящий `chooseLanguage`, то есть выбор сохраняется. В спеке было «только в памяти». Причины: правило 5 (запись выбора без потребителя не мёржится) и проверка реального пути в маноре. «pseudo» по-прежнему не сохраняется.
- `shared/lib/discount-copy` тоже переведён: его `firstSessionOfferTitle` использует `CouponTicket`, текст должен жить в одном месте. Функции читают глобальный `i18next.t` в языке на экране. Вызовы в `features/booking` и `entities/campaign` получают перевод без изменений.
- Греческие заглавные: `textTransform: 'uppercase'` в бровке билета оставлен, иначе тесты, сверяющие текст «Welcome offer», пришлось бы менять. Вместо этого `el` написан заглавными без тоноса («ΠΡΟΣΦΟΡΑ ΚΑΛΩΣΟΡΙΣΜΑΤΟΣ»). Правило записано в build rules.

## Проверки (slave)

- `npx tsc --noEmit` — чисто.
- `npx eslint .` — 0 ошибок и 0 предупреждений.
- `npx jest` — 164 набора, 1282 теста, все зелёные (было 159 наборов). Предупреждения `act()` в тестах билетов были и до задачи: 9 и 9 на `develop` в маноре.
- Новые файлы и прежде чистые изменённые прогнаны prettier.
- Релизный бандл Android (`AURA_ENV=prod`, `hermesc -O`): HBC 4 384 965 → 4 588 179 байт (+198 КБ, +4,6 %), gzip +97 КБ. Загрузчики остались ленивыми (`bg:()=>r(d[1]).default`). Сборка «до» — из манора; его `node_modules` могут быть несвежими.

## Открыто / дальше

- **Манор после merge, dev-сборка** (меню разработчика):
  - de / fr / pl / lt / el / bg и pseudo на купоне, билете кампании, StarPicker, ResendTimer, DobField;
  - корешок билета с «PROMOCJA» и «НАМАЛЕНИЕ» не вылезает за 74pt;
  - el / bg пока системным шрифтом — это ожидаемо (шаг 1c);
  - выбор переживает перезапуск только с `AURA_I18N_ENABLED=true` в `.local`.
- На устройстве не проверены: язык системы из Intl на Android, работа `DevSettings.addMenuItem` в RN 0.85.
- Следующие задачи `AURAF-0023`: 1b (глоссарий), 1c (шрифты), shared + app, лист Language.
