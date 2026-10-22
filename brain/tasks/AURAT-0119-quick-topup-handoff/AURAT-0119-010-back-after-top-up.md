# AURAT-0119-010 — после оплаты обратно в шторку бронирования

Date: 2026-10-22

## Запрос владельца

«после оплаты б возвращать обратно на модалку бронирования»

## Сделано

- `useStoreTopUp.buy(sku, onCredited?)`: колбэк вызывается при исходе `credited`, то есть когда
  BFF проверил покупку и баланс её уже содержит. При отмене, отказе или pending колбэк не
  вызывается.
- `useTopUpSheet(visible, close, onCredited?)`: если хост передал `onCredited`, после
  зачисления вызывается он, а не «остаётся открытой» (store) или `close` (stub). Profile его
  не передаёт, поведение Profile не изменилось.
- Тред (`useChatThread`):
  - `topUpFrom` запоминает, откуда открыт Top Up: `quickBook` или `extend`.
  - После зачисления Top Up закрывается, и снова открывается исходная шторка:
    - Quick book через `quickBook.open()` (свежий ответ, при «ничего нет» переход на сетку);
    - Extend через `session.openExtend()`, только пока сессия ещё `live`.
  - На Android исходная шторка выезжает сразу. На iOS она ждёт `onClosed` у Top Up
    (AURAT-0020); для этого у `TopUpSheet` снова есть `onClosed`.
  - Если Top Up закрыли вручную, ничего не возвращается, даже если деньги дойдут позже.

## Тесты

- `use-store-topup.test.tsx`: `onCredited` после зачисления — ровно один раз; при отмене — ни
  разу.
- `ChatThreadScreen.session.test.tsx`: после зачисления Extend → Top Up → Extend снова
  открыт; закрытие Top Up вручную Extend не возвращает.
- tsc и eslint чистые; jest: 129 suites, 958 tests пройдены.
