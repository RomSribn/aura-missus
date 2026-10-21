# AURAT-0110-007 — Execute

Дата: 2026-10-20
Слот: `slave-2`, ветка `feature/AURAT-0110-web-sessions` (от develop `79bf311`). Не закоммичено —
всё в индексе (281 файл в master), ждёт ревью владельца.

## Сделано (по `005` + `006`)

- **Контракты** `v0.22.0 → v0.23.0` (`package.json`, lock) — при коммите отдельным первым коммитом.
- **shared**: теги `Session`, `Review`, `Advisors`; `downloadFile`; `relativeDay` (данные, слова — в
  локалях), `formatMonthShort` / `formatDayMonth` / `formatShortDate`; вид диалога `review`;
  токены `--sessions-panel-w(-narrow)`; `Avatar.src` принимает `undefined`.
- **entities/session**: порт копией с тестами — `session-state.ts`, `refund.ts` (`AURAD-0009`,
  `AURAT-0015/0017`), `labels.ts` (`windowStart`, `pastMinutes` — из `session-detail/lib/labels.ts` и
  `sessions/lib/format-session.ts`, только данные); веб — `sessions.ts` (`splitSessions`,
  `withSession`, `canReschedule` 4 ч, `sessionOfferPct`, `offerRestored`), `config/sessions.ts`;
  `getSessions` (тег списка) и `getSession` с тегом по id; `sessionUpdated` (ответ / сокет → кэш на
  месте), `refreshSessions`; `useSessions`, `useSessionClock` (60 с), `useAddToCalendar` (переехал из
  Booked); `.ics` с `SEQUENCE`; UI — `SessionCard`, `PastSessionRow`, `SessionTimePicker` (поднят из
  `BookingForm`, ключи `date`/`time` переехали из `book-session` в `session.picker` во всех 24 языках
  без перевода заново; ключи календаря — из `booked-page` в `session.calendar`).
- **app**: сокет — `app/session/use-live-socket.ts` (`useChatLive` удалён; чат-события → чат,
  `session.updated` → `sessionUpdated`; на (пере)подключение / вкладку / online — синк тредов +
  `refreshSessions`); тест переехал (`use-live-socket.test.tsx`) + сценарий `session.updated`;
  роут `/sessions`; диалоги `reschedule`, `cancel` (`CancelDialog`: «Rescheduling is free» открывает
  перенос), `review`; неймспейсы в `I18N_NAMESPACES` и `vitest.setup.ts`.
- **features/reschedule-session**: `PATCH`, 14 дней с сегодня, блок сессии, без черновика, открыт на
  дне слота, свой слот — занят; выключено внутри 4 ч; 409 — одна фраза, 400 — «нельзя», перечитка сетки.
- **features/cancel-session**: оценка по правилу; после — `refundedMinor`, «оффер вернулся» по
  `offerRestored`; перечитка кошелька, сетки, при оффере — pricing; результат в той же шторке («Done»).
- **features/write-review**: `getMyReviews`, `submitReview` (десятые, текст ≤ 400 со счётчиком,
  анонимность), 403 `review_not_eligible` → текст + «Open chat»; `ReviewAction` («Leave a review» /
  «Reviewed»); каталог перечитывается (`Advisors`).
- **features/book-session**: `BookAgainButton`; `BookingForm` = длительности + `SessionTimePicker`.
- **widgets/session-detail**: hero (день / идёт · N min left / Completed), оплата и экономия, Open chat
  (у идущей — «· N min left»), Reschedule (гаснет за 4 ч с причиной), Add to calendar, Cancel, сноска;
  у завершённой — отзыв и Book again.
- **pages/sessions**: Upcoming / Past (tablist), desktop — липкая панель, телефон — шторка по `?id=`
  (push, Back закрывает); сессия, ушедшая из списка (отменена), отпускается; «Show more» по 24;
  пустые состояния, ошибка без данных.
- **pages/booked**: «Go to session» → `/sessions?id=`; календарь из сущности.
- Строки — на 24 языках (переводчики по группам, регистр и термины — по существующим файлам языка).

## Проверка в слоте

`typecheck`, `lint` (eslint + steiger) — чисто; `build` — ок; `test` — 1052/1052 (при `TZ=America/
Los_Angeles`). В CEST после ~21:00 падает **старый** `advisors.test.tsx` («the next 4 slots»): фикстура
`+3 ч` / `+26 ч` уходит за «Tomorrow» — зависит от времени суток, к задаче не относится.

## Заметки

- Переводчики местами перестроили фразы, чтобы имя советника не склонялось (cs, sk, sl, pl, hr, hu, fi,
  et, lt, lv): «{{when}} · N min · {{name}}», «{{name}} — …?». Ревью носителем приветствуется.
- `AURAF-0020`: строку 009 (UI ✗ → ✓) и бэклог 029–035 (+ к 025 — отказы переноса/отмены без `code`)
  внесу при закрытии, после проверки в маноре.
- В маноре проверить (после merge, против `bff-dev` с включённым биллингом): список и деталь, перенос
  (сетка, 409 внутри 4 ч), отмена (> 24 ч / < 24 ч, оффер), отзыв (и 403 без своего сообщения),
  `session.updated` из приложения, Booked → «Go to session», телефон (шторка, Back).

Дальше: ревью владельца в IDE.
