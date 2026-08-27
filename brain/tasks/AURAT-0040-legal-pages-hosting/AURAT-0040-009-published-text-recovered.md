# AURAT-0040-009 — Опубликованный текст, снятый с боевых страниц

Дата снятия: **2026-08-27**
Источник: `https://aura-app.cc/privacy/` и `/terms/`, оба `200`
Метод: текст лежит в HTML обычными строковыми литералами (в сжатых блоках
только шрифты и React) — рецепт извлечения записан в `AURAS-0004`, раздел
«The legal pages are not on this host», и **проверен исполнением**, а не
переписан по памяти.

## Зачем этот файл

Исходника страниц **не существует нигде**: учётка Netlify личная, деплой
перетаскиванием, в гите ничего. Единственная копия была развёрнутым артефактом
на Netlify, у которого нет ни истории, ни версий.

Это первая копия под контролем версий. Она **не заменяет исходник** — из неё
нельзя собрать страницу обратно, вёрстка и шрифты сюда не входят. Она отвечает
на два вопроса, на которые сегодня ответить нечем: **что именно было
опубликовано на эту дату** и **изменилось ли что-то с тех пор** (снять заново
тем же рецептом и сравнить).

Расхождения этого текста с кодом разобраны в `AURAT-0040-007` — одиннадцать штук.

---

## `/privacy/`

```text
Aura
Terms
← Back to Aura
Legal
Privacy Policy
This policy explains what Aura collects, why we collect it, and the choices you have. It applies to the Aura mobile app and to this website, both operated by Silvermind OÜ.
Last updated
27 August 2026
Controller
Silvermind OÜ (Estonia)
Privacy contact
info@aura-app.cc
On this page
01 Who we are
02 What we collect
03 Why we use it
04 Readings are not health data
05 Who sees your data
06 Transfers outside the EEA
07 How long we keep it
08 Your rights
09 Security
10 Notifications and marketing
11 Children
12 Website and cookies
13 Changes and contact
01 · Who we are
Aura is operated by Silvermind OÜ , a private limited company registered in Estonia. For the purposes of the EU General Data Protection Regulation (GDPR) and the Estonian Personal Data Protection Act, Silvermind OÜ is the controller of the personal data described here. You can reach our privacy team at info@aura-app.cc , and our postal address is available on request.
Advisors who give readings on Aura are independent practitioners rather than our employees. Where an advisor processes information about you for their own purposes, they act as a separate controller; where they read and reply to your messages inside Aura, they do so under our instructions.
02 · What we collect
We try to collect as little as the service allows. In practice that is four groups of data.
Account data
Your mobile phone number, which we use to sign you in with a one-time code, and the display name you choose. We do not ask for your legal name, your address or your email address to create an account.
What you tell an advisor
Your chat messages, the questions you ask, dreams you write down, any photographs or files you attach, and birth details (date, time and place) if you choose to share them for an astrological reading. This content is stored so that you and the advisor can return to the conversation later.
Payment and balance data
If you decide to buy credits, the purchase itself is handled by the App Store or Google Play. We receive a confirmation that a purchase was made and the resulting balance and session history — never your card number, bank details or store password .
Technical data
Device model and operating system version, app version, language, a push notification token, IP address, and diagnostic or crash reports. We use this to keep the app running and to investigate faults and abuse.
We do not sell personal data, and we do not run third-party advertising networks inside Aura.
03 · Why we use it, and on what legal basis
Purpose Legal basis (GDPR Art. 6)
Creating your account and signing you in Performance of a contract
Delivering readings and keeping your chat history Performance of a contract
Processing credit purchases and keeping records Contract; legal obligation (accounting)
Service notifications about your sessions Performance of a contract
Optional marketing messages Your consent, withdrawable at any time
Security, fraud prevention and abuse investigation Legitimate interests
Aggregated, non-identifying product statistics Legitimate interests
Responding to legal claims and requests from authorities Legal obligation; legitimate interests
04 · Readings are not health data
Aura is an entertainment service. We never ask you for medical, psychiatric, religious, political or biometric information, and advisors are instructed not to request it. If you volunteer something sensitive in a chat — an illness, a diagnosis, a belief — you are asking us to process it, and we handle it on the basis of your explicit consent (GDPR Art. 9(2)(a)) for the sole purpose of delivering that conversation. Please do not send us more than a reading requires.
05 · Who sees your data
Your conversation is visible to you and to the advisor you chose. A small number of our staff can access account and conversation data where necessary to support you, to investigate a report of abuse, or to comply with the law, under confidentiality obligations.
We also rely on service providers who process data on our behalf under written data-processing agreements:
Google (Firebase) — phone-number sign-in, push notifications and crash diagnostics.
Apple and Google — in-app purchases and app distribution, acting under their own privacy policies.
Cloud hosting and storage providers in the European Union, which run our servers and store chat content and attachments.
Customer-support tooling used to answer your messages to us.
We disclose data to courts, regulators or law enforcement only where we are legally required to, and to a buyer or successor if our business is reorganised — in which case this policy continues to apply until you are told otherwise.
06 · Transfers outside the EEA
We keep data in the European Economic Area wherever we can. Some providers — notably Google and Apple — may process limited data outside the EEA. Where that happens we rely on an adequacy decision of the European Commission or on the Commission's Standard Contractual Clauses together with additional technical safeguards. You may ask us for a copy of the relevant safeguards.
07 · How long we keep it
Account data — for as long as your account exists, then up to 30 days in backups.
Chats and attachments — while your account exists, so you can re-read them; deleted with the account, or earlier if you delete a conversation.
Purchase and accounting records — seven years, as Estonian accounting law requires.
Diagnostic and security logs — normally up to 12 months.
08 · Your rights
Under the GDPR you may ask us to give you access to your data, correct it, delete it, restrict or object to how we use it, and provide it in a portable form. Where we rely on consent, you may withdraw it at any time, without affecting processing that already took place. You can delete your account from the app's profile screen, or write to info@aura-app.cc and we will answer within one month.
If you believe we have handled your data badly, you can complain to the Estonian Data Protection Inspectorate (Andmekaitse Inspektsioon, aki.ee ) or to the supervisory authority where you live. We would rather hear from you first.
09 · Security
Traffic between the app and our servers is encrypted in transit, attachments are served only to authenticated requests, access to production systems is limited and logged, and sign-in relies on a one-time code sent to your phone rather than a reusable password. No service can promise perfect security, so please keep access to your phone number and device protected. If a breach ever affects your rights, we will notify you and the Inspectorate as the GDPR requires.
10 · Notifications and marketing
Push notifications tell you when an advisor replies or when a session is about to end. You can turn them off in your device settings at any time. Marketing messages are sent only with your consent and every one of them carries a way to unsubscribe.
11 · Children
Aura is for adults: you must be 18 or older to create an account. We do not knowingly collect data from anyone under 18. If you believe a minor is using Aura, write to info@aura-app.cc and we will close the account and erase the data.
12 · This website and cookies
This marketing site exists to describe the app and send you to the App Store or Google Play. It sets no advertising or profiling cookies. Our hosting provider keeps standard server logs, including IP addresses, for security and for aggregate visit counts. If we ever add analytics or measurement cookies, we will ask for your consent first and update this section.
13 · Changes and contact
If we change this policy we will update the date at the top and, for anything material, tell you in the app before it takes effect. Questions, requests and complaints go to info@aura-app.cc . Our terms of use are set out in the Terms of Service .
Your first reading is still free.
Get the app
© Silvermind OÜ. All rights reserved 2026. Psychic Reading is for entertainment purposes only. Must be 18 years or older.
```

---

## `/terms/`

```text
01 · Who we are
Aura is provided by Silvermind OÜ , a private limited company registered in Estonia (“we”, “us”, “Aura”). “You” means the person using the app or this website. These terms, together with the Privacy Policy , form the whole agreement between us. They are written in English; a translation, if we publish one, is for convenience only.
02 · Who may use Aura
You must be at least 18 years old and legally able to enter into a contract. By creating an account you confirm both. You may not use Aura on behalf of anyone else, and you may not let another person use your account. If we learn that an account belongs to a minor, we close it and delete the data.
03 · Entertainment, not advice
Psychic readings, tarot, astrology and dream interpretation on Aura are offered for entertainment purposes only . Nothing said in a reading is a statement of fact, a prediction that will come true, or professional advice of any kind — medical, psychological, psychiatric, legal, financial, or otherwise. Advisors are not doctors, therapists, lawyers or financial advisers, and a reading is not a substitute for consulting one.
You are responsible for your own decisions and actions. If you are in crisis, or worried about your health or safety or someone else's, contact your local emergency number or a qualified professional — Aura is not an emergency or crisis service .
04 · Your account
You sign in with your mobile phone number and a one-time code, so keeping your phone and number secure is what keeps your account secure. Tell us at support@aura-app.cc if you think someone else has access. Give accurate information, keep it current, and use one account per person. You can delete your account at any time from the profile screen in the app.
05 · Advisors
Advisors are independent practitioners who offer readings through Aura. They are not our employees or agents, and the words of a reading are their own. We check the profiles we publish and we act on reports, but we do not guarantee any advisor's abilities, qualifications, availability, or the accuracy, usefulness or outcome of anything said in a reading.
Conversations must stay inside Aura. Asking an advisor for private contact details, arranging payment outside the app, or soliciting advisors for other services is not allowed, and we may close accounts on either side for doing it. Ratings and review counts shown in the app come from users and reflect their opinions, not ours.
06 · Free start, paid depth
Every reading on Aura begins free of charge. You can ask your question and receive a genuine first response without paying anything and without entering card details. Going deeper is a paid option — and it is only ever your decision to take it. Nothing is charged until you confirm it in the app.
Where paid sessions are available, they run on credits you buy in advance and spend in short blocks. Before a block ends the app asks whether you want to continue; if you do nothing, the session simply stops. Credits have no cash value, cannot be exchanged for money, and cannot be transferred between accounts. Prices, block lengths and the amount included in the free start are shown in the app before you commit, and we may change them for future purchases.
07 · Payments and refunds
Purchases are processed by Apple's App Store or Google Play, under their terms and their payment rules. They handle your payment details; we never see them. Prices include VAT where it applies.
Because credits are digital content delivered immediately, EU consumers who ask for immediate delivery and acknowledge it lose the 14-day right of withdrawal for the credits actually used; unused credits may be refunded on request. Refund requests for store purchases usually have to go through Apple or Google. If a session failed for technical reasons on our side, write to support@aura-app.cc and we will credit or refund it. Nothing here limits the statutory rights you have as a consumer.
08 · House rules
Aura is a calm place and we intend to keep it that way. You agree not to:
harass, threaten, insult or sexually solicit advisors or other users;
send unlawful, hateful, or sexually explicit material, or content involving minors;
impersonate anyone, or misrepresent who you are;
use Aura for medical, legal or financial decisions, or ask advisors to make them for you;
attempt fraudulent purchases, chargebacks or abuse of the free first reading through multiple accounts;
copy, scrape, resell or republish readings, profiles or app content;
interfere with the service — reverse engineering, automated access, security testing without our written consent, or anything that overloads our systems.
09 · Your content
What you write and upload stays yours. To run the service, you give us a limited, worldwide, royalty-free licence to store, transmit and display that content to you and to the advisor you chose, and to keep it available in your chat history. We use it for nothing else. You confirm you have the right to share what you send, and that it does not infringe anyone's rights.
If you send us feedback or ideas about Aura, we may use them without obligation to you.
10 · Our content
The Aura app, this website, the name, the logo, the interface, the illustrations and the texts we publish belong to Silvermind OÜ or our licensors. We grant you a personal, non-exclusive, non-transferable, revocable licence to use the app for your own private, non-commercial purposes. Everything not expressly granted is reserved.
11 · Availability
We work to keep Aura available, but we cannot promise it will be uninterrupted or error-free. We may add, change or withdraw features, and we may take the service down for maintenance. Advisors set their own hours, so the parlour is not always full, and an advisor you liked may stop reading on Aura. Where a change materially reduces what you paid for, we will refund the unused credits.
12 · Suspension and closure
You may stop using Aura and delete your account whenever you like. We may suspend or close an account if these terms are broken, if we are required to by law, or where we reasonably suspect fraud or abuse — normally with notice, and immediately where the breach is serious. If we close your account without cause, we refund unused credits. Sections 03, 09, 10, 13 and 14 survive the end of this agreement.
13 · Liability
Aura is provided as an entertainment service, without warranty that any reading will be accurate, complete, or lead to any particular outcome. To the fullest extent the law allows, we are not liable for decisions you take after a reading, for what an advisor says, for indirect or consequential loss, or for lost profits, data or opportunities. Where we are liable, our total liability for any claim is limited to the amount you paid us in the twelve months before the claim arose, or €100 if that is greater.
Nothing in these terms excludes liability that cannot lawfully be excluded — including for death or personal injury caused by negligence, for fraud, or for the mandatory rights of consumers under Estonian and EU law.
14 · Law and disputes
These terms are governed by the law of the Republic of Estonia. Disputes go to the courts of Estonia, except that consumers keep the right to bring proceedings in the country where they live and to rely on its mandatory consumer protections. Consumers in the EU may also use the European Commission's online dispute resolution platform, or the Estonian Consumer Disputes Committee. Please write to us first — most things are settled that way.
15 · Changes and contact
We may update these terms; the date at the top always shows the current version, and we will tell you in the app before material changes take effect. Continuing to use Aura after that means you accept the new terms. If one provision turns out to be unenforceable, the rest still stands. Write to support@aura-app.cc for anything at all — including a copy of these terms in a durable form.
Your first reading is still free.
Get the app
© Silvermind OÜ. All rights reserved 2026. Psychic Reading is for entertainment purposes only. Must be 18 years or older.
```
