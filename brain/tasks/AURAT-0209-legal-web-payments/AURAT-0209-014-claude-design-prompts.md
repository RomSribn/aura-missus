# AURAT-0209-014 — Промпты для Claude Design: /terms/, /privacy/, /delete-account/, лендинг

Дата: 2026-11-18. Тексты — `011` с поправкой `013` п. 1. Решение владельца по App Store (`013` п. 2):
«Оставить Soon, добавить веб». Промпты собраны по образцу `AURAT-0202-003`: «изменить только
перечисленное».

**Не отправлять, пока не пройдены ворота `011`:**
1. прод-веб открывается на `web.aura-app.cc`;
2. выкачен `AURAT-0217` (свои шрифты): без него §12 Privacy неверна;
3. вместо `[PHONE]` вписан номер, на звонки по которому отвечают в рабочие часы.

`[DATE]` — день публикации, одинаковый на всех страницах. После публикации — снимок страниц и сверка
по абзацам (как в `AURAT-0202-005`).

## 1. /terms/

```text
Update the Terms of Service page (https://aura-app.cc/terms/).

Change ONLY what is listed below, using the new text word for word. Do not reword, reorder, shorten or restyle anything else: keep the layout, the headings and their numbers, the anchors (#s01 … #s15), the links and every other sentence exactly as they are now.

1. Header: set "Last updated" to [DATE]. In the intro line, replace "These terms govern your use of the Aura app and this website." with "These terms govern your use of the Aura app, the Aura web app and this website."

2. Section 01 "Who we are": replace the whole paragraph with:

Aura is provided by Silvermind OÜ, a private limited company entered in the Estonian Commercial Register under registry code 17345387, with its address at Lõõtsa tn 5, 11415 Tallinn, Estonia ("we", "us", "Aura"). You can reach us at support@aura-app.cc or by phone on [PHONE]. "You" means the person using the app, the web app at web.aura-app.cc or this website. These terms, together with the Privacy Policy, form the whole agreement between us. They are written in English; a translation, if we publish one, is for convenience only.

Keep "support@aura-app.cc" as a mailto link and "Privacy Policy" as the link to /privacy/, as they are now.

3. Section 06 "Free start, paid depth":
a) First paragraph: replace the last sentence "Nothing is charged until you confirm it in the app." with "Nothing is charged until you confirm it in the app or the web app."
b) Replace the second paragraph (it begins "Paid sessions are private conversations") with:

Paid sessions are private conversations with an advisor for a length of time you book in advance, paid from the credits on your Aura balance. You buy credits in the app through Google Play or the App Store, or in the Aura web app at web.aura-app.cc, where Silvermind OÜ sells them to you directly (see 07). Before your booked time runs out, Aura asks whether you want to continue; if you do nothing, the session simply ends. Your first paid session is discounted. Prices and session lengths are shown before you commit, and we may change them for future purchases and bookings.

c) Third paragraph (it begins "Cancelling and rescheduling"): keep it exactly as it is and add this sentence at its end:

If you don't join a session you booked, it is held for you for its full length and is not refunded.

4. Section 07 "Payments and refunds": keep the heading and replace the whole text under it with the blocks below, in this order. Each bold lead-in starts a paragraph, in the same bold-label style the page already uses. "support@aura-app.cc" is a mailto link each time, "06" and "03" link to #s06 and #s03, and "web.aura-app.cc" links to https://web.aura-app.cc.

**Buying in the app.** In the Android app, credits are bought through Google Play, and in the iOS app through the App Store, under their terms and payment rules. The store handles your payment details; we never see them.

**Buying on the web.** In the Aura web app at web.aura-app.cc you buy credits directly from Silvermind OÜ. Payments there are processed by Stripe: you pay by card or with another method offered at checkout, such as Apple Pay, Google Pay or Link, and Stripe handles your payment details — we never see your card number. A top-up is a whole number of US dollars, from $5 to $120, and your balance receives exactly that amount. Stripe may show you the price in your own currency, at an exchange rate that includes Stripe's currency conversion fee; that is the amount charged, and you can choose to pay in US dollars instead. The payment appears on your statement as AURA-APP.CC. The credits are added to your balance as soon as Stripe confirms the payment.

Prices include VAT where it applies.

**Refunds and your right of withdrawal.** Unused credits you bought on the web or through Google Play can be refunded on request, at any time and without giving a reason. This goes further than the 14-day right of withdrawal that EU consumers have for purchases made at a distance. Write to support@aura-app.cc with the phone number of your account; you may use the model form below, but you do not have to. Credits bought on the web are refunded to the payment method you paid with, in the currency you paid in, and credits bought through Google Play are refunded through Google Play — without undue delay, and no later than 14 days after we receive your request. Purchases made through the App Store can be refunded only by Apple: request a refund at reportaproblem.apple.com. If a refund to your payment method does not go through, the amount returns to your balance and we agree another way to refund it with you. A refund is never more than the purchase the credits came from. Credits we give you for free, for example with a promo code, are used first and are not refunded.

**Booked sessions.** A booking is a contract for a reading at the date and time you choose. Readings are entertainment (see 03), and a booking reserves an advisor's time for you, so the 14-day right of withdrawal does not apply to it (Article 16(l) of Directive 2011/83/EU): a booked session can be cancelled or rescheduled only as described in 06. When you book or extend a session, we also ask you to confirm that you want it at that time and that you understand you cannot withdraw from it once it has taken place. Credits that return to your balance after a cancellation can be refunded like any unused credits. If a session failed for technical reasons on our side, write to support@aura-app.cc and we will credit or refund it.

Ask before you delete your account — once an account is deleted, its balance cannot be recovered or refunded.

**Reversed payments.** If a payment is reversed — you dispute a web payment with your bank or card issuer and the amount is taken back from us, or a store refunds or cancels a purchase — we deduct the credits it bought from your balance. If they have already been spent, your balance goes below zero, and you cannot book a session until a top-up covers it. If a dispute is decided in our favour, the credits return. Please write to us first — a refund through support is quicker.

Nothing here limits the statutory rights you have as a consumer.

Then, still inside section 07, a "Model withdrawal form" block, set apart as a quiet bordered box (like a form to copy), with these lines exactly:

Model withdrawal form
(complete and return this form only if you wish to withdraw)
To: Silvermind OÜ, Lõõtsa tn 5, 11415 Tallinn, Estonia, support@aura-app.cc
I hereby give notice that I withdraw from my contract for the provision of the following service: Aura credits bought on ________ for ________.
Phone number of my Aura account: ________
Name: ________
Address: ________
Signature (only if this form is sent on paper): ________
Date: ________

5. Footer: directly under the line "© Silvermind OÜ. All rights reserved 2026. …", add one line in the same small footer style:

Silvermind OÜ · Registry code 17345387 · Lõõtsa tn 5, 11415 Tallinn, Estonia · support@aura-app.cc · [PHONE]

("support@aura-app.cc" is a mailto link.)

Sections 02–05 and 08–15 stay exactly as they are.
```

## 2. /privacy/

```text
Update the Privacy Policy page (https://aura-app.cc/privacy/).

Change ONLY what is listed below, using the new text word for word. Do not reword, reorder, shorten or restyle anything else: keep the layout, the headings and their numbers, the table, the links and every other sentence exactly as they are now — including the Meta advertising text in sections 02, 03, 05, 06 and 08, and the Anthropic text added on 8 November 2026.

1. Header: set "Last updated" to [DATE]. In the intro, replace "It applies to the Aura mobile app and to this website, both operated by Silvermind OÜ." with "It applies to the Aura mobile app, the Aura web app at web.aura-app.cc and this website, all operated by Silvermind OÜ."

2. Section 01: replace the end of the first paragraph ", and our postal address is available on request." with:

, or by post at Silvermind OÜ, Lõõtsa tn 5, 11415 Tallinn, Estonia (registry code 17345387).

3. Section 02, subsection "Payments, balance and sessions": replace the whole subsection text with these three paragraphs:

When you buy credits in the app, the purchase is handled by the app store you bought through: Google Play on Android, the App Store on iOS. We receive a confirmation of the purchase (a purchase token, an order number and the product you bought).
When you buy credits in the web app, the payment is handled by Stripe. To start it, we send Stripe the amount, the email address in your profile if you have added one, the language of the web app, and internal numbers for your account and for the payment, so that the payment can be matched to your balance. You enter your payment details on Stripe's form, not ours. Stripe tells us whether the payment succeeded, the amount and currency you were charged and its own references for the payment, and later any refund or dispute. We do not keep your email address with the payment once Stripe has received it. If your profile has no email address, Stripe's form asks you for one. While you pay, Stripe's form also collects information about your device and connection to help prevent fraud.
We keep your balance and your session history: when a session was booked, how long it was, what it cost, and any refund or dispute. We never receive your card number, bank details or store account password.

4. Section 03 table: replace the row "Using the optional details you add, such as your date of birth for horoscope features | Performance of a contract, at your choice" with:
| Keeping the optional details you add to your profile, such as your date of birth | Performance of a contract, at your choice |

5. Section 05, list of service providers: add this item right after the "Apple — …" item, in the same style as the other items:

- Stripe — payments in the web app. Stripe Payments Europe, Limited (Ireland) receives the details described in section 02 and the payment details you enter on its form, and carries out payments, refunds and disputes. It processes this data partly on our behalf and partly as a separate controller for its own purposes, such as preventing fraud and meeting its legal obligations as a regulated payment provider, under its own privacy policy (stripe.com/privacy). If you pay with Apple Pay, Google Pay or Link, that service also processes your payment under its own terms.

("stripe.com/privacy" links to https://stripe.com/privacy.)

6. Section 06: in the sentence "Some of our providers — Google, Apple, Meta, Cloudflare, Resend, Netlify and Anthropic — …" change the list to "Google, Apple, Meta, Stripe, Cloudflare, Resend, Netlify and Anthropic". Nothing else in section 06 changes.

7. Section 07, entry "Purchases, balance and sessions": replace its text with:

At least seven years, as Estonian accounting law requires. When you delete your account, these records are kept without your name or phone number. They still carry the payment references accounting needs, such as the store's order number or Stripe's payment reference. Stripe keeps its own records of web payments for as long as its legal obligations require, as described in its privacy policy.

8. Section 12: change the heading to "12 · This website, the web app and cookies" (also in "On this page"), and replace the whole text under it with:

This site describes Aura and links to the web app and to the app stores. It sets no cookies and uses no analytics. Our hosting provider keeps standard server logs, including IP addresses, for security and for aggregate visit counts.
The web app at web.aura-app.cc uses no analytics or advertising cookies. It keeps your sign-in and a few settings, such as your language and how you view the advisor list, in your browser's storage, and keeps a booking or payment in progress only until you close the tab. To stop automated sign-ins, signing in uses Google reCAPTCHA, which processes information about your device and browser under Google's privacy policy. When you pay, Stripe's payment form loads in the page and sets Stripe's own cookies to prevent fraud, as explained in Stripe's cookie policy. These are needed for the service you ask for, so we do not ask for consent to them.
If we ever add analytics or measurement cookies, we will ask for your consent first and update this section.

("Google's privacy policy" links to https://policies.google.com/privacy, "Stripe's cookie policy" to https://stripe.com/cookie-settings.)

9. Footer: directly under the line "© Silvermind OÜ. …", add one line in the same small footer style:

Silvermind OÜ · Registry code 17345387 · Lõõtsa tn 5, 11415 Tallinn, Estonia · support@aura-app.cc · [PHONE]

All other sections and subsections stay exactly as they are.
```

## 3. /delete-account/

```text
Update the "Delete your Aura account" page (https://aura-app.cc/delete-account/).

Change ONLY what is listed below. Keep everything else exactly as it is now.

1. Header: set "Last updated" to [DATE], and change the "App" value from "Aura (Google Play, App Store)" to "Aura (web, Google Play, App Store)".

2. Footer: directly under the line "© Silvermind OÜ. …", add one line in the same small footer style:

Silvermind OÜ · Registry code 17345387 · Lõõtsa tn 5, 11415 Tallinn, Estonia · support@aura-app.cc · [PHONE]

("support@aura-app.cc" is a mailto link.)
```

## 4. Лендинг /

```text
Update the landing page (https://aura-app.cc/).

Change ONLY what is listed below. Keep everything else exactly as it is now, including the inactive "App Store · Soon" buttons and both Google Play buttons (same links, look and order).

1. Web app button. In both groups of store buttons — in the hero (the block with id="get") and in the closing call-to-action — add a third button after the Google Play button, in the same size and shape as the store buttons, linking to https://web.aura-app.cc (same tab). Small top line: "Open in your", main line: "Browser". Give it a simple globe icon in the same style as the store icons. It is active, with the same hover and press effect as the Google Play button. Screen readers announce it as "Open Aura in your browser". On narrow screens the three buttons wrap the same way the two do now.

2. Prices line. In the hero, directly under the line "Every reading starts free · no card details", add one more line in the same small style:

Top-ups from $5 to $120 · sessions from $2.20/min

3. Footer: directly under the line "© Silvermind OÜ. …", add one line in the same small footer style:

Silvermind OÜ · Registry code 17345387 · Lõõtsa tn 5, 11415 Tallinn, Estonia · support@aura-app.cc · [PHONE]

("support@aura-app.cc" is a mailto link.)

Change nothing else on the page.
```

## После публикации

- Снять четыре страницы (байты, sha256), распаковать шаблон и сверить по абзацам с этими промптами.
- В Stripe (владелец): Public details и Checkout Settings — по таблице `011`.
- Строка цен: прод 2026-11-17 — от $2.20 до $3.80 в минуту. Перед отправкой промпта сверить
  `bff.aura-app.cc/v1/advisors`.
