# AURAT-0207-005 — spec

Тип: **задача** (фича-родитель `AURAF-0009`; закрывает BE-часть `AURAF-0020` 037–040).
Спека: `AURAT-0207-bff-stripe-checkout.md` (Status: draft).

Суть: контракты `v0.32.0` (`card-top-up.ts`); `POST /v1/wallet/top-ups/card` → Checkout Session;
таблицы `stripe_top_ups` / `stripe_refunds` / `stripe_disputes` и типы `CARD_*`; одна функция
`settle`; вебхук `/webhooks/stripe` → очередь; статус и отмена; возврат на карту в бэкофисе
(«Пополнения картой»); сверка раз в 5 минут + события Stripe за 72 ч; конфиг `STRIPE_*`.

Поправки к шагу 001 по сверке со Stripe: диспут двигает деньги на `funds_withdrawn` /
`funds_reinstated`; добавлен `refund.failed`; сигнал о диспуте — staff chat вместо desk; маршрут
статуса — `/top-ups/card/:paymentId` (строку `AURAF-0020-038` поправить).

Ждёт одобрения владельца (8 решений в таблице спеки).
