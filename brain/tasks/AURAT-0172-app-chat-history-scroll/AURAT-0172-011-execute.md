# AURAT-0172-011 — execute: реализация по spec v3

Дата: 2026-11-07. Слот `slave-3`, ветка `feature/AURAT-0172-app-chat-history-scroll` @ `9d3a65e` (develop с 0169).
Работа лежит в stage, не закоммичена: коммит — только с одобрения владельца.

## Проверки в слоте

- `npm run lint` — чисто; `npx tsc --noEmit` — чисто.
- `npx jest` — **2979 / 2979**, в том числе под закреплённым поясом Europe/Kyiv (весь набор).
- `node scripts/i18n/generate-formats.mjs --check` — таблицы совпадают с Node 22.23.0 / CLDR 48.0.
- `translate.mjs check` — 0 запрещённых форм. Советы по новым строкам — только падежные формы термина «message» (lt
  «žinučių», fi «viesteihin») — это склонение, не другое слово.

## Что сделано

**`features/chat`**
- `ChatProvider`: состояние истории треда (`historyOf` → `ThreadHistory { loadingOlder, reachedStart, olderFailed,
  firstSyncPending }`), `loadOlder` / `retryOlder` / `resumeOlder`.
- Поколение = `эпоха:обрезки`. Эпоха растёт на каждой новой личности и не обнуляется. Запрос владеет
  `loadingOlder` по токену.
- `syncThread` разделён: `readThread` проверяет поколение после каждого `await`, а `syncThread` хранит промис
  синхронизации, к которому присоединяется `loadOlder` на пустом треде.
- `reachedStart` — только от первого ответа без курсора (< 50), от короткой старой страницы или от страницы без новых
  после дедупа.
- Раунды удалений: при 200 id — `limit: 1`, текущий `after`, не больше 5, с проверкой поколения.
- Смена языка (`onLanguageChange`, провайдер): обрезка по числу (> 50 серверных) и новое поколение. Тред без обрезки,
  но с `loadOlder` в полёте, тоже получает новое поколение. Ответ на другом языке выбрасывается. `spreadLanguages`
  `loadOlder` не трогает.
- `olderFailed` снимается на `onOpen` сокета и на `AppState 'active'`.
- `lib/trim-thread.ts` (`trimThread`, `serverCountOf`), `config/constants.ts` (`DELETED_IDS_PAGE`,
  `DELETION_ROUNDS_MAX`), `api/chat-api.ts` — параметр `before`.

**`screens/chat-thread`**
- Перевёрнутый `FlatList` с `maintainVisibleContentPosition`. Порог `AT_BOTTOM_DP = 80` один на всё; на Android он
  переводится в px.
- `lib/layout-thread.ts` — строки от нового к старому, ключ `day-<YYYY-MM-DD>-<n>`, будущий день — сегодня.
- `lib/classify-arrivals.ts` — что пришло в новейший конец; ключ отправки `idempotencyKey` защищает от смены
  local → server.
- `model/use-thread-scroll.ts`: зоны, «у верха», точка, кнопка, фокус диктора после перехода, перезапрос, прокрутка
  после своей отправки, pop-in.
- `model/use-today-key.ts` — полночь календарём, `AppState`, поздний день → `Date.now()`.
- `usePopIn(enabled)` — флаг пропом в `MessageBubble` / `SpreadMessage` / `SessionInviteMessage`.
- `ui/DaySeparator` (header), `ui/HistoryFooter` (один View; iOS — `announceForAccessibilityWithOptions`; Android —
  live region только на строке повтора и только на экране), `ui/JumpToLatestButton` (`CircleButton`, `chev` на 90°,
  teal-точка, fade `durations.fast`, размонтирование), `ui/caption-style.ts`.
- Приветствие: при `reachedStart` или (нет серверных и первая синхронизация не идёт).

**`shared`**
- `dayLabel`, `dayMonthYearLabel`. Шаблон `dayMonthYear` и `{y}` — в генераторе и `fillDatePattern`; таблица
  перегенерирована, не правлена руками.
- Токены `theme.jumpToLatest { size 40, icon 18, dot 10, dotRing 2 }`.
- `day.yesterday` на 24 языках (переводы веба, `message:yesterday`); JSDoc `day.today` — все четыре места.

**Строки `chat-thread`** — `history.loading` / `failed` / `failedLabel` / `retryHint`, `jumpToLatest`,
`jumpToLatestNew`, на 24 языках. Регистр и форма кнопок — по правилам; `failed` во всех языках ≤ 66 символов
(`@max 70`) и начинается с `failedLabel ·`.

## Отклонения и находки (по сравнению со спекой)

1. **Пояс в Jest — глобально.** `process.env.TZ` в файле теста не действует: у каждого файла Jest своя копия
   `process.env`. Поэтому `jest.global-setup.js` ставит `Europe/Kyiv` до запуска воркеров. Весь набор (2979) под ним
   зелёный.
2. **bg, год.** CLDR (и `formatToParts`) ставит перед «г.» U+202F, а `format()` в V8 — обычный пробел. Таблица
   держит вариант CLDR; в drift-тесте это исключение записано по имени (`YEAR_SPACE_EXCEPTIONS`).
3. **Перезапрос уточнён.** Хук перезапрашивает, только если число серверных сообщений не изменилось с начала
   запроса: страницу выбросили, сбросили или сняли ошибку. Если принятая страница выросла, иначе ушла бы лишняя
   страница до того, как список измерил новый контент; повторный запрос тогда делает сам список
   (`onEndReached` на смену длины). Есть тест.
4. **Фокус после «вниз».** Каждая строка обёрнута в одинаковый `View` — ref на новейшую строку, и строки не
   перемонтируются от переноса ref. Сработает ли `sendAccessibilityEvent('focus')` на обёртке — проверка на
   устройстве, п. 8.
5. **Неподписанный тред** (без входа и не из `initialThreads`): первая синхронизация не считается идущей, приветствие
   видно (как раньше).

## Что осталось

- Ревью кода.
- Коммит (с одобрения владельца) → мёрж в develop (с одобрения, через merge gate) → проверка на устройстве в маноре
  (iOS и Android), список — `009-spec-v3`, пп. 1–13. Главный риск — mVCP в перевёрнутом списке на Android
  (пп. 2–5) и фокус диктора (пп. 2, 8).
