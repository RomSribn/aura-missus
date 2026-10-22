# AURAT-0119-011 — Top Up прямо на Review

Date: 2026-10-22

## Запрос владельца

«ок, все норм. Сделай так же на странице review booking, чтобы шторка пополнения выезжала
прямо на скрине». Тред (`009`/`010`) владелец проверил на устройстве и принял.

## Сделано

- `useBookReview`:
  - `onTopUp` больше не ведёт в `MAIN → PROFILE → PROFILE_ROOT { sheet: 'topup' }`, а
    открывает свой `TopUpSheet`. Хук `useTopUpSheet(visible, close, onCredited = close)`.
  - После зачисления шторка закрывается, Review остаётся с новым балансом: «Confirm & pay»
    сразу доступен.
  - Возвращать некуда: Review — это экран, а не шторка. Других модалок на Review нет, так что
    ждать `onClosed` (AURAT-0020) не нужно.
- `BookReviewScreen` рендерит `TopUpSheet`.
- Мёртвый код удалён (жёсткое правило 5). Других отправителей `sheet: 'topup'` не осталось:
  - параметр `sheet` у `PROFILE_ROOT` (теперь `undefined`);
  - эффект `requestedSheet` и `useRoute` в `use-profile`;
  - тип `ProfileStackRouteProp` (потребителей нет);
  - тест Profile «another tab can land here with Top Up already open».

## Тесты

- `use-book-review.test.tsx`: вместо «Top Up lands on Profile…» новый тест «Top Up opens on
  Review and closes once credited» — навигации в MAIN нет, после `onCredited` шторка закрыта.
- tsc и eslint чистые; jest: 129 suites, 957 tests пройдены (минус удалённый тест Profile).
