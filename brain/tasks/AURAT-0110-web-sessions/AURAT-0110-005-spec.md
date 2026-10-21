# AURAT-0110-005 — Spec: страница `/sessions` в aura-web

Date: 2026-10-20
Type: task (строка `AURAF-0020-009`, колонка UI). Новой фичи нет.
Status: draft — на одобрение владельцу

## Цель

Вошедший человек видит свои сессии (Upcoming / Past), открывает одну (`/sessions?id=`),
переносит её, отменяет с возвратом на баланс, сохраняет в календарь и оставляет отзыв
советнику; изменения с сокета (`session.updated`) видны сразу. Деньги — сервера (hard rule 7):
возврат до отмены — только оценка по правилу, перенесённому из приложения; после — серверный
`refundedMinor`; баланс — из ответа. BFF и contracts **не меняются** (`004`); пробелы — в конце,
владельцу для `aura-app-manor`.

Решения 1–14 — в конце, у каждого варианты и рекомендация. «Что делаем» написано по
рекомендациям.

## Что делаем

### 1. Данные — `entities/session` (дополнение)

- `shared/api/base-api.ts`: теги `Session` (список и сессия по id), `Review`, `Advisors`.
- **api**: `getSessions` — `GET /v1/sessions` → `SessionsResponse.parse`, тег `Session`.
  `getSession(id)` — тот же список (как сейчас), тег `{Session, id}`; когда маршрут `AURAT-0111`
  выкатится — `GET /v1/sessions/:id` → `SessionResponse.parse`, 404 → `null`. Подъём контрактов
  `v0.22.0 → v0.23.0` (тег уже в origin) — первым отдельным коммитом (решение 13). `bookSession` дополнительно инвалидирует `Session`.
- **lib** (порт копией с тестами, шапка `// Ported from aura-app <path> (<ID>)`):
  - `session-state.ts` — `sessionState`, `remainingSeconds`, `secondsUntilStart`, `minsLeft`,
    `minsUntilStart`, `isUpcoming`, `isPast` (`AURAD-0009`, `AURAT-0015`);
  - `refund.ts` — `refundEstimate(session, now)` → `{tier: 'full' | 'late', refundMinor}`,
    ≥ 24 ч — весь `costMinor`, иначе `floor/2` (`AURAD-0009`, `AURAT-0017`);
  - `labels.ts` (из `screens/session-detail/lib/labels.ts`) — только логика без английских строк:
    `windowStart`, и `pastMinutes` (фактическая длительность из `format-session.ts`);
  - `relativeDay` из `shared/lib/dates.ts` приложения → в вебе ключ дня (`today | tomorrow |
    inDays`) поверх уже перенесённого `daysUntil`; текст — из локалей;
  - веб-собственное: `splitSessions(list)` → `{upcoming (ближайшие сверху), past}`, CANCELLED
    скрыты; `canReschedule(session, now)` — SCHEDULED и ≥ 4 ч до текущего слота (решение 2);
    `offerRestored(session, refundedMinor)` — `refundedMinor === costMinor && saving > 0`;
    `sessionIcs` получает `SEQUENCE` (минуты от эпохи на момент файла), чтобы файл после переноса
    обновлял событие с тем же `UID`.
- **model**: `useSessions()` → `{status, upcoming, past, retry}` (404 биллинга → пусто, как
  приложение); `useSessionClock()` — `serverNow()` с тиком 60 с (как `DETAIL_TICK_MS`);
  `applySessionEvent(event)` — `session.updated` в кэш: заменить/вставить в `getSessions`
  (порядок `startsAt` по убыванию), `upsert getSession`; `refreshSessions()` — инвалидирует
  `Session` (перечитываются только открытые запросы — одна выборка, без веера, лимит 120/мин).
- **ui** (render-only): `SessionCard` (Upcoming), `PastSessionRow`, `SessionDetailCard` (hero +
  строки), `DayStrip` и `SlotGrid` — **подняты** из `features/book-session/ui/booking-form.tsx`
  (второй потребитель — перенос; `BookingForm` собирает их + длительности, поведение брони не
  меняется). Календарь: `useAddToCalendar(session, advisorName)` — `download` и заголовок события
  переезжают из `pages/booked` в `entities/session` (`download` → `shared/lib/download-file.ts`).

### 2. Сокет — владелец `app` (решение 12)

`useChatLive` из `entities/message` распадается: `app/session/use-live-socket.ts` держит один
`BffSocket` и раздаёт события по типу — `message.*`, `typing.*`, `presence.*` → `applyChatEvent`,
`session.updated` → `applySessionEvent`; на (пере)подключение, возврат во вкладку и `online` —
`syncAllThreads()` + `refreshSessions()`. `entities/message` экспортирует то, что сейчас делает
хук внутри (`applyChatEvent`, `syncAllThreads`, `socketClosed`, `chatLiveReset`,
`forgetAttachmentFiles`); тесты `use-chat-live` переезжают в `app/__tests__`, поведение чата то
же. Ветка `session.updated` в `applyChatEvent` уходит.

### 3. Перенос — `features/reschedule-session` (dialog `reschedule`)

- **api**: `rescheduleSession {sessionId, startsAt}` — `PATCH /v1/sessions/:id`,
  `BookSessionResponse.parse`; успех → `upsert getSession`, инвалидирует `Session`,
  `{Availability, advisorId}`, `Wallet` не трогает (денег нет); 400/409 → `{Availability}`.
- **model** `useReschedule(sessionId)`: сессия из `getSession`; сетка — `useAvailability(advisorId,
  session.bookedMinutes)` (блок сессии, без выбора длительности, без черновика брони); 14 дней с
  сегодня (решение 7); открывается на дне текущего слота, текущий слот не выбран и показан
  занятым (так отвечает availability); `changed` — выбран другой слот. Внутри 4 ч (по
  `serverNow`) — кнопка выключена с причиной (решение 2). Ошибки как в приложении: 409 — одна
  фраза на все причины («внутри 4 ч или время уже заняли»), 400 — «время больше нельзя
  забронировать», прочее — «попробуйте ещё раз»; после 400/409 — перечитка сетки, выбор сброшен.
- **ui** `RescheduleSheet`: «Current time» (дата · время · N min with {name}), заметка «Free up to
  4 hours before… {First} sees the new time», `DayStrip` + `SlotGrid`, превью «старое → новое»,
  «Pick a new time» → «Confirm new time». Успех — шторка закрывается, деталь показывает новое время
  (из ответа сервера).

### 4. Отмена — `features/cancel-session` (dialog `cancel`)

- **api**: `cancelSession(sessionId)` — `POST …/cancel` без тела, `CancelSessionResponse.parse`;
  успех → `upsert getSession`, инвалидирует `Session`, `Wallet`, `{Availability, advisorId}`, а
  при `offerRestored` — ещё `Pricing` (оффер вернулся у всех советников). 409 → перечитать сессию.
- **model** `useCancelSession(sessionId)`: оценка `refundEstimate(session, serverNow())` — только
  для SCHEDULED; фазы `confirm → sending → done | refused`; один запрос за раз (повтор — после
  ответа; у отмены нет ключа, BFF на повтор отвечает 409 — не двойной возврат).
- **ui** `CancelSheet`: «Cancel this session?», «Your N-minute private chat with {name} on {date}
  at {time} will be released.»; карточка возврата — «Full refund» (teal, shield) / «Late
  cancellation» (coral, clock), «about {amount} goes back to your **balance**» (решение 8), при
  полном возврате со скидкой — «Your welcome offer comes back too»; «We'll confirm the exact amount
  once the cancellation goes through.»; если перенос ещё доступен — «Just need another time?
  Rescheduling is free» (открывает `reschedule` вместо `cancel`). Без чипов причин (решение 3).
  «Keep it» / «Cancel session». После ответа — состояние результата в той же шторке: «Session
  cancelled», «{refundedMinor} is back in your balance» (или «Nothing was charged…» при 0),
  «Your welcome offer is available again» при `offerRestored`, кнопка «Done» (тоста в вебе нет).
  409 «уже началась» — текст приложения, кнопка выключена.

### 5. Отзыв — `features/write-review` (dialog `review`, новый вид в `DialogKind`)

- **api**: `getMyReviews` — `GET /v1/reviews/me` → `MyReviewsResponse.parse`, тег `Review`;
  `submitReview {advisorId, ratingTenths, text, anonymous, sessionId}` — `PUT
  /v1/advisors/:id/review` → `SubmitReviewResponse.parse`; успех → `Review`, `Advisors`
  (рейтинг и число в каталоге); 403 `review_not_eligible` → своё сообщение (решение 5).
- **config** (порт `features/advisor-review/config/review.ts`, `AURAF-0016`):
  `REVIEW_MAX_TEXT_LENGTH` из contracts (400), `REVIEW_COUNTER_WARN_AT = 40`, `TENTHS_PER_STAR = 10`;
  подписи звёзд — ключи локалей.
- **model** `useMyReview(advisorId)` (отзыв есть / нет / неизвестно), `useWriteReview`.
- **ui** `ReviewSheet`: «How was your reading with {First}?», 5 звёзд-кнопок (`role="radiogroup"`)
  с подписями, текст «Your review — optional» с обрезкой на 400 и счётчиком (coral < 40),
  `Toggle` «Publish anonymously» («Shown as "Anonymous · Verified client"» / «Shown with your
  name»), заметка о модерации (текст приложения), «Tap a star to rate» → «Submit review». Успех —
  шторка закрывается, строка Past показывает «Reviewed». Ошибка — шторка остаётся с текстом.
- Входы: только Sessions → Past (решение 6).

### 6. Страница — `pages/sessions` + `widgets/session-detail`

- `pages/sessions`: заголовок «Sessions», сегменты Upcoming / Past (`role="tablist"`), список
  слева; на desktop справа липкая панель `widgets/session-detail` для выбранной сессии (на обеих
  вкладках — решение 10); на телефоне выбор открывает шторку «Your session» с той же деталью.
  Выбор = `?id=` (`replace` на desktop, push на телефоне — Back закрывает шторку); без `?id=` на
  desktop выбрана первая предстоящая (URL не пишется). `?id=` чужой/отменённой/несуществующей
  сессии — пустая панель «This session is no longer here» (текст приложения), список на месте.
  Открытые `reschedule` / `cancel` / `review` — диалоги хоста `app` (один за раз): на телефоне
  шторка детали прячется, пока открыт диалог, и возвращается после.
- Upcoming-карточка (`SessionCard`, `React.memo`): дата-блок, имя, тег «−50%» при скидке,
  «{Weekday, Month D} · {HH:MM} · N min private chat», для ACTIVE — «In progress · N min left».
  Вопроса нет (поля нет в `Session`).
- Past-строка (`PastSessionRow`, `React.memo`): аватар, имя, «{24 May} · {фактические} min»;
  справа «Leave a review» (нет отзыва) или тег «Reviewed», и «Book again» → Book-шторка этого
  советника (решение 4). «Show more» по 24 (hard rule 5).
- Деталь (`widgets/session-detail`): plum hero — «{Today | Tomorrow | In N days} · private chat» /
  «In progress · N min left» (teal) / «Completed»; аватар, имя, роль; крупное время и «{long date}
  · N min»; строки «Paid from balance» (при скидке — зачёркнутая полная и оплаченная через
  `PriceTag`) и «Welcome offer saved». Кнопки: «Open chat» (teal, всегда; для ACTIVE — «Open
  session chat · N min left») (решение 1); для SCHEDULED — «Reschedule» (выключена внутри 4 ч с
  «Free reschedule closes 4 h before»), «Add to calendar», «Cancel session» (coral, текстом);
  для FINISHED — «Leave a review» / «Reviewed», «Book again». Сноска для SCHEDULED: «Free
  reschedule up to 4 h before · full refund up to 24 h before» (+ «— your welcome offer comes
  back too» при скидке). Без Join, Message, Reminder и плашки напоминаний (решения 1, 9).
- Пустые состояния (`EmptyState`, teal orb по README §6): Upcoming — «No sessions booked» / «Book a
  1:1 reading with an advisor and it will show up here.» / «Find an advisor» → каталог; Past — «No
  past sessions yet» / «Finished readings and your reviews will appear here.» Сегменты остаются.
  Ошибка загрузки без данных — «Couldn't load your sessions» + «Try again»; есть данные — они
  показываются. Советник вне каталога — «Your advisor» и монограмма; «Book again» не показан
  (решение 11).
- `pages/booked`: «Go to session» → `paths.sessions({id})` вместо «Open chat with {name}»
  (решение 14); «Add to calendar» — из `entities/session`.
- `app/router/router.tsx`: `ROUTES.sessions` → `SessionsPage`; `app/config/dialogs.ts`:
  `reschedule`, `cancel`, `review`.

### 7. Строки и тесты

- Новые неймспейсы `sessions-page`, `session-detail`, `reschedule-session`, `cancel-session`,
  `write-review` + ключи в `session`, `booked-page` — **сразу на 24 языках** (правило 9), плюралы
  `_one/_other/…`, суммы и даты — `Intl`. Регистрация в `I18N_NAMESPACES` и `vitest.setup.ts`.
- Unit: перенесённые `refund`, `session-state` с тестами приложения; `splitSessions`,
  `canReschedule`, `offerRestored`, `pastMinutes`, `ics` (`SEQUENCE`), `applySessionEvent`.
- Сценарии (`app/__tests__/sessions.test.tsx`, по тестам приложения `SessionsScreen`,
  `SessionDetailScreen`, `RescheduleScreen`, `WriteReviewScreen`): CANCELLED нигде; Past — фактическая
  длительность; ACTIVE нельзя перенести и отменить; сетка — блок сессии; открывается на её дне;
  нельзя подтвердить без другого слота; PATCH на выбранный; 409 — одна фраза; > 24 ч — full,
  < 24 ч — late; после отмены — серверная сумма, а не оценка; полная со скидкой → кошелёк и pricing
  перечитаны; уже начатая — отказ с причиной; отзыв в десятых, звёзды без текста — валидно, счётчик
  с 40, ошибка оставляет текст; `session.updated` меняет карточку без перечитки; гость → GuestGate;
  `?id=` выбирает сессию.
- `npm ci`, `lint` (eslint + steiger), `typecheck`, `test`, `build` — в слоте. Живой BFF — только в
  маноре после merge.

## Не делаем

Живая платная сессия в треде (баннер, таймер, Extend, раннее завершение) — новая строка (см.
просьбы); входы в отзыв с профиля и из чата; напоминания и web push; аналитика; пагинация с
сервера; Home «Next session» (`AURAT-0112`).

## Решения владельцу

1. **Join / Message.** (A) как приложение и мобильный хендофф: одна «Open chat» всегда, для ACTIVE —
   «Open session chat · N min left», без Join и Message; (B) веб-хендофф: Join с T−5 мин до конца +
   Message. **Рекомендую A**: сессия идёт в том же треде (`AURAD-0009`), Join вёл бы туда же, а
   в треде веба живой сессии ещё нет — выключенная до T−5 кнопка обещает «вход», которого нет.
2. **Перенос внутри 4 ч.** (A) веб-хендофф: кнопка выключена по `serverNow` с «Free reschedule closes
   4 h before», 409 сервера всё равно обрабатывается; (B) приложение: решает только сервер, шторка
   открывается, 409 объясняет. **Рекомендую A**: часы веба идут по BFF (`AURAF-0020-017` ✓), а
   открывать форму, которую сервер точно отвергнет, — лишний шаг. Последнее слово — сервера.
3. **Чипы причин отмены.** (A) не показывать (как приложение) — передать некуда, у отмены нет тела;
   (B) показывать и не отправлять; (C) показывать + задача BFF на `reason`. **Рекомендую A**, причина
   — в пробелы BFF; «Rescheduling is free» оставить (правда и полезно).
4. **Past-строка.** (A) веб: «Leave a review» / «Reviewed» + всегда «Book again»; (B) приложение: одна
   кнопка «Review» → «Open chat». **Рекомендую A**: Book-шторка уже есть (`AURAT-0107`), чат — из
   детали.
5. **Право на отзыв.** Сервер требует своё сообщение советнику, хендофф — «после завершённой
   сессии». (A) «Leave a review» у каждой завершённой без отзыва, 403 → «Reviews open once you've
   sent {First} a message» + «Open chat»; (B) скрывать кнопку, пока не известно своё сообщение
   (нужна история треда — веер запросов). **Рекомендую A** + пробел BFF (завершённая сессия должна
   давать право).
6. **Входы в отзыв с профиля и из чата.** (A) только Past в этой задаче, профиль и тред — новые
   строки; (B) все три сейчас (нужно `use-review-access` по треду, карточка после маркера конца,
   машиночитаемого маркера нет — `AURAF-0020-020`). **Рекомендую A.**
7. **Дни переноса.** (A) 14 с сегодня, как бронь (`AURAT-0107-006` §1) и приложение; (B) 7 с завтра
   (веб-хендофф). **Рекомендую A** — одна сетка, весь горизонт BFF.
8. **Тексты возврата.** (A) на баланс («goes back to your balance», «Full refund» / «Late
   cancellation») — мобильный CHECKOUT rule 6, `AURAD-0009`; (B) «to your card» веб-хендоффа.
   **Рекомендую A** — карты нет, возврат идёт в кошелёк.
9. **Reminder и «email and push 30 min before».** (A) не показывать: BFF человеку ничего не шлёт;
   напоминанием служит «Add to calendar»; (B) показывать как в хендоффе. **Рекомендую A.**
10. **Панель на вкладке Past.** (A) деталь работает на обеих вкладках (Completed, оплачено, Open
    chat, отзыв, Book again) — `?id=` завершённой открывается так же; (B) на Past без панели, строка
    ведёт в чат. **Рекомендую A.**
11. **Советник не в каталоге.** (A) показать сессию с «Your advisor» и монограммой — это деньги
    человека, перенос и отмена работают; (B) скрыть, как приложение. **Рекомендую A.**
12. **Где `session.updated` попадает в кэш.** (A) `app` владеет сокетом и раздаёт события по
    сущностям (`use-live-socket.ts`); (B) `useChatLive({onEvent, onOpen})` — `app` передаёт
    обработчик сессий в хук чата. **Рекомендую A**: сокет один на приложение, а не на чат; `app` —
    единственный слой, которому можно знать обе сущности.
13. **`GET /v1/sessions/:id`.** Тег `v0.23.0` (`SessionResponse`) уже в origin контрактов; маршрут
    BFF (`AURAT-0111`) ещё не влит в `develop` / `bff-dev`. (A) поднять тег сейчас отдельным
    коммитом, `getSession` — на списке; на `GET /:id` переключить в этой задаче, если `AURAT-0111`
    выкатится до нашего merge, иначе — отдельной мини-задачей; (B) ждать `AURAT-0111` и сразу читать
    по id. **Рекомендую A** — не блокируемся, переключение — одна точка (`getSession`).
14. **Booked.** (A) «Go to session» вместо «Open chat with {name}» (+ «Add to calendar») — по
    хендоффу, чат — из детали; (B) третья кнопка рядом с чатом. **Рекомендую A.**

## Пересечения

`AURAT-0112` (slave-3): Home «Next session» читает тот же список — `getSessions` / `useSessions`
вводит та задача, что влита первой; вторая перестраивается на неё. `AURAT-0108` (slave-1): общие
`app/config/dialogs.ts`, `shared/model/dialog.ts`, локали `app`; `features/pay` не трогаю. Подъём
`DayStrip`/`SlotGrid` трогает `features/book-session/ui` — `AURAT-0108` его не меняет (проверю при
merge).

## Пробелы BFF / contracts — в бэклог `AURAF-0020` (ID задач — `aura-app-manor`)

1. **`PATCH /v1/sessions/:id` не проверяет занятость самого человека** у других советников (бронь
   проверяет) — перенос может наложить две его сессии. Дефект; предлагаю отдельную задачу BFF.
2. Отказы переноса и отмены без `code` (одна фраза на 409) — расширить `AURAF-0020-025`.
3. Нет `offerRestored` в ответе отмены — веб выводит из `refundedMinor === costMinor` и скидки.
4. Нет предпросмотра возврата — веб считает оценку правилом, скопированным из приложения.
5. Availability не исключает переносимую сессию — её слот «занят» (сейчас совпадает с хендоффом:
   «текущий слот зачёркнут»; станет проблемой при блоках длиннее шага сетки).
6. Право на отзыв — только своё сообщение; завершённая сессия его не даёт (хендофф — даёт).
7. У отмены нет тела (`reason`) — только если владелец захочет чипы.
8. Напоминаний человеку нет (email / push) — продуктовое решение.

## Просьба владельцу — `aura-app-manor`

- Строка `AURAF-0020` под **живую платную сессию в треде** веба (баннер, таймер из `endsAt`,
  Extend, раннее завершение) и её задача.
- ID под пробел №1 (BFF, перенос и занятость человека); остальные — строками бэклога при закрытии.
- Если решение 6 = A — строка «отзыв с профиля и из треда в вебе».
