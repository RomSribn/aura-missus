# AURAT-0116-004 — Context

Date: 2026-10-21

Код (ground truth, slave-1):
- `features/booking/model/use-booking.ts` — грид: pricing + availability по длительности;
  `instantAvailable` уже приходит в ответе, но не читается. Смена длительности / даты сбрасывает
  выбранное время; выбор дня по умолчанию — первый день со свободным слотом.
- `features/booking/ui/SlotGrid.tsx` — пилюли `React.memo`; пустое состояние «No times left
  this day», когда все слоты недоступны. Тот же `SlotGrid` использует `RescheduleScreen` —
  там «Now» быть не должно.
- `features/booking/lib/slots.ts` — `toBookingDays` (index 0 = «Today», `hasFreeSlots`),
  `toBookingSlots` (прошедшие отбрасываются по `serverNow`).
- `features/booking/model/use-booking-confirm.ts` — уже умеет `startNow` (флаг, не время).
- `features/booking/model/use-quick-booking.ts` + `screens/chat-thread/model/use-quick-book.ts`
  — эталон instant-пути: после брони сессия `ACTIVE`, экран Booked **не** показывается,
  `adoptSession` + тост `Session started · N min`; checkout `verb: 'start now'`.
- `screens/booking/model/use-book-review.ts` — Review: `startsAt` обязателен в params
  (`shared/config/navigation.ts`, `BOOK_REVIEW`), после брони `replace(BOOKED)`.
- `features/paid-session/model/use-paid-session.ts` — активная сессия чата перечитывается на
  mount / смене advisor / foreground; **на focus — нет**. Если тред этого советника уже лежит в
  стеке (Chat → Book now → Pick another time → грид), после instant-брони баннер не загорится.

Дизайн: `SESSIONS_BOOKING.md` про «Now» в сетке ничего не говорит (решение владельца
2026-10-21 — первоисточник).

Противоречий нет.
