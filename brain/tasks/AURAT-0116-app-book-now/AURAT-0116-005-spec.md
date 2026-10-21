# AURAT-0116-005 — Spec

Date: 2026-10-21
Тип: task (под `AURAF-0008`); отдельный feature-файл не нужен — в `AURAF-0008` добавится строка
в scope при исполнении.
Status: approved 2026-10-21 (см. 006).

## Что делаем

1. **Модель грида** (`use-booking.ts`): читает `instantAvailable`; новое состояние
   `startNow: boolean` + `selectNow()`. «Now» и слот взаимоисключающие; смена длительности,
   даты и `refreshAvailability` сбрасывают оба. `canReview` = длительность + (слот **или**
   `startNow`). `instantNow` (показывать ли «Now») = `instantAvailable` **и** выбран сегодняшний
   день (`days[0]`). Footer: `10 min chat · starts now`.
2. **Сегодня с «Now» — не пустой день**: в `toBookingDays` у «Today» `hasFreeSlots` учитывает
   instant; день по умолчанию — сегодня, если есть «Now», даже когда все слоты сетки заняты;
   пустое состояние «No times left this day» при «Now» не показывается.
3. **`SlotGrid`**: необязательный проп `now?: { selected; onSelect }` — когда передан, первой
   идёт пилюля «Now» (та же форма и выбор коралловым, плюс маленькая teal-точка «свободен
   сейчас»; a11y-label `Now, start immediately`). `RescheduleScreen` проп не передаёт — там
   «Now» нет. Пилюля — `React.memo`, как остальные.
4. **Навигация** (`shared/config/navigation.ts`): `BOOK_REVIEW` params —
   `{ advisorId; minutes } & ({ startsAt: string } | { startNow: true })`.
5. **Review** (`use-book-review.ts` / `BookReviewScreen`): на instant-пути строки «Date / Time»
   → `Today` / `Starts now · 10 min`; политика переноса («Free reschedule up to 4 hours…») →
   `The session starts as soon as it's paid.`; checkout `verb: 'start now'`, CTA остаётся
   `Confirm & pay $X`. `useBookingConfirm` получает `startNow`, ключ идемпотентности — как сейчас.
6. **После оплаты «Now»**: не экран Booked (он про «будет готов в выбранное время»), а сразу
   тред этого советника (`MAIN → CHATS → CHAT_THREAD`, `initial: false`), тост
   `Session started · N min` — как Quick book.
7. **Баннер в треде**: `use-paid-session` перечитывает активную сессию **на focus** экрана
   треда (один `GET …/sessions/active`), чтобы баннер загорелся и когда тред уже был в стеке.
8. **409 / 400 на «Now»** — тот же путь, что у слота: `No longer available — try another time`
   → назад к гриду. Сейчас грид экрана брони после возврата с Review **не** перечитывается
   (`refreshAvailability` зовёт только Reschedule) — а `instantAvailable` протухает быстрее
   слота. Добавляю: `use-book-session` перечитывает availability при возврате фокуса на экран
   (не при первом mount), выбор сбрасывается.

## Тесты (unit, в слоте)
- `use-booking`: `selectNow`/`selectSlot` взаимоисключение, сброс при смене длительности/даты,
  `instantNow` только для сегодня, `canReview`, summary, выбор дня по умолчанию.
- `slots.test`: `hasFreeSlots` у Today с instant.
- `BookSessionScreen.test`: «Now» первой при `instantAvailable`, нет — при false и не на
  сегодня; нет пустого состояния при «Now».
- Review: бронь уходит `{ startNow: true }` без `startsAt`; после — навигация в тред.

## Не делаем
- BFF (закрыт `AURAT-0115`), lead time в приложении, Reschedule «Now», веб (`AURAT-0117`).

## Проверка вживую
Только в маноре после merge (APK / симулятор против bff-dev).

## Решения владельцу
- Вид «Now»: та же пилюля + teal-точка (предложение) или иначе?
- После оплаты «Now» — в тред с тостом (предложение, как Quick book) или экран Booked?
