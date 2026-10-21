# AURAT-0116-007 — Execute

Date: 2026-10-21
Slave: `slave-1`, ветка `feature/AURAT-0116-app-book-now` (не закоммичено, всё в stage на ревью).

## Изменено (aura-app)

- `features/booking/lib/slots.ts` — `toBookingDays(availability, offersNow)`: у «Today»
  `hasFreeSlots` учитывает `instantAvailable`, только когда вызывающий предлагает «Now».
- `features/booking/model/use-booking.ts` — опция `{ offersNow }`; `nowOffered` (сегодня +
  `instantAvailable`), `startNow` + `selectNow()`, взаимоисключение со слотом; сброс при смене
  длительности / даты / `refreshAvailability`; день по умолчанию — через `toBookingDays`
  (сегодня с «Now» и полной сеткой открывается на сегодня); `summaryLabel` `… · starts now`;
  `canReview` учитывает «Now».
- `features/booking/ui/SlotGrid.tsx` — проп `now?`; `NowPill` (`React.memo`) первой: та же
  пилюля + teal-точка (белая на выбранной), a11y `Now, start immediately`; пустое состояние
  не показывается, когда есть «Now».
- `shared/config/navigation.ts` — `BOOK_REVIEW`: `{ advisorId; minutes } & ({ startsAt } |
  { startNow: true })`.
- `screens/booking/model/use-book-session.ts` — `useBooking(…, { offersNow: true })`; Review
  с `startNow`; перечитывание грида при возврате фокуса (через ref — чтобы смена длительности
  не давала второй запрос).
- `screens/booking/ui/BookSessionScreen.tsx` — передаёт `now` в `SlotGrid`.
- `screens/booking/model/use-book-review.ts` — `startNow` в `useBookingConfirm`, checkout
  `verb: 'start now'`; после брони «Now» → `MAIN › CHATS › CHAT_THREAD` (`initial: false`) +
  тост `Session started · N min`; слот — как раньше `replace(BOOKED)`.
- `screens/booking/ui/BookReviewScreen.tsx` — instant: Date `Today`, Time `Starts now · N min`,
  политика `The session starts as soon as it's paid.`, без хвоста про отмену за 24 ч в
  reassure-строке; ошибки 409/400 — `Starting now isn't possible any more. Pick a time.`
- `features/paid-session/model/{types,use-paid-session}.ts` — наружу `refreshActive`.
- `screens/chat-thread/model/use-chat-thread.ts` — `refreshActive` на focus (кроме первого).

Тесты: `slots.test` (+1), `use-booking.test` (+7, describe «Now»), `BookSessionScreen.test`
(+4: «Now» первой, нет при false, полный сегодня без «No times left», Review получает
`{ startNow: true }`), новый `screens/booking/model/__tests__/use-book-review.test.tsx` (3).

Проверки: `tsc --noEmit` — чисто; `npm run lint` — чисто; `jest` — 128 suites / 940 tests passed.

## Brain
- `AURAF-0008` — строка `AURAF-0008-013` + абзац про `AURAT-0116` / `0115` / `0117`.

## Открытое
- Живая проверка (APK / симулятор против bff-dev) — только в маноре после merge.
- Reschedule «Now» не получает (так задумано).
