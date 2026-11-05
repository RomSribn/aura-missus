# AURAT-0159-005 — spec (draft)

Тип: задача фичи `AURAF-0023`, шаг 2, **часть B — форматтеры по CLDR языка интерфейса** (`AURAI-0010` решение 2,
`AURAT-0157-008`). Только `aura-app`; флаг `AURA_I18N_ENABLED` выключен — в релизе язык английский, меняется только
порядок английской даты по региону (решение C). Фразы вокруг чисел («/min», «30 min chat», «% off», «stays on your
balance») — шаг 3, здесь не трогаются.

## Что меняется

1. **Генератор** `scripts/i18n/generate-formats.mjs` (Node ICU) → `src/shared/lib/i18n/formats.generated.ts`, 25
   таблиц (23 языка + `en-US` + `en-GB`) и версия CLDR:
   - числа: десятичный и групповой разделитель, минимальная группировка; USD — приставка / суффикс с пробелами
     как есть (en «$1.99», de «1,99 $», nl «US$ 1,99»; без замены U+202F / U+00A0);
   - время h23: разделитель (da / fi «.»);
   - шаблоны дат как последовательность частей и литералов, с 12 месяцами / 7 днями **в контексте шаблона**:
     длинная дата (день недели + число + месяц), «число месяц» (вторая часть шапки Home), короткая дата MMMd
     (de «4. Sept.», cs «4. 9.»); отдельно стоящие: день недели полный и короткий, месяц короткий;
   - **деньги en — из `en`** у всех англоязычных (en-GB даёт «US$1.99»).
   Во время работы — только сборка строк из таблиц, `Intl` не вызывается.
2. **Ручные подмены** (`shared/config/date-overrides.ts`) — только короткий отдельный месяц bg и lt (CLDR даёт
   «01…12»): bg «яну фев мар апр май юни юли авг сеп окт ное дек», lt «sau vas kov bal geg bir lie rgp rgs spa lap
   grd» (календарные сокращения). cs / fi / lv — CLDR как есть (проверено: «zář», «syys», «janv.»).
3. **Drift-тест** (Jest, Node с полным ICU): каждая функция × 25 таблиц == живой `Intl` на суммах (0, 5, 199,
   123 456, 100 000 000 центов + 1 234,50 $ для группировки), всех месяцах и днях, временах 00:00 / 09:05 / 16:05 /
   23:59; список подмен из п. 2 — явный. Версия CLDR таблиц ≠ CLDR Node → сверка **пропускается** с
   предупреждением («таблицы из CLDR 48, у тебя N — сверка пропущена»): обновление Node у разработчика не ломает
   чужие тесты (`engines` `>= 22.11.0`, `.nvmrc` нет). Строгая сверка — `node scripts/i18n/generate-formats.mjs
   --check` (ненулевой код, если перегенерация даёт другой файл); тест на сборку без генерации (структура таблиц,
   подмены) идёт всегда.
4. **Регион для английской даты.** `deviceLocale` и `regionOfLocale` переезжают из `screens/phone-auth/lib/
   device-country.ts` в `shared/lib/device-locale.ts`; phone-auth берёт их из `@/shared` (его цепочка SIM → сеть →
   пояс → локаль остаётся у него — это «страна номера»). Английская таблица: регион локали ∈ {US, PR, GU, VI, AS,
   MP, UM, CA, PH} → `en-US`, иначе `en-GB`. Читается один раз (как пояс устройства). → **решение 1**.
5. **API в `shared/lib`** — язык явный, регион скрыт внутри, как часовой пояс сегодня:
   - деньги: `formatUsdMinor(minor, language)`, `formatUsdMinorCompact(minor, language)` («25 $» в de),
     `formatUsd(amount, language)` (один вызов — нулевой баланс в профиле → `formatUsdMinor(0, …)`, сам `formatUsd`
     удаляется, у него не останется потребителей);
   - `formatDecimal(value, language)` — до 1 знака после запятой, без лишнего нуля («4,9» de, «5»): рейтинги —
     `Stars` (`shared/ui`, сам берёт `useLanguage()`) и `StatsCard` (`String(ratingFromTenths(…))`);
   - `formatClockTime(date, language)`; `formatFileSize(bytes, language)` — десятичный разделитель языка, единицы —
     ключи `shared` (`size.b/kb/mb`: fr «o / Ko / Mo», остальные по глоссарию / вебу), `maxAttachmentLabel(language)`
     вместо модульной константы;
   - `longDateLabel(iso, language)`, `dayMonthLabel(iso, language)`, `shortDateLabel(iso, language)`,
     `weekdayLabel(iso, language, 'long' | 'short')`, `monthShort(iso, language)`; `dayNumber` — как есть («04»);
   - `relativeDay(startsAt, now)` → `{ kind: 'today' | 'tomorrow' | 'inDays', days }`,
     `relativeDayLabel(day, t)` — `day.today` / `day.tomorrow` (есть) + новый `day.inDays_*` (плюралы, 24 языка);
   - `upperLabel(text, language)` = `toLocaleUpperCase(language)` для дат, которые рисуются заглавными;
   - `useLanguage()` (`shared/lib/i18n`) — язык на экране через `useTranslation`, псевдоязык → `en`.
6. **Потребители (≈ 33 файла):** хуки и memo-строки берут `useLanguage()`, lib получает `language` параметром,
   мемо подписей зависят от языка. Удаляются: таблицы в `slots.ts` (полоса отдаёт дату, подписи — при рендере;
   «Today» → `day.today`), `screens/home/lib/format-date.ts` (+ тест), английские таблицы `dates.ts`.
   - **Шапка Home** — `weekdayLabel(long) · dayMonthLabel`, заглавные `upperLabel`; `textTransform` снят;
     `accessibilityLabel` — та же строка в обычном регистре. en-US «WEDNESDAY · NOVEMBER 4», en-GB
     «WEDNESDAY · 4 NOVEMBER», el без ударений.
   - Заглавные из п. 5 и у `DateStrip` (день недели), месяцев в блоках `BookedScreen` / `UpcomingSessionCard` и
     глаз-строки `UpcomingSessionCard`.
   - `DateStrip`: день недели и месяц `numberOfLines={1}` + `adjustsFontSizeToFit` (lv «CETURTD.», fr
     «AUJOURD'HUI» в 58pt); `accessibilityLabel` — `longDateLabel` вместо «Fri 04 Sep».
   - `pastDate` («24 May») и Reschedule («16:05, Sep 04») → `shortDateLabel`: en-US «May 24» / «16:05, Sep 4»,
     en-GB «24 May» / «16:05, 4 Sept».
   - **Время в чате** — `ChatMessage.time` заменяется на `sentAt` (ISO), подпись — в строке при рендере с
     `useLanguage()` (`MessageBubble`, `ChatListRow`, `ImageViewer`). → **решение 2**.
7. **Jest:** `jest.setup.js` закрепляет локаль устройства `en_US` (иначе порядок даты зависит от машины); путь
   en-GB — отдельными тестами. Существующие английские ожидания денег и времени не меняются; дат — только по
   решению C (шапка Home в US-порядке, `pastDate`, Reschedule).
8. **Тесты:** drift; каждая функция на en-US / en-GB / de / fr / pl / lt / bg / fi / hu / el (заглавные без
   ударений); регион (US / PR / CA / PH / GB / DE / нет региона / `@rg=`); реактивность (смена языка → новая подпись
   в хуке и в строке чата); `day.inDays` — плюралы проверяет существующий тест переводов.

## Решения владельца

1. **Откуда регион.** Рекомендую — только регион локали (настройка «Регион» / язык-страна Android), без SIM и
   сети: дата — это формат, который человек выбрал, SIM говорит лишь, откуда номер. Нет региона в локали → en-GB.
   Иначе — цепочка как у phone-auth (SIM → сеть → пояс → локаль).
2. **Время в чате.** Рекомендую — хранить `sentAt`, форматировать при рендере (переживает смену языка; da / fi
   иначе останутся «16:05» до перезагрузки ленты). Дешевле — форматировать при маппинге текущим языком и
   смириться.
3. **Сокращения bg / lt** из п. 2 — годятся? (носитель не нужен, но если у вас есть свой вариант — лучше он.)

## Ревью (slave-1, 2026-11-05) — внесено

1. Drift при чужой версии CLDR — пропуск с предупреждением + `--check` для строгой сверки (п. 3).
2. Рейтинги «4.9» → `formatDecimal` здесь (п. 5): 2 потребителя, таблицы разделителей всё равно появляются.
3. bg «ян» → «яну» (форма CLDR-словаря и болгарских приложений) (п. 2).
Ревьюер согласен с рекомендациями по решениям 1–3; решают владелец.

## Не входит

- Строка Language и лист (`AURAT-0158`, slave-1): `screens/profile`, таблица названий языков; `use-profile.ts`
  трогаю одной строкой (баланс) — пересечение с 0158 возможно, при слиянии второй мёржит.
- Проценты («−50%», «% off»), «N min», «/min», ошибки вложений — фразы шага 3 (там же `formatPercent`, если
  понадобится). `formatMediaTime`, таймеры — цифры и двоеточие, не зависят от языка. Ввод даты рождения — шаг 3.
- Нативные объявления языков, включение флага — шаг 4.

## Проверка

- **Slave:** `npm run lint` (0 / 0), `npx tsc --noEmit`, `npx jest --no-watchman`,
  `node scripts/i18n/translate.mjs check src/shared/config/locales/en.ts`.
- **Манор, dev-сборка, «i18n: next language» на de / fi / lt / el / псевдоязыке:** шапка Home, полоса брони (не
  обрезана), блоки сессий, деньги на чекауте и в профиле, время в чате до и после смены языка; телефон с регионом
  US и с регионом DE — английская шапка Home в двух порядках.
