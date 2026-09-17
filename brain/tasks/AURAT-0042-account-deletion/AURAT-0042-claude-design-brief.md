# AURAT-0042 — Бриф для Claude Design: юридические страницы и страница удаления аккаунта

Дата: 2026-09-16
Пишет: `aura-app-manor` / `slave-0`
Статус: **draft** — текст сверен с проверками в маноре (`115`, правка
2026-09-16); публиковать после условий из части 2
Фактура: `107-app-legal-audit`, `115-manor-checks`; решения: `106`, `108`;
удаление: `008`/`009` половины BFF; проверка личности: черновик `116`.

Файл из двух частей:

- **Часть 1** — промпт для Claude Design. Копируется **целиком**, от строки
  `=== BEGIN PROMPT ===` до `=== END PROMPT ===`. Самодостаточен: в нём
  визуальный язык, структура и полный финальный текст трёх страниц.
- **Часть 2** — для владельца: что проверить до публикации, ответы для Data
  safety, откуда взято каждое утверждение. В Claude Design **не** вставлять.

Перед вставкой заменить одно место: `[PUBLICATION DATE]` → дата публикации
словами, например `20 October 2026` (встречается трижды).

---

# Часть 1 — промпт для Claude Design

```text
=== BEGIN PROMPT ===

Build three static legal pages for the Aura website (aura-app.cc). They replace
the existing /privacy/ and /terms/ pages and add a new /delete-account/ page.
The site is deployed as static files, so each page must work on its own route:
/privacy/, /terms/, /delete-account/ (each an index.html in its folder).

HARD RULES
1. Use the page text below VERBATIM. Do not add, remove, soften, summarise or
   reword any statement. Do not invent facts: no street addresses, company
   registration numbers, phone numbers, prices, dates or names that are not in
   the text. If something seems missing, leave it out.
2. No cookies, no analytics, no tracking pixels, no third-party embeds, no
   chat widgets. The only external resource allowed is Google Fonts.
3. No App Store / Apple badges or links anywhere. The app is on Google Play
   only. The "Get the app" button links to "/#get".
4. Every email address in the text is a mailto: link.
5. Accessible: semantic headings (one h1 per page, h2 per numbered section),
   real <table> elements for tables, visible focus states, colour contrast
   AA, works at 320px width without horizontal scroll.

VISUAL LANGUAGE (match the existing Aura legal pages)
- Fonts: headings "Cormorant Garamond" weight 600; body "Lora" regular/italic.
- Colours: background #F4EFE6; text #221F1A; secondary text #221F1A at ~65%
  opacity; dividers #221F1A at 13% opacity; surface/cards #FFFFFF; accent
  (links, primary button) #E0485F with hover #C43550; secondary accent teal
  #2BA39A (use sparingly, e.g. the "Kept" card marker); deep plum #1F122B for
  the closing call-to-action band.
- Reading column max width 68ch, body line-height 28px, side padding
  clamp(20px, 5vw, 64px). Small radii (2px / 4px / 7px). Soft shadows only.
- Calm, editorial, generous white space. No stock photos, no icons beyond a
  simple arrow for "Back".

SHARED PAGE SHELL (all three pages)
- Top bar: "Aura" wordmark (links to "/"), nav links "Terms" (/terms/),
  "Privacy" (/privacy/), "Delete account" (/delete-account/), and a
  "← Back to Aura" link to "/".
- Eyebrow label "Legal", then the page h1, then a short intro paragraph.
- Meta block (small, two columns on desktop): the key/value pairs given per
  page.
- "On this page" table of contents listing the numbered sections, each linking
  to its anchor (#s01, #s02, ...). Sticky in a left rail on wide screens,
  collapsed at the top on narrow screens.
- Numbered sections, heading format "01 · Title".
- Closing band on plum background: line "Your first reading is still free."
  and a coral button "Get the app" → "/#get".
- Footer: "© Silvermind OÜ. All rights reserved 2026. Psychic readings are for
  entertainment purposes only. Must be 18 years or older." plus the three
  legal links.

------------------------------------------------------------------------
PAGE 1 — /privacy/
------------------------------------------------------------------------
Title (h1): Privacy Policy
Intro: This policy explains what Aura collects, why we collect it, who can
see it, and the choices you have. It applies to the Aura mobile app and to
this website, both operated by Silvermind OÜ.
Meta: Last updated — [PUBLICATION DATE] · Controller — Silvermind OÜ
(Estonia) · Privacy contact — privacy@aura-app.cc

01 · Who we are
Aura is operated by Silvermind OÜ, a private limited company registered in
Estonia. For the purposes of the EU General Data Protection Regulation (GDPR)
and the Estonian Personal Data Protection Act, Silvermind OÜ is the controller
of the personal data described here. You can reach us about privacy at
privacy@aura-app.cc, and our postal address is available on request.
The advisors you meet in Aura are personas created by us. An advisor's name,
photo and description introduce a style of reading; the messages you send
to an advisor are read and answered by members of our advisor team, who work
under our instructions and confidentiality obligations. More than one team
member may answer under the same advisor. They do not use your data for their
own purposes.

02 · What we collect
We try to collect only what the service needs.
Account and profile
Your mobile phone number, which is how you sign in with a one-time code. The
name you choose, which is required to create an account. If you choose to
add them: your email address, your date of birth (the date only — no time or
place of birth), and a profile photo. Your choice about receiving marketing
emails. We do not ask for your legal name or your home address.
What you share in Aura
The messages you send to advisors and the files you attach — photos, images,
videos, audio files and documents. The tarot cards dealt to you and the
choices you make in a reading. Reviews you write: your star rating, any text
you add, and whether you posted it anonymously.
Payments, balance and sessions
When you buy credits, the purchase is handled by Google Play. We receive a
confirmation of the purchase (a purchase token, an order number and the
product you bought) and keep your balance and your session history: when a
session was booked, how long it was, what it cost and any refund. We never
receive your card number, bank details or Google account password.
Technical data
A push notification token for your device and whether it runs Android or
iOS. Your time zone, so that the daily card and booking times match your
day. Like any online service, our servers see your IP address and the
technical details your app or browser sends with each request, and record
them in server logs. Aura contains no advertising, analytics or crash
reporting software and does not use an advertising identifier.
We do not sell personal data, and we do not run advertising networks inside
Aura.

03 · Why we use it, and on what legal basis
Table with two columns — Purpose | Legal basis (GDPR Art. 6):
Creating your account and signing you in | Performance of a contract
Delivering readings, keeping your conversations and files | Performance of a contract
Showing your name and profile photo to our advisor team | Performance of a contract
Using the optional details you add, such as your date of birth for horoscope features | Performance of a contract, at your choice
Publishing the reviews you write | Performance of a contract
Processing credit purchases, sessions and refunds, and keeping accounting records | Contract; legal obligation (accounting)
Service notifications about new messages and your sessions | Performance of a contract
Marketing emails | Your consent, which you can withdraw at any time
Security, fraud prevention, abuse investigation and server logs | Legitimate interests
Responding to legal claims and requests from authorities | Legal obligation; legitimate interests

04 · Readings are not health data
Aura is an entertainment service. We never ask you for medical, psychiatric,
religious, political or biometric information. If you volunteer something
sensitive in a conversation — an illness, a diagnosis, a belief — you are
asking us to process it, and we handle it on the basis of your explicit
consent (GDPR Art. 9(2)(a)) for the sole purpose of delivering that
conversation. Please do not send us more than a reading requires.

05 · Who sees your data
You see your own conversations, files, profile and history.
Our advisor team sees your conversations with advisors and the files you
attach, together with your name, your phone number and your profile photo.
They do not see your email address or your date of birth. They work in a
customer-conversation tool that we run on our own servers.
Other Aura users see the reviews you publish: your star rating, your text
once it has been approved, and your first name — or "Anonymous" if you
choose to post anonymously. Before written review text is published, a member
of our team reads it.
A small number of our staff with administrative access can reach account and
conversation data where necessary to support you, to investigate abuse, or to
comply with the law, under confidentiality obligations.
We rely on these service providers, who process data on our behalf:
Google (Firebase) — phone-number sign-in and push notifications. Notifications
tell your device that a new message has arrived; they do not contain the
message text.
Google Play — app distribution and in-app purchases, acting under its own
privacy policy.
Hetzner Online — the servers and databases that run Aura, in Finland (EU).
Cloudflare — file storage with EU data location, used for attachments,
profile photos and database backups; and our domain name service.
Resend — delivery of the emails our customer-conversation tool sends to our
team.
Netlify — hosting of this website.
We disclose data to courts, regulators or law enforcement only where we are
legally required to, and to a buyer or successor if our business is
reorganised — in which case this policy continues to apply until you are told
otherwise.

06 · Transfers outside the EEA
We store Aura's data in the European Union. Some of our providers — Google,
Cloudflare, Resend and Netlify — are companies based outside the European
Economic Area and may process limited data outside it. Where that happens we
rely on an adequacy decision of the European Commission, including the
EU–US Data Privacy Framework where the provider is certified under it, or on
the Commission's Standard Contractual Clauses. You may ask us for a copy of
the relevant safeguards.

07 · How long we keep it
Account and profile — while your account exists. When you delete your
account, they are erased, including your sign-in identity at Google Firebase.
Conversations and files — while your account exists, so you can come back to
them. They are erased when you delete your account, including the copies in
our customer-conversation tool. That tool keeps technical audit entries about
conversation settings, which contain no message text.
Reviews — when you delete your account, your star ratings stay on the
advisors' profiles as "Anonymous", with your name and your text removed.
Purchases, balance and sessions — at least seven years, as Estonian accounting
law requires. When you delete your account, these records are kept without
your name, phone number or anything else that identifies you.
Push notification tokens — until you sign out, delete your account, or the
token stops working.
Server logs — kept in rotating files that are overwritten as new entries
arrive; we do not archive them. Logs do not record the content of your
messages. The exception is when a background task in our
customer-conversation tool fails: its log entry may include your phone number
and part of a message until the log is overwritten.
Delivery queues — messages and notifications on their way between the app,
our advisor team and your device pass through queues on our servers. An entry
is deleted within 25 hours after it is delivered, or within 8 days if
delivery fails. This also applies to entries still in a queue when you delete
your account. Queues are not included in backups.
Backups — our databases are backed up daily and each backup is kept for up to
30 days, so deleted data disappears from backups within 30 days. If we ever
have to restore a backup, we repeat the deletions made after it was taken.

08 · Your rights
Under the GDPR you may ask us to give you access to your data, correct it,
delete it, restrict or object to how we use it, and provide it in a portable
form. Where we rely on consent, you may withdraw it at any time, without
affecting processing that already took place.
In the app you can change your name, email address, date of birth, profile
photo and marketing choice under Edit Profile, and you can delete your
account from the Profile screen. For anything else — including a copy of your
data — write to privacy@aura-app.cc with the phone number of your account, and
we will answer within one month. If you no longer have the app, see Delete
your account (/delete-account/).
If you believe we have handled your data badly, you can complain to the
Estonian Data Protection Inspectorate (Andmekaitse Inspektsioon, aki.ee) or
to the supervisory authority where you live. We would rather hear from you
first.

09 · Security
Traffic between the app and our servers is encrypted in transit. Our app
serves attachments and profile photos only to the signed-in account they
belong to. Inside our customer-conversation tool, attachments and profile
photos open through long, unguessable links that work without signing in;
these links are shown only to our advisor team and are never sent to your
device or to other users. Sign-in relies on a one-time code sent to your phone rather than a
reusable password. No service can promise perfect security, so please keep
access to your phone number and device protected. If a breach ever affects
your rights, we will notify you and the Inspectorate as the GDPR requires.

10 · Notifications and marketing
Push notifications tell you when an advisor replies and when a paid session
starts or ends. You can turn them off in your device settings at any time.
Marketing emails about offers and recommendations are sent only if you switch
on email updates — the switch is off unless you turn it on — and you can
switch it off again under Edit Profile. Every marketing email will carry a way
to unsubscribe.

11 · Children
Aura is for adults: you must be 18 or older to use it, and you confirm this
when you sign in. We do not knowingly collect data from anyone under 18. If
you believe a minor is using Aura, write to privacy@aura-app.cc and we will
delete the account.

12 · This website and cookies
This site describes the app and sends you to Google Play. It sets no cookies
and uses no analytics. Our hosting provider keeps standard server logs,
including IP addresses, for security and for aggregate visit counts. If we
ever add analytics or measurement cookies, we will ask for your consent first
and update this section.

13 · Changes and contact
If we change this policy we will update the date at the top. For material
changes we will make reasonable efforts to tell you in advance, for example in
the app. Questions, requests and complaints go to privacy@aura-app.cc. Our
terms of use are set out in the Terms of Service (/terms/).

------------------------------------------------------------------------
PAGE 2 — /terms/
------------------------------------------------------------------------
Title (h1): Terms of Service
Intro: These terms govern your use of the Aura app and this website. Please
read them before you create an account.
Meta: Last updated — [PUBLICATION DATE] · Provider — Silvermind OÜ (Estonia)
· Support — support@aura-app.cc

01 · Who we are
Aura is provided by Silvermind OÜ, a private limited company registered in
Estonia ("we", "us", "Aura"). "You" means the person using the app or this
website. These terms, together with the Privacy Policy (/privacy/), form the
whole agreement between us. They are written in English; a translation, if we
publish one, is for convenience only.

02 · Who may use Aura
You must be at least 18 years old and legally able to enter into a contract.
By signing in you confirm both. You may not use Aura on behalf of anyone
else, and you may not let another person use your account. If we learn that
an account belongs to a minor, we delete it.

03 · Entertainment, not advice
Psychic readings, tarot and astrology on Aura are offered for entertainment
purposes only. Nothing said in a reading is a statement of fact, a prediction
that will come true, or professional advice of any kind — medical,
psychological, psychiatric, legal, financial, or otherwise. Advisors are not
doctors, therapists, lawyers or financial advisers, and a reading is not a
substitute for consulting one.
You are responsible for your own decisions and actions. If you are in crisis,
or worried about your health or safety or someone else's, contact your local
emergency number or a qualified professional — Aura is not an emergency or
crisis service.

04 · Your account
You sign in with your mobile phone number and a one-time code, so keeping
your phone and number secure is what keeps your account secure. Tell us at
support@aura-app.cc if you think someone else has access. Give accurate
information, keep it current, and use one account per person.
You can delete your account at any time from the Profile screen in the app,
or by following the steps at /delete-account/. An account cannot be deleted
while a session is booked or in progress: cancel the session or let it
finish first. Deleting your account is permanent, and any unused credits are
lost — if you want them refunded, ask before you delete (section 07).

05 · Advisors
The advisors in Aura are personas presented by us. An advisor's name, photo
and description introduce a style and specialism of reading; the messages you
receive from an advisor are written by members of our advisor team, and more
than one team member may answer under the same advisor. We do not guarantee
the accuracy, usefulness or outcome of anything said in a reading.
Conversations must stay inside Aura. Asking an advisor for private contact
details, arranging payment outside the app, or soliciting advisors for other
services is not allowed, and we may close accounts for doing it.
Star ratings and reviews shown in the app come from users and reflect their
opinions, not ours. Written review text is read by our team before it is
published.

06 · Free start, paid depth
Every reading on Aura begins free of charge, without entering card details.
Going deeper is a paid option — and it is only ever your decision to take
it. Nothing is charged until you confirm it in the app.
Paid sessions are private conversations with an advisor for a length of time
you book in advance, paid from credits you buy through Google Play. Before
your booked time runs out, the app asks whether you want to continue; if you
do nothing, the session simply ends. Your first paid session is discounted.
Prices and session lengths are
shown in the app before you commit, and we may change them for future
purchases and bookings.
Cancelling and rescheduling: if you cancel a session more than 24 hours
before it starts, the full cost returns to your balance; if you cancel less
than 24 hours before it starts, half of the cost returns to your balance. You
can reschedule a session free of charge until 4 hours before it starts. If
you end a session early, the unused part of the booked time is not returned.
Credits have no cash value and cannot be transferred between accounts. They
can be refunded only as described in section 07.

07 · Payments and refunds
Purchases are processed by Google Play under its terms and payment rules.
Google handles your payment details; we never see them. Prices include VAT
where it applies.
Because credits are digital content delivered immediately, EU consumers who
ask for immediate delivery and acknowledge it lose the 14-day right of
withdrawal for the credits actually used. Unused credits can be refunded on
request: write to support@aura-app.cc with the phone number of your account,
and we will refund them through Google Play. Ask before you delete your
account — once an account is deleted, its balance cannot be recovered or
refunded. If a session failed for technical reasons on our side, write to
support@aura-app.cc and we will credit or refund it. Nothing here limits the
statutory rights you have as a consumer.

08 · House rules
Aura is a calm place and we intend to keep it that way. You agree not to:
- harass, threaten, insult or sexually solicit advisors or other users;
- send unlawful, hateful, or sexually explicit material, or content involving
  minors;
- impersonate anyone, or misrepresent who you are;
- use Aura for medical, legal or financial decisions, or ask advisors to make
  them for you;
- attempt fraudulent purchases or chargebacks, or abuse free readings or
  first-session discounts through multiple accounts;
- copy, scrape, resell or republish readings, profiles or app content;
- interfere with the service — reverse engineering, automated access,
  security testing without our written consent, or anything that overloads our
  systems.

09 · Your content
What you write and upload stays yours. To run the service, you give us a
limited, worldwide, royalty-free licence to store, transmit and display that
content to you and to our advisor team, and to keep it available in your
conversation history. When you publish a review, the licence also covers
showing your star rating, your text and your first name (or "Anonymous") to
other users; if you delete your account, your star ratings stay as
"Anonymous" without your name or text. We use your content for nothing else.
You confirm you have the right to share what you send, and that it does not
infringe anyone's rights.
If you send us feedback or ideas about Aura, we may use them without
obligation to you.

10 · Our content
The Aura app, this website, the name, the logo, the interface, the
illustrations and the texts we publish belong to Silvermind OÜ or our
licensors. We grant you a personal, non-exclusive, non-transferable,
revocable licence to use the app for your own private, non-commercial
purposes. Everything not expressly granted is reserved.

11 · Availability
We work to keep Aura available, but we cannot promise it will be
uninterrupted or error-free. We may add, change or withdraw features, and we
may take the service down for maintenance. Advisors are not available at all
hours, and an advisor may be withdrawn from Aura. Where a change materially
reduces what you paid for, we will refund the unused credits.

12 · Suspension and closure
You may stop using Aura and delete your account whenever you like, as
described in section 04. We may suspend or close an account if these terms
are broken, if we are required to by law, or where we reasonably suspect
fraud or abuse — normally with notice, and immediately where the breach is
serious. If we close your account without cause, we refund unused credits.
Sections 03, 09, 10, 13 and 14 survive the end of this agreement.

13 · Liability
Aura is provided as an entertainment service, without warranty that any
reading will be accurate, complete, or lead to any particular outcome. To the
fullest extent the law allows, we are not liable for decisions you take after
a reading, for what an advisor says, for indirect or consequential loss, or
for lost profits, data or opportunities. Where we are liable, our total
liability for any claim is limited to the amount you paid us in the twelve
months before the claim arose, or €100 if that is greater.
Nothing in these terms excludes liability that cannot lawfully be excluded —
including for death or personal injury caused by negligence, for fraud, or
for the mandatory rights of consumers under Estonian and EU law.

14 · Law and disputes
These terms are governed by the law of the Republic of Estonia. Disputes go
to the courts of Estonia, except that consumers keep the right to bring
proceedings in the country where they live and to rely on its mandatory
consumer protections. Consumers in the EU may also use the Estonian Consumer
Disputes Committee. Please write to us first — most things are settled that
way.

15 · Changes and contact
We may update these terms; the date at the top always shows the current
version, and for material changes we will make reasonable efforts to tell you
in advance, for example in the app. Continuing to use Aura after changes take
effect means you accept the new terms. If one provision turns out to be
unenforceable, the rest still stands. Write to support@aura-app.cc for
anything at all — including a copy of these terms in a durable form.

------------------------------------------------------------------------
PAGE 3 — /delete-account/
------------------------------------------------------------------------
Title (h1): Delete your Aura account
Intro: Aura is an app by Silvermind OÜ. You can delete your Aura account and
the data linked to it at any time — in the app, or by writing to us if you no
longer have the app.
Meta: Last updated — [PUBLICATION DATE] · App — Aura (Google Play) ·
Developer — Silvermind OÜ · Contact — privacy@aura-app.cc

Layout note for this page: sections 01 and 02 are two side-by-side cards on
wide screens (stacked on narrow screens), each with its steps as a numbered
list. Section 04 is two cards side by side titled "Deleted" and "Kept" (the
"Kept" card uses the teal marker). Section 02 has a coral button "Email us"
linking to
mailto:privacy@aura-app.cc?subject=Delete%20my%20Aura%20account

01 · In the app
1. Open Aura and go to the Profile tab.
2. Tap "Delete account", below "Sign out".
3. Read what will be deleted and tap "Delete account" to confirm.
Your account is deleted straight away and you are signed out.

02 · Without the app
1. Email privacy@aura-app.cc with the subject "Delete my Aura account".
2. Include the phone number of your account, in international format (for
   example +34 600 000 000).
3. We may ask you for details to make sure the account is yours. We delete
   the account and confirm by email within one month.

03 · Before you delete
If a session is booked or in progress, cancel it or let it finish first — an
account cannot be deleted while a session is active.
Any unused credits are lost when your account is deleted. If you want them
refunded, write to support@aura-app.cc before you delete your account.
Deletion is permanent. If you sign in again later with the same phone number,
you will start a new, empty account.

04 · What is deleted and what is kept
Deleted:
- your profile: name, phone number, email address, date of birth and profile
  photo;
- your conversations and the files you attached, including the copies in our
  customer-conversation tool;
- the tarot cards dealt to you;
- your push notification tokens;
- your sign-in identity at Google Firebase.
Kept:
- records of purchases, balance and paid sessions, for at least seven years
  as Estonian accounting law requires — without your name, phone number or
  anything else that identifies you;
- the star ratings of reviews you wrote, shown as "Anonymous" with your name
  and text removed;
- technical audit entries in our customer-conversation tool about
  conversation settings, which contain no message text;
- entries still in the queues that carry messages and notifications through
  our servers, for up to 25 hours, or up to 8 days for a delivery that failed;
- server log entries from background tasks that failed, which may include
  your phone number and part of a message, until the logs are overwritten;
- a record that the account was deleted and when, without your name, phone
  number or contact details, so that the deletion can be repeated if a backup
  is ever restored;
- database backups made before the deletion, for up to 30 days, after which
  they are overwritten.
More about how we handle data: Privacy Policy (/privacy/).

=== END PROMPT ===
```

---

# Часть 2 — для владельца (в Claude Design не вставлять)

## До публикации — по порядку

1. **Почта — Spacemail (Spaceship), решение 2026-09-17. Сделано и проверено
   17.09:** письма с чужого адреса на `support@`, `privacy@`, `info@` доходят;
   ответ с `privacy@` — SPF, DKIM, DMARC `PASS` (`AURAS-0004`). Без почты
   страница удаления была бы тупиком (`106` #9).
   - **Ящик `support@aura-app.cc`** — на него пишут чаще всего (Terms, Play).
     Spacemail умеет отправлять и с алиасов: на запросы по `privacy@`
     отвечать с `privacy@`.
   - **Алиасы:**
     - `privacy@`;
     - `info@` — стоит на опубликованных сейчас страницах;
     - `postmaster@`, `abuse@`;
     - по желанию `dmarc@`.
   - **Логины сервисов** (Cloudflare, Hetzner, Play, Resend) на `support@` не
     переносить. Этот адрес публичный, а позже его может читать поддержка.
   - **DNS домена — в Cloudflare** (NS `jasper`/`rayne.ns.cloudflare.com`;
     Spaceship только регистратор, его DNS-зона не используется), поэтому
     записи из панели Spacemail вносятся вручную: MX, SPF на корень, DKIM, одна запись DMARC (для начала
     `p=none`). Корень сейчас пуст. У Resend свой SPF и MX на
     `send.aura-app.cc` — их не трогать. **Cloudflare Email Routing не
     включать**: он перепишет MX.
   - **Проверка:** письмо на `support@` и `privacy@` **с чужого адреса**
     доходит; ответ с `support@` не попадает в спам (заголовки: SPF, DKIM и
     DMARC — `pass`).
2. **Что должно быть в проде** — текст описывает именно это:
   - `aura-bff`: `AURAT-0042` (удаление) и `AURAT-0072` (имя на контакте
     Chatwoot) — **в проде** с 2026-09-16 (`main` = `781957a`);
   - **`AURAT-0073` и `AURAT-0074` — в проде с 2026-09-17** (`main` =
     `abe2039`): прод-бакет журнала с правилом 45 дней, токен и переменные
     проверены; `LOG_LEVEL=warn` у Chatwoot; Scheduled Task dead set работает.
     Ниже — что каждая из них держит в тексте;
   - `aura-bff`: **`AURAT-0073`** — журнал удалений вне базы. Без него фраза
     §07 «we repeat the deletions made after it was taken» ни на что не
     опирается;
   - `aura-bff`: **`AURAT-0074`**. Без неё неверны строки §07 «Server logs»
     и «Delivery queues» и два пункта «Kept». В задачу входят:
     - `LOG_LEVEL: warn` у Chatwoot — доходит только релизом в `main`;
     - FCM-токен и имя файла вложения больше не пишутся в лог BFF;
     - сроки в очередях BFF: выполненные записи хранятся сутки, упавшие
       7 дней, ежечасная чистка — граница «+1 час»;
     - **Scheduled Task в Coolify** на контейнере `sidekiq` Chatwoot:
       ежедневно удаляет мёртвые задачи старше 7 дней — граница «+1 сутки».
       От релиза не зависит, включается в панели.

     Отсюда в тексте 25 часов и 8 дней;
   - `aura-app` в Play: экран удаления, строка 18+ на входе, выключенное по
     умолчанию согласие на маркетинг (`105` часть A) — сборка `20`, пока
     internal testing.
3. **Шесть проверок в маноре** (`107` §6) — **сделаны**, `115`. Что
   получилось и чем закрыто (решение владельца 2026-09-16 — правка продукта
   там, где она есть):

   | Проверка | Ответ | Чем закрыто |
   |---|---|---|
   | Логи Chatwoot с текстами и телефонами | да | продукт: `AURAT-0074` (`LOG_LEVEL: warn`). Остаток — Sidekiq пишет аргументы упавшей задачи на WARN, реальный путь — сбой после удаления аккаунта. Описан текстом в §07 «Server logs» и в «Kept» |
   | Traefik пишет access log | нет | — |
   | Письма Resend операторам цитируют текст | да (назначение, создание, упоминание) | продукт: письма выключены у всех операторов 2026-09-16; §05 не меняется |
   | Перевод или AI в Chatwoot | получателя нет | продукт: флаг `captain_tasks` выключен; §05–06 не меняются |
   | `avatar_url` контакта открывается без входа | да, как и вложения | текст: §09 — ссылки стойки работают без входа, видны только команде |
   | Redis на диске и в бэкапе | на диске да, в бэкапе нет; без срока | продукт: сроки в `AURAT-0074` (BFF — сутки / 7 дней + 1 ч; dead set Chatwoot — 7 дней + 1 сутки); текст: §07 «Delivery queues» и «Kept» |

   Сверх списка: журнал удалений (`AURAT-0073`) — отсюда пункт «a record that
   the account was deleted» в «Kept».
4. **Не ломать сказанное настройками стойки.** Текст опирается на три
   настройки Chatwoot, и каждую можно тихо вернуть:
   - новому оператору Chatwoot сам включает письмо о назначении — выключать
     при добавлении (`AURAS-0004`, «Adding a colleague»);
   - ключ OpenAI или интеграцию (перевод, Dialogflow и т. п.) не добавлять,
     не дописав получателя в §05 и §06;
   - `LOG_LEVEL` в compose не поднимать обратно до `info`;
   - Scheduled Task чистки dead set Chatwoot не выключать и не удалять при
     пересоздании ресурса. Сроки `age` в очередях BFF не увеличивать, не
     поправив «25 hours» и «8 days».

5. **Дата.** `[PUBLICATION DATE]` → дата, трижды.
6. **После сборки в Claude Design** — пройти глазами: ни одного App Store,
   три страницы по своим адресам, `mailto:` работают, ничего не дописано от
   себя (номер регистрации, адрес, цены — их в тексте нет намеренно).
7. **Play Console:** privacy URL `https://aura-app.cc/privacy/`, URL удаления
   `https://aura-app.cc/delete-account/`, Data safety — таблица ниже.
8. **После публикации:** снять опубликованный текст в brain тем же рецептом,
   что `AURAT-0040-009` (`AURAS-0004`, «The legal pages are not on this
   host») — это единственная копия под контролем версий.

## Известные дыры, которые текст не закрывает

- **Проверка личности при запросе по почте.** Страница говорит «We may ask
  you for details to make sure the account is yours». Процедура есть только
  черновиком (`116`): до решения владельца CLI `account:erase --phone` удалит
  любой номер, который назовут. Если для Play выбрать вариант B (страница
  с входом по SMS), §02 страницы удаления переписывается под вход на странице
  — до сборки в Claude Design.
- **Остаток в логах Chatwoot.** Когда фоновая задача падает, Sidekiq на WARN
  пишет её аргументы: там могут быть телефон и данные сообщения
  (`AURAT-0074` Q1, принято). Сказано в §07 и в «Kept». Закрыть можно своим
  initializer в образе Chatwoot — отдельной задачей, если захочется.
- **Лендинг `/`** не входит в бриф, но на нём бейдж «Download on the App
  Store» и **нет ссылки на Google Play** (`Get the app` ведёт на `/#get`).
  §12 privacy теперь говорит «sends you to Google Play» — лендинг стоит
  поправить в ту же пересборку.
- **Edit Profile: «Only your advisors see your name.»** — «only» неверно,
  пока имя видно в подписи отзывов (`108`).
- **Хвост тарифа «first reading is free».** §06 terms и полоса «Your first
  reading is still free.» сохранены из опубликованного текста; в коде
  сверялся только $5 на первую платную сессию. Бесплатность обычной переписки
  не перепроверялась — подтвердить.

## Data safety — ответы для консоли

Основа — сверка приложения (`107`, раздел H исходного отчёта), с решениями
`108`. ⚑ — классификация, которую стоит перечитать в подсказках консоли.

Общие вопросы:

| Вопрос | Ответ |
|---|---|
| Собирает или передаёт данные из списка | Да |
| Шифруются при передаче | Да (`usesCleartextTraffic=false`, только https) |
| Можно запросить удаление | Да — в приложении и `https://aura-app.cc/delete-account/` |
| Аккаунт создаётся | Да, по номеру телефона |

| Тип данных Play | Собирается | Передаётся третьим | Обязательно | Цели |
|---|---|---|---|---|
| Personal info → Name | да | нет | обязательно | App functionality, Account management |
| Personal info → Email address | да | нет | необязательно | Account management, Advertising or marketing |
| Personal info → User IDs | да (Firebase UID) ⚑ | нет | обязательно | App functionality, Account management |
| Personal info → Phone number | да | нет ⚑ (Google — обработчик) | обязательно | App functionality, Account management, Fraud prevention |
| Personal info → Other info (date of birth) | да | нет | необязательно | Personalization |
| Financial info → Purchase history | да | нет | необязательно | App functionality, Account management |
| Messages → Other in-app messages | да | нет | обязательно ⚑ | App functionality |
| Photos and videos → Photos | да | нет | необязательно | App functionality |
| Photos and videos → Videos | да (готовые файлы) | нет | необязательно | App functionality |
| Audio → Other audio files | да | нет | необязательно | App functionality |
| Audio → Voice or sound recordings | нет ⚑ (записи в приложении нет) | — | — | — |
| Files and docs | да | нет | необязательно | App functionality |
| App activity → Other user-generated content (reviews) | да | нет ⚑ (показ другим — по действию пользователя) | необязательно | App functionality |
| App activity → App interactions (tarot) | да ⚑ | нет | необязательно | App functionality |
| Device or other IDs (push token, Firebase Installation ID) | да | нет | обязательно ⚑ (токен уходит и без разрешения на уведомления) | App functionality |
| Location | нет ⚑ (часовой пояс не считаем) | — | — | — |
| App info and performance | нет | — | — | — |
| Contacts, calendar, health, web browsing, installed apps | нет | — | — | — |

## Откуда взято (для проверки текста, не для страницы)

| Утверждение | Источник |
|---|---|
| Советники — персоны над командой | `AURAD-0001`; решение `106` #10 |
| Дата рождения — только дата | сверка приложения, `shared/lib/birth-date.ts:97-131` |
| Имя обязательно, почта/дата/фото — по желанию | `profile-form/model/use-profile-fields.ts`; `@aura/contracts` `profile.ts` |
| Операторы видят имя, телефон, фото; не видят почту и дату | `provisioning.service.ts:89-94`, `avatar.service.ts:162-166`; имя — `AURAT-0072`; `108` #12, #15 |
| Подпись отзыва — первое имя или Anonymous; текст модерируется | `reviews/review-quote.ts:28-34`, `reviews.service.ts` |
| Пуш без текста сообщения; о новом сообщении и старте/конце сессии | `delivery/fcm.sender.ts:49-57`, `jobs/queues.ts:145-148` |
| Нет аналитики, крашей, рекламного ID | релизный манифест сборки 19; `package.json` обоих репозиториев |
| IP и User-Agent в логах сервера, ротация по объёму | `app.module.ts:32-39`, `fastify.options.ts:14-33`; `AURAS-0004` (3×10 МБ) |
| Hetzner (Хельсинки), R2 в EU, Resend EU, Netlify | `AURAS-0004` |
| Бэкапы ежедневно, до 30 дней; повтор стираний после восстановления | `AURAS-0004`; `008` D4; опора — `AURAT-0073` |
| Логи без текстов, кроме упавших задач Chatwoot | `115` п. 1 и находка 2; `AURAT-0074` (`006` Q1, Q2); Sidekiq 7.3.1 `config.rb:43-50` |
| Ссылки стойки на вложения и фото работают без входа, устройству не уходят | `AURAD-0011`; `115` п. 5 |
| Очереди: 25 часов после доставки, 8 дней при сбое, не в бэкапе | `AURAT-0074` `007`/`008` Q3–Q5: `age` сутки / 7 дней и ежечасная `clean()` в BFF; ежедневная Scheduled Task на dead set Chatwoot; `115` п. 6 |
| Запись об удалении без имени и телефона | `schema.prisma` `AccountErasure` (хэндлы чистятся по завершении); `AURAT-0073` |
| Resend не получает текстов; AI-получателя нет | `115` п. 3–4, настройки выключены 2026-09-16 |
| Что удаляется и что остаётся | `008` §1–2, `009` (Q1–Q4) |
| Отказ удаления при живой сессии | `008` Q1 |
| Остаток сгорает; возвраты по запросу вручную | `008` Q4; `108` #13 |
| 24 ч — полный возврат, меньше — половина; перенос до 4 ч; досрочное завершение | `sessions/session-policy.ts:12-18, 43-52` |
| Маркетинг выключен по умолчанию | `108` #11, часть A `105` |
| Подтверждение 18+ при входе | `108` #14, часть A `105` |
| Удалено «or earlier if you delete a conversation» | `008` D1 |
| Удалено «aggregated statistics», «access is logged», «push when a session is about to end», ODR-платформа ЕС | `107` §3; ODR-платформа Еврокомиссии закрыта с 20.07.2025 |
