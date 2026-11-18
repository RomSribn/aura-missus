# AURAT-0216-102 — Приложение: состояние и контекст

Дата: 2026-11-18. Шагов `1NN-app` до этого не было; ветка новая, от develop `8296f62`.

## Контракты v0.31.0 → v0.35.0

- `v0.32`–`v0.34` — оплата картой на вебе (`card-top-up.ts`), приложению не нужна; только добавления.
- `chat.ts` — только JSDoc (`AURAT-0198`, приложение уже так работает).
- `v0.35.0` — `consent.ts`: `SessionConsent` / `ExtensionConsent`, версии `booking-v1` / `now-v1` /
  `extension-v1`, `SESSION_CONSENT_TEXTS` (английский), коды `consent_required` / `consent_invalid`;
  необязательный `consent` в `BookSessionRequest` и `ExtendSessionRequest`. Переход — смена тега и
  `npm install`, ломающих изменений нет.

## Где в приложении бронь, «сейчас» и продление

| Поверхность | Файлы | Действие | Кнопка при оплате с баланса |
|---|---|---|---|
| Review (экран 21) | `screens/booking` (`use-book-review`, `BookReviewScreen`) | слот или `startNow` | «Confirm & pay {{amount}}» — «pay» есть |
| Быстрая бронь в чате | `features/booking/QuickBookSheet`, собирает `screens/chat-thread/use-quick-book` | слот или «сейчас» | «Book · {{cost}}», «Start now · {{cost}}» — без «pay» |
| Продление | `features/paid-session/SessionBlockSheet`, `screens/chat-thread/use-extend-checkout` | `extendSession` | «Extend · {{cost}}» — без «pay» |

- Один запрос брони на всё — `features/booking/use-booking-confirm.ts` (`bookSession`), продление —
  `features/paid-session/use-paid-session.ts` (`extendSession`).
- Кнопку оплаты строит `features/store-topup/use-checkout.ts`: с баланса — подпись от экрана
  (`balanceCta`), через стор — свои «Pay {{price}} & book / start now / extend» (с «pay», 24 языка уже
  есть). Через стор деньги сначала идут в стор, бронь — следом, значит галочка должна держать и
  кнопку стора.
- Пилюля «Extend +{{count}} min» в шапке чата только открывает шторку — она не обязывает платить и
  остаётся.
- Строка условий отмены есть только на Review (`book-session:review.policy`): «Free cancellation up
  to 24 hours before — refunds go to your Aura balance. Reschedule free up to 4 hours before.» О
  половине после 24 ч в ней ничего нет, ссылок нет. В быстрой брони строки нет.
- Ответ 400 брони сейчас всегда понимается как `slotGone`, поэтому `consent_invalid` показал бы
  «время недоступно».
- Готовый образец галочки — `features/chat-settings/ChatConsentCard` (пустая, вся карточка нажимается,
  `accessibilityRole="checkbox"`). Ссылки — `LEGAL_URLS.terms` + `openExternalUrl` (`shared`).
- Текст удаления — `features/account-deletion` `keptBody`.
- Тестов «24 перевода закреплены» в проекте пока нет, снимков (`toMatchSnapshot`) тоже нет.

## Веб

`aura-web-manor` slave-2 — на `feature/AURAT-0218-web-pay-sheet-seller-terms`, строк галочек ещё нет:
переводит первым приложение, веб берёт у нас.
