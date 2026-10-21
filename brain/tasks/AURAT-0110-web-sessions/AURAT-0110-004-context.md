# AURAT-0110-004 — Context

Дата: 2026-10-20

## Веб сейчас (develop `79bf311`, ground truth)

- `/sessions` — в роутере `element: null` под `PrivateRoute`, гейт `sessions` (GuestGate
  «Your sessions live here») уже есть; `paths.sessions({id})` и `parseSessionsSearch` — в
  `shared/config/routes.ts`.
- `entities/session`: `getSessionPricing`, `getAvailability`, `bookSession`, `getSession`
  (поиск в `GET /v1/sessions`, без тегов); `lib/{saving,slots,ics,offer}`;
  `ui/{SessionSummary,SessionInviteCard}`. Тегов `Session`/`Review` в `baseApi` нет.
- `pages/booked`: «Open chat with {name}» + «Add to calendar»; `download()` и заголовок
  события — в модели страницы; «Go to session» отложен до этой строки (`AURAT-0107-006` §6).
- Сокет — `entities/message/model/use-chat-live.ts` (`useChatLive`, вызывается из
  `app/session/use-account-session.ts`); `session.updated` в `applyChatEvent` — `return`.
- `features/book-session/ui/booking-form.tsx` — длительности + полоса дней + сетка; вторым
  потребителем дней/сетки станет перенос (feature → feature запрещён).
- `shared/model/dialog.ts`: виды `reschedule`, `cancel` уже объявлены, не зарегистрированы;
  вида `review` нет. Тоста в вебе нет. `shared/ui/Stars` — только показ.
- В слоте нет `node_modules` (preflight пуст) — `npm ci` перед исполнением.

## BFF (manor `aura-bff`, только чтение)

- `GET /v1/sessions` — все статусы, `startsAt` по убыванию, до 100, без параметров.
- `PATCH /v1/sessions/:id {startsAt}` → `{session, balanceMinor}`; 404 чужая; 409 «Only a
  scheduled session…», 409 «…within 4h of its start» (4 ч от **текущего** слота, ≥ включительно),
  400 сетка / lead 30 мин / горизонт 14 (+1 день), 409 «slot has just been taken». Занятость
  самого человека у **других** советников **не проверяется** (у брони проверяется).
  Availability **не исключает** переносимую сессию (её слот — `available:false`).
- `POST /v1/sessions/:id/cancel` — без тела → `{session, refundedMinor, balanceMinor}`; можно,
  пока SCHEDULED и `startsAt > now` (4 ч к отмене не относятся); ≥ 24 ч — весь `costMinor`,
  иначе `floor(costMinor/2)`; 409 начатая / уже отменённая. Предпросмотра нет. Оффер
  возвращается только при полном возврате сессии со скидкой (`first-session-offer.query.ts`).
- Ошибки — тело Nest `{statusCode, message}` без `code`; код есть только у
  `review_not_eligible`.
- `Session`: `id, advisorId, status, bookedMinutes, priceMinorPerMinute, costMinor, startsAt,
  startedAt, endsAt, finishedAt, finishReason` — **нет** `question`, `refundedMinor`,
  `startNow`.
- `session.updated {advisorId, session}` — бронь, перенос, отмена, продление, раннее
  завершение, старт и конец счётчика; только сокет.
- `PUT /v1/advisors/:id/review {ratingTenths 10–50 кратно 10, text ≤ 400, anonymous,
  sessionId?}` → `{review}`; 403 `review_not_eligible` — нет **своего** сообщения советнику
  (сессия не нужна и не достаточна); звёзды — сразу, текст — после модерации, автору статус
  не виден; один отзыв на советника, повтор правит. `GET /v1/reviews/me` →
  `{advisorId, ratingTenths, anonymous, hasText, …}` (текста нет).
- Напоминаний человеку нет (только заметка staff за 5 мин). Лимит 120/мин на IP, общий.
- `AURAT-0111` (aura-bff-manor slave-2) — спека 005 на одобрении: `v0.23.0`,
  `SessionResponse {session}`; тег `v0.23.0` уже в origin контрактов (`65183ff`), маршрут BFF ещё не
  влит.

## Приложение (aura-app, только чтение)

- Список: Upcoming = SCHEDULED+ACTIVE (ближайшие сверху), Past = FINISHED; CANCELLED нигде;
  сессии с советником вне каталога молча выкидываются; перечитка на фокусе, сокета нет.
- Карточка Upcoming: «{relativeDay} · N min chat» / «In progress · N min chat», Reschedule
  (не для live) + Details. Past: «24 May · 22 min» (фактическая длительность), одна кнопка
  «Review» → после отзыва «Open chat»; «Book again» заменён сознательно.
- Деталь: тик 60 с; состояния `scheduled/active/ended` (`session-state.ts`); строки Date,
  Time, Format, Paid from balance, Welcome offer saved; Reschedule + Cancel только в
  `scheduled`; внизу всегда «Open chat» / «Open session chat · N min left». Ни Join, ни
  Message (`AURAD-0009`: тред и есть сессия), ни календаря, ни напоминаний.
- Перенос: 14 дней с сегодня, блок сессии, без выбора длительности, текущий слот не выбран;
  4 ч — **только сервер** (`AURAT-0022`); 409 — одна фраза на все причины, 400 — «time no
  longer bookable», перечитка сетки.
- Отмена: без чипов; «Full refund» (teal shield) / «Late cancellation» (coral clock), «goes
  back to your balance», «We'll confirm the exact amount…»; после — серверный
  `refundedMinor`, баланс из ответа, при скидке — перечитка кошелька.
- Отзыв: 1–5 звёзд с подписями, текст ≤ 400 (счётчик coral < 40), анонимность, заметка о
  модерации, тосты; входы — Past, профиль (3 состояния), карточка в треде после маркера
  конца; право — своё сообщение (`use-review-access`), на Past — только «ещё нет отзыва».
- `session.updated` в приложении сознательно игнорируется (тест).

## Хендофф

- Веб (NAVIGATION §2.9, §4, README §4.6, прототип `web-sessions.jsx`, `web-modals.jsx`):
  desktop — список + липкая панель 480 px, телефон — шторка «Your session»; карточка без
  кнопок (дата-блок, имя, −50%, «дата · время · N min private chat», вопрос); деталь — Join
  с T−5 мин, Reschedule, Message, Cancel, строки Question / Reminder / Paid, сноска «Free
  reschedule up to 4 h before · full refund up to 24 h before»; перенос — 7 дней с завтра,
  «old → new», выключен внутри 4 ч с причиной; отмена — чипы причин, «Rescheduling is free»,
  «to your card», «Your 50% welcome offer comes back too»; Past — «Reviewed» / «Leave a
  review» + всегда «Book again»; плашка «email and push 30 minutes before»; аналитика
  `reschedule_confirm`, `cancel_confirm`.
- Мобильный (SESSIONS_BOOKING, REVIEWS, CHECKOUT rule 6, OFFER): без Join и Message, 14 дней с
  сегодня, возврат — **на баланс, никогда «to your card»**, Late cancellation, отзыв — «any
  chat counts».

## Противоречия (решает владелец — в спеке)

Join/Message; 4 ч на клиенте или сервере; чипы причин; Past-строка; панель на Past; входы в
отзыв; дни переноса; тексты возврата; Reminder; «Go to session» на Booked; право на отзыв.

Дальше: 005 — спека.
