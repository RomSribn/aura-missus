# AURAT-0117-007 — Execute

Date: 2026-10-21
Slave: `slave-1`, `feature/AURAT-0117-web-book-now`. master — fast-forward на develop `77ee5ae`
(в ветке не было коммитов, `booking-form.tsx` уже на `ChoiceCard` из `AURAT-0114` — конфликта нет);
missus — fast-forward на `origin/master` `eb106fd`. Не закоммичено, staged.

## Файлы (aura-web)

**entities/session**
- `api/session-api.ts` — `BookSessionArgs.startsAt: string | null` (null = `startNow`), тело —
  `BookSessionRequest.parse({ startNow: true, minutes, idempotencyKey })` или со `startsAt`.
- `lib/sessions.ts` (+ тест) — `bookedPathOf(session)`: `ACTIVE` → `/chats/:advisorId`, иначе →
  `/booked/:id`; по сессии из ответа, не по выбору экрана.
- `ui/session-time-picker.tsx` — необязательный `instant` → кнопка «Now» первой в сетке (классы
  слота, `aria-pressed`, `aria-label`); с ней сетка не «пустая». Reschedule проп не передаёт.
- `ui/session-summary.tsx` — `startsAt`/`endsAt` nullable → «Starts right away» (`/checkout`).
- `config/locales/*` — `summary.now`, `picker.time.now`, `picker.time.nowOption`.

**features/book-session**
- `lib/choice.ts` (+ тесты) — `todayDate`; `startNow` в выборе; из чата — «Now» при `instant`,
  иначе ближайший слот; первый открытый день — сегодня при `instant`; черновик с «Now» — только
  пока `instant`; ссылка `?slot=` важнее «Now».
- `lib/draft.ts` (+ тест) — `startNow` с умолчанием `false` (старые черновики читаются).
- `model/use-book-session.ts` — `instant` (сегодня + `instantAvailable` этого блока), `startNow`,
  `selectNow`; выбор слота / дня / блока / отказ снимают «Now»; сегодня в полосе дней не «full»,
  пока «Now» есть.
- `ui/booking-form.tsx`, `ui/booking-total.tsx` — «Now» в пикер; итог «Starts now · N min».
- `config/locales/*` — `total.now_*` (плюральные формы — как у `duration.minutes_*` языка).

**features/pay**
- `model/payment-method.ts`, `lib/pending.ts` (+ тест) — `startsAt` nullable («Now»).
- `model/use-pay.ts` — `startNow` в аргументах; `ready` — слот или «Now»; попытка несёт
  `startsAt: null`; ключ — как был (до определённого исхода, смена «Now» ↔ слот его не сбрасывает);
  отказ «Now» — ошибка `nowTaken`.
- `model/use-payment-return.ts` — 409 после пополнения для «Now» → `nowTaken` (поправка 3).
- `ui/pay-actions.tsx` — «Start now · $X»; для «Now» нет строки про отмену за 24 ч / перенос за 4 ч,
  «You save» остаётся; пустая строка условий не рисуется.
- `ui/pay-notice.tsx` — `credited.nowTaken`.
- `config/locales/*` — `confirmNow`, `error.nowTaken`, `credited.nowTaken`.

**widgets/book-sheet** — `startNow` в `usePay`, `BookingTotal`, `PayActions`; после брони —
`bookedPathOf`. URL открытой шторки для «Now» — `?book=1` без `slot`.

**pages/checkout** — `bookedPathOf`; `nowTaken` → «Pick another time»; возврат в шторку без
`slot` для «Now»; сводка с «Starts right away».

**Тесты** — `app/__tests__/book-now.test.tsx` (5): «Now» первым сегодня, не выбран из профиля,
итог, без строки 24 ч, URL без slot, тело `{startNow, minutes, key}` без `startsAt`, `ACTIVE` →
тред с `role="timer"` без Booked; нет «Now» на другой день и для блока без `instant`; из чата
«Now» выбран, тред остаётся; 409 → текст, перечитка, «Now» пропал; потеря ответа → тот же ключ и
тело. `app/__tests__/psp.test.tsx` (+2): «Now» картой → тред; 409 после пополнения → «It can’t
start right now any more. $7.00 is on your balance — pick a time.».

## Решения по ходу

- Отдельная ошибка `nowTaken` и для отказа без пополнения («It can’t start right now any more —
  pick a time.»): «That time is no longer available» про «Now» звучит странно. +1 ключ сверх спеки.
- «Сегодня» — день сетки, чей `date` даёт `daysUntil(...) === 0` (как подпись «Today» в пикере).
- hu `confirmNow` — двоеточие, как у соседнего `confirm` («Kezdés most: {{amount}}»).
- Переводы — 3 агента по языкам, лексика взята из существующих файлов языка.

## Проверки

`npm run lint` (eslint + steiger) — чисто; `npm run typecheck` — чисто; `npm test` — 75 файлов,
1311 тестов, зелёные; `npm run build` — собран (предупреждение о чанке > 500 kB — как было).
Живой BFF — в маноре после merge.

## AURAF-0020

Заметка к UI 006 — «Now» (`AURAT-0117`). Абзац для приложения (`AURAT-0116`, поправка 2) — при
закрытии задачи.

Next: ревью владельцем в IDE → коммит → merge gate.
