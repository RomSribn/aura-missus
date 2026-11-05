# AURAT-0159-007 — execute

Дата: 2026-11-05. slave-0, `feature/AURAT-0159-app-i18n-formatters` (от `develop` @ `d5b25bc`). Изменения
**в индексе, не закоммичены** — ждут просмотра владельцем. 110 файлов (11 новых, 2 удалены).

## Сделано

- **Генератор** `scripts/i18n/generate-formats.mjs` → `src/shared/lib/i18n/formats.generated.ts` (Node 22.23 /
  ICU 78.2 / CLDR 48): 24 числовые таблицы (разделители, минимальная группировка, USD-аффиксы, единицы размеров) и
  25 таблиц дат (23 языка + `en-US` + `en-GB`): длинная дата, «число месяц», MMMd, отдельно стоящие дни и месяцы,
  время h23. Невидимые пробелы — escape-последовательностями; вывод через prettier; `--check` — строгая сверка.
- **`shared/config/formats.ts`**: `US_DATE_ORDER_REGIONS` (US PR GU VI AS MP UM CA PH), короткие месяцы bg «яну…»
  и lt «sau…» (решение 3), `ENGLISH_FILE_SIZE`.
- **`shared/lib/device-locale.ts`**: `deviceLocale` + `regionOfLocale` перенесены из phone-auth
  (`device-country.ts` берёт их из `@/shared`, тесты `regionOfLocale` — туда же).
- **`shared/lib/i18n/formats.ts`** (внутренний): выбор таблицы, английская — по региону локали (решение 1), без
  региона → en-GB.
- **API** (`@/shared`): `formatUsdMinor` / `formatUsdMinorCompact` / `formatDecimal` / `formatClockTime` /
  `formatFileSize` / `formatMegabytes` — с языком; `longDateLabel`, `dayMonthLabel`, `shortDateLabel`,
  `weekdayLabel`, `monthShort` — с языком; `relativeDay` → данные + `relativeDayLabel`; `upperLabel`;
  `useLanguage()`. `formatUsd` удалён (последний вызов — ноль в профиле → `formatUsdMinor(balance ?? 0)`).
- **`shared` `day.inDays_*`** — 24 языка, переводы веба дословно (`entities/session` там).
- **Потребители (≈ 40 файлов)**: деньги в чекауте, top-up, брони, оплачиваемой сессии, промокоде, профиле,
  карточках консультантов, `PriceTag` / `CouponTicket`; рейтинги — `Stars`, `StatsCard`; время и даты в полосе
  брони, слотах, сессиях, деталях, отмене, переносе, ежедневной карте; размеры вложений.
  - удалены таблицы `slots.ts` и `screens/home/lib/format-date.ts` (+ тест); `BookingDay` несёт `noon` и `today`,
    подписи — в `DateStrip` при рендере;
  - **шапка Home**: `weekdayLabel(long) · dayMonthLabel`, `upperLabel`, `accessibilityLabel` в обычном регистре;
    `useMemo([])` → `[language]`;
  - `textTransform: 'uppercase'` снят с дат: Home, `DateStrip`, месяц в блоках `BookedScreen` /
    `UpcomingSessionCard`, глаз-строки `UpcomingSessionCard` и `SessionHero` (у героя — `accessibilityLabel`);
  - `DateStrip`: `numberOfLines={1}` + `adjustsFontSizeToFit` (0.6), a11y — `longDateLabel`; BookReview «Today» →
    `day.today`;
  - **чат** (решение 2): `ChatMessage.time` → `sentAt` (ISO), `messageTime(message, language)` в `features/chat`;
    `MessageBubble`, `ChatListRow`, просмотрщик; `MAX_ATTACHMENT_LABEL` → `MAX_ATTACHMENT_MEGABYTES` +
    `formatMegabytes`; `refuseDraft` / `describeRefusal` принимают язык.
- **Jest**: `jest.setup.js` закрепляет `deviceLocale` → `en_US`; drift-тест `formats-drift.test.ts` (24 языка ×
  деньги, десятичные, размеры, время, все даты; en — в двух регионах; при чужой CLDR — пропуск с предупреждением);
  тесты форматтеров на en / de / fr / nl / pl / fi / da / cs / hu / lt / bg / el; регион (US / CA / PH / PR / GB /
  DE / без региона / `@rg=`); реактивность (`useLanguage` — цена; строка чата 09:41 → 09.41 после `fi`); шапка Home в
  двух порядках.

## Проверка (slave)

`npx tsc --noEmit` — чисто; `npm run lint` — 0 / 0; `npx jest --no-watchman` — 175 наборов, 1657 тестов, все
зелёные; `node scripts/i18n/generate-formats.mjs --check` — совпадает; `translate.mjs check` по `shared` — 0
запрещённых форм (12 старых советов, новых нет).

## Решения по ходу (на просмотр владельцу)

1. **Единицы размеров — из CLDR, не ключами `shared`** (отступ от п. 5 спеки): генератор берёт kB / MB (fr «ko» /
   «Mo», fi «kt» / «Mt») и пробел из CLDR, drift-тест их сверяет; иначе — 3 ключа × 21 язык в `SAME_AS_ENGLISH`.
   Английский остаётся «248 KB» (`ENGLISH_FILE_SIZE`). Байты — узкий символ CLDR, где он слово (el, mt, nl) — «B».
2. **Английские суммы от $1000 получают запятую**: «$1,234.56» вместо «$1234.56» (CLDR en). Балансы такого размера
   редки; прежний вывод был без группировки.
3. Reschedule «16:05, Sep 04» → «16:05, Sep 4» (US) / «16:05, 4 Aug» (GB) — `shortDateLabel`, без ведущего нуля.
4. Подпись доступности дня в полосе — длинная дата («Friday, August 14») вместо «Fri 04 Sep»; «, fully booked»
   остаётся английским до шага 3.
5. Ошибка размера вложения и текст ошибок чата хранятся строкой в состоянии — пересчитаются при следующей ошибке, не
   при смене языка (кратковременные).
6. Регион читается при каждом вызове (регэксп по закешированной RN строке) — смена региона в настройках подхватится
   без перезапуска; тесты меняют его моком.

## Открыто / дальше

- `use-profile.ts` — одна строка (баланс) + импорт; возможен конфликт с `AURAT-0158` при слиянии.
- Проверка в маноре (после merge): dev-меню «i18n: next language» на de / fi / lt / el / псевдоязыке — шапка Home,
  полоса брони (не обрезана), блоки сессий, деньги в чекауте и профиле, время в чате до / после смены языка;
  английская шапка на телефоне с регионом US и с регионом DE.
- Фразы вокруг чисел («/min», «min chat», «% off», «stays on your balance», ошибки вложений) — шаг 3.
