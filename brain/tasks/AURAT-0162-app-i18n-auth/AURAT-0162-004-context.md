# AURAT-0162-004 — context

## Код (ground truth, develop @ 307bb14)
- `screens/phone-auth`: ~15 строк в `PhoneAuthScreen` (заголовок с жёстким `\n`, подзаголовок с `OTP_LENGTH`,
  a11y пилюли «Country, +34. Change», «Phone number», юридическая строка из 5 фрагментов, «Send code»);
  `CountryPickerSheet` — «Country», «Search», «Search countries», «No country matches “…”.», a11y строки
  `${name}, +${dial}`; `use-phone-auth` — «We can't text numbers from ${country} yet.» (страна — любая из 245,
  `COUNTRY_BY_ISO2[region].name`). Ошибки Firebase уже ключами `shared:auth.*` (`AURAT-0157`).
- `screens/verify-otp`: «Enter the code», «Sent to {phone} · » + ссылка «change», «Could not send a new code…»
  (`resendFailed` — строкой в хуке). `ResendTimer` уже в `shared` (`resend.*`).
- `screens/onboarding-slider`: 3 слайда в `config/slides.ts` (строки в config), «Skip», «Continue», «Get started»,
  «I already have an account».
- `screens/splash`: `TAGLINE` 'PSYCHIC · TAROT · DREAMS' (капсом), a11y «Continue». «Aura» — бренд.
- `screens/create-account`: 15 строк в `config/copy.ts`; поля Name / Date of birth общие с `edit-profile`.
- `shared/config/countries.ts`: 245 стран (`iso2`, англ. `name`, `dial`, 7 ключей `search`), сгенерировано из
  `Intl.DisplayNames(['en'])` 2026-08-28; `SMS_COUNTRIES` — 35 стран пикера. Потребители `name`: пикер, поиск
  (`country-search.ts`), сообщение о неподдерживаемой стране.
- Инфраструктура: `useLanguage()`, загрузчики `require`, генераторы `scripts/i18n/generate-*.mjs` с drift-тестом
  против Node (ICU 78.2 / CLDR 48 — та же версия, что у таблиц `0159`).

## Пробник CLDR (Node 22.23, все 245 × 24)
- Покрытие полное, кроме `mt` × `IO` (нет названия → английское).
- Объём: ~112 КБ исходника на все 24 языка, ~4,3–6,9 КБ на язык.
- `ga` и `mt` несут артикль: «an Ghearmáin», «an tSeicia», «il-Ġermanja», «l-Awstrija», «ir-Renju Unit» — при
  обычной сортировке почти весь список уходит под A / I / L. Нужен ключ сортировки без артикля.
- Hermes: `normalize` и `\p{M}` есть (`AURAI-0010` §1) — свёртка NFD + удаление меток + карта ł ø đ ħ ß æ œ.

## Веб (aura-web `auth-by-phone`, advisory — переиспользовать переводы)
- Имена стран — `Intl.DisplayNames` в рантайме, сортировка `Intl.Collator`; без учёта артиклей ga/mt.
- Совпадают по английскому: «Send code», «Country», «Phone number», «Enter the code», «Sent to {{phone}}», «change»,
  ошибки, юридическое предложение (у веба — вторым предложением строки `phone.legal`), Step 2 of 2 и тексты
  `name.*` (create-account).
- `phone.unsupported` у веба — «from {{country}}»; переводчики местами уже вынесли имя из падежа (pl, lt, hu, fi),
  местами нет (de «aus {{country}}», cs «ze země {{country}}»).

## Противоречия / замечания
- Слайд 3 «Your first chat is free» — по `ONBOARDING.md`; free chat в приложении есть (`startFreeChat`), т. е. не
  противоречит коду. Переводим как есть.
