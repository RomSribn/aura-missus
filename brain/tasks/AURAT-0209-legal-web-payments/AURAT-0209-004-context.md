# AURAT-0209-004 — Контекст: источники и факты

Дата: 2026-11-17

## Что проверено

- `AURAD-0023` с поправками до 2026-11-13; `AURAI-0013` «Риски», «Решения владельца», «Следующие
  шаги» п. 1–2, 4; `AURAI-0014` §4 (данные трейдера, телефон).
- Код (ground truth):
  - BFF `develop` `cd0975b`: Checkout Session — `price_data` USD, `client_reference_id = paymentId`,
    `metadata { paymentId, userId }` (внутренний `users.id`), `customer_email` из профиля, `locale`,
    `consent_collection` по `STRIPE_TERMS_CONSENT`. Таблица `stripe_top_ups` хранит сумму USD,
    сумму и валюту списания (`presentment*`), ID сессии / PaymentIntent / Charge, язык; почта
    обнуляется после ответа Stripe. Карты (бренд, last4), страны и адреса BFF не хранит. Есть
    `stripe_refunds`, `stripe_disputes`.
  - Веб `develop` `60bf412`: вход по телефону — Firebase с reCAPTCHA (в форме ссылки на правила
    Google); ссылки на Terms / Privacy — `shared/config/legal.ts` → `aura-app.cc/terms/`,
    `/privacy/`; в браузере — `sessionStorage` (черновики брони, попытка оплаты и входа) и
    `localStorage` (язык, вид каталога, сезон); Stripe.js в шторке оплаты (Elements).
- Stripe docs: Public details — название, сайт, support email / **телефон** / адрес, support site,
  statement descriptor; Checkout Settings — ссылки на Terms, Privacy и refund policy (можно ссылкой на
  раздел). `consent_collection.terms_of_service = required` требует Terms URL в Public details.

## Факты для текста

- Пополнение на вебе — целые доллары $5–$120; на баланс ложится ровно USD-сумма; покупатель видит и
  платит в своей валюте (Adaptive Pricing, есть выбор валюты); методы сейчас — карта, Apple Pay,
  Google Pay, Link (банки — `AURAT-0214`).
- Возврат неистраченного — BFF через Stripe Refunds из бэкофиса, на исходный способ, не больше
  остатка пополнения. Диспут списывает сумму с баланса при `funds_withdrawn`, баланс может уйти в
  минус (`AURAD-0023` п. 4).
- Строка в выписке — `AURA-APP.CC` (рекомендация `AURAI-0013`, ставит владелец в анкете).
- Срок платёжных записей — Privacy §07 уже пишет «at least seven years, as Estonian accounting law
  requires» (Raamatupidamise seadus § 12: 7 лет). Менять не нужно.

## Расхождения и находки

1. **Privacy не покрывает веб-приложение.** Вводная: «applies to the Aura mobile app and to this
   website»; §12 — «This site … sets no cookies». А `web.aura-app.cc` — отдельное приложение: вход
   через Firebase с reCAPTCHA (Google), хранилище браузера, Stripe.js со своими куками от
   мошенничества. Покупатель на вебе этого в политике не найдёт. Предлагаю закрыть в этой же правке.
2. **Terms §07 называет кредиты «digital content delivered immediately».** Чтение — услуга с
   участием человека, а не цифровой контент (`AURAI-0013`: Managed Payments не взял по той же
   причине). Право отказа для услуги — Директива 2011/83/EU ст. 9, 14(3), 16(a). Переписать.
3. **Признание о потере права отказа должно быть в интерфейсе в момент брони** (ст. 16(a): «prior
   express consent and acknowledgement»), а не только в Terms. Это код веба и приложения на 24
   языках — вне задачи, отдельная задача.
4. Бесплатные кредиты (промокоды) в Terms не отделены от купленных.
5. НДС-номер Silvermind OÜ (2000/31/EC ст. 5(1)(g)) — если компания зарегистрирована по НДС. Вопрос
   НДС открыт (`AURAI-0013` шаг 4).

## Снимок `/terms/` (2026-11-17, основа правки)

```text
Terms of Service
These terms govern your use of the Aura app and this website. Please read them before you create an account.
Last updated
1 October 2026
Provider
Silvermind OÜ (Estonia)
Support
support@aura-app.cc [mailto:support@aura-app.cc]
On this page
01 Who we are [#s01]
02 Who may use Aura [#s02]
03 Entertainment, not advice [#s03]
04 Your account [#s04]
05 Advisors [#s05]
06 Free start, paid depth [#s06]
07 Payments and refunds [#s07]
08 House rules [#s08]
09 Your content [#s09]
10 Our content [#s10]
11 Availability [#s11]
12 Suspension and closure [#s12]
13 Liability [#s13]
14 Law and disputes [#s14]
15 Changes and contact [#s15]
01 · Who we are
Aura is provided by Silvermind OÜ, a private limited company registered in Estonia ("we", "us", "Aura"). "You" means the person using the app or this website. These terms, together with the Privacy Policy [/privacy/], form the whole agreement between us. They are written in English; a translation, if we publish one, is for convenience only.
02 · Who may use Aura
You must be at least 18 years old and legally able to enter into a contract. By signing in you confirm both. You may not use Aura on behalf of anyone else, and you may not let another person use your account. If we learn that an account belongs to a minor, we delete it.
03 · Entertainment, not advice
Psychic readings, tarot and astrology on Aura are offered for entertainment purposes only. Nothing said in a reading is a statement of fact, a prediction that will come true, or professional advice of any kind — medical, psychological, psychiatric, legal, financial, or otherwise. Advisors are not doctors, therapists, lawyers or financial advisers, and a reading is not a substitute for consulting one.
You are responsible for your own decisions and actions. If you are in crisis, or worried about your health or safety or someone else's, contact your local emergency number or a qualified professional — Aura is not an emergency or crisis service.
04 · Your account
You sign in with your mobile phone number and a one-time code, so keeping your phone and number secure is what keeps your account secure. Tell us at support@aura-app.cc [mailto:support@aura-app.cc] if you think someone else has access. Give accurate information, keep it current, and use one account per person.
You can delete your account at any time from the Profile screen in the app, or by following the steps at Delete your Aura account [/delete-account/]. An account cannot be deleted while a session is booked or in progress: cancel the session or let it finish first. Deleting your account is permanent, and any unused credits are lost — if you want them refunded, ask before you delete (section 07).
05 · Advisors
The advisors in Aura are personas presented by us. An advisor's name, photo and description introduce a style and specialism of reading; the messages you receive from an advisor are written by members of our advisor team, and more than one team member may answer under the same advisor. We do not guarantee the accuracy, usefulness or outcome of anything said in a reading.
Conversations must stay inside Aura. Asking an advisor for private contact details, arranging payment outside the app, or soliciting advisors for other services is not allowed, and we may close accounts for doing it.
Star ratings and reviews shown in the app come from users and reflect their opinions, not ours. Written review text is read by our team before it is published.
06 · Free start, paid depth
Every reading on Aura begins free of charge, without entering card details. Going deeper is a paid option — and it is only ever your decision to take it. Nothing is charged until you confirm it in the app.
Paid sessions are private conversations with an advisor for a length of time you book in advance, paid from credits you buy through the app store. Before your booked time runs out, the app asks whether you want to continue; if you do nothing, the session simply ends. Your first paid session is discounted. Prices and session lengths are shown in the app before you commit, and we may change them for future purchases and bookings.
Cancelling and rescheduling: if you cancel a session more than 24 hours before it starts, the full cost returns to your balance; if you cancel less than 24 hours before it starts, half of the cost returns to your balance. You can reschedule a session free of charge until 4 hours before it starts. If you end a session early, the unused part of the booked time is not returned.
Credits have no cash value and cannot be transferred between accounts. They can be refunded only as described in section 07.
07 · Payments and refunds
Purchases are processed by Google Play or the App Store under their terms and payment rules. The store handles your payment details; we never see them. Prices include VAT where it applies.
Because credits are digital content delivered immediately, EU consumers who ask for immediate delivery and acknowledge it lose the 14-day right of withdrawal for the credits actually used. Unused credits can be refunded on request: write to support@aura-app.cc [mailto:support@aura-app.cc] with the phone number of your account, and we will refund them through the store you bought from. Ask before you delete your account — once an account is deleted, its balance cannot be recovered or refunded. If a session failed for technical reasons on our side, write to support@aura-app.cc [mailto:support@aura-app.cc] and we will credit or refund it. Nothing here limits the statutory rights you have as a consumer.
08 · House rules
Aura is a calm place and we intend to keep it that way. You agree not to:
harass, threaten, insult or sexually solicit advisors or other users;
send unlawful, hateful, or sexually explicit material, or content involving minors;
impersonate anyone, or misrepresent who you are;
use Aura for medical, legal or financial decisions, or ask advisors to make them for you;
attempt fraudulent purchases or chargebacks, or abuse free readings or first-session discounts through multiple accounts;
copy, scrape, resell or republish readings, profiles or app content;
interfere with the service — reverse engineering, automated access, security testing without our written consent, or anything that overloads our systems.
09 · Your content
What you write and upload stays yours. To run the service, you give us a limited, worldwide, royalty-free licence to store, transmit and display that content to you and to our advisor team, and to keep it available in your conversation history. When you publish a review, the licence also covers showing your star rating, your text and your first name (or "Anonymous") to other users; if you delete your account, your star ratings stay as "Anonymous" without your name or text. We use your content for nothing else. You confirm you have the right to share what you send, and that it does not infringe anyone's rights.
If you send us feedback or ideas about Aura, we may use them without obligation to you.
10 · Our content
The Aura app, this website, the name, the logo, the interface, the illustrations and the texts we publish belong to Silvermind OÜ or our licensors. We grant you a personal, non-exclusive, non-transferable, revocable licence to use the app for your own private, non-commercial purposes. Everything not expressly granted is reserved.
11 · Availability
We work to keep Aura available, but we cannot promise it will be uninterrupted or error-free. We may add, change or withdraw features, and we may take the service down for maintenance. Advisors are not available at all hours, and an advisor may be withdrawn from Aura. Where a change materially reduces what you paid for, we will refund the unused credits.
12 · Suspension and closure
You may stop using Aura and delete your account whenever you like, as described in section 04. We may suspend or close an account if these terms are broken, if we are required to by law, or where we reasonably suspect fraud or abuse — normally with notice, and immediately where the breach is serious. If we close your account without cause, we refund unused credits. Sections 03, 09, 10, 13 and 14 survive the end of this agreement.
13 · Liability
Aura is provided as an entertainment service, without warranty that any reading will be accurate, complete, or lead to any particular outcome. To the fullest extent the law allows, we are not liable for decisions you take after a reading, for what an advisor says, for indirect or consequential loss, or for lost profits, data or opportunities. Where we are liable, our total liability for any claim is limited to the amount you paid us in the twelve months before the claim arose, or €100 if that is greater.
Nothing in these terms excludes liability that cannot lawfully be excluded — including for death or personal injury caused by negligence, for fraud, or for the mandatory rights of consumers under Estonian and EU law.
14 · Law and disputes
These terms are governed by the law of the Republic of Estonia. Disputes go to the courts of Estonia, except that consumers keep the right to bring proceedings in the country where they live and to rely on its mandatory consumer protections. Consumers in the EU may also use the Estonian Consumer Disputes Committee. Please write to us first — most things are settled that way.
15 · Changes and contact
We may update these terms; the date at the top always shows the current version, and for material changes we will make reasonable efforts to tell you in advance, for example in the app. Continuing to use Aura after changes take effect means you accept the new terms. If one provision turns out to be unenforceable, the rest still stands. Write to support@aura-app.cc [mailto:support@aura-app.cc] for anything at all — including a copy of these terms in a durable form.
```
