# AURAT-0202-005 — опубликовано и сверено

Дата: 2026-11-08 · Status: **опубликовано**. Владелец: «политики обновлены».

## Что снято

| URL | байт | sha256 |
|---|---|---|
| `https://aura-app.cc/privacy/` | 561001 | `47aae8e858a189c747f0beeb8bce6372c8e43eded532f1dd7b4bf09e3ce2161c` |
| `https://aura-app.cc/delete-account/` | 533209 | `f4b0d427c2e32e8717b24ef4d83bd10792f38f87a4a9ebbcd2e5b8faa2e47c36` |
| `https://aura-app.cc/` | 2160036 | `d44e9f1b3fafd8263b7ab74e0fb5f98812365b6f12dea6c20c10d650aa0de2e5` |

Текст распакован из шаблона страницы, как в `AURAT-0042-118`. Сверка — по абзацам с промптом `003` / `004`.

## Итог

- **/privacy/** — «Last updated 8 November 2026». Все новые абзацы §02, §03 (три строки и правленая строка про команду), §04, §05 (команда и Anthropic), §06, §07 (три записи), §08 и §09 стоят дословно. Отличия только в оформлении: ссылки на страницы подписаны названием вместо `(/delete-account/)`.
- **Отклонение от промпта — в нашу пользу.** На живой странице уже был раздел о рекламе Meta, которого не было ни в брифе, ни в снимках `118` / `119`:
  - §02 «Advertising measurement (Android)»;
  - строка §03 об измерении рекламы;
  - Meta Platforms в §05 — совместные контролёры;
  - абзац §08 о рекламном ID.

  Claude Design всё это сохранил, а в §06 оставил Meta в списке («Google, Apple, Meta, Cloudflare, Resend, Netlify and Anthropic»), хотя в промпте Meta не было. Значит, для будущих правок основа — **этот снимок**, а не `118` / `119` и не бриф.
- **/delete-account/** — «Last updated 8 November 2026». В «Deleted» «their translations» и строка про язык, настройку и согласие на месте; в «Kept» — кэш 24 ч и Anthropic.
- **/** (лендинг):
  - ссылок `apps.apple.com` больше нет: обе кнопки App Store — `<span>` с `aria-disabled="true"` и `aria-label="App Store — coming soon"`;
  - текст приглушён (opacity 0.45), рядом плашка «Soon» (#c43550);
  - пять ссылок Google Play на `cc.silvermind.aura` прежние.

## Мелочь вне правки

§12: «This site … sends you to Google Play or the App Store» — пока App Store неактивен, верно только про Google Play. Владелец оставил эту фразу в `AURAT-0042-119` до публикации в App Store, а тогда «Soon» снимается (`004`).

## Снимок опубликованного текста

### `/privacy/`

```text
 Legal
 Privacy Policy
 This policy explains what Aura collects, why we collect it, who can see it, and the choices you have. It applies to the Aura mobile app and to this website, both operated by Silvermind OÜ.
 Last updated 
 8 November 2026 
 Controller 
 Silvermind OÜ (Estonia) 
 Privacy contact 
 privacy@aura-app.cc 
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
 12 This website and cookies 
 13 Changes and contact 
 01 · Who we are
 Aura is operated by Silvermind OÜ, a private limited company registered in Estonia. For the purposes of the EU General Data Protection Regulation (GDPR) and the Estonian Personal Data Protection Act, Silvermind OÜ is the controller of the personal data described here. You can reach us about privacy at privacy@aura-app.cc , and our postal address is available on request.
 The advisors you meet in Aura are personas created by us. An advisor's name, photo and description introduce a style of reading; the messages you send to an advisor are read and answered by members of our advisor team, who work under our instructions and confidentiality obligations. More than one team member may answer under the same advisor. They do not use your data for their own purposes.
 02 · What we collect
 We try to collect only what the service needs.
 Account and profile
 Your mobile phone number, which is how you sign in with a one-time code. The name you choose, which is required to create an account. If you choose to add them: your email address, your date of birth (the date only — no time or place of birth), and a profile photo. Your choice about receiving marketing emails. We do not ask for your legal name or your home address.
 What you share in Aura
 The messages you send to advisors and the files you attach — photos, images, videos, audio files and documents. The tarot cards dealt to you and the choices you make in a reading. Reviews you write: your star rating, any text you add, and whether you posted it anonymously.
 Your chat language: the language your app is set to when you send a message. Your chat settings: whether "Translate my chat" is on, and a record of your chat consent — which version of the consent text you agreed to, and when. While translation is on, the machine translations of your chat: your messages in English, and advisors' replies in your language.
 Payments, balance and sessions
 When you buy credits, the purchase is handled by the app store you bought through: Google Play on Android, the App Store on iOS. We receive a confirmation of the purchase (a purchase token, an order number and the product you bought) and keep your balance and your session history: when a session was booked, how long it was, what it cost and any refund. We never receive your card number, bank details or store account password.
 Technical data
 A push notification token for your device and whether it runs Android or iOS. Your time zone, so that the daily card and booking times match your day. Like any online service, our servers see your IP address and the technical details your app or browser sends with each request, and record them in server logs. On Android, Aura includes Meta's software development kit to measure our advertising, as described under Advertising measurement below. Aura contains no analytics or crash reporting software, and the iOS app does not use an advertising identifier.
 Advertising measurement (Android)
 We advertise Aura on Facebook and Instagram. To learn which ads lead people to install and use Aura, the Android app sends Meta the following: your device's advertising identifier, the fact that the app was installed and opened, and three events — that you completed your profile, that you opened Top Up, and that a purchase was confirmed by our server, with its amount, its currency and the product bought. We do not send Meta your name, phone number, email address, messages, files or account ID. The iOS app sends nothing to Meta.
 We do not sell personal data, and we do not run advertising networks inside Aura.
 03 · Why we use it, and on what legal basis
 Purpose Legal basis (GDPR Art. 6) 
 Creating your account and signing you in Performance of a contract 
 Delivering readings, keeping your conversations and files Performance of a contract 
 Using sensitive details you choose to share in chat, such as your health, love life or beliefs, to deliver your readings Performance of a contract; for those details, your explicit consent (GDPR Art. 9(2)(a)) — see 04 
 Machine translation of your chat, while "Translate my chat" is on Performance of a contract, at your choice; for sensitive details in your chat, your explicit consent (GDPR Art. 9(2)(a)) — see 04 
 Keeping a record of your chat consent: which text you agreed to, and when Legal obligation (to be able to show that you consented, GDPR Art. 7(1)) 
 Showing your name, phone number, profile photo and chat language to our advisor team Performance of a contract 
 Using the optional details you add, such as your date of birth for horoscope features Performance of a contract, at your choice 
 Publishing the reviews you write Performance of a contract 
 Processing credit purchases, sessions and refunds, and keeping accounting records Contract; legal obligation (accounting) 
 Service notifications about new messages and your sessions Performance of a contract 
 Marketing emails Your consent, which you can withdraw at any time 
 Security, fraud prevention, abuse investigation and server logs Legitimate interests 
 Measuring which of our ads lead to installs, sign-ups and purchases (Android) Legitimate interests — knowing whether our advertising works. You can object at any time (see Your rights ) 
 Responding to legal claims and requests from authorities Legal obligation; legitimate interests 
 04 · Readings are not health data
 Aura is an entertainment service. We never ask you for medical, psychiatric, religious, political or biometric information. But a reading is a conversation, and you may choose to tell an advisor about your health, your love life or your beliefs. The GDPR calls these special categories of data. We use them only with your explicit consent (GDPR Art. 9(2)(a)), and only to deliver your readings.
 The app asks for this consent before your first message, with a box above the message field. The box reads: "I agree that Aura may use sensitive details I choose to share in chat, like health, love life or beliefs, for my readings, and that my chat is machine-translated by an external translation service. I can turn translation off or withdraw this consent at any time in my profile." We keep a record of which version of this text you agreed to and when. If we change the text, we ask again, and your chat is not translated until you agree to the new version. Without this consent, nothing from your chat is ever sent for translation.
 Our advisor team writes in English, and the same consent covers machine translation of your chat. If your app is set to a language other than English, your messages are translated into English for the advisor team, and their replies into your language. The language used is the one your app is set to, not the one you write in. If your app is set to English, nothing is translated. A machine does the translation, run by an external service: Anthropic, a company in the United States, which acts as our processor (see 05 and 06). Anthropic does not use your chat to train its models. A translated reply is marked "Machine-translated", and you can always show the original. Your own messages appear to you as you wrote them. The advisor team sees them in English and can open what you wrote.
 If your app is set to another language, translation turns on when you tick the box. You can turn it off at any time under Profile → "Translate my chat". From then on, new messages are not sent for translation in either direction: your messages reach the advisor team as you wrote them, and replies reach you in English. Translations made earlier are not erased. They stay with their messages, and you still see them (see 07). You can turn translation back on later without ticking the box again.
 Turning translation off is how you withdraw your consent to translation. It does not stop us keeping your chat, including any sensitive details in it, so that you and the advisor team can come back to it. To withdraw your consent for the chat as a whole, delete your account, under Profile or by writing to privacy@aura-app.cc (see Delete your account ). Your conversations are then erased as described in 07. Withdrawing consent does not affect what we processed before.
 Please do not send us more than a reading requires, especially about other people. Whatever you write is read by our advisor team and, while translation is on, sent for translation.
 05 · Who sees your data
 You see your own conversations, files, profile and history.
 Our advisor team sees your conversations with advisors and the files you attach, together with your name, your phone number, your profile photo and your chat language. While translation is on, they see your messages machine-translated into English and can open what you wrote; sometimes the English is added as a separate note in the conversation. They do not see your email address or your date of birth. They work in a customer-conversation tool that we run on our own servers.
 Other Aura users see the reviews you publish: your star rating, your text once it has been approved, and your first name — or "Anonymous" if you choose to post anonymously. Before written review text is published, a member of our team reads it.
 A small number of our staff with administrative access can reach account and conversation data where necessary to support you, to investigate abuse, or to comply with the law, under confidentiality obligations.
 We rely on these service providers, who process data on our behalf:
 Google (Firebase) — phone-number sign-in and push notifications. Notifications tell your device that a new message has arrived; they do not contain the message text.
 Google Play — app distribution and in-app purchases, acting under its own privacy policy.
 Meta Platforms — measurement of our advertising on Android: receives the advertising identifier and app events described in section 02. For this data Meta Platforms Ireland Limited and Silvermind OÜ act as joint controllers under Meta's Business Tools Terms; Meta uses it under its own privacy policy, which explains how to exercise your rights with Meta directly.
 Apple — the App Store, in-app purchases and push notification delivery on iOS, acting under its own privacy policy.
 Hetzner Online — the servers and databases that run Aura, in Finland (EU).
 Cloudflare — file storage with EU data location, used for attachments, profile photos and database backups; and our domain name service.
 Resend — delivery of the emails our customer-conversation tool sends to our team.
 Anthropic (USA) — machine translation of the chat, only while "Translate my chat" is on (see 04). For each message it translates, it receives the text of that message (for a file, only its caption); up to four earlier messages from the same chat as context, each cut to 500 characters; whether each was written by you or by the advisor; the language to translate into. It does not receive your files. No name, phone number, email address, profile photo, or account or conversation identifier is attached to the text, but it does receive whatever you write in those messages yourself. It acts as our processor under its data processing terms and does not use this data to train its models.
 Netlify — hosting of this website.
 We disclose data to courts, regulators or law enforcement only where we are legally required to, and to a buyer or successor if our business is reorganised — in which case this policy continues to apply until you are told otherwise.
 06 · Transfers outside the EEA
 We store Aura's data in the European Union. Some of our providers — Google, Apple, Meta, Cloudflare, Resend, Netlify and Anthropic — are companies based outside the European Economic Area and may process limited data outside it. Anthropic is based in the United States. While translation is on, it processes the chat texts described in 05 outside the EEA. Where data leaves the EEA we rely on an adequacy decision of the European Commission, including the EU–US Data Privacy Framework where the provider is certified under it, or on the Commission's Standard Contractual Clauses. For Anthropic we rely on the Standard Contractual Clauses in its data processing terms. You may ask us for a copy of the relevant safeguards.
 07 · How long we keep it
 Account and profile 
 While your account exists. When you delete your account, they are erased, including your sign-in identity at Google Firebase. 
 Conversations and files 
 While your account exists, so you can come back to them. They are erased when you delete your account, including the copies in our customer-conversation tool. That tool keeps technical audit entries about conversation settings, which contain no message text. 
 Chat settings and consent 
 While your account exists. Your chat language follows the language your app is set to. Turning translation off does not erase the record of your consent. When you delete your account, your chat language, your translation setting and the record of your consent are erased. 
 Chat translations 
 Kept with the messages they belong to. The English of your messages, including any note that carries it, is kept in our customer-conversation tool. The translations of advisors' replies are kept in our database. They are erased with the conversation, including when you delete your account. Turning translation off does not erase translations already made. So that a message is not translated twice, our servers also keep a copy of a translation in a short-lived cache for up to 24 hours. Deleting your account does not clear that cache; its entries expire on their own within those 24 hours. 
 At our translation provider 
 Anthropic deletes the texts it receives from us, and its translations of them, within 30 days. Texts its safety systems flag as breaking its usage policy may be kept for up to 2 years. It does not use them to train its models. Deleting your account does not reach these copies or shorten these periods. 
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
 08 · Your rights
 Under the GDPR you may ask us to give you access to your data, correct it, delete it, restrict or object to how we use it, and provide it in a portable form. Where we rely on consent, you may withdraw it at any time, without affecting processing that already took place. For your chat consent (see 04): turning off "Translate my chat" withdraws it for translation, for everything sent after that; deleting your account withdraws it for the chat as a whole.
 In the app you can change your name, email address, date of birth, profile photo and marketing choice under Edit Profile. You can turn chat translation on or off under Profile → "Translate my chat", and you can delete your account from the Profile screen. For anything else — including a copy of your data — write to privacy@aura-app.cc with the phone number of your account, and we will answer within one month. If you no longer have the app, see Delete your account .
 If you believe we have handled your data badly, you can complain to the Estonian Data Protection Inspectorate (Andmekaitse Inspektsioon, aki.ee ) or to the supervisory authority where you live. We would rather hear from you first.
 You can stop Aura from sharing your advertising identifier at any time: on your Android device, delete or reset the advertising ID in Settings → Google → Ads (on some devices, Settings → Privacy → Ads). You can also object to advertising measurement by writing to privacy@aura-app.cc .
 09 · Security
 Traffic between the app and our servers is encrypted in transit. Chat texts we send to our translation provider are also encrypted in transit and carry no account identifiers. Our app serves attachments and profile photos only to the signed-in account they belong to. Inside our customer-conversation tool, attachments and profile photos open through long, unguessable links that work without signing in; these links are shown only to our advisor team and are never sent to your device or to other users. Sign-in relies on a one-time code sent to your phone rather than a reusable password. No service can promise perfect security, so please keep access to your phone number and device protected. If a breach ever affects your rights, we will notify you and the Inspectorate as the GDPR requires.
 10 · Notifications and marketing
 Push notifications tell you when an advisor replies and when a paid session starts or ends. You can turn them off in your device settings at any time. Marketing emails about offers and recommendations are sent only if you switch on email updates — the switch is off unless you turn it on — and you can switch it off again under Edit Profile. Every marketing email will carry a way to unsubscribe.
 11 · Children
 Aura is for adults: you must be 18 or older to use it, and you confirm this when you sign in. We do not knowingly collect data from anyone under 18. If you believe a minor is using Aura, write to privacy@aura-app.cc and we will delete the account.
 12 · This website and cookies
 This site describes the app and sends you to Google Play or the App Store. It sets no cookies and uses no analytics. Our hosting provider keeps standard server logs, including IP addresses, for security and for aggregate visit counts. If we ever add analytics or measurement cookies, we will ask for your consent first and update this section.
 13 · Changes and contact
 If we change this policy we will update the date at the top. For material changes we will make reasonable efforts to tell you in advance, for example in the app. Questions, requests and complaints go to privacy@aura-app.cc . Our terms of use are set out in the Terms of Service .
 Your first reading is still free.
 Get the app 
```

### `/delete-account/`

```text
 Legal
 Delete your Aura account
 Aura is an app by Silvermind OÜ. You can delete your Aura account and the data linked to it at any time — in the app, or by writing to us if you no longer have the app.
 Last updated 
 8 November 2026 
 App 
 Aura (Google Play, App Store) 
 Developer 
 Silvermind OÜ 
 Contact 
 privacy@aura-app.cc 
 On this page
 01 In the app 
 02 Without the app 
 03 Before you delete 
 04 What is deleted and what is kept 
 01 · In the app
 Open Aura and go to the Profile tab.
 Tap "Delete account", below "Sign out".
 Read what will be deleted and tap "Delete account" to confirm.
 Your account is deleted straight away and you are signed out.
 02 · Without the app
 Email privacy@aura-app.cc with the subject "Delete my Aura account".
 Include the phone number of your account, in international format (for example +34 600 000 000).
 We may ask you for details to make sure the account is yours. We delete the account and confirm by email within one month.
 Email us 
 03 · Before you delete
 If a session is booked or in progress, cancel it or let it finish first — an account cannot be deleted while a session is active.
 Any unused credits are lost when your account is deleted. If you want them refunded, write to support@aura-app.cc before you delete your account.
 Deletion is permanent. If you sign in again later with the same phone number, you will start a new, empty account.
 04 · What is deleted and what is kept
 Deleted
 your profile: name, phone number, email address, date of birth and profile photo;
 your conversations, their translations and the files you attached, including the copies in our customer-conversation tool;
 the tarot cards dealt to you;
 your chat language, your translation setting and the record of your chat consent;
 your push notification tokens;
 your sign-in identity at Google Firebase.
 Kept
 records of purchases, balance and paid sessions, for at least seven years as Estonian accounting law requires — without your name, phone number or anything else that identifies you;
 the star ratings of reviews you wrote, shown as "Anonymous" with your name and text removed;
 technical audit entries in our customer-conversation tool about conversation settings, which contain no message text;
 entries still in the queues that carry messages and notifications through our servers, for up to 25 hours, or up to 8 days for a delivery that failed;
 translations of recent messages in a short-lived cache on our servers, for up to 24 hours;
 texts our translation provider, Anthropic, received while translation was on: it deletes them within 30 days, or keeps them for up to 2 years if its safety systems flagged them;
 server log entries from background tasks that failed, which may include your phone number and part of a message, until the logs are overwritten;
 a record that the account was deleted and when, without your name, phone number or contact details, so that the deletion can be repeated if a backup is ever restored;
 database backups made before the deletion, for up to 30 days, after which they are overwritten.
 More about how we handle data: Privacy Policy .
 Your first reading is still free.
 Get the app 
```
