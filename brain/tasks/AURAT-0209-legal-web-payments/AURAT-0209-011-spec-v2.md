# AURAT-0209-011 — Спека v2: вариант 2+ и сводный текст правок

Дата: 2026-11-17 · Status: **draft, ждёт одобрения владельца** · заменяет тексты `005`, `007`, `009`.

## Решение по отмене: вариант 2+

Четвёртое письмо манора. Владелец: «давай по рекомендации, то что выгодно будет Aura по деньгам».
Правило приложения (`AURAD-0009`) не меняется:
- отмена за 24 ч и раньше — полный возврат на баланс;
- позже чем за 24 ч — половина;
- перенос — бесплатно до 4 ч;
- при досрочном завершении остаток не возвращается.

Вариант 1 (`009`) отменён целиком: нового решения вместо `AURAD-0009` нет, задачи BFF нет.

**Обоснование** (источники — `009`):
- Брони и продления — отдельные договоры: кредиты — «payment of a price» (Guidance 2021/C 525/01
  §1.6.1).
- Право отказа на них снимаем через ст. 16(l). Сессия — развлечение (Terms §03) на конкретные дату и
  время и резервирует время советника (C-96/21 CTS Eventim п. 44–48, 53).
  - Толкование спорное, судами не проверено. Guidance §5.11.6 велит толковать узко, а ёмкость общей
    стойки спорна.
- **Страховка — галочка `AURAT-0216`** (ст. 16(a)): прошедшая сессия не подлежит отказу, даже если
  16(l) не устоит. Без галочки — риск C-97/22: отказ после сессии без оплаты. **Обязательна до live.**
- **Остаточный риск:**
  - по претензии придётся вернуть удержанную половину или неиспользованную часть прерванной сессии;
  - регулятор может потребовать переписать Terms;
  - в Германии — Abmahnung за неверную информацию об отказе.
- **Практика рынка** — Treatwell (запись в салоны по ЕС): окно отмены 24–72 ч, внутри окна без
  возврата, неявка оплачивается полностью. На ст. 16(l) не ссылается, есть только «statutory rights
  prevail» (https://www.treatwell.de/en/info/booking-terms-and-conditions/, п. 5.2.1.1, 8.8, 8.9.3,
  9.4).

**Горизонт брони** (`SESSION_BOOKING_HORIZON_DAYS`, по умолчанию 14, допускается до 60) при варианте
2+ ничего не ломает, задача BFF не нужна:
- если 16(l) устоит, права отказа на брони нет при любом горизонте;
- если не устоит, бронь дальше 14 дней только помогает: и поздняя отмена, и сама сессия приходятся
  уже на время после окончания срока отказа.

Граница 14-го дня была важна только для варианта 1.

**Внутреннее правило поддержки** (не в Terms): если клиент из ЕС ссылается на право отказа после
поздней отмены или прерванной сессии, удержанное возвращаем на баланс без спора. Куда записать для
операторов стойки — решает владелец.

## Сводный текст правок (для промптов Claude Design)

`[DATE]` ставит владелец в день публикации. `[PHONE]` — номер владельца. `[MIN]` — из прод-данных
при сборке промпта.

### `/terms/`

1. Шапка: «Last updated» → `[DATE]`. Вводная: «…your use of the Aura app, the Aura web app and this
   website.»
2. **§01, первый абзац:**
   > Aura is provided by Silvermind OÜ, a private limited company entered in the Estonian Commercial
   > Register under registry code 17345387, with its address at Lõõtsa tn 5, 11415 Tallinn, Estonia
   > ("we", "us", "Aura"). You can reach us at support@aura-app.cc or by phone on [PHONE]. "You" means
   > the person using the app, the web app at web.aura-app.cc or this website. These terms, together
   > with the Privacy Policy, form the whole agreement between us. They are written in English; a
   > translation, if we publish one, is for convenience only.
3. **§06, первый абзац:** «Nothing is charged until you confirm it in the app or the web app.»
4. **§06, второй абзац:**
   > Paid sessions are private conversations with an advisor for a length of time you book in
   > advance, paid from the credits on your Aura balance. You buy credits in the app through Google
   > Play or the App Store, or in the Aura web app at web.aura-app.cc, where Silvermind OÜ sells them
   > to you directly (see 07). Before your booked time runs out, Aura asks whether you want to
   > continue; if you do nothing, the session simply ends. Your first paid session is discounted.
   > Prices and session lengths are shown before you commit, and we may change them for future
   > purchases and bookings.
5. **§06, абзац об отмене** — без изменений. По решению 3 в конец добавляется: «If you don't join a
   session you booked, it is held for you for its full length and is not refunded.» Так работает код:
   сессия сама начинается в назначенное время.
6. **§07** — весь текст под заголовком:

   > **Buying in the app.** In the Android app, credits are bought through Google Play, and in the
   > iOS app through the App Store, under their terms and payment rules. The store handles your
   > payment details; we never see them.
   >
   > **Buying on the web.** In the Aura web app at web.aura-app.cc you buy credits directly from
   > Silvermind OÜ. Payments there are processed by Stripe: you pay by card or with another method
   > offered at checkout, such as Apple Pay, Google Pay or Link, and Stripe handles your payment
   > details — we never see your card number. A top-up is a whole number of US dollars, from $5 to
   > $120, and your balance receives exactly that amount. Stripe may show you the price in your own
   > currency, at an exchange rate that includes Stripe's currency conversion fee; that is the amount
   > charged, and you can choose to pay in US dollars instead. The payment appears on your statement
   > as AURA-APP.CC. The credits are added to your balance as soon as Stripe confirms the payment.
   >
   > Prices include VAT where it applies.
   >
   > **Refunds and your right of withdrawal.** Unused credits you bought can be refunded on request,
   > at any time and without giving a reason. This goes further than the 14-day right of withdrawal
   > that EU consumers have for purchases made at a distance. Write to support@aura-app.cc with the
   > phone number of your account; you may use the model form below, but you do not have to. Credits
   > bought on the web are refunded to the payment method you paid with, in the currency you paid in,
   > and credits bought through Google Play are refunded through Google Play — without undue delay,
   > and no later than 14 days after we receive your request. Purchases made through the App Store
   > can be refunded only by Apple: request a refund at reportaproblem.apple.com. If a refund to your
   > payment method does not go through, the amount returns to your balance and we agree another way
   > to refund it with you. A refund is never more than the purchase the credits came from. Credits
   > we give you for free, for example with a promo code, are used first and are not refunded.
   >
   > **Booked sessions.** A booking is a contract for a reading at the date and time you choose.
   > Readings are entertainment (see 03), and a booking reserves an advisor's time for you, so the
   > 14-day right of withdrawal does not apply to it (Article 16(l) of Directive 2011/83/EU): a booked
   > session can be cancelled or rescheduled only as described in 06. When you book or extend a
   > session, we also ask you to confirm that you want it at that time and that you understand you
   > cannot withdraw from it once it has taken place. Credits that return to your balance after a
   > cancellation can be refunded like any unused credits. If a session failed for technical reasons
   > on our side, write to support@aura-app.cc and we will credit or refund it.
   >
   > Ask before you delete your account — once an account is deleted, its balance cannot be recovered
   > or refunded.
   >
   > **Reversed payments.** If a payment is reversed — you dispute a web payment with your bank or
   > card issuer and the amount is taken back from us, or a store refunds or cancels a purchase — we
   > deduct the credits it bought from your balance. If they have already been spent, your balance
   > goes below zero, and you cannot book a session until a top-up covers it. If a dispute is decided
   > in our favour, the credits return. Please write to us first — a refund through support is
   > quicker.
   >
   > Nothing here limits the statutory rights you have as a consumer.
   >
   > **Model withdrawal form** (complete and return this form only if you wish to withdraw)
   > To: Silvermind OÜ, Lõõtsa tn 5, 11415 Tallinn, Estonia, support@aura-app.cc
   > I hereby give notice that I withdraw from my contract for the provision of the following service:
   > Aura credits bought on ________ for ________.
   > Phone number of my Aura account: ________
   > Name: ________
   > Address: ________
   > Signature (only if this form is sent on paper): ________
   > Date: ________

Разделы 02–05 и 08–15 — без изменений.

### `/privacy/`

1. Шапка: «Last updated» → `[DATE]`. Вводная: «It applies to the Aura mobile app, the Aura web app at
   web.aura-app.cc and this website, all operated by Silvermind OÜ.»
2. **§01:** «…and our postal address is available on request.» → «…or by post at Silvermind OÜ,
   Lõõtsa tn 5, 11415 Tallinn, Estonia (registry code 17345387).»
3. **§02, «Payments, balance and sessions»** — заменить на:
   > When you buy credits in the app, the purchase is handled by the app store you bought through:
   > Google Play on Android, the App Store on iOS. We receive a confirmation of the purchase (a
   > purchase token, an order number and the product you bought).
   > When you buy credits in the web app, the payment is handled by Stripe. To start it, we send
   > Stripe the amount, the email address in your profile if you have added one, the language of the
   > web app, and internal numbers for your account and for the payment, so that the payment can be
   > matched to your balance. You enter your payment details on Stripe's form, not ours. Stripe tells
   > us whether the payment succeeded, the amount and currency you were charged and its own
   > references for the payment, and later any refund or dispute. We do not keep your email address
   > with the payment once Stripe has received it. If your profile has no email address, Stripe's
   > form asks you for one. While you pay, Stripe's form also collects information about your device
   > and connection to help prevent fraud.
   > We keep your balance and your session history: when a session was booked, how long it was, what
   > it cost, and any refund or dispute. We never receive your card number, bank details or store
   > account password.
4. **§03:** «Using the optional details you add, such as your date of birth for horoscope features» →
   «Keeping the optional details you add to your profile, such as your date of birth». Основание
   прежнее.
5. **§05**, после пункта «Apple — …»:
   > Stripe — payments in the web app. Stripe Payments Europe, Limited (Ireland) receives the details
   > described in section 02 and the payment details you enter on its form, and carries out payments,
   > refunds and disputes. It processes this data partly on our behalf and partly as a separate
   > controller for its own purposes, such as preventing fraud and meeting its legal obligations as a
   > regulated payment provider, under its own privacy policy (stripe.com/privacy). If you pay with
   > Apple Pay, Google Pay or Link, that service also processes your payment under its own terms.
6. **§06:** список → «Google, Apple, Meta, Stripe, Cloudflare, Resend, Netlify and Anthropic».
7. **§07, «Purchases, balance and sessions»:** фразу про удаление аккаунта заменить на «When you
   delete your account, these records are kept without your name or phone number. They still carry
   the payment references accounting needs, such as the store's order number or Stripe's payment
   reference.» В конец добавить: «Stripe keeps its own records of web payments for as long as its
   legal obligations require, as described in its privacy policy.»
8. **§12** — заголовок «12 · This website, the web app and cookies» (и в оглавлении); текст:
   > This site describes Aura and links to the web app and to the app stores. It sets no cookies and
   > uses no analytics. Our hosting provider keeps standard server logs, including IP addresses, for
   > security and for aggregate visit counts.
   > The web app at web.aura-app.cc uses no analytics or advertising cookies. It keeps your sign-in
   > and a few settings, such as your language and how you view the advisor list, in your browser's
   > storage, and keeps a booking or payment in progress only until you close the tab. To stop
   > automated sign-ins, signing in uses Google reCAPTCHA, which processes information about your
   > device and browser under Google's privacy policy. When you pay, Stripe's payment form loads in
   > the page and sets Stripe's own cookies to prevent fraud, as explained in Stripe's cookie policy.
   > These are needed for the service you ask for, so we do not ask for consent to them.
   > If we ever add analytics or measurement cookies, we will ask for your consent first and update
   > this section.

   Публикуется только после выката `AURAT-0217`.

### Подвалы, `/delete-account/`, лендинг

- **Подвал всех четырёх страниц**, строка под «© Silvermind OÜ…»: «Silvermind OÜ · Registry code
  17345387 · Lõõtsa tn 5, 11415 Tallinn, Estonia · support@aura-app.cc · [PHONE]».
- **`/delete-account/`**, шапка: «App: Aura (web, Google Play, App Store)».
- **Лендинг:**
  - кнопка в веб-приложение (`https://web.aura-app.cc`) рядом с кнопками сторов;
  - строка «Top-ups from $5 to $120 · sessions from $[MIN]/min».

### Stripe (владелец, Dashboard)

| Поле | Значение |
|---|---|
| Business website | `https://aura-app.cc` |
| Support email / phone / address | `support@aura-app.cc` / `[PHONE]` / Lõõtsa tn 5, 11415 Tallinn |
| Support site | `https://aura-app.cc/terms/#s15` |
| Terms / Privacy / Refund policy | `/terms/` · `/privacy/` · `/terms/#s07` |
| Statement descriptor | `AURA-APP.CC` |
| Customer emails | Successful payments и Refunds — включить в live |

В `ui_mode: 'elements'` Stripe не показывает в шторке policies и контакты — это `AURAT-0218`.

## Ворота публикации

прод-веб на `web.aura-app.cc` → выкат `AURAT-0217` → номер телефона (на звонки отвечают в рабочие
часы, одной голосовой почты мало) → публикация `0209` → анкета Stripe. До live оплаты — `AURAT-0216`
и `AURAT-0218`.

## Решения владельца

1. Одобрить сводный текст.
2. Оформить вариант 2+ решением AURAD (следующий свободный — `AURAD-0024`)?
3. Фраза о неявке в §06?
4. Куда положить внутреннее правило поддержки для операторов стойки?
5. Номер телефона.

Задачу на письма-подтверждения по ст. 8(7) владельцу объясняет манор и передаст ответ.
