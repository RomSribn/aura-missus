# AURAT-0157-004 — context

Источники: `AURAI-0010` (§1, §4, §7, решения 2 и 5), `AURAF-0023` + `AURAF-0023-glossary.md`, «Translations» в
`.claude/aura-build-rules.md`, шаги `AURAT-0154`, `AURAT-0155`, код slave-1 (`a2350f8`), aura-web манора (`88dd553`).

## Код (ground truth)

**Форматтеры** (`shared/lib/format.ts`, `dates.ts`) — все английские, язык не принимают:
- деньги: `formatUsdMinor` — 43 вызова в 19 файлах; `formatUsd` ×2, `formatUsdMinorCompact` ×3 (`'$' + toFixed`);
- время: `formatClockTime` ×14 в 7 файлах (24h, `HH:mm` руками);
- размер файла: `formatFileSize` ×8 (`"1.2 MB"`, точка);
- даты: `longDateLabel` ×6 («Friday, August 14», US-порядок), `monthShort` ×4, `dayNumber` ×3, `relativeDay` ×3
  («Today» / «Tomorrow» / «In 3 days» — английский текст из lib);
- ещё две свои таблицы дней и месяцев: `features/booking/lib/slots.ts` (полоса 14 дней: «Today», «Fri», «14»,
  «Aug») и `screens/home/lib/format-date.ts` («Friday · 30 May», UK-порядок, рисуется `textTransform: uppercase`);
- всего форматтеры зовут 33 файла: model 11, lib 7, ui 15. В lib/model подписи собираются заранее → язык надо
  передать параметром, в хуке — реактивно.
- «N min», «/min», «Sending 34%» — строки слайсов, не форматтеры (шаг 3).

**CLDR в Node** (ICU 78.2 / CLDR 48, как в Jest), USD 1234.50 / пятница 14 августа / 16:05:
- деньги: `$1,234.50` en, `1.234,50 $` de, `1 234,50 $US` fr, `1234,50 щ.д.` bg, `US$ 1.234,50` nl/pt,
  `1234,50 USD` pl/it/hu…; группировка от 5 цифр в bg es et hu it lv pl sl (min grouping 2); в fr cs sk sv fi —
  U+202F / U+00A0 (U+202F нет в Hanken → заменять на U+00A0, пока `AURAT-0156` его не добавит);
- длинная дата: de «Freitag, 14. August», pl «piątek, 14 sierpnia» (родительный), lt «rugpjūčio 14 d.,
  penktadienis», hu «augusztus 14., péntek» — порядок и падеж разные, шаблоном «weekday, month day» не собрать;
- короткий месяц: bg и lt — «08» (цифрой) → ручные сокращения; et/hu короткий день — одна буква («R», «P»);
- время 24h: везде `16:05`, кроме da и fi — `16.05`.
- Веб форматирует через `Intl` во время работы (`shared/lib/format.ts`, `dates.ts` там), т. е. CLDR браузера.

**SegmentedControl** (`shared/ui/segmented`): `options: readonly T[]`, рисует value как подпись и как
`accessibilityLabel`. Потребители: advisors `SEGMENTS` ['All','Online','Top rated'] (сравнения в
`filter-advisors.ts`, `use-advisors.ts`), sessions `SESSION_SEGMENTS` ['Upcoming','Past'] (`SessionsScreen.tsx:48`),
home `HOROSCOPE_DAYS` ['Today','Tomorrow'] (`use-home.ts`).

**AuthError** (`shared/api/firebase/auth.service.ts`): `handleAuthError` кладёт в `message` одну из 12 английских
фраз по коду; потребители — `use-phone-auth.ts` (×3 `error.message`), `use-verify-otp.ts` (×4), плюс литерал
«Something went wrong. Please try again.» в `use-phone-auth.ts:188`.

**Пуши** (`features/push`): `MESSAGES_CHANNEL_NAME` 'Messages', `ANNOUNCEMENTS_CHANNEL_NAME` 'Announcements',
заголовок — имя консультанта или 'Your advisor', тело — 'sent you a new message' (склеивается с именем в одну
фразу: в pl / cs / sk / hr / sl / lt / lv глагол согласуется с родом консультанта). Каналы создаются при каждом
показе и при старте (announcements). `index.js` зовёт `startAppI18n()` первой строкой, но не ждёт его — с
включённым флагом headless-обработчик может нарисовать пуш до чтения файла выбора.

**SMS**: `authService.sendOTP` → `auth().verifyPhoneNumber`; `setLanguageCode` нигде не зовётся.

**Общие фразы** вне `shared`: «Go back» — 13 копий `CircleButton` + `AuraIcon back` (размер 40 или 44, иконка
20 или 22) в 11 экранах; «Check your connection and come back in a moment.» ×3; «Try again» ×4 (home, advisors,
daily-card, PayNotice); «Something went wrong. Please try again.» ×2. «Close» уже в `shared`.

## Противоречия и заметки
- Build rules / 001: «время 24h» ↔ CLDR da/fi пишет `16.05` — решение владельца нужно (рекомендую CLDR).
- Английский источник: «Friday, August 14» (US) и «Friday · 30 May» (UK). При CLDR en оба станут US.
- Тело пуша — фрагмент фразы с именем: переводимо только с переделкой английского (решение владельца).
- `AURAI-0010` §4 считал 42 вызова `formatUsdMinor`, сейчас 43.
