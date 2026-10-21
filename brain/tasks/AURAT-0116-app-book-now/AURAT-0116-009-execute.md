# AURAT-0116-009 — Execute (fix 008)

Date: 2026-10-21

- `features/booking/lib/slots.ts` — `isSlotStillFree(availability, startsAt, now)`: слот есть
  в ответе, свободен и ещё не начался по часам сервера.
- `features/booking/model/use-booking.ts` — `revalidateAvailability()`: перечитывает сетку для
  текущей длительности; `startsAt` остаётся, пока `isSlotStillFree`, `startNow` — пока
  `instantAvailable`; при ошибке чтения сетка и выбор не трогаются. `refreshAvailability`
  (безусловный сброс, Reschedule после 409) без изменений.
- `screens/booking/model/use-book-session.ts` — на возврат фокуса зовёт
  `revalidateAvailability` вместо `refreshAvailability`. Возврат после 409 тоже идёт сюда: в
  свежем ответе слот уже не свободен — выбор снимается.

Тесты: `slots.test` (+1 `isSlotStillFree`), `use-booking.test` (+4: слот свободен — остаётся,
занят — снимается, «Now» остаётся / снимается и не «воскресает», ошибка чтения — всё на месте),
`BookSessionScreen.test` (+3 «Back from Review»: Back без ошибки сохраняет слот и сетка
перечитана; сохраняет «Now»; слот ушёл — «Pick a time»).

Проверки: `tsc` — чисто; `npm run lint` — чисто; `jest` — 128 suites / 948 tests passed.

Не трогал (мелочи ревью, на усмотрение): CTA «Confirm & pay $X» на Review для «Now» — по
`CHECKOUT.md`; числа в стилях `NowPill` — как в остальном `SlotGrid`.
