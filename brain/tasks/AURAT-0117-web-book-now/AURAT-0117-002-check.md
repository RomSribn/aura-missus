# AURAT-0117-002 — Check

Date: 2026-10-21

- Папка задачи есть (заглушка `001` из `aura-app-manor`, missus `a5004aa`); других шагов нет.
- `AURAT-0115` (BFF, lead → 0) — **done** (`010-approved`, aura-bff `54640f3`): ближайший
  получасовой слот бронируется; для «Now» BFF ничего нового не нужно (`instantAvailable` +
  `startNow`).
- `AURAT-0116` (приложение) — только заглушка `001`, кода в приложении ещё нет; ориентир —
  Quick book (`use-quick-booking.ts`, `use-booking-confirm.ts` со `startNow`).
- Веб: бронь — `AURAT-0107` (develop `79bf311`), шторка Book в `features/book-session`,
  слоты — `entities/session`, `SessionTimePicker` — `AURAT-0110`. Живая сессия (таймер) —
  `AURAT-0114` (slave-4, на ревью, не в develop).

Next: 003-understand, 004-context.
