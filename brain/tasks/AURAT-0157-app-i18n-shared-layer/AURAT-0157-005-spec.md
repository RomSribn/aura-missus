# AURAT-0157-005 — spec (draft)

Тип: задача фичи `AURAF-0023`, шаг 2 (shared + app). Только `aura-app`. Флаг `AURA_I18N_ENABLED` остаётся
выключенным: в релизе всё английское, как сейчас. Основание — `AURAI-0010` §1, §4, §7, решения владельца 2 и 5;
контекст и счёт мест — `004-context.md`.

## Предложение: две задачи вместо одной

Работа делится по природе на две почти независимые части:

| | A. Строки и структура (`AURAT-0157`, этот слот) | B. Форматтеры по CLDR (новый номер, `AURAT-0159`) |
|---|---|---|
| Что | общие фразы + `BackButton`, `SegmentedControl` `{value,label}`, `AuthError` → код, пуши и каналы Notifee, `setLanguageCode` | генератор таблиц CLDR + drift-тест, деньги / даты / время / размер файла с явным языком, `useLanguage`, перевод всех 33 файлов-потребителей |
| Файлы | ≈ 25 (11 экранов с «Go back», 3 с сегментами, phone-auth / verify-otp, push, firebase) | ≈ 40 (33 потребителя + shared/lib + скрипт + тесты) |
| Риск | малый, механика | средний: точность таблиц, реактивность подписей в model/lib |
| Решения владельца | 1, 2 | 3, 4 |

Пересекаются в 4–5 экранах разными строками — конфликты слияния мелкие. Рекомендация: **A — здесь, сейчас; B —
отдельной задачей** (в slave-0 после `AURAT-0156` или сразу после A). Ревью дифа в одной задаче на ≈ 65 файлов
тяжёлое; A разблокирует шаг 3 для entities и входа раньше. Если владелец против деления — делаю A и B здесь
одной задачей, в порядке A → B, тот же текст спеки.

## A. Строки и структура (`AURAT-0157`)

1. **Общие фразы — пространство `shared`** (во всех 24 языках, память веба через `translate.mjs scan`):
   - `goBack` «Go back», `tryAgain` «Try again», `connection.comeBack` «Check your connection and come back in a
     moment.», `error.generic` «Something went wrong. Please try again.»; «Close» уже есть.
   - **`BackButton`** в `shared/ui` (`CircleButton` + иконка `back` + переведённый `accessibilityLabel`; размеры
     40 / 44 → иконка 20 / 22, как сейчас) заменяет 13 копий в 11 экранах (build rule 3: дубль → shared-компонент).
     Где кнопка устроена иначе (daily-card) — тот же ключ через `t`.
   - Потребители точных совпадений переходят на ключи `shared`: «Try again» ×4 (константы `RETRY_LABEL`,
     `HOROSCOPE_RETRY_LABEL`, `RETRY` удаляются — config не держит текст), «Check your connection and come back…» ×3.
     Остальные строки этих экранов — английские до их задачи шага 3.
2. **`SegmentedControl`** — `options: readonly { value: T; label: string }[]`; значение — состояние,
   подпись — только текст и `accessibilityLabel`.
   - Значения — машинные: advisors `'all' | 'online' | 'topRated'`, sessions `'upcoming' | 'past'`, home
     `'today' | 'tomorrow'`; все сравнения (`filter-advisors.ts`, `use-advisors.ts`, `SessionsScreen.tsx`,
     `use-home.ts`) — по ним.
   - Подписи — через `t`: у advisors и sessions заводятся свои пространства (`advisors`, `sessions`) с одними
     подписями сегментов (правило: слайс заводит `config/locales` с первой строкой; полный перенос — шаг 3);
     home берёт «Today» / «Tomorrow» из `shared` (`day.today`, `day.tomorrow` — понадобятся и части B).
3. **`AuthError` хранит код**, не текст: `new AuthError(code, cause)`, `message` = код (для логов).
   - `authErrorKey(code)` в `shared` — код → ключ `auth.*` пространства `shared` (12 фраз из `handleAuthError`,
     английский дословно); неизвестный код → `error.generic`.
   - phone-auth и verify-otp держат в состоянии код / ошибку и переводят при рендере — смена языка
     перерисовывает текст. Литерал `use-phone-auth.ts:188` → `error.generic`.
4. **Пуши и каналы Notifee** (`features/push`) — пространство `push` (все 24 языка):
   - имена каналов «Messages» / «Announcements», запасной заголовок «Your advisor», тело пуша — **решение 2**;
   - headless: `displayMessageNotification` и создание канала ждут `i18nReady()` — текст на языке приложения и с
     включённым флагом;
   - при смене языка (Android) оба канала пересоздаются с тем же id и новым именем (подписка на
     `languageChanged`), чтобы в системных настройках имя сменилось сразу.
   - Тексты кампаний из консоли Firebase не трогаем (пишет оператор).
5. **SMS**: `auth().setLanguageCode(currentLanguage())` прямо перед `verifyPhoneNumber`. С выключенным флагом —
   `'en'`. ga / mt: передаём код как есть; если у Firebase нет шаблона — проверяется в маноре (`AURAI-0010` §11).
6. **Линтер**: `i18next/no-literal-string` `error` — `shared/ui/back-button`, `features/push`, `shared/api/firebase`.
7. **Тесты**: новые ключи в тестах полноты (сами), `BackButton` (метка на de), сегменты (значение ≠ подпись,
   подпись на de), `authErrorKey` (все коды + неизвестный), push: заголовок/тело/канал на de, ожидание
   `i18nReady`, пересоздание каналов при смене языка, `setLanguageCode` перед `verifyPhoneNumber`. Английские
   ожидания существующих тестов не меняются, кроме решения 2.

## B. Форматтеры по CLDR (`AURAT-0159`, если владелец за деление)

1. **Генератор** `scripts/i18n/generate-formats.mjs` (Node ICU) → `src/shared/lib/i18n/formats.generated.ts`:
   по языку — десятичный и групповой разделитель, минимальная группировка, шаблон USD (символ, сторона, пробел),
   месяцы (полные — в форме «с числом», короткие — отдельно стоящие), дни недели (полные, короткие), порядок
   частей длинной даты с литералами, разделитель времени. Во время работы — только сборка строк, без `Intl`.
   - U+202F → U+00A0 (в Hanken нет U+202F; снять, если `AURAT-0156` его добавит);
   - ручные короткие месяцы для bg и lt (CLDR даёт «08»), проверить cs / fi — `shared/config`.
2. **Drift-тест** (Jest, полный ICU): каждая функция × 24 языка == Node `Intl` на наборе сумм (0, 5, 199, 123 456,
   100 000 000 центов), всех месяцах и днях, нескольких временах — с явным списком подмен из п. 1.
3. **API с явным языком** (`shared/lib`): `formatUsdMinor(minor, language)`, `formatUsd`, `formatUsdMinorCompact`,
   `formatClockTime(date, language)` (24h; разделитель — **решение 3**), `formatFileSize(bytes, language)`
   (десятичный разделитель языка, единицы — ключи `shared`: fr «Ko / Mo»), `longDateLabel(iso, language)`,
   `shortDateParts(iso, language)` → `{ weekday, day, month }` для полосы брони и календарных блоков,
   `relativeDay(startsAt, now)` → данные `{ kind: 'today' | 'tomorrow' | 'inDays', days }` +
   `relativeDayLabel(day, language)` (плюралы в `shared`). `useLanguage()` — язык на экране (псевдоязык → en).
4. **Все 33 файла-потребителя**: хуки берут `useLanguage()`, lib получает `language` параметром, мемо подписей
   зависят от языка. Таблицы `slots.ts` и `home/lib/format-date.ts` удаляются — всё через shared.
   Английский вывод не меняется ни на символ, кроме **решения 4**.
5. Заглавные: домашняя дата — `toLocaleUpperCase(language)` вместо `textTransform` (греческие ударения).
6. Тесты: drift, каждая функция на en/de/fr/pl/lt/bg, реактивность (смена языка → новая подпись в хуке).

## Решения владельца

1. **Делить на две задачи?** Рекомендую да (A здесь, B — `AURAT-0159`).
2. **Тело пуша о сообщении.** Сейчас заголовок «Mia», тело «sent you a new message» — половина фразы; в pl, cs,
   sk, hr, sl, lt, lv глагол требует рода консультанта, которого приложение не знает. Рекомендую: тело
   «New message» (заголовок — имя, как сейчас). Иначе — «{{name}} sent you a message» в теле с нейтральной
   конструкцией в каждом языке (длиннее, имя дважды).
3. **Время в da и fi.** CLDR пишет `16.05`; сейчас везде `16:05`. Рекомендую CLDR (так читают в этих странах; 24h
   сохраняется везде).
4. **Порядок английской даты.** Источник смешивает «Friday, August 14» и «Friday · 30 May» (шапка Home). Рекомендую
   один формат CLDR en: шапка Home станет «FRIDAY, MAY 30». Иначе — шапка Home остаётся своей формой только в
   английском.

## Не входит

- Строка Language и лист — `AURAT-0158`. Названия стран — задача «вход» шага 3.
- Остальные строки слайсов («N min», «/min», ошибки экранов…) — шаг 3.
- Нативные объявления, включение флага — шаг 4. Файлы `AURAT-0156` (шрифты, `FORBIDDEN` в `translations.test.ts`).

## Проверка

- **Slave:** `npm run lint` (0 / 0), `npx tsc --noEmit`, `npx jest --no-watchman` (все зелёные),
  `node scripts/i18n/translate.mjs check src/shared/config/locales` (и новых пространств).
- **Манор, dev-сборка, меню «i18n: next language» на de / pl / el / псевдоязыке:** кнопка «назад» читается
  VoiceOver/TalkBack на языке; сегменты Advisors / Sessions / гороскоп переключаются и фильтруют; ошибка неверного
  кода на языке; пуш о сообщении в фоне (Android) и имя канала в настройках после смены языка; SMS на реальный
  номер после смены языка (тестовые номера SMS не шлют).
