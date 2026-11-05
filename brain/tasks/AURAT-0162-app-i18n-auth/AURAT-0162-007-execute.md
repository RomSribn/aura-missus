# AURAT-0162-007 — execute

Дата: 2026-11-05. slave-1, `feature/AURAT-0162-app-i18n-auth`. Не закоммичено — всё в stage для ревью.

## Сделано

### Строки — 4 namespace × 24 языка
- `screens/splash` → `splash`: слоган (капсом во всех языках, el без тонов), a11y «Continue». «Aura» — бренд,
  литерал с `eslint-disable` и причиной.
- `screens/onboarding-slider` → `onboarding-slider`: Skip / Continue / Get started / I already have an account,
  3 слайда. `config/slides.ts` отдаёт ключ (`copy: 'chat' | 'dailyCard' | 'free'`), `SlideItem` (memo) сам зовёт
  `useTranslation`.
- `screens/phone-auth` → `phone-auth`: заголовок (перенос `\n` — часть перевода), подзаголовок с `{{digits}}`,
  a11y пилюли и поля, юридическая строка — одна, `<Trans>` с `<terms>` / `<privacy>`, `@sensitive legal`
  (23 языка в `translate.mjs review` как «missing» — ждут носителя), Send code, «нет SMS» в новой формулировке
  (`{{country}}: we can't text numbers there yet.` — решение 2), лист: заголовок, поиск, a11y, «ничего не найдено»
  (кавычки языка).
- `screens/verify-otp` → `verify-otp`: Enter the code, «Sent to {{phone}}» + «change» отдельными строками,
  `resendFailed` ключом. Строка «Sent to … · change» теперь переносится (`flexWrap`); у «change» — role button.
- Переводы: из веба, где английский совпал (Continue, Get started, Phone number, Send code, Country, Enter the
  code, Sent to, change, вторая фраза веб-строки `phone.legal`); остальное — по глоссарию и регистру языка.
  `@max` на кнопках, заголовках слайдов, «change», заголовке листа.
- `app/i18n/namespaces.ts` +4; `.eslintrc.js` — `i18next/no-literal-string` на `error` для четырёх слайсов.
  `Pagination`: `'clamp'` вынесен в константу (линтер читает строки внутри JSX).

### Названия стран (AURAF-0023-005)
- `scripts/i18n/generate-country-names.mjs` → `src/shared/config/country-names/<lang>.generated.ts`, 245 × 24 из
  Node 22.23 / ICU 78.2 / CLDR 48. Порядок ключей = порядок списка языка (Collator при генерации).
  `mt:IO` — английским (в CLDR нет).
- `scripts/i18n/country-order.js` — общий для генератора и теста ключ сортировки: ga / mt без начального артикля,
  в ga ещё без лениции после артикля («an Bhulgáir» под B).
- `country-names/index.ts` — `require`-загрузчики по языку; `shared/lib/country-names.ts` — `useCountryNames()` /
  `countryNamesOf(language)`: `nameOf`, `inListOrder`, `searchKeysOf` (своё название + английское, свёрнутые
  один раз на язык), `foldForSearch` (NFD, без `\p{M}`, ł ø đ ħ ß æ œ ı, ς→σ, ’→').
- `shared/config/countries.ts` — без `name` / `search` (только `iso2`, `dial`).
- Пикер: страны по алфавиту языка, поиск через `foldForSearch` по обоим названиям, ISO и коду; сообщение
  «нет SMS» называет страну на языке интерфейса.

### Тесты
- Новые: drift-тест таблиц против Node ICU и порядка (`country-names/__tests__`), ключи сортировки ga / mt, свёртка
  и поиск (`shared/lib/__tests__/country-names.test.ts`), поиск на de / el / pl и по английскому названию
  (`country-search.test.ts`).
- Обновлены: `countries.test.ts` (ушли тесты имён), `use-phone-auth.test.tsx` (новая формулировка), `SplashScreen`.
- `tsc` — 0 ошибок; `eslint .` — 0; Jest — 183 набора, 1977 тестов, все зелёные.
  `translate.mjs check` — только советы (составные слова, падежи, «Get started» ↔ star), запретных форм нет.

## Не сделано / проверить в маноре
- Вёрстка на устройстве: псевдоязык и de / fi / hu / el / ga — заголовки, Send code, «I already have an account»,
  строка «Sent to … · change», строки листа (48 pt). Проверить после мёржа (флаг `AURA_I18N_ENABLED`, dev-меню).
- create-account — в задачу «профиль и аккаунт» (решение 1).
- Общие файлы с `AURAT-0161`: `namespaces.ts`, `.eslintrc.js` — конфликт при мёрже второй задачи.
