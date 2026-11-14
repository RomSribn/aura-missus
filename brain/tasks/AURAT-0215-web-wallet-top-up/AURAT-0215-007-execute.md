# AURAT-0215-007 — Execute

Date: 2026-11-13. Slave `slave-1`, ветка `feature/AURAT-0215-web-wallet-top-up` (от develop `6e811b2`).
Код не закоммичен — на ревью владельцу (всё застейджено в master и missus).

## Что сделано

### `features/pay` — порт пополнения знает цель
- `settleTopUp` больше не бронирует сам: ждёт зачисления, потом вызывает `afterCredit` цели.
  `Settled<R>` = итог цели или `TopUpEnd` (`declined` / `cancelled` / `processing` / `aborted`).
- `useCardCheckout` — дженерик по цели `CardPurpose<A, R>`: `begin`, `record` (запись для банка),
  `afterCredit`, `done`, `keepsRecord`. Book — цель `book`: поведение прежнее (все старые тесты
  зелёные). Хэндл `isAway()` → `away()` (id платежа).
- Запись попытки (`lib/pending.ts`) — union по `purpose`: `book` (как раньше), `topUp` (`from` —
  страница, откуда открыли шторку; только путь сайта), `extend` (`advisorId`). Запись без `purpose`
  читается как `book`.
- `useCardTopUp` — общий хук для шторок без брони: провайдер, язык, фаза, Back из bfcache с
  платежом в пути → `/checkout?…&cancelled=1` (`041`).
- `cardTopUpOf(cost, balance)` — недостача по правилу $5–$120 (общая для Book и Extend).
- Шторка **Top up balance** (`TopUpSheet`, диалог `topup`, `useOpenTopUp`): текущий баланс,
  $10 / $25 / $50 / $100 (по умолчанию $25, `TOP_UP_AMOUNTS_USD`), выбор валюты, кошельки,
  «Other ways to pay» → шаг карты («Payment», ← «Back to amounts»). Зачислено → «Balance topped
  up»: новый баланс, «New balance · +$25.00 added», Done. 404 BFF → строка «в приложении».
- `/checkout` (`usePaymentReturn`): `topUp` — «Balance topped up», Done → `from`; отмена → `from`;
  отказ / processing — «Your payment isn’t complete» + текст, OK → `from`. `extend` — «Balance
  topped up», «Add your minutes in the chat — they’ll be paid from your balance.», «Back to chat»
  (решение 4). `book` — как раньше.
- Book: текст недостачи больше $120 — «…Pick a shorter session, or top up your balance first.»
  (решение 5).
- `CardChoice` / `PayStep` принимают фазу и подпись «paying» (у Book — прежняя «Booking…»).

### Продление — `features/extend-session` + новый виджет `widgets/extend-sheet`
- `useExtendSession(sessionId, onDone, cardCovers)`: с картой блок дороже баланса выбирается
  (выключен только если недостача больше $120). `card.begin` берёт попытку (ключ, минуты, `endsAt`
  до) в момент оплаты; после зачисления `card.extend` шлёт продление тем же ключом; `card.end` —
  Stripe отказал / processing / отмена: попытка снимается, ничего не продлено.
- После зачисления: потерян ответ → блок заперт, текст «The extension didn’t go through. $10.00 is
  safely on your balance…», повтор тем же ключом с баланса; 409 при идущей сессии — `credited.refused`;
  сессия кончилась → «The session has ended. $10.00 is on your balance.» и Done (не закрывается
  молча).
- UI шторки — `SessionBlockSheet` (был `ExtendSheet` в фиче) получает модель и слот оплаты;
  собирает их виджет `widgets/extend-sheet` (`ExtendSheet`) — фичи `pay` и `extend-session` друг
  друга не импортируют. `app/dialog-host/extend-dialog.tsx` берёт виджет.
- Окно второго списания при «Choose another block» — как принято в `AURAT-0114-007`, не менялось.

### Шапка и профиль
- `BalanceChip` — необязательное действие «Top up» внутри чипа (десктоп; на телефоне чипа нет —
  решение 2). `app-layout` даёт его только при `PSP_ENABLED`.
- `/me`: в карточке баланса (Account и Payments & balance) — кнопка «+ Top up» при `PSP_ENABLED`,
  иначе прежняя строка «Top up in the Aura app…». Строки Default card и Apple Pay удалены; Payment
  history — «Coming soon».
- `shared`: `formatUsdWhole` («$25»), `ChoiceCard` без нижней строки.

### Строки
Новые и изменённые — на 24 языках: `pay` (`topUpSheet.*`, `topUp.tooMuch`), `extend-session`
(`errors.declined|processing`, `credited.*`, `over`, `done`, `pay.*`), `checkout-page`
(`textTopUp`, `toppedUp`, `notComplete`, `extendInChat`, `next.done|chat`), `wallet` (`topUp`),
`me-page` (`balance.topUpAction`; удалены `payments.card|applePay`). `me-page balance.topUp`
остаётся — это текст при выключенной оплате (в спеке `005` п. 6 он ошибочно назван уходящим).

### Тесты
- Новый `src/app/__tests__/top-up.test.tsx` (22): шторка из шапки, смена суммы (новая сессия,
  `cancel` старой), кошелёк → «Balance topped up», шаг карты и ←, отказ Stripe, отказ BFF, 404,
  ×, Back из bfcache; профиль (кнопка, нет Default card / Apple Pay); `/checkout` для `topUp`
  (зачислено, шаг назад, отказ) и `extend`; продление (план и кошельки, оплата → продление одним
  ключом, отказ Stripe, сессия кончилась, потерянный ответ → тот же ключ, недостача > $120, 404).
- `pending.test.ts` — цели и старая запись; `format.test.ts` — `formatUsdWhole`;
  `profile.test.tsx` — без флага нет Top up; `psp.test.tsx` — новый текст `tooMuch`.

## Проверки
- `typecheck` (`tsc -b`) — чисто: переводы полные на 24 языках.
- `lint` (eslint + steiger) — чисто; `prettier --check` по изменённым файлам — чисто.
- `test` — 118 файлов, 1997 тестов, все зелёные (тест переводов — все 23 языка).
- `build` — ок. `card-elements` 17,5 kB отдельным чанком, как было. Основной чанк 954 kB против
  943 kB на develop (+11 kB, gzip +3,4 kB); предупреждение «> 500 kB» было и до задачи.
- Переводы делали четыре агента по группам языков. Термины сверены с файлами того же языка и с
  пополнением в приложении. Спорные места — в отчёте ревью.

## Брейн
- `AURAF-0020`: 011 — UI ✓, BE ✓; 042 — UI ✓; абзац бэклога — ссылка на `AURAT-0215`, приёмка на
  web-dev после мёржа.

## Открыто
- Запись `topUp` после свежей загрузки (Back из банка без bfcache) не доигрывается: шторки на
  странице нет; деньги BFF зачислит сам по вебхуку, запись перепишет следующая оплата. Банки
  целиком — `AURAT-0214`.
