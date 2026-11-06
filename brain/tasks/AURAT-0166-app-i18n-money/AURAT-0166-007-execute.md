# AURAT-0166-007 — execute

Дата: 2026-11-06. slave-3, `feature/AURAT-0166-app-i18n-money` (от `develop` @ `7f58117`). Не закоммичено — всё в
stage для ревью. 139 файлов, +5081 / −355.

## Сделано

### Строки — 3 namespace × 24 языка, `@sensitive`
- `features/store-topup` → `store-topup` (`@sensitive payment`): TopUpSheet, PayWith / PayCompact / PayBreakdown,
  UseBalanceToggle, TopUpLink, PayNotice (6 исходов), тексты `use-checkout` (CTA всех фаз, «… left after», «… not
  enough», остаток, «Charged by …»).
- `features/promo-code` → `promo-code` (`@sensitive payment`): заголовок листа = строка меню профиля, поле, Apply,
  тосты, 9 отказов (`tooMany` — плюралы).
- `features/paid-session` → `paid-session` (`@sensitive refund`): баннер (+ a11y), «Extend +N min», лист продления
  (заголовок, a11y блоков, 3 ошибки, примечание о невозврате, End session early), Alert досрочного завершения.
- Переводы: с веба — где английский совпал (store-topup 11 из 49, promo-code 15 из 16, paid-session 14 из 17); остальное —
  3 агента по группам языков (effort medium, ~8 мин каждый) по глоссарию и регистру, затем `translate.mjs check`
  (0 запретных форм) и выборочная вычитка мной (de, pl, el, fr).
- `app/i18n/namespaces.ts` +3; `.eslintrc.js` — `i18next/no-literal-string` на `error` для трёх слайсов.

### Склейки → целые строки
- `CheckoutVerb` остался ключом логики; тексты — `cta.store.{book,startNow,extend}` «Pay {{price}} & …» и
  `cta.topUp.{book,extend}` (`TOP_UP_CTA` / `STORE_CTA` отображают глагол на ключ).
- Бренд стора как подлежащее / агент — пары `ios` / `android` (`STORE_PLATFORM` в `config/products.ts`): «… couldn’t
  complete the payment», «Charged by …», строка аккаунта, «Waiting for …». `STORE_ACCOUNT_LABEL` / `STORE_VENDOR`
  удалены; `STORE_NAME` / `STORE_ACCOUNT_LABEL` убраны из public API (потребителей вне слайса не было).
- «Use my balance · {{amount}}» — одна строка `<Trans>`, сумма жирным.
- `−${formatUsdMinor(x)}` → `formatUsdMinor(-x)`: место знака по CLDR, знак — U+2212 (см. раунд правок ниже).
- Минуты: `formatMinutes` удалён; плитка блока — `shared:minutes` (ключ `AURAT-0165`, взят дословно из slave-2),
  остальное — плюралы с `count` в своих строках. `BlockOption.minutesLabel` удалён.
- `/min` ставки — `shared:price.perMinute` (хунк `AURAT-0164` применён побайтно, с его блоком `SAME_AS_ENGLISH`).
- `OffChip` — `shared:offer.pctOff` «−{{pct}}%» с пробелом языка (U+00A0, fr тоже — после ревью); 11 языков без
  пробела — в `SAME_AS_ENGLISH`.

### Модель
- `use-promo-code`: отказ хранится причиной (`PromoRefusal`, `lib/refusal.ts`, бывший `refusal-copy.ts`), лист
  переводит при отрисовке; `title` в состоянии листа — им же подписана строка профиля
  (`screens/profile`: строка промокода без `label` в конфиге, `use-profile` берёт `promoCodeSheet.title`).
  `config/copy.ts` → `config/constants.ts` (только `CODE_MAX_LENGTH`).
- `use-checkout`, `use-paid-session` — `useTranslation`, хуки перерисовываются на смену языка.

### Решения владельца (`006`)
- Граница по слайсу: `features/booking`, `screens/booking` — `0165`; `screens/chat-thread` (`balanceCta` «Extend ·
  …», «Choose a block», тост «Added N minutes», «Book now», «Online/Away») — задача чата.
- Заглушка «Visa ···· 4242 / Change» убрана: вне store-rail строки способа оплаты нет (и стиль `cardRowStore` слит в
  `cardRow`). Неиспользуемый prop `TopUpLink.label` удалён.

### Вёрстка — замер шрифтами (opentype.js по бандл-TTF, 360 pt)
- Плитка PayCompact (~100 pt текста): «{{balance}} · not enough» шире в 18 языках → подпись плитки в 2 строки
  (`numberOfLines={2}`), обрезка съела бы смысл.
- Подстрока баннера (~187 pt): в 14 языках шире → до 2 строк.
- «Left» под счётчиком: el / hu / pt на 1–3 pt шире «20:57» — колонка расширится, средняя часть сожмётся; оставлено.
- Кнопки во всю ширину листа (~253 pt): укорочены el / hu / lt `startNow`, ga `topUp.extend`; фазы ожидания
  («Adding … to your balance…») в 9 языках переносятся на 2 строки — состояние на секунды, оставлено.
- Агенты укоротили под `@max`: `banner.live` (el / hu / fi / mt без «live» — в a11y он есть), `banner.booked`
  («· details»), `extend` (de «+N Min. buchen»), `notice.slotTaken.action`; `payPlain` — форма кнопки вместо
  существительного веба.

### Тесты
- Новые: checkout на de (CTA, balanceSub, минус CLDR, «Charged by» по платформе, остаток); PayNotice меняет язык на
  экране; ошибка стора на pl; UseBalanceToggle — одна строка; отказ промокода перечитывается при смене языка
  (`PromoCodeSheet.test.tsx`); баннер на lt (плюрал, a11y); плитка блока и a11y на de; OffChip en / de / fr.
- Обновлены: `refusal.test.ts` (причины вместо строк), `use-promo-code` (причина, точка в тосте как на вебе),
  `SessionBlockSheet` (’, a11y «10 more minutes for …»), `format-countdown`, `blocks`.
- `tsc` — 0, `eslint .` — 0, Jest — 190 наборов / 2159 тестов.

## Раунд правок по ревью slave-1 (2026-11-06, владелец: «да, передай»)
Отчёт: `wf0166-review.md` (translations F1–F11, structure F1–F5, tests T1–T9). Блокеров не было; итог — 144 файла
в stage, `tsc` 0, `eslint .` 0, Jest 190 / 2175, `translate.mjs check` — 0 запретных форм.

- **Минус у сумм — решение владельца, одно правило для 0165 и 0166.** `formatUsdMinor(-x)`: место знака по CLDR, сам
  знак — U+2212 во всех языках (en «−$4.00», de «−4,00 $», nl «US$ −4,00»), как в `CHECKOUT.md` и чипе «−50%».
  Сделано в `shared/lib/format.ts` (`usd`: минус таблицы → U+2212), таблицы CLDR не тронуты; `formats-drift.test` —
  это единственное ручное исключение для денег. 0165 переводит свои две строки Review сам (передал slave-1).
- **Плюс у долга:** новый `formatUsdMinorSigned` (плюс на месте минуса: nl «US$ +4,00» вместо склеенного
  «+US$ 4,00»), сверен с `Intl` `signDisplay: 'exceptZero'` во всех 24 языках; `use-checkout` на нём.
- F1 «Top up to book / extend» в de cs sk et fi hr lt lv mt sl ga было «пополнить И забронировать» — кнопка только
  открывает Top Up: форма цели (de «Zum Buchen aufladen» / «Zum Verlängern aufladen» …); ga «Cuir le d’iarmhéid ar
  dtús» для обоих — кандидат, в список для носителя.
- F2 el: `payWith` (заголовок Review, обычный регистр, «Πληρωμή με») и новый `payWithEyebrow` (PayCompact, капсом,
  «ΠΛΗΡΩΜΗ ΜΕ»); JSDoc обоих исправлены.
- F4 `breakdown.owed`: de «Negatives Guthaben», nl «Negatief tegoed», es «Saldo negativo».
- fi «Saldosi ei riitä tähän jaksoon.» (один термин «jakso» на листе); hu `endEarly` «Korai befejezés», ga
  «Críochnaigh an seisiún go luath» (`@max` 28 → 32); ro пилюля «Prelungește +{{count}} min» (`@max` 16 → 19, по
  ширине как el); nl примечание «… blijft altijd van jou.»; it «Addebitato da …».
- fr перед % — U+00A0, как CLDR и 0165: `pctOff`, `campaignTitle`, `firstSessionTitle`. `glossary.json` не тронут
  (v2 у 0164).
- `@max` у группы `account` не проверялся: теперь на `ios` / `android`; `readNotes` (`scripts/i18n/locales.js`)
  бросает ошибку на `@max N` у группы (слово «`@max`» в прозе, как у horoscope, не считается).
- JSDoc `banner.booked` (до двух строк, ~187 pt × 13 pt, `@max` 34 → 40) и `balance.short` (до двух строк ~100 pt
  × 11 pt, `@max` 24 → 30). Строки не менял: короткие формы понятны, полные без носителя писать не стал.
- Тесты: CTA каждого глагола × en / de и top-up CTA (T1), фазы waiting / adding / gettingPrice на de; платформа
  через мок `products` с геттером — обе платформы литералами (T2): hu `chargedBy`, de `notice.storeError.title`,
  строка аккаунта (T3); плюралы pl 1 / 2 / 5 / 22 и lt 21 / 25 / 10 на a11y блока (T4); `use-checkout` — сброс языка
  и `rnfs.reset()` в afterEach, переключения с await (T5); перерисовка уже смонтированных OffChip (в `React.memo`),
  SessionBanner, UseBalanceToggle (T6); сумма в UseBalanceToggle — жирный Text внутри фразы, без «<amount>» (T7);
  Top Up без «4242» / «Change» вне store-rail, со строкой аккаунта на нём (T8); долг en / nl (T9). Новые тесты
  проверены мутациями (неверный глагол, `.ios` вместо платформы, переименованный ключ `<Trans>`) — падают.

### Мёрж develop — как разрешать (structure F4, проверено slave-1 пробным мёржем)
- `use-profile.ts`: deps `[walletEnabled, languageRow, t, promoCodeSheet.title]`, обе ветки `flatMap`.
- `screens/profile/config/constants.ts`: из JSDoc `ProfileMenuPromoRow` убрать «Its label is the feature's, still
  English…».
- `namespaces.ts`, `translations.test.ts` — обе стороны. С 0164 конфликтов нет, с 0165 — только `namespaces.ts`.

## Для носителя (из отчётов агентов; `translate.mjs review` — все три namespace)
- ga — весь store-topup (особенно `cta.topUp.*` «Cuir le d’iarmhéid ar dtús», `account.*`); mt — `account.*`,
  `notice.failed.body`, `breakdown.owed`; de — `breakdown.owed` «Negatives Guthaben», «+N Min. buchen».
- el / hu / fi / mt — `banner.live` без «live»; ro «Extinde», hu «Bővítés» — не глоссарий; hu `cta.store.*` с ценой
  в конце; lv `oneTap` «1 pieskāriens»; lt / lv / pl — строка аккаунта без «Your»; hr — род «Google Play».
- «Блок» во всех языках — открытый вопрос глоссария.

## Не сделано / дальше
- ~~`develop` ушёл вперёд~~ — после «ок» владельца: коммит `692c496`, мёрж develop @ `ce900e5` (`0163` + `0164`) —
  `d2b1430`. Конфликты только в `namespaces.ts` (импорты — обе стороны по алфавиту), `translations.test.ts`
  (`SAME_AS_ENGLISH` — обе стороны), `use-profile.ts` (deps `[walletEnabled, languageRow, t, promoCodeSheet.title]`;
  `flatMap` слился сам); JSDoc `ProfileMenuPromoRow` исправлен. `.eslintrc.js`, `TECH-DEBT.md` — без конфликтов.
  После мёржа: `tsc` 0, `eslint .` 0, Jest 192 / 2427, `translate.mjs check` (глоссарий v2) — 0 запретных форм.
- Вёрстка на устройстве (флаг `AURA_I18N_ENABLED`): плитки PayCompact, баннер в 2 строки, кнопки оплаты — de / el /
  hu / ga / pl — в маноре после мёржа.
- `TECH-DEBT.md` строка 13: «Half price» при любом `pct`.
