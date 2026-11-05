# AURAT-0159-004 — context

Дата: 2026-11-05. Код — slave-0 `feature/AURAT-0159-app-i18n-formatters` @ `d5b25bc`.

## Что есть сейчас

- `shared/lib/format.ts`: `formatUsd` / `formatUsdMinor` / `formatUsdMinorCompact` — `'$' + toFixed(2)`;
  `formatClockTime` — «HH:mm» руками; `formatFileSize` — «248 KB» / «1.2 MB». Без языка.
- `shared/lib/dates.ts`: английские таблицы `WEEKDAYS`, `MONTHS_LONG`, `MONTHS`; `longDateLabel` («Friday, August
  14», US-порядок), `monthShort`, `dayNumber` («02»), `relativeDay` → готовая английская строка «Today» / «Tomorrow» /
  «In 3 days».
- Ещё две таблицы: `features/booking/lib/slots.ts` (`Sun…Sat`, `Jan…Dec`, «Today» прямо в данных полосы),
  `screens/home/lib/format-date.ts` (шапка «Friday · 30 May», UK-порядок; `useMemo([])` замораживает язык).
- Вызовы: `formatUsd*` — 45 в 20 файлах; даты / время / размеры — ещё ≈ 20 файлов. Месячные/дневные строки
  склеиваются в lib и model (`pastDate` «24 May», Reschedule «16:05, Sep 04», `DateStrip` a11y
  «Fri 04 Sep»).
- Чат: `ChatMessage.time` — строка, отформатированная при маппинге (`map-message.ts`, `ChatProvider.tsx:448`) →
  смену языка не переживёт; читают `MessageBubble`, `ChatListRow`, `ImageViewer`.
- `features/chat/config/attachments.ts`: `MAX_ATTACHMENT_LABEL` «25 MB» считается на уровне модуля.
- `textTransform: 'uppercase'` на датах: шапка Home, `DateStrip` (день недели), месяц в блоках `BookedScreen` и
  `UpcomingSessionCard`, глаз-строка `UpcomingSessionCard` («TODAY · 30 MIN CHAT»).
- Регион: `screens/phone-auth/lib/device-country.ts` — `regionOfLocale` (+ `@rg=` iOS) и `deviceLocale`
  (`I18nManager` → `Intl…resolvedOptions().locale`); `startCountry` поверх этого добавляет SIM → сеть → пояс и
  фильтр по `SMS_REGIONS` с запасной Испанией — это «страна номера», не настройка форматов.
- i18n: `currentLanguage()` есть, `useLanguage()` нет; в `shared` уже `day.today` / `day.tomorrow` (0157).

## CLDR в Node (22.23, ICU 78.2, CLDR 48) — что даст генератор

- Деньги: en «$1.99», de «1,99 $», fr «1,99 $US», nl «US$ 1,99», hu / pl / hr / it / ro / sk / lt «1,99 USD»,
  bg «1,99 щ.д.», ga «$1.99», mt «US$1.99», en-GB «US$1.99» (поэтому деньги en — из en). Группировка с
  минимумом 2 у es / pl / pt / hu / lv / bg («1234,50»).
- Время h23: «16:05» везде, кроме da / fi «16.05».
- Длинная дата: en «Friday, September 4», en-GB «Friday 4 September», pl «piątek, 4 września», hu «szeptember 4.,
  péntek», lt «rugsėjo 4 d., penktadienis» — порядок и литералы разные, месяц в форме «с числом».
- Короткая дата (MMMd): de «4. Sept.», en-GB «4 Sept», cs «4. 9.», fi «4.9.», bg «4.09», lt «09-04» — у cs / fi /
  bg / lt цифрами (так там и пишут).
- Отдельно стоящий короткий месяц (блоки «число над месяцем»): bg и lt — «01…12» (непригодно, нужны ручные), cs
  «zář», fi «syys» / «maalis» / «marras» (годятся), lv «janv.», hu «szept.».
- Короткий день недели: lv «Ceturtd.» (8 знаков в ячейке 58pt, 11px заглавными — не влезет), hu «P», et «R».
- `fr` — U+202F в группах; шрифты 0156 его рисуют.

## Противоречие

`AURAT-0157-008`: регион — из `Intl…resolvedOptions().locale`; диспетчер: не дублировать `device-country.ts`. Это
совместимо: общая часть — именно `deviceLocale` + `regionOfLocale`; цепочка SIM → сеть → пояс отвечает на другой
вопрос. → решение в спеке.
