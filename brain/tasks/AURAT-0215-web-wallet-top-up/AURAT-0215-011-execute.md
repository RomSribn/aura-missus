# AURAT-0215-011 — Execute: правки по ревью координатора

Date: 2026-11-14. Slave `slave-1`, ветка `feature/AURAT-0215-web-wallet-top-up`. Поведение не менялось:
весь прежний набор тестов зелёный без правок ожиданий, только тесты перенесены по файлам. Не
закоммичено; застейджено.

## Что сделано (по `010`)

- **F1.** `/checkout` больше не знает форму записи. В `features/pay/lib/return-path.ts` отображения
  `returnedBookingOf` / `returnedTopUpOf` / `returnedOf` дают то, что страница показывает: бронь —
  советник, минуты, слот; пополнение — сумма и `backTo` (страница шторки или чат сессии).
  `usePaymentReturn` зовёт `onBackToPage(to)` с готовым путём. `PendingTopUp` / `PendingExtension`
  ушли из `index.ts`.
- **F2.** `useExtendSession` (398 строк вместо 438):
  - `startable()` — одна копия guard и сборки попытки для `confirm` и `card.begin`;
  - `lib/block-choice.ts` — `chooseBlocks`: блоки, выбранный, `shortfall`, `overCardMax`; с тестом;
  - `lib/failure.ts` — `failureOf`: статус → `lost` / `conflict` / `gone` / `short` / `failed`;
    `send` делится на `send` и `refused`;
  - `lib/session-end.ts` — конец сессии одним значением `'none' | 'checking' | 'money' | 'close'`
    вместо шести флагов; с тестом.
- **F3.** `Settled<R>` = `{ credited: true; outcome }` | `{ credited: false; end }`; `isTopUpEnd` и
  ручной список удалены; `settleTopUp` возвращает `Settled<R>`. `usePay` — `finishBooking` и
  `finishEnded`; `usePaymentReturn` — `finishBooking` и `finishTopUp`, без веток «сюда не попасть».
- **F4.** Вложенные тернарники ушли:
  - путь дальше на `/checkout` — `bookingNextOf` / `topUpNextOf`;
  - заголовок и строка — из модели (`title` / `line`);
  - строка ошибки продления — `lib/error-line.ts` `errorLineOf` (с тестом);
  - вместо флага `balanceOnly` у `PayNotice` — компонент `TopUpNotice`.
- **F5.** `TopUpSheetView` и `CheckoutPageView` — дискриминированные union. У каждого статуса —
  только свои поля. Статусы `/checkout`: `notice` — бронь, `failed` — пополнение без брони.
  `PaymentReturnView` — тоже union.
- **F6.** Одна `progressLabel` в `lib/progress.ts` — в `CardChoice`, `PayStep`, `PayActions`; `paying`
  обязателен в обоих компонентах. `beginOn` в `use-card-checkout`. `keptPayment()` — одно чтение
  записи в `pending-store`.
- **F7.** Переименования:
  - `TopUpView` → `ShortfallTopUp`; компонент `TopUpPlan` → `ShortfallTopUpLine`;
  - `PendingTop` → `PendingBase`; `top` → `cardTopUp`; `minutes` → `extensionPurpose`; `on` → `cardOn`;
  - `record` → `recordOf`, `done` → `isDone`; `CardOutcome.result` / `credited` → `settled` /
    `creditedMinor`;
  - `refreshOnOpen` → `refreshWallet`; `onBack` → `onBackToPage`.
- **F8.** Тесты:
  - фабрика стенда Stripe Elements — `src/test-support/stripe-elements.tsx`; ею пользуются
    `psp.test.tsx` и новые тесты;
  - заглушка BFF пополнения — `src/test-support/top-up-bff.ts`;
  - `top-up.test.tsx` разделён на `top-up-sheet`, `checkout-top-up`, `extend-card`; два теста
    профиля — в `profile.test.tsx`, флаг оплаты там переключаемый через геттер в моке;
  - ожидания 400 мс — на поддельных таймерах.

## Проверки
- `typecheck`, `lint` (eslint + steiger), `prettier --check` — чисто.
- `test` — 126 файлов, 2022 теста, зелёные.
- `build` — ок. `card-elements` 17,5 kB отдельно; основной чанк 957,5 kB. `test-support` в бандл не
  попадает.
- Мутационные проверки из `009` ловятся после переноса:
  - снять защиту `kept` → падают 2 теста;
  - не читать сессию перед итогом (M1) → 3;
  - не сбрасывать `creditedMinor` (M3) → 1;
  - закрыть, не дождавшись чтения (M4) → 2.

## Ревью сохранения поведения (один агент, как разрешил владелец)
Сравнил застейдженную версию с рефакторингом. Изменений поведения не нашёл, ни один тест не потерян и
не ослаблен:
- `chooseBlocks` — 200 000 случайных случаев, `errorLineOf` — все 48 сочетаний, расхождений нет;
- `sessionEndOf` — из 64 сочетаний расходятся 4, и все недостижимы: ветка, ставящая
  `endedAfterCredit`, в том же такте снимает попытку;
- 30 тестов прежнего файла разложены на 11 + 4 + 13 + 2, тела те же.

По замечаниям ревьюера:
- убраны экспорты без потребителей: `returnedOf`, `CheckoutTitle`; `CheckoutLine` и
  `CheckoutPageView` больше не экспортируются;
- индекс снова совпадает с рабочим деревом.

Повторный прогон — те же 126 / 2022, сборка ок.

## Открыто — после мёржа (ID — у координатора, по команде владельца)
- A1 — Book на `useCardTopUp` (одна логика доведения прерванной оплаты).
- A2 — `shared/ui/notice` вместо 13 копий CSS-плашки (правило 3).
- A3 — общий test-support для `json` / `renderAt` / `NoopObserver` (13–15 копий).
