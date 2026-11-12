# AURAT-0212-026 — Approved

Date: 2026-11-13. Владелец проверил на web-dev (develop aura-web `6e811b2`, BFF `AURAT-0213` на bff-dev).

Слова владельца: «проверять все банки будем потом в отдельной задачи, пока базово работает, gpay,
apple pay, link и просто с карты». На вопрос о приёмке: «Принято»; об освобождении слота: «Да,
освободить».

## Принято

- Stripe Elements на Checkout Session в шторке Book: выбор валюты (Adaptive Pricing), кошельки
  Google Pay / Apple Pay / Link, шаг оплаты с `PaymentElement` для карты.
- Фикс `025`: ряд кошельков не висит контуром.

## Вынесено в отдельные задачи (выдаёт aura-app-manor через координатора)

- Банковские методы (Bancontact, iDEAL и другие): уход в банк и возврат на `/checkout`. Как
  проверять — `025`: testing assistant или email профиля `test+location_BE@example.com`.
- Terms для live: доступ к `TermsElement` у Stripe — или своё согласие на вебе и в BFF (ворота
  live, `AURAD-0023`, `AURAF-0009` п. 7).

## Закрытие

- missus: один коммит по шагам `001`–`026`.
- `wts-release slave-1`; `active-work.md` — slave-1 свободен, AURAT-0212 в Recently completed.
