# AURAT-0214-001 — Initial (заготовка; исполняется в `aura-web-manor`)

Date: 2026-11-13
Выдан в `aura-app-manor` (slave-0) по просьбе веба `AURAT-0212` (slave-1-6f), после приёмки. Слова
владельца при приёмке `AURAT-0212`: «проверять все банки будем потом в отдельной задачи, пока базово
работает, gpay, apple pay, link и просто с карты».

Статус: бэклог. Запуск — по команде владельца.

Основания:
- `AURAD-0023` — Stripe Checkout для пополнения на вебе: поправка 2026-11-12 (Elements) и состояния
  2026-11-12 / 2026-11-13;
- оплата в шторке Book на Stripe Elements: веб `AURAT-0212` v2 (`develop` `6e811b2`) и BFF `AURAT-0213`
  (`develop` `cd0975b`). На web-dev 2026-11-13 приняты карта, Apple Pay, Google Pay и Link;
- `AURAF-0020-041` — Back со страницы, которая ушла, и завершение на `/checkout`.

## Что нужно

Проверить и довести банковские методы в шторке Book. Это методы, которые уводят со страницы в банк и
возвращают на `/checkout?payment=<id>` (`return_url` сессии).

1. **Уход и возврат.**
   - `confirm({ redirect: 'if_required' })` уводит в банк. Запись попытки сохраняется до `confirm`.
   - Возврат на `/checkout` → зачисление по слову BFF, затем та же бронь под тем же ключом.
   - Отказ или отмена в банке → «ничего не списано», снова шторка.
   - Back из банка — из bfcache и свежей загрузкой — работает как в `041`.
2. **Какие методы.**
   - В sandbox на 2026-11-13 включены Bancontact, BLIK, EPS, Klarna, MB Way, Satispay, Samsung Pay,
     Pix, Kakao Pay, Naver Pay и PAYCO. iDEAL выключен.
   - Методы зависят от валюты: форма показывает их по стране и валюте покупателя (Adaptive Pricing).
   - Что оставить в live — решение владельца (ворота live, п. 6 в `AURAF-0009`).
3. **Как проверять на sandbox.**
   - Stripe.js testing assistant: значок справа внизу на web-dev → Elements inspector → место покупателя.
     Для Бельгии — EUR и Bancontact.
   - Или email профиля тестового аккаунта `test+location_BE@example.com`. BFF передаёт его как
     `customer_email`, и сессия создаётся для Бельгии (docs.stripe.com/testing). Если ввести такой адрес
     в поле email Stripe после создания сессии, место не меняется.
4. **BFF.**
   - Отложенные методы BFF уже разбирает: `checkout.session.async_payment_succeeded` / `…_failed` в
     `card-events.service.ts`.
   - Вебхук bff-dev (`we_1UaexWPzZXCl9nsGFRm9tpP7`) подписан на оба события.
   - Отложенные методы (SEPA Debit) в sandbox выключены. Если их включат — отдельная проверка:
     «оплачено, ждём» на `/checkout`.
5. **Строки.** Если появятся новые — на 24 языках.

## Вне задачи

Согласие с Terms в live — п. 7 ворот live (`AURAF-0009`, `AURAD-0023`). Отдельная задача заводится, если
Stripe не откроет аккаунту Terms Element.
