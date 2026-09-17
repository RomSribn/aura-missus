# AURAT-0042-118 — Опубликованные страницы: проверка и снимок текста

Дата: 2026-09-17
Где: `https://aura-app.cc` (Netlify через Cloudflare). Страницы выложил
владелец. Манор сверил их с брифом (`AURAT-0042-claude-design-brief.md`).

## Как проверялось

Страницы — экспорт Claude Design («bundled page»): текст лежит в шаблоне
внутри файла, React и шрифты зашиты в тот же файл. Проверка шла по
распакованному шаблону:
- в обе стороны: каждый фрагмент брифа есть на странице, каждое предложение
  страницы есть в брифе;
- отдельно — ссылки, заголовки, внешние адреса и cookies.

## Первая выкладка 17.09 — текст брифа от 16.09

- Выложена версия брифа до сроков `AURAT-0074` (`d51b7aa`). В privacy §07
  «Server logs» не было исключения про упавшие задачи, «Delivery queues» —
  без сроков. В «Kept» на странице удаления был старый пункт про очереди и не
  было пункта про логи.
- Claude Design сама заменила пример телефона на `+1 415 555 0123`.
- Ни у одной страницы не было `<title>`.

Владелец отправил в Claude Design правку из шести пунктов (текст — дословно
из брифа) и перевыложил.

## Вторая выкладка 17.09 — принята

| URL | байт | sha256 |
|---|---|---|
| `https://aura-app.cc/privacy/` | 550 609 | `d9ee463f0474ac2506f9511788004856927d809b33ef13095b5ca9e19df77753` |
| `https://aura-app.cc/terms/` | 545 044 | `b4744eba03137d2454023034f06c6c302bf73f7d40442f1e5f99cbf41ed4b2af` |
| `https://aura-app.cc/delete-account/` | 532 780 | `292303a9ac8dd3a30a2629358caeb76623cda816c7de41e8c8d3f337fcc917d0` |

- Все три отвечают `200`; без слеша — `301` на адрес со слешем.
- `Set-Cookie` нет.
- Сетевых запросов к чужим хостам нет: `unpkg.com` встречается только как
  имя зашитого ресурса. Единственная внешняя ссылка — `https://www.aki.ee`.
- App Store и Apple не упоминаются.
- `mailto:`:
  - privacy — `privacy@`;
  - terms — `support@`;
  - delete-account — `privacy@`, `support@` и кнопка «Email us» с темой
    `Delete my Aura account`.
- Один `h1` на страницу, `h2` на каждый раздел, таблица в privacy §03,
  оглавление `#s01…`.
- `<title>`: «Privacy Policy — Aura», «Terms of Service — Aura», «Delete your
  Aura account — Aura».
- «Last updated»: privacy и delete-account — 17 September 2026, terms —
  16 September 2026.
- **Текст совпадает с брифом дословно.** Ни одной фразы старой версии не
  осталось. Отличия только в оформлении:
  - мета-блок и пункты §07 — «ярлык + текст» вместо «ярлык — текст»;
  - ссылки на страницы подписаны их названиями вместо `(/privacy/)`.

## Вне брифа — не исправлено

Главная `/`: «App Store» — 3 раза, ссылки на Google Play нет (часть 2 брифа,
«Известные дыры»). Privacy §12 говорит, что сайт ведёт в Google Play.

## Дальше

Play Console:
- privacy URL — `https://aura-app.cc/privacy/`;
- URL удаления — `https://aura-app.cc/delete-account/`;
- Data safety — по таблице части 2 брифа.

## Снимок опубликованного текста

Текст извлечён из шаблона страниц (вторая выкладка), навигация и оглавление
опущены. Это копия под контролем версий: следующую выкладку сравнивать с ней.

### `/privacy/`

```text
Privacy Policy — Aura
Legal

# Privacy Policy
This policy explains what Aura collects, why we collect it, who can see it, and the choices you have. It applies to the Aura mobile app and to this website, both operated by Silvermind OÜ.
Last updated
17 September 2026
Controller
Silvermind OÜ (Estonia)
Privacy contact
privacy@aura-app.cc

## 01 · Who we are
Aura is operated by Silvermind OÜ, a private limited company registered in Estonia. For the purposes of the EU General Data Protection Regulation (GDPR) and the Estonian Personal Data Protection Act, Silvermind OÜ is the controller of the personal data described here. You can reach us about privacy at privacy@aura-app.cc , and our postal address is available on request.
The advisors you meet in Aura are personas created by us. An advisor's name, photo and description introduce a style of reading; the messages you send to an advisor are read and answered by members of our advisor team, who work under our instructions and confidentiality obligations. More than one team member may answer under the same advisor. They do not use your data for their own purposes.

## 02 · What we collect
We try to collect only what the service needs.

### Account and profile
Your mobile phone number, which is how you sign in with a one-time code. The name you choose, which is required to create an account. If you choose to add them: your email address, your date of birth (the date only — no time or place of birth), and a profile photo. Your choice about receiving marketing emails. We do not ask for your legal name or your home address.

### What you share in Aura
The messages you send to advisors and the files you attach — photos, images, videos, audio files and documents. The tarot cards dealt to you and the choices you make in a reading. Reviews you write: your star rating, any text you add, and whether you posted it anonymously.

### Payments, balance and sessions
When you buy credits, the purchase is handled by Google Play. We receive a confirmation of the purchase (a purchase token, an order number and the product you bought) and keep your balance and your session history: when a session was booked, how long it was, what it cost and any refund. We never receive your card number, bank details or Google account password.

### Technical data
A push notification token for your device and whether it runs Android or iOS. Your time zone, so that the daily card and booking times match your day. Like any online service, our servers see your IP address and the technical details your app or browser sends with each request, and record them in server logs. Aura contains no advertising, analytics or crash reporting software and does not use an advertising identifier.
We do not sell personal data, and we do not run advertising networks inside Aura.

## 03 · Why we use it, and on what legal basis
| Purpose | Legal basis (GDPR Art. 6) |
| Creating your account and signing you in | Performance of a contract |
| Delivering readings, keeping your conversations and files | Performance of a contract |
| Showing your name and profile photo to our advisor team | Performance of a contract |
| Using the optional details you add, such as your date of birth for horoscope features | Performance of a contract, at your choice |
| Publishing the reviews you write | Performance of a contract |
| Processing credit purchases, sessions and refunds, and keeping accounting records | Contract; legal obligation (accounting) |
| Service notifications about new messages and your sessions | Performance of a contract |
| Marketing emails | Your consent, which you can withdraw at any time |
| Security, fraud prevention, abuse investigation and server logs | Legitimate interests |
| Responding to legal claims and requests from authorities | Legal obligation; legitimate interests |

## 04 · Readings are not health data
Aura is an entertainment service. We never ask you for medical, psychiatric, religious, political or biometric information. If you volunteer something sensitive in a conversation — an illness, a diagnosis, a belief — you are asking us to process it, and we handle it on the basis of your explicit consent (GDPR Art. 9(2)(a)) for the sole purpose of delivering that conversation. Please do not send us more than a reading requires.

## 05 · Who sees your data
You see your own conversations, files, profile and history.
Our advisor team sees your conversations with advisors and the files you attach, together with your name, your phone number and your profile photo. They do not see your email address or your date of birth. They work in a customer-conversation tool that we run on our own servers.
Other Aura users see the reviews you publish: your star rating, your text once it has been approved, and your first name — or "Anonymous" if you choose to post anonymously. Before written review text is published, a member of our team reads it.
A small number of our staff with administrative access can reach account and conversation data where necessary to support you, to investigate abuse, or to comply with the law, under confidentiality obligations.
We rely on these service providers, who process data on our behalf:
- Google (Firebase) — phone-number sign-in and push notifications. Notifications tell your device that a new message has arrived; they do not contain the message text.
- Google Play — app distribution and in-app purchases, acting under its own privacy policy.
- Hetzner Online — the servers and databases that run Aura, in Finland (EU).
- Cloudflare — file storage with EU data location, used for attachments, profile photos and database backups; and our domain name service.
- Resend — delivery of the emails our customer-conversation tool sends to our team.
- Netlify — hosting of this website.
We disclose data to courts, regulators or law enforcement only where we are legally required to, and to a buyer or successor if our business is reorganised — in which case this policy continues to apply until you are told otherwise.

## 06 · Transfers outside the EEA
We store Aura's data in the European Union. Some of our providers — Google, Cloudflare, Resend and Netlify — are companies based outside the European Economic Area and may process limited data outside it. Where that happens we rely on an adequacy decision of the European Commission, including the EU–US Data Privacy Framework where the provider is certified under it, or on the Commission's Standard Contractual Clauses. You may ask us for a copy of the relevant safeguards.

## 07 · How long we keep it
Account and profile
While your account exists. When you delete your account, they are erased, including your sign-in identity at Google Firebase.
Conversations and files
While your account exists, so you can come back to them. They are erased when you delete your account, including the copies in our customer-conversation tool. That tool keeps technical audit entries about conversation settings, which contain no message text.
Reviews
When you delete your account, your star ratings stay on the advisors' profiles as "Anonymous", with your name and your text removed.
Purchases, balance and sessions
At least seven years, as Estonian accounting law requires. When you delete your account, these records are kept without your name, phone number or anything else that identifies you.
Push notification tokens
Until you sign out, delete your account, or the token stops working.
Server logs
Kept in rotating files that are overwritten as new entries arrive; we do not archive them. Logs do not record the content of your messages. The exception is when a background task in our customer-conversation tool fails: its log entry may include your phone number and part of a message until the log is overwritten.
Delivery queues
Messages and notifications on their way between the app, our advisor team and your device pass through queues on our servers. An entry is deleted within 25 hours after it is delivered, or within 8 days if delivery fails. This also applies to entries still in a queue when you delete your account. Queues are not included in backups.
Backups
Our databases are backed up daily and each backup is kept for up to 30 days, so deleted data disappears from backups within 30 days. If we ever have to restore a backup, we repeat the deletions made after it was taken.

## 08 · Your rights
Under the GDPR you may ask us to give you access to your data, correct it, delete it, restrict or object to how we use it, and provide it in a portable form. Where we rely on consent, you may withdraw it at any time, without affecting processing that already took place.
In the app you can change your name, email address, date of birth, profile photo and marketing choice under Edit Profile, and you can delete your account from the Profile screen. For anything else — including a copy of your data — write to privacy@aura-app.cc with the phone number of your account, and we will answer within one month. If you no longer have the app, see Delete your account (/delete-account/).
If you believe we have handled your data badly, you can complain to the Estonian Data Protection Inspectorate (Andmekaitse Inspektsioon, aki.ee ) or to the supervisory authority where you live. We would rather hear from you first.

## 09 · Security
Traffic between the app and our servers is encrypted in transit. Our app serves attachments and profile photos only to the signed-in account they belong to. Inside our customer-conversation tool, attachments and profile photos open through long, unguessable links that work without signing in; these links are shown only to our advisor team and are never sent to your device or to other users. Sign-in relies on a one-time code sent to your phone rather than a reusable password. No service can promise perfect security, so please keep access to your phone number and device protected. If a breach ever affects your rights, we will notify you and the Inspectorate as the GDPR requires.

## 10 · Notifications and marketing
Push notifications tell you when an advisor replies and when a paid session starts or ends. You can turn them off in your device settings at any time. Marketing emails about offers and recommendations are sent only if you switch on email updates — the switch is off unless you turn it on — and you can switch it off again under Edit Profile. Every marketing email will carry a way to unsubscribe.

## 11 · Children
Aura is for adults: you must be 18 or older to use it, and you confirm this when you sign in. We do not knowingly collect data from anyone under 18. If you believe a minor is using Aura, write to privacy@aura-app.cc and we will delete the account.

## 12 · This website and cookies
This site describes the app and sends you to Google Play. It sets no cookies and uses no analytics. Our hosting provider keeps standard server logs, including IP addresses, for security and for aggregate visit counts. If we ever add analytics or measurement cookies, we will ask for your consent first and update this section.

## 13 · Changes and contact
If we change this policy we will update the date at the top. For material changes we will make reasonable efforts to tell you in advance, for example in the app. Questions, requests and complaints go to privacy@aura-app.cc . Our terms of use are set out in the Terms of Service (/terms/).
Your first reading is still free.
Get the app
© Silvermind OÜ. All rights reserved 2026. Psychic readings are for entertainment purposes only. Must be 18 years or older.
Privacy (/privacy/)
Terms (/terms/)
Delete account (/delete-account/)
```

### `/terms/`

```text
Terms of Service — Aura
Legal

# Terms of Service
These terms govern your use of the Aura app and this website. Please read them before you create an account.
Last updated
16 September 2026
Provider
Silvermind OÜ (Estonia)
Support
support@aura-app.cc

## 01 · Who we are
Aura is provided by Silvermind OÜ, a private limited company registered in Estonia ("we", "us", "Aura"). "You" means the person using the app or this website. These terms, together with the Privacy Policy (/privacy/), form the whole agreement between us. They are written in English; a translation, if we publish one, is for convenience only.

## 02 · Who may use Aura
You must be at least 18 years old and legally able to enter into a contract. By signing in you confirm both. You may not use Aura on behalf of anyone else, and you may not let another person use your account. If we learn that an account belongs to a minor, we delete it.

## 03 · Entertainment, not advice
Psychic readings, tarot and astrology on Aura are offered for entertainment purposes only. Nothing said in a reading is a statement of fact, a prediction that will come true, or professional advice of any kind — medical, psychological, psychiatric, legal, financial, or otherwise. Advisors are not doctors, therapists, lawyers or financial advisers, and a reading is not a substitute for consulting one.
You are responsible for your own decisions and actions. If you are in crisis, or worried about your health or safety or someone else's, contact your local emergency number or a qualified professional — Aura is not an emergency or crisis service.

## 04 · Your account
You sign in with your mobile phone number and a one-time code, so keeping your phone and number secure is what keeps your account secure. Tell us at support@aura-app.cc if you think someone else has access. Give accurate information, keep it current, and use one account per person.
You can delete your account at any time from the Profile screen in the app, or by following the steps at Delete your Aura account (/delete-account/). An account cannot be deleted while a session is booked or in progress: cancel the session or let it finish first. Deleting your account is permanent, and any unused credits are lost — if you want them refunded, ask before you delete (section 07).

## 05 · Advisors
The advisors in Aura are personas presented by us. An advisor's name, photo and description introduce a style and specialism of reading; the messages you receive from an advisor are written by members of our advisor team, and more than one team member may answer under the same advisor. We do not guarantee the accuracy, usefulness or outcome of anything said in a reading.
Conversations must stay inside Aura. Asking an advisor for private contact details, arranging payment outside the app, or soliciting advisors for other services is not allowed, and we may close accounts for doing it.
Star ratings and reviews shown in the app come from users and reflect their opinions, not ours. Written review text is read by our team before it is published.

## 06 · Free start, paid depth
Every reading on Aura begins free of charge, without entering card details. Going deeper is a paid option — and it is only ever your decision to take it. Nothing is charged until you confirm it in the app.
Paid sessions are private conversations with an advisor for a length of time you book in advance, paid from credits you buy through Google Play. Before your booked time runs out, the app asks whether you want to continue; if you do nothing, the session simply ends. Your first paid session is discounted. Prices and session lengths are shown in the app before you commit, and we may change them for future purchases and bookings.
Cancelling and rescheduling: if you cancel a session more than 24 hours before it starts, the full cost returns to your balance; if you cancel less than 24 hours before it starts, half of the cost returns to your balance. You can reschedule a session free of charge until 4 hours before it starts. If you end a session early, the unused part of the booked time is not returned.
Credits have no cash value and cannot be transferred between accounts. They can be refunded only as described in section 07.

## 07 · Payments and refunds
Purchases are processed by Google Play under its terms and payment rules. Google handles your payment details; we never see them. Prices include VAT where it applies.
Because credits are digital content delivered immediately, EU consumers who ask for immediate delivery and acknowledge it lose the 14-day right of withdrawal for the credits actually used. Unused credits can be refunded on request: write to support@aura-app.cc with the phone number of your account, and we will refund them through Google Play. Ask before you delete your account — once an account is deleted, its balance cannot be recovered or refunded. If a session failed for technical reasons on our side, write to support@aura-app.cc and we will credit or refund it. Nothing here limits the statutory rights you have as a consumer.

## 08 · House rules
Aura is a calm place and we intend to keep it that way. You agree not to:
- harass, threaten, insult or sexually solicit advisors or other users;
- send unlawful, hateful, or sexually explicit material, or content involving minors;
- impersonate anyone, or misrepresent who you are;
- use Aura for medical, legal or financial decisions, or ask advisors to make them for you;
- attempt fraudulent purchases or chargebacks, or abuse free readings or first-session discounts through multiple accounts;
- copy, scrape, resell or republish readings, profiles or app content;
- interfere with the service — reverse engineering, automated access, security testing without our written consent, or anything that overloads our systems.

## 09 · Your content
What you write and upload stays yours. To run the service, you give us a limited, worldwide, royalty-free licence to store, transmit and display that content to you and to our advisor team, and to keep it available in your conversation history. When you publish a review, the licence also covers showing your star rating, your text and your first name (or "Anonymous") to other users; if you delete your account, your star ratings stay as "Anonymous" without your name or text. We use your content for nothing else. You confirm you have the right to share what you send, and that it does not infringe anyone's rights.
If you send us feedback or ideas about Aura, we may use them without obligation to you.

## 10 · Our content
The Aura app, this website, the name, the logo, the interface, the illustrations and the texts we publish belong to Silvermind OÜ or our licensors. We grant you a personal, non-exclusive, non-transferable, revocable licence to use the app for your own private, non-commercial purposes. Everything not expressly granted is reserved.

## 11 · Availability
We work to keep Aura available, but we cannot promise it will be uninterrupted or error-free. We may add, change or withdraw features, and we may take the service down for maintenance. Advisors are not available at all hours, and an advisor may be withdrawn from Aura. Where a change materially reduces what you paid for, we will refund the unused credits.

## 12 · Suspension and closure
You may stop using Aura and delete your account whenever you like, as described in section 04. We may suspend or close an account if these terms are broken, if we are required to by law, or where we reasonably suspect fraud or abuse — normally with notice, and immediately where the breach is serious. If we close your account without cause, we refund unused credits. Sections 03, 09, 10, 13 and 14 survive the end of this agreement.

## 13 · Liability
Aura is provided as an entertainment service, without warranty that any reading will be accurate, complete, or lead to any particular outcome. To the fullest extent the law allows, we are not liable for decisions you take after a reading, for what an advisor says, for indirect or consequential loss, or for lost profits, data or opportunities. Where we are liable, our total liability for any claim is limited to the amount you paid us in the twelve months before the claim arose, or €100 if that is greater.
Nothing in these terms excludes liability that cannot lawfully be excluded — including for death or personal injury caused by negligence, for fraud, or for the mandatory rights of consumers under Estonian and EU law.

## 14 · Law and disputes
These terms are governed by the law of the Republic of Estonia. Disputes go to the courts of Estonia, except that consumers keep the right to bring proceedings in the country where they live and to rely on its mandatory consumer protections. Consumers in the EU may also use the Estonian Consumer Disputes Committee. Please write to us first — most things are settled that way.

## 15 · Changes and contact
We may update these terms; the date at the top always shows the current version, and for material changes we will make reasonable efforts to tell you in advance, for example in the app. Continuing to use Aura after changes take effect means you accept the new terms. If one provision turns out to be unenforceable, the rest still stands. Write to support@aura-app.cc for anything at all — including a copy of these terms in a durable form.
Your first reading is still free.
Get the app
© Silvermind OÜ. All rights reserved 2026. Psychic readings are for entertainment purposes only. Must be 18 years or older.
Privacy (/privacy/)
Terms (/terms/)
Delete account (/delete-account/)
```

### `/delete-account/`

```text
Delete your Aura account — Aura
Legal

# Delete your Aura account
Aura is an app by Silvermind OÜ. You can delete your Aura account and the data linked to it at any time — in the app, or by writing to us if you no longer have the app.
Last updated
17 September 2026
App
Aura (Google Play)
Developer
Silvermind OÜ
Contact
privacy@aura-app.cc

## 01 · In the app
- Open Aura and go to the Profile tab.
- Tap "Delete account", below "Sign out".
- Read what will be deleted and tap "Delete account" to confirm.
Your account is deleted straight away and you are signed out.

## 02 · Without the app
- Email privacy@aura-app.cc with the subject "Delete my Aura account".
- Include the phone number of your account, in international format (for example +34 600 000 000).
- We may ask you for details to make sure the account is yours. We delete the account and confirm by email within one month.
Email us

## 03 · Before you delete
If a session is booked or in progress, cancel it or let it finish first — an account cannot be deleted while a session is active.
Any unused credits are lost when your account is deleted. If you want them refunded, write to support@aura-app.cc before you delete your account.
Deletion is permanent. If you sign in again later with the same phone number, you will start a new, empty account.

## 04 · What is deleted and what is kept

### Deleted
- your profile: name, phone number, email address, date of birth and profile photo;
- your conversations and the files you attached, including the copies in our customer-conversation tool;
- the tarot cards dealt to you;
- your push notification tokens;
- your sign-in identity at Google Firebase.

### Kept
- records of purchases, balance and paid sessions, for at least seven years as Estonian accounting law requires — without your name, phone number or anything else that identifies you;
- the star ratings of reviews you wrote, shown as "Anonymous" with your name and text removed;
- technical audit entries in our customer-conversation tool about conversation settings, which contain no message text;
- entries still in the queues that carry messages and notifications through our servers, for up to 25 hours, or up to 8 days for a delivery that failed;
- server log entries from background tasks that failed, which may include your phone number and part of a message, until the logs are overwritten;
- a record that the account was deleted and when, without your name, phone number or contact details, so that the deletion can be repeated if a backup is ever restored;
- database backups made before the deletion, for up to 30 days, after which they are overwritten.
More about how we handle data: Privacy Policy (/privacy/).
Your first reading is still free.
Get the app
© Silvermind OÜ. All rights reserved 2026. Psychic readings are for entertainment purposes only. Must be 18 years or older.
Privacy (/privacy/)
Terms (/terms/)
Delete account (/delete-account/)
```
