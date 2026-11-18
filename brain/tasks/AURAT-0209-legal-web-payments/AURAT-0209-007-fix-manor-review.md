# AURAT-0209-007 — Замечания манора к `005` / `006`: внесены

Дата: 2026-11-17. Замечания прислала сессия манора: «владелец велел передать их тебе и внести, до его
одобрения текста». Сверено по коду: шрифты Google в `aura-web/index.html:10–14` и `pay.ts:47`;
`ContactDetailsElement` при `askEmail` (`card-elements.tsx:147`); `refundableMinor` в бэкофисе BFF.

**На паузе до второго письма манора** (поздняя отмена против права отказа, форма согласия, подтверждение
на durable medium): §06 «Cancelling and rescheduling», абзац §07 «Sessions that have taken place» и
формулировка признания в `AURAT-0216`. В `005` они остаются черновиком.

## Поправки к `006`

- **Телефон обязателен.** Довод `006` («where available», C-649/17) взят из старой редакции: после
  Директивы 2019/2161 ст. 4(4)(a)(i) (с 28.05.2022) ст. 6(1)(c) 2011/83/EU требует «the trader's
  telephone number and email address» без оговорки. `[PHONE]` возвращается в A2, C и D. **Без
  номера не публикуем.** Он же нужен анкете Stripe и статусу трейдера Play. Виртуальный номер подойдёт.
- **Порядок:** прод-веб на `web.aura-app.cc` → публикация `0209` → анкета Stripe. Сейчас домен не
  резолвится (16 и 17.11): A2, A4, A5 и B1 называют работающим то, чего нет.

## Тексты взамен `005`

**A2** — как в `005`, со строкой «You can reach us at support@aura-app.cc or by phone on [PHONE].»

**A5 §07**: что заменено или добавлено к `005`. Абзацы, которых здесь нет, остаются как в `005`.

> **Buying in the app.** In the Android app, credits are bought through Google Play, and in the iOS
> app through the App Store, under their terms and payment rules. The store handles your payment
> details; we never see them.

В «Buying on the web» предложение о валюте:

> Stripe may show you the price in your own currency, at an exchange rate that includes Stripe's
> currency conversion fee; that is the amount charged, and you can choose to pay in US dollars
> instead.

«Refunds and your right of withdrawal» — целиком:

> Unused credits you bought can be refunded on request, at any time and without giving a reason.
> This goes further than the 14-day right of withdrawal that EU consumers have for purchases made at
> a distance. Write to support@aura-app.cc with the phone number of your account; you may use the
> model form below, but you do not have to. Credits bought on the web are refunded to the payment
> method you paid with, in the currency you paid in, and credits bought through Google Play are
> refunded through Google Play — without undue delay, and no later than 14 days after we receive
> your request. If a refund to your payment method does not go through, the amount returns to your
> balance and we agree another way to refund it with you. A refund is never more than the purchase
> the credits came from. Credits we give you for free, for example with a promo code, are used first
> and are not refunded.
> *[App Store — по решению владельца, см. ниже:]* Purchases made through the App Store can be
> refunded only by Apple: request a refund at reportaproblem.apple.com.

Возврат через App Store делает только Apple. Обещание «we refund … through the store … within 14
days» для него невыполнимо.

«Disputed payments» → **«Reversed payments»**:

> If a payment is reversed — you dispute a web payment with your bank or card issuer and the amount
> is taken back from us, or a store refunds or cancels a purchase — we deduct the credits it bought
> from your balance. If they have already been spent, your balance goes below zero, and you cannot
> book a session until a top-up covers it. If a dispute is decided in our favour, the credits
> return. Please write to us first — a refund through support is quicker.

Основание: `AURAD-0010` п. 5 (`STORE_REFUND`) и `AURAD-0023` п. 4.

В типовую форму после «Address» добавить строку из Annex I(B): «Signature (only if this form is
sent on paper): ________».

**B1**: как в `005`, но только после выката прод-веба.

**B3**: в конец абзаца о вебе (после «…once Stripe has received it.»):

> If your profile has no email address, Stripe's form asks you for one. While you pay, Stripe's
> form also collects information about your device and connection to help prevent fraud.

**B9 (новое), §03**: строку «Using the optional details you add, such as your date of birth for
horoscope features» заменить на «Keeping the optional details you add to your profile, such as your
date of birth». Функций гороскопа по дате рождения нет. Основание прежнее: «Performance of a contract,
at your choice».

**B7**: в записи «Purchases, balance and sessions» заменить «When you delete your account, these
records are kept without your name, phone number or anything else that identifies you.» на:

> When you delete your account, these records are kept without your name or phone number. They still
> carry the payment references accounting needs, such as the store's order number or Stripe's
> payment reference.

Хвост про Stripe из `005` B7 остаётся.

**B8**: первая фраза — «This site describes Aura and links to the web app and to the app stores.»
Абзац о шрифтах — по решению о шрифтах:
- если веб берёт шрифты со своего домена, включая `cssSrc` Elements, — B8 как в `005`;
- если нет — дописать в B8: «The web app loads its fonts from Google Fonts, so your browser sends
  your IP address to Google when a page opens.» И в §05 — пункт «Google Fonts — fonts for the web
  app».

Основание: в `index.html` и `cssSrc` Elements сейчас стоит `fonts.googleapis.com`; см. LG München I,
20.01.2022, 3 O 17493/20.

**C**: строка подвала с `[PHONE]`, как в `005`.

**C2 (новое), `/delete-account/`**: в шапке «App: Aura (Google Play, App Store)» → «App: Aura (web,
Google Play, App Store)».

**C3 (новое), лендинг**: в тот же промпт, что и подвал:
- кнопка в веб-приложение (`https://web.aura-app.cc`) рядом с кнопками сторов;
- строка с ценами: «Top-ups from $5 to $120 · sessions from $[MIN]/min». `[MIN]` — из прод-данных
  при сборке промпта.

Без этого проверяющий Stripe не увидит на сайте, что и где продаётся.

**D**: добавить строку «Customer emails → Successful payments и Refunds — включить в live»: это
подтверждение покупки. И заметку:
- в `ui_mode: 'elements'` Stripe не показывает policies и contact из Checkout Settings;
- в шторке оплаты веба продавца (Silvermind OÜ, Estonia) и ссылки на Terms, Privacy и §07 надо
  показать самим. Задача — по решению владельца, туда же своё согласие с Terms из ворот `AURAD-0023`;
- Public details всё равно заполнять: квитанции, проверка, URL Terms.

## Вопросы владельцу

1. Номер телефона.
2. Шрифты веба со своего домена (новая задача веба) или Google Fonts в Privacy.
3. Продавец и ссылки в шторке оплаты: в `AURAT-0216` или отдельной задачей.
4. App Store в §07: отправлять за возвратом в Apple или убрать App Store из абзаца до выхода iOS.
