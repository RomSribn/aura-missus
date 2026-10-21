# AURAT-0114-004 — Context

Date: 2026-10-20

## Источники

- Веб (develop `d4e6772`): `entities/session` (`getSessions` тег `{Session, LIST}`, `getSession` из
  списка, `sessionUpdated`, `refreshSessions`, `useSessions`, `useSessionClock` 60 с,
  `session-state.ts` уже перенесён — `remainingSeconds`, `sessionState`, `minsLeft`,
  `secondsUntilStart`), `app/session/use-live-socket.ts`, `widgets/chat-thread`
  (шапка: календарь → Book-шторка; статус «Online · free chat» / «Free chat»), `features/pay`
  (порт `balance`; строка «Top up in the Aura app»), `entities/wallet` (тег `Wallet`),
  `shared/model/dialog.ts` (вида `extend` / `finish` нет), маркеры `SystemLine` (`AURAT-0105`).
- Приложение (только чтение): `features/paid-session/**`, `screens/chat-thread/**` — отчёт агента.
- BFF (только чтение) на `4277664`: `modules/sessions` — отчёт агента, ключевое перепроверено.
- Хендоффы: мобильный `SESSIONS_BOOKING.md` §5b, `CHECKOUT.md`, прототип `checkout.jsx`;
  веб `Aura Web - Plan.html`, `design_handoff_aura_web/*`.
- Brain: `AURAT-0110-005/006` (slave-2), `AURAT-0108-005/008` (slave-1), `AURAT-0112-005/008`
  (slave-3), `aura-app-manor/active-work.md` (строки 029–035 пишет `AURAT-0110` при закрытии).

## Ключевое

**BFF.** `POST /v1/sessions/:id/extend` `{minutes, idempotencyKey}` (ключ — в теле), 201
`BookSessionResponse {session, balanceMinor}`, `session.updated` по сокету (на повтор — нет).
`minutes` — только блоки `SESSION_BLOCK_MINUTES` (10, 20, 30), иначе 400. **Цена продления —
`minutes × session.priceMinorPerMinute`** (цена, захваченная при брони, без оффера) — не
`costMinor` блока из pricing (тот — по текущей цене советника и с оффером). Отказы (тело Nest,
**без `code`**): 409 «Session is not active» (не ACTIVE или `endsAt` прошёл), 409 «Extending would
run into the advisor’s next booking», 409 «You already have a session covering that time», 409
«idempotencyKey was already used for a different charge»; 402 «Insufficient wallet balance: cost
N, balance M» — **полей недостачи нет**; пересечения проверяются раньше денег.
`POST …/finish` без тела → 201 `{session}`; ACTIVE → FINISHED `ENDED_EARLY`, денег не двигает,
остаток сгорает; на не-ACTIVE (и SCHEDULED) — 201 без изменений. Конец по времени — задача
`finish` на `endsAt` + свип раз в 60 с (ACTIVE после `endsAt` живёт до ~60 с). Маркеры — `message.new`
`system` «Your session has started» / «…finished». Чат не гейтится сессией.
`GET /v1/sessions/:id` — в BFF develop (`7625b44`), **на bff-dev нет** — не опираемся.

**Приложение.** Сессия — `GET …/advisors/:id/sessions/active` на тред (веер в списке чатов,
`AURAT-0090`), `session.updated` игнорируется. Тик 1 с от `endsAt` по `serverNow`; в 0 — баннер
снимается без запроса. `nearEnd` ≤ 120 с — только вид (счётчик и полоса коралловые), ничего не
открывается. Шапка: «Book now» ↔ «Extend +{наименьший блок} min» (cross-fade 150 мс). Шторка «Add
more minutes»: блоки из pricing (`costMinor` блока), недоступные по балансу — выключены; «Extend ·
$X»; 402 — «Not enough balance for that block.» + «Top up»; 409 — молча закрыть и перечитать;
сеть / 5xx — тот же ключ при повторе; 400/402/404/409 — ключ сгорает. «End session early» — в
шторке → Alert «End this session?» / «The remaining N min are non-refundable…» / «Keep going» ·
«End session». Баннер (plum, «Paid session live», «N min booked · tap for details», счётчик + «Left»,
полоса прошедшего) ведёт на Session Detail. Баннера «starting soon» **нет**. Список чатов —
пилюля «Session live · N min left», живые сверху. Главная и таб-бар — ничего.

**Хендоффы.** Мобильный §5b рисует баннер live и **«SESSION SCHEDULED · UNTIL START» за ≤ 24 ч**;
состояния «последние 2 мин» нет (только «2 min left» в шторке); подтверждения раннего конца нет.
`CHECKOUT.md`: Extend при PSP — «Pay $X & extend», тост «Added 10 minutes», «Your session ended before
the minutes were added». Веб Plan: таймер и «Add more minutes» — в правой колонке на desktop, Extend —
«окно поверх переписки». Веб hi-fi: живого состояния нет вовсе, аналитики продления нет.

**Соседи.** `/sessions` (`AURAT-0110`) уже показывает ACTIVE: «In progress · N min left», «Open
session chat · N min left» (тик 60 с). Главная (`AURAT-0112`, не влита) — «Session in progress» →
чат. `AURAT-0108`: PSP — пополнение недостачи + та же бронь с ключом; продления не касается.

## Противоречия

1. Где таймер: баннер под шапкой треда (мобильный, приложение) vs правая колонка (веб Plan).
2. «Starting soon»: в мобильном хендоффе есть, в приложении нет.
3. Цена блока: приложение — `costMinor` из pricing; BFF списывает `minutes × session.priceMinorPerMinute`
   (расходится, если советник сменил цену после брони) — дефект приложения.
4. 409 продления: приложение молчит; причин четыре, кодов нет.
