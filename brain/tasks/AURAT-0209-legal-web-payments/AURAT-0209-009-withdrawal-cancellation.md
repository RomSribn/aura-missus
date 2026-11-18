# AURAT-0209-009 — Право отказа и отмена сессий: вариант 1 владельца (второе письмо манора)

Дата: 2026-11-17. Владелец выбрал **вариант 1**: отмена до начала и неиспользованные минуты
возвращаются на баланс Aura; штраф 50% за позднюю отмену и «остаток не возвращается» уходят. Анализ —
сессия манора (по открытым источникам). Это не юридическая консультация.

## Анализ

- **Кредиты — это плата.** Commission Guidance 2021/C 525/01 §1.6.1 относит ваучеры и «virtual
  currencies» к «payment of a price». Значит, каждая бронь и каждое продление — отдельный
  дистанционный договор на услугу со своим правом отказа на 14 дней (ст. 9).
- **Горизонт брони.** BFF: `SESSION_BOOKING_HORIZON_DAYS` по умолчанию 14 (`env.schema.ts:426`), но
  допускает до 60. Сессия внутри срока отказа, только пока горизонт ≤ 14 дней — закрепить в
  BFF-задаче. Там же сверить границу: срок считается со дня после брони до конца 14-го дня (Регламент
  1182/71).
- **Отказ до начала** → полный возврат (ст. 13). **Посреди сессии** → оплата только оказанного (ст.
  14(3); C-641/19 PE Digital п. 28–32 — pro rata temporis). Возврат — «using the same means of
  payment» (ст. 13(1)): бронь оплачена кредитами, значит кредиты возвращаются на баланс. Деньги не
  заперты: неистраченное по запросу уходит на карту или в стор (§07).
- **Почему не ст. 16(l)** («досуг с конкретной датой»):
  - C-96/21 CTS Eventim п. 44–48, 53 — исключение требует риска незаполненной ёмкости у
    организатора;
  - Guidance §5.11.6 — толковать узко; «should not apply … that do not have a capacity limitation»;
  - у нас общая стойка операторов, ёмкость спорна; практики по индивидуальным онлайн-консультациям
    нет.

  Если 16(l) не устоит, Terms неверно сообщили о праве отказа. Тогда срок продлевается на 12 месяцев
  (ст. 10), а за оказанное в этот срок клиент не платит (ст. 14(4)(a)(i); C-97/22 DC v HJ п. 25–27,
  32). Под риском вся выручка сессий, а не половина брони.
- **Конкуренты** (viversum.de, questico.de) не образец:
  - опираются на § 312 Abs. 2 Nr. 11 BGB;
  - берут только общую галочку AGB;
  - неистраченное гасят через 9 месяцев.
- **Согласие** (Guidance §5.6.1):
  - нужно «a positive action by the consumer, such as ticking a box»;
  - «pre-ticked box or a clause in the general terms» не годится;
  - просьбу и признание можно дать одной фразой, до начала оказания.

  Без согласия действует ст. 14(4)(a)(ii): клиент может отказаться после сессии и ничего не платить.
  Это `AURAT-0216`.
- **Кнопки** (ст. 8(2)): иначе «the consumer shall not be bound». C-249/21 Fuhrmann-2 п. 28–34 —
  оценивается только надпись на кнопке. Guidance §4.2.2: «pay now / buy now» — надёжно, «confirm /
  order now» — сомнительно. Это `AURAT-0216`.
- **Телефон** (Guidance §3.2.2.2): обязателен, на звонки отвечают в рабочие часы. Одной голосовой
  почты мало.
- **Неявка.** «Не пришёл — сессия считается оказанной» — единственное место с остаточным риском:
  «оказано» здесь значит «время было доступно». Оставляем, помечено.

Источники:
- Guidance: https://eur-lex.europa.eu/legal-content/EN/TXT/HTML/?uri=CELEX:52021XC1229(04)
- решения Суда ЕС — тот же адрес с `?uri=CELEX:…`: 62021CJ0096, 62022CJ0097, 62019CJ0641,
  62021CJ0249, 62011CJ0049.

## Тексты взамен `005` (A4, A5)

**§06, абзац «Cancelling and rescheduling»** — заменить на:

> You can cancel a session at any time before it starts, and its full cost returns to your balance.
> You can reschedule a session free of charge until 4 hours before it starts. If you end a session
> early, the minutes you did not use return to your balance. If you don't join a session you booked,
> it is held for you for its full length and counts as provided.

**§07, вместо «Sessions that have taken place»:**

> **Booked sessions and your right of withdrawal.** Each booking, and each extension of a session, is
> a separate contract paid from your balance, and as a consumer in the EU you may withdraw from it
> within 14 days of making it. A session always falls within those 14 days, so when you book or
> extend, we ask you to confirm that you want it at the time you chose and that you understand you
> will lose the right to withdraw once it has taken place. Until a session starts, you can cancel it —
> that is your withdrawal — and its full cost returns to your balance. If you withdraw during a
> session, for example by ending it early, you pay only for the minutes you used, and the rest returns
> to your balance. Once a session has taken place, the right of withdrawal no longer applies to it,
> and the credits spent on it are not refunded. Credits that return to your balance can be refunded
> like any unused credits. If a session failed for technical reasons on our side, write to
> support@aura-app.cc and we will credit or refund it.

**Типовая форма** — строка услуги:

> I hereby give notice that I withdraw from my contract for the provision of the following service:
> Aura credits bought on ________ for ________ / the session booked on ________ for ________
> (*delete as appropriate)

## Ворота публикации (добавить к `008`)

§06 и §07 в новом виде публикуются **только после выката нового правила отмены в BFF**, иначе Terms
разойдутся с продуктом: сейчас действует правило `AURAD-0009` — 50% при отмене < 24 ч, остаток при
досрочном завершении не возвращается. Нужны:
- решение вместо правила отмены `AURAD-0009`;
- задача BFF;
- тексты отмены в обоих клиентах: диалоги «Cancel the session and return about {{amount}}»,
  «Rescheduling is free» и т. п.

ID — с «да» владельца (`010`).

Полная цепочка: прод-веб → `AURAT-0217` → новое правило отмены в BFF и клиентах → номер телефона →
публикация `0209` → анкета Stripe. `AURAT-0216` (галочки и кнопки) и `AURAT-0218` — до live оплаты.

## Остаётся юристу

- ст. 16(l) — если владелец захочет вернуть штраф;
- языковые требования стран к Terms;
- НДС (`AURAI-0013` шаг 4).
