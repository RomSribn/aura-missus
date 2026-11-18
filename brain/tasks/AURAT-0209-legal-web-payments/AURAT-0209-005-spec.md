# AURAT-0209-005 — Спека: правки Terms, Privacy и данных продавца (черновик текста)

Дата: 2026-11-17 · Status: **draft, ждёт решений владельца** · Тип: задача (без feature-файла).

Основа — живые страницы 2026-11-17 (`004`; `/privacy/` = снимок `AURAT-0202-005`). Ниже — только
то, что меняется; всё остальное остаётся как есть. После одобрения из этого текста собираются промпты
Claude Design (`006`/`007`, как `AURAT-0202-003`), `[DATE]` ставит владелец в день публикации,
`[PHONE]` — по решению 1. Это не юридическая консультация: формулировки сверены с Директивой
2011/83/EU (ст. 6, 9, 13, 14(3), 16(a), Annex I(B)) и 2000/31/EC ст. 5, но юристом не проверены.

## A. `/terms/`

**A1. Шапка.** «Last updated» → `[DATE]`. Вводная: «These terms govern your use of the Aura app and
this website.» → «These terms govern your use of the Aura app, the Aura web app and this website.»

**A2. §01, первый абзац** — заменить на:

> Aura is provided by Silvermind OÜ, a private limited company entered in the Estonian Commercial
> Register under registry code 17345387, with its address at Lõõtsa tn 5, 11415 Tallinn, Estonia
> ("we", "us", "Aura"). You can reach us at support@aura-app.cc or by phone on [PHONE]. "You" means
> the person using the app, the web app at web.aura-app.cc or this website. These terms, together
> with the Privacy Policy, form the whole agreement between us. They are written in English; a
> translation, if we publish one, is for convenience only.

**A3. §06, первый абзац** — последняя фраза «Nothing is charged until you confirm it in the app.» →
«Nothing is charged until you confirm it in the app or the web app.»

**A4. §06, второй абзац** — заменить на:

> Paid sessions are private conversations with an advisor for a length of time you book in advance,
> paid from the credits on your Aura balance. You buy credits in the app through Google Play or the
> App Store, or in the Aura web app at web.aura-app.cc, where Silvermind OÜ sells them to you
> directly (see 07). Before your booked time runs out, Aura asks whether you want to continue; if you
> do nothing, the session simply ends. Your first paid session is discounted. Prices and session
> lengths are shown before you commit, and we may change them for future purchases and bookings.

Абзацы про отмену / перенос и «Credits have no cash value…» — без изменений.

**A5. §07 «Payments and refunds»** — заголовок прежний, весь текст под ним заменить на:

> **Buying in the app.** In the Android and iOS apps, credits are bought through Google Play or the
> App Store, under their terms and payment rules. The store handles your payment details; we never
> see them.
>
> **Buying on the web.** In the Aura web app at web.aura-app.cc you buy credits directly from
> Silvermind OÜ. Payments there are processed by Stripe: you pay by card or with another method
> offered at checkout, such as Apple Pay, Google Pay or Link, and Stripe handles your payment
> details — we never see your card number. A top-up is a whole number of US dollars, from $5 to
> $120, and your balance receives exactly that amount. Stripe may show you the price in your own
> currency, at the exchange rate it applies at checkout; that is the amount charged, and you can
> choose to pay in US dollars instead. The payment appears on your statement as AURA-APP.CC. The
> credits are added to your balance as soon as Stripe confirms the payment.
>
> Prices include VAT where it applies.
>
> **Refunds and your right of withdrawal.** Unused credits can be refunded on request, at any time
> and without giving a reason. This goes further than the 14-day right of withdrawal that EU
> consumers have for purchases made at a distance. Write to support@aura-app.cc with the phone
> number of your account; you may use the model form below, but you do not have to. We refund without
> undue delay, and no later than 14 days after we receive your request. Credits bought on the web are
> refunded to the payment method you paid with, in the currency you paid in; credits bought in the
> app are refunded through the store you bought from. A refund is never more than the purchase the
> credits came from. Credits we give you for free, for example with a promo code, are not refunded.
>
> **Sessions that have taken place.** When you book a session, you ask us to provide it at the time
> you choose, which may fall within the 14-day withdrawal period. Once a session has taken place, it
> has been provided in full, the right of withdrawal no longer applies to it, and the credits spent
> on it are not refunded. If you cancel a session before it starts, what returns to your balance
> (see 06) can be refunded like any unused credits. If a session failed for technical reasons on our
> side, write to support@aura-app.cc and we will credit or refund it.
>
> Ask before you delete your account — once an account is deleted, its balance cannot be recovered
> or refunded.
>
> **Disputed payments.** If you dispute a web payment with your bank or card issuer and the amount
> is taken back from us, we deduct the credits it bought from your balance; if they have already
> been spent, your balance can go below zero. If the dispute is decided in our favour, the credits
> return. Please write to us first — a refund through support is quicker.
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
> Date: ________

Что изменилось по смыслу и почему:
- убрано «credits are digital content delivered immediately» — чтение пишет человек, это услуга
  (`004` п. 2);
- право отказа описано через ст. 16(a): услуга, полностью оказанная по просьбе клиента;
  неистраченное возвращается всегда — это и есть исполнение ст. 14(3) (платит только за оказанное);
- типовая форма — Annex I(B), её требует ст. 6(1)(h);
- срок возврата 14 дней — ст. 13, распространён на все возвраты, чтобы не было двух правил;
- «не больше покупки» и промокоды — как в бэкофисе BFF (возврат ≤ остатка пополнения);
- диспуты и минус на балансе — `AURAD-0023` п. 4, раскрываем честно.

Остальные разделы Terms (02–05, 08–15) — без изменений.

## B. `/privacy/`

**B1. Шапка.** «Last updated» → `[DATE]`. Вводная: «It applies to the Aura mobile app and to this
website, both operated by Silvermind OÜ.» → «It applies to the Aura mobile app, the Aura web app at
web.aura-app.cc and this website, all operated by Silvermind OÜ.» *(если решение 4 — «да»)*

**B2. §01** — «…and our postal address is available on request.» → «…or by post at Silvermind OÜ,
Lõõtsa tn 5, 11415 Tallinn, Estonia (registry code 17345387).»

**B3. §02, подраздел «Payments, balance and sessions»** — заменить на:

> When you buy credits in the app, the purchase is handled by the app store you bought through:
> Google Play on Android, the App Store on iOS. We receive a confirmation of the purchase (a purchase
> token, an order number and the product you bought).
> When you buy credits in the web app, the payment is handled by Stripe. To start it, we send Stripe
> the amount, the email address in your profile if you have added one, the language of the web app,
> and internal numbers for your account and for the payment, so that the payment can be matched to
> your balance. You enter your payment details on Stripe's form, not ours. Stripe tells us whether
> the payment succeeded, the amount and currency you were charged and its own references for the
> payment, and later any refund or dispute. We do not keep your email address with the payment once
> Stripe has received it.
> We keep your balance and your session history: when a session was booked, how long it was, what it
> cost, and any refund or dispute. We never receive your card number, bank details or store account
> password.

**B4. §03** — без изменений: строка «Processing credit purchases, sessions and refunds, and keeping
accounting records | Contract; legal obligation (accounting)» и строка про мошенничество
(legitimate interests) покрывают веб.

**B5. §05, список провайдеров** — сразу после пункта «Apple — …» добавить:

> Stripe — payments in the web app. Stripe Payments Europe, Limited (Ireland) receives the details
> described in section 02 and the payment details you enter on its form, and carries out payments,
> refunds and disputes. It processes this data partly on our behalf and partly as a separate
> controller for its own purposes, such as preventing fraud and meeting its legal obligations as a
> regulated payment provider, under its own privacy policy (stripe.com/privacy). If you pay with
> Apple Pay, Google Pay or Link, that service also processes your payment under its own terms.

**B6. §06** — в списке «Google, Apple, Meta, Cloudflare, Resend, Netlify and Anthropic» добавить
Stripe: «Google, Apple, Meta, Stripe, Cloudflare, Resend, Netlify and Anthropic». Остальное в §06
как есть (DPF / SCC покрывают Stripe, Inc.).

**B7. §07, запись «Purchases, balance and sessions»** — добавить в конец: «Stripe keeps its own
records of web payments for as long as its legal obligations require, as described in its privacy
policy.» Срок «at least seven years, as Estonian accounting law requires» — верный, не трогаем.

**B8. §12** *(если решение 4 — «да»)* — заголовок «12 · This website, the web app and cookies» (и в
оглавлении), текст заменить на:

> This site describes the app and sends you to Google Play or the App Store. It sets no cookies and
> uses no analytics. Our hosting provider keeps standard server logs, including IP addresses, for
> security and for aggregate visit counts.
> The web app at web.aura-app.cc uses no analytics or advertising cookies. It keeps your sign-in and
> a few settings, such as your language and how you view the advisor list, in your browser's
> storage, and keeps a booking or payment in progress only until you close the tab. To stop
> automated sign-ins, signing in uses Google reCAPTCHA, which processes information about your
> device and browser under Google's privacy policy. When you pay, Stripe's payment form loads in the
> page and sets Stripe's own cookies to prevent fraud, as explained in Stripe's cookie policy. These
> are needed for the service you ask for, so we do not ask for consent to them.
> If we ever add analytics or measurement cookies, we will ask for your consent first and update this
> section.

Остальные разделы Privacy — без изменений.

## C. Данные продавца на сайте

Строка в подвале лендинга и трёх юридических страниц (под «© Silvermind OÜ…»), по решению 3:

> Silvermind OÜ · Registry code 17345387 · Lõõtsa tn 5, 11415 Tallinn, Estonia ·
> support@aura-app.cc · [PHONE]

Плюс Terms §01 (A2) и Privacy §01 (B2).

## D. Публичные данные Stripe (вносит владелец в анкете / Settings → Public details и Checkout)

| Поле | Значение |
|---|---|
| Business website | `https://aura-app.cc` |
| Support email / phone / address | `support@aura-app.cc` / `[PHONE]` / Lõõtsa tn 5, 11415 Tallinn |
| Support site | `https://aura-app.cc/terms/#s15` |
| Terms of service | `https://aura-app.cc/terms/` (нужен для `consent_collection`, `AURAT-0207-011`) |
| Privacy policy | `https://aura-app.cc/privacy/` |
| Refund policy | `https://aura-app.cc/terms/#s07` (по решению 2) |
| Statement descriptor | `AURA-APP.CC` |

Якоря `#s07` и `#s15` на живой странице есть.

## Решения владельца

1. **Телефон** (`AURAI-0014` §4): рабочий или виртуальный, не личный; он же нужен Stripe (support
   phone) и Google Play (статус трейдера).
2. **Refund policy:** раздел Terms §07 по якорю *(рекомендую)* или отдельная страница.
3. **Где строка продавца:** подвал всех четырёх страниц + Terms §01 *(рекомендую)* или только
   Terms.
4. **Веб-приложение в Privacy сейчас** (B1, B8) *(рекомендую — покупатель на вебе должен найти, что
   делает приложение, в котором он платит)* или отдельной задачей.
5. **Признание при брони** (`004` п. 3): выдать отдельную задачу на строку под кнопкой брони в вебе
   и приложении — «By booking, you ask us to provide the session at the time you chose. Once it has
   taken place, you can't withdraw from it.» на 24 языках — *рекомендую, до live*.
6. **НДС-номер:** если Silvermind OÜ зарегистрирована по НДС — добавить в A2 и C; если нет — ничего.

## Вне задачи

Код BFF / веба / приложения; НДС в цене и чеке (`AURAI-0013` шаг 4); переводы страниц;
`/delete-account/` (в «App: Aura (Google Play, App Store)» веба нет — мелочь, можно попутно).
