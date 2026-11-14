# AURAT-0215-010 — Fix: ревью координатора (clean code, FSD)

Date: 2026-11-14. Координатор `aura-app-manor` (сессия `manor-a8`) просмотрел застейдженный дифф (код,
без переводов) по `aura-web-build-rules` и скиллу `clean-code`. Файлов не менял; `npm run lint` — чисто.
Владелец одобрил раскладку: «да, передай сессии в slave-1». Правки — без смены поведения;
typecheck, lint и test зелёные; мутационные проверки из `009` должны ловиться по-прежнему. Агентов —
по минимуму.

Итог координатора: FSD в порядке. Хорошее, которое не трогать: виджет `widgets/extend-sheet` (как
`book-sheet`), `BalanceChip` с `onTopUp`, `formatUsdWhole` в `shared/lib`, `CardPurpose`, `cardTopUpOf`
(одно правило для Book и Extend), `TopUpPlan` вне `PayActions`, у всех 16 новых экспортов есть
потребители.

## В этой задаче

- **F1.** `pages/checkout` знает форму записи из `sessionStorage` (`backFrom` читает `from` /
  `advisorId`), и ради этого `pay` экспортирует `PendingTopUp` / `PendingExtension`. → Куда
  возвращаться, знает `pay`: `usePaymentReturn` отдаёт готовый путь; типы записи уходят из
  `index.ts`.
- **F2.** `useExtendSession` — 438 строк (было 280): 10 `useState`, 5 `useRef`, шесть флагов конца
  сессии, `send` на 60 строк. →
  - guard и сборка попытки — одна копия (`confirm` = `card.begin`);
  - блоки / недостача / `overCardMax` — чистая функция в `lib` с тестом;
  - код ответа → итог продления — чистая функция;
  - конец сессии — одно значение вместо россыпи флагов.
- **F3.** `Settled<R>` смешивает два смысла в одном `kind`; `isTopUpEnd` сверяет с ручным списком;
  в `usePaymentReturn.finish` есть ветки «сюда не попасть». → Обёртка «зачислено — итог цели» |
  «без денег — как кончилось»; `finish` делится на бронь и пополнение; `settleTopUp` возвращает
  `Settled<R>`.
- **F4.** Выбор текста вложенными тернарниками, часто в `ui`: next и topUpNext на `/checkout`,
  заголовок `/checkout`, текст ошибки шторки продления, `PayNotice` с флагом `balanceOnly`. →
  Маленькие функции с ранними `return` в `model` / `lib`; флаг-аргумент убрать.
- **F5.** Невозможные состояния в типах: `TopUpSheetView` (`done` при `addedMinor` null),
  `CheckoutPageView` (независимые null). → Дискриминированные union.
- **F6.** Повторы:
  - подпись прогресса в `card-choice` и `pay-step`;
  - `begin` + `savePending(record(…))` дважды в `use-card-checkout`;
  - `parsePending(read(KEY))` трижды в `pending-store`.
- **F7.** Имена:
  - `TopUpPlan` и интерфейс, и компонент;
  - `top` / `PendingTop` → `cardTopUp`, `PendingBase`;
  - `minutes` для объекта цели → `extensionPurpose`;
  - `on` → `cardOn`;
  - `record` → `recordOf`, `done` → `isDone`, `CardOutcome.credited` → `creditedMinor`;
  - `refreshOnOpen` зовётся и при возврате;
  - `onBack` рядом с `onBackToSheet` — из имени должно быть ясно, куда.
- **F8.** Тесты:
  - мок Stripe Elements скопирован в два файла → фабрика в `src/test-support`;
  - два теста ждут настоящие 400 мс → поддельные таймеры;
  - `top-up.test.tsx` (1023 строки) разделить: шторка, `/checkout`, продление; профиль — в
    `profile.test.tsx`.

## Открыто — после мёржа (ID выдаёт координатор, по команде владельца)

- **A1.** Две копии логики «оплата прервалась → довести на `/checkout`»: `useCardTopUp` (Top up,
  Extend) и Book в `usePay` (`finishOnCheckout`, свой `pageshow`). Перевести Book на
  `useCardTopUp` (`resumes` — бронь этого советника, сброс ключа — в `onReturn`). Отдельной задачей:
  Book уже принят, спека `005` обещала его не трогать.
- **A2.** CSS-плашка (padding `10px var(--s12)`, `--r-sm`, 13.5px/600) — 13 копий в 10 файлах, задача
  добавила `.off` и `.over`. Нужен `shared/ui/notice`. Долг репозитория, правило 3.
- **A3.** `json` / `renderAt` / `NoopObserver` скопированы в 13–15 тестовых файлов — общий
  test-support. Долг репозитория.
