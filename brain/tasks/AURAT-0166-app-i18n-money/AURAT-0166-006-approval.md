# AURAT-0166-006 — approval

Дата: 2026-11-06. Владелец ответил на оба вопроса спеки — по рекомендации:

1. Граница — по слайсу: денежные строки `features/booking` / `screens/booking` — в `AURAT-0165`, `screens/chat-thread`
   — в задачу чата. Здесь — store-topup, promo-code, paid-session, shared/ui/offer, строка промокода в профиле.
2. Заглушка «Visa ···· 4242 / Change» вне store-rail — убрать.

Договорённость с `AURAT-0165` (сообщение slave-2, по его `006-approval`): ключ минут — `shared:minutes`
(«{{count}} min», плюралы) заводит `0165`; здесь беру его же дословно (тексты от slave-2), а не свой
`duration.minutes`. `balanceCta` в `useCheckout` приходит от вызывающих уже переведённым; `CheckoutVerb` и
`useCheckout` — здесь.

Спека `005` одобрена, начинаю исполнение.
