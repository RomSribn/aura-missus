# AURAT-0161-007 — execute

Дата: 2026-11-05. slave-0, `feature/AURAT-0161-app-i18n-entities` (от `develop` @ `307bb14`). Спека — `005` rev. 1,
решения — `006`. Изменения **staged, не закоммичены** — ждут ревью владельца. 100 файлов, из них 69 — файлы
языков.

## Сделано (aura-app)

1. **Разделитель диапазона «месяц–день»** — генератор `scripts/i18n/generate-formats.mjs`:
   `monthDayRangeSeparator` в каждой таблице `formats.generated.ts`. Берётся как диапазон из `formatRange` минус
   две одиночные даты (MMMd, разные месяцы, 4 пары — один ответ). Для mt CLDR пишет диапазон иначе, чем одиночную
   дату («21 ta’ Mar» против «Mar 21»): там разделитель берётся из общих частей `formatRangeToParts`
   (`RANGE_PATTERN_DIFFERS`). `@/shared` `monthDayRangeLabel(from, to, language)` — две одиночные
   `shortDateLabel` и разделитель. В JSDoc сказано: только месяц–день, у времени свой.
   - drift-тест: `monthDayRangeLabel` == Node `formatRange` во всех 25 таблицах (mt — по общим частям).
     `jest.setup.js` до удаления сохраняет Node `formatRange` в `__NODE_FORMAT_RANGE__`, как `PluralRules`.
2. **horoscope** — namespace `horoscope`, `sign.<SIGN>` × 12 × 24, `@max 14`.
   - `config/signs.ts`: `SIGN_COPY` заменён на `SIGN_DATES` (`[месяц, день]`, границы те же).
     `HOROSCOPE_ABSENT_STATUS` на месте.
   - `lib/sign-dates.ts`: `signDatesLabel`.
   - `useHoroscope().signCopy` той же формы, `useMemo` по знаку, `t` и языку; тип `SignCopy` перенесён в
     model (public API тот же).
   - Названия знаков — общепринятые; на вебе их нет. Латинские названия в `SAME_AS_ENGLISH`: es Aries / Leo /
     Virgo / Libra, fr Cancer, ro Capricorn.
3. **campaign** — namespace `campaign` `ticket.*` (переводы веба: `season:ticket.*`, «Promo code» —
   `redeem-promo-code:label`).
   - `FALLBACK_TICKET_COPY` удалён.
   - `campaignTicketContent(kind, config, { t, language })`: сезон — `fillSeasonCopy`, английский, как было;
     без сезона — `t()`, `{{amount}}` = `formatUsdMinorCompact` (en «$5» / «$5.50» как прежде).
   - `useOfferTicket` берёт `t` и язык.
   - `SEASON_COPY_LANGUAGE = 'en'`: `accessibilityLanguage` у заголовка, текста, кнопки и (без кнопки) у блока
     `SeasonHero`.
4. **user** — namespace `user` `changePhoto` (веб `edit-profile:photo.change`), `PhotoRow` → `useTranslation`.
5. **Обвязка**: 3 namespace в `app/i18n/namespaces.ts`; `src/entities/**/*.tsx` — в override
   `i18next/no-literal-string`.
6. **Тесты**:
   - новые — `PhotoRow` (en / de), `SeasonHero` (`accessibilityLanguage`), сжатие строк `CampaignTicket`;
   - `use-horoscope`: de / pl / cs, en-GB (регион);
   - `ticket-content`: en «$5» / «$5.50», de / fr без «,00», сезон при de — английский «$5»;
   - `HomeScreen` — ожидание с тонкими пробелами.

## Решения по ходу (на просмотр владельцу)

1. **Тонкие пробелы в английском диапазоне.** CLDR 48 пишет «May 21 – Jun 20» с U+2009 вокруг тире. Раньше там
   были обычные пробелы. Оставил CLDR как есть, по правилу `0159` (U+202F / U+00A0 не заменяем). Видимая разница —
   пробел чуть уже. Шрифты U+2009 и U+2013 содержат (проверено по cmap всех 7 начертаний). Если нужен прежний
   английский вывод — одна подмена для en в генераторе.
2. **`CampaignTicket` (shared): заголовок и строка под ним — `adjustsFontSizeToFit`, `minimumFontScale 0.85`.**
   Переводы веба для строки под заголовком — 38–43 символа, а на билет 316pt при 12pt помещается ≈ 36. Так же
   сделано у `SegmentedControl` в `0157`.
   - `@max`: codeEyebrow 22, codeTitle 18, discountTitle 20, discountSub 40 (36 при полном размере, 40 со
     сжатием).
   - **Отступления от веба ради `@max`:**
     - discountTitle: de «−{{pct}} % auf Sitzungen», el «−{{pct}}% στις συνεδρίες», mt «−{{pct}}% fuq
       sessjonijiet», ga «−{{pct}}% ar sheisiúin», da / sv «−{{pct}} % på sessioner», ro «−{{pct}} % la
       sesiuni»;
     - codeTitle: mt «{{amount}} fil-bilanċ»;
     - discountSub: mt «Kull konsulent · …», pl «Każdy doradca · …», pt «Todo o consultor · aplicado no
       pagamento», sk «Každý poradca · …»;
     - el codeEyebrow — капсом «ΚΩΔΙΚΟΣ ΠΡΟΣΦΟΡΑΣ» (eyebrow рисуется в капсе).
3. fr сумма — по CLDR «5 $US» (так же, как в остальном приложении после `0159`).
4. Диапазон — две одиночные даты, не интервальный шаблон CLDR. Шаблон дополняет однозначный день нулём в hr / it /
   pt («04 mag»); у знаков дни 18–23, поэтому разницы нет.

## Проверка (slave)

- `npx tsc --noEmit` — чисто; `npm run lint` — 0 / 0.
- `npx jest --no-watchman` — 182 / 182 наборов, 1884 / 1884 тестов.
- `generate-formats.mjs --check` — совпадает.
- `translate.mjs check` по 3 namespace — 0 запретных форм. 15 советов: формы веба и ложные — ga «sheisiúin» —
  это «seisiún» с лениацией; «код» внутри «Промокод».
- Байты: NFC, нет U+00AD / ş / ţ / U+02BC.
- Prettier — новые и изменённые мной файлы; `shared/lib/dates.ts` и `shared/index.ts` не проходили prettier и до
  задачи, чужое форматирование не трогал.

## Открыто / в манор

- Dev-меню «i18n: next language»:
  - Home — знак и даты на de / pl / pt / el / ga («An tUisceadóir» — ровно 14) и на псевдоязыке, без обрезки;
  - билет без сезона на профиле — de / fr / mt / pl (сжатие строки), el в капсе;
  - «Change photo» в Create Account / Edit Profile;
  - VoiceOver на сезонной карточке при de — английский голос.
- mt и ga названия знаков — желательна проверка носителем (не блокирует).
- `HoroscopeCard` (screens/home): a11y `${name}, ${dates}` и подсказки — задача слайса home.
- `CampaignTicket`: `accessibilityLanguage` для серверных строк сезона на билете — отдельной строкой (см. `005`).
- Общие с `AURAT-0162` файлы: `app/i18n/namespaces.ts`, `.eslintrc.js` (override), `translations.test.ts`
  (`SAME_AS_ENGLISH`) — конфликт при мёрже второй.
