# AURAT-0216-002 — Скоуп дополнен: галочки согласия и надписи кнопок

Дата: 2026-11-17. Из `AURAT-0209-009` (второе письмо манора, вариант 1 владельца). Черновик строки из
`001` заменён. Оба клиента, 24 языка, `@sensitive`. Основания: Guidance 2021/C 525/01 §5.6.1, §4.2.2;
ст. 8(2), 14(4)(a)(ii), 16(a) Директивы 2011/83/EU; C-249/21 Fuhrmann-2.

## 1. Галочка перед КАЖДОЙ бронью, сессией «сейчас» и КАЖДЫМ продлением

- Пустая, не предотмеченная. Кнопка неактивна, пока галочки нет.
- На сервер: версия текста, время, id брони или продления.
- Тексты:
  - бронь: «I want this session at the time I chose, within my 14-day withdrawal period. I understand
    that once it has taken place, I can no longer withdraw from it.» + ссылка на Terms §07
    (`https://aura-app.cc/terms/#s07`);
  - «сейчас»: «I want this session to start now, within my 14-day withdrawal period. I understand that
    once it has taken place, I can no longer withdraw from it.»;
  - продление: «I want these minutes now, within my 14-day withdrawal period. I understand that once
    they have been used, I can no longer withdraw from them.»
- Рядом — строка-информация, не согласие: «Until it starts, you can cancel for a full refund to your
  balance.» Она верна только после нового правила отмены (`AURAT-0209-009`, ворота).

## 2. Надписи кнопок, которые обязывают платить

Сейчас в надписях нет глагола «платить». Нашёл манор:

| Где | Сейчас | Станет |
|---|---|---|
| app `screens/chat-thread`, cta | «Extend · {{cost}}» (de «Verlängern · {{cost}}») | «Pay {{amount}} & extend» |
| web `features/extend-session`, confirm | «Extend · {{amount}}» | «Pay {{amount}} & extend» |
| web `features/pay`, confirmNow | «Start now · {{amount}}» (de «Jetzt starten · {{amount}}») | «Pay {{amount}} & start now» |

- Цепочку продления в приложении (`features/paid-session`, «Extend +{{count}} min») проследить: если
  эта кнопка финальная, её тоже.
- Образец — уже существующие «Confirm & pay {{amount}}» и «Pay {{price}} & extend».
- В каждом языке — с глаголом «платить» (de «zahlen»), с учётом `@max`.

## Вне задачи

Шторка оплаты (продавец, ссылки, согласие с Terms) — `AURAT-0218`. Правило отмены в BFF — по решению
владельца (`AURAT-0209-010`).
