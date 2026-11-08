# AURAT-0202-003 — промпты для Claude Design: /privacy/ и /delete-account/

Дата: 2026-11-08. Владелец: «что отдавать claude design тогда?». Тексты — из `001` (проверены по коду), собраны в промпты «изменить только перечисленное», как правка от 1 октября (`AURAT-0042-119`). Запись Anthropic в §05 сведена в один абзац, как остальные пункты списка. Дату `[DATE]` владелец ставит в день публикации.

## 1. /privacy/

```text
Update the Privacy Policy page (https://aura-app.cc/privacy/).

Change ONLY what is listed below, using the new text word for word. Do not reword, reorder, shorten or restyle anything else: keep the layout, the headings and their numbers, the table, the links and every other sentence exactly as they are now, including the App Store / Apple wording added on 1 October 2026.

1. Header: set "Last updated" to [DATE — the day you publish, e.g. 10 November 2026].

2. Section 02 "What we collect", subsection "What you share in Aura": replace the whole subsection text with these two paragraphs:

The messages you send to advisors and the files you attach — photos, images, videos, audio files and documents. The tarot cards dealt to you and the choices you make in a reading. Reviews you write: your star rating, any text you add, and whether you posted it anonymously.
Your chat language: the language your app is set to when you send a message. Your chat settings: whether "Translate my chat" is on, and a record of your chat consent — which version of the consent text you agreed to, and when. While translation is on, the machine translations of your chat: your messages in English, and advisors' replies in your language.

3. Section 03 table:
1) Replace the row "Showing your name and profile photo to our advisor team | Performance of a contract" with:
| Showing your name, phone number, profile photo and chat language to our advisor team | Performance of a contract |

2) Insert directly after the row "Delivering readings, keeping your conversations and files":
| Using sensitive details you choose to share in chat, such as your health, love life or beliefs, to deliver your readings | Performance of a contract; for those details, your explicit consent (GDPR Art. 9(2)(a)) — see 04 |
| Machine translation of your chat, while "Translate my chat" is on | Performance of a contract, at your choice; for sensitive details in your chat, your explicit consent (GDPR Art. 9(2)(a)) — see 04 |
| Keeping a record of your chat consent: which text you agreed to, and when | Legal obligation (to be able to show that you consented, GDPR Art. 7(1)) |

4. Section 04: keep the heading "04 · Readings are not health data" and replace the whole text under it with:

Aura is an entertainment service. We never ask you for medical, psychiatric, religious, political or biometric information. But a reading is a conversation, and you may choose to tell an advisor about your health, your love life or your beliefs. The GDPR calls these special categories of data. We use them only with your explicit consent (GDPR Art. 9(2)(a)), and only to deliver your readings.
The app asks for this consent before your first message, with a box above the message field. The box reads: "I agree that Aura may use sensitive details I choose to share in chat, like health, love life or beliefs, for my readings, and that my chat is machine-translated by an external translation service. I can turn translation off or withdraw this consent at any time in my profile." We keep a record of which version of this text you agreed to and when. If we change the text, we ask again, and your chat is not translated until you agree to the new version. Without this consent, nothing from your chat is ever sent for translation.
Our advisor team writes in English, and the same consent covers machine translation of your chat. If your app is set to a language other than English, your messages are translated into English for the advisor team, and their replies into your language. The language used is the one your app is set to, not the one you write in. If your app is set to English, nothing is translated. A machine does the translation, run by an external service: Anthropic, a company in the United States, which acts as our processor (see 05 and 06). Anthropic does not use your chat to train its models. A translated reply is marked "Machine-translated", and you can always show the original. Your own messages appear to you as you wrote them. The advisor team sees them in English and can open what you wrote.
If your app is set to another language, translation turns on when you tick the box. You can turn it off at any time under Profile → "Translate my chat". From then on, new messages are not sent for translation in either direction: your messages reach the advisor team as you wrote them, and replies reach you in English. Translations made earlier are not erased. They stay with their messages, and you still see them (see 07). You can turn translation back on later without ticking the box again.
Turning translation off is how you withdraw your consent to translation. It does not stop us keeping your chat, including any sensitive details in it, so that you and the advisor team can come back to it. To withdraw your consent for the chat as a whole, delete your account, under Profile or by writing to privacy@aura-app.cc (see Delete your account (/delete-account/)). Your conversations are then erased as described in 07. Withdrawing consent does not affect what we processed before.
Please do not send us more than a reading requires, especially about other people. Whatever you write is read by our advisor team and, while translation is on, sent for translation.

5. Section 05 "Who sees your data":
a) Replace the paragraph that begins "Our advisor team sees your conversations with advisors" with:

Our advisor team sees your conversations with advisors and the files you attach, together with your name, your phone number, your profile photo and your chat language. While translation is on, they see your messages machine-translated into English and can open what you wrote; sometimes the English is added as a separate note in the conversation. They do not see your email address or your date of birth. They work in a customer-conversation tool that we run on our own servers.

b) In the list of service providers, add this item right after the "Resend — …" item, in the same style as the other items:

- Anthropic (USA) — machine translation of the chat, only while "Translate my chat" is on (see 04). For each message it translates, it receives the text of that message (for a file, only its caption); up to four earlier messages from the same chat as context, each cut to 500 characters; whether each was written by you or by the advisor; the language to translate into. It does not receive your files. No name, phone number, email address, profile photo, or account or conversation identifier is attached to the text, but it does receive whatever you write in those messages yourself. It acts as our processor under its data processing terms and does not use this data to train its models.

6. Section 06: keep the heading "06 · Transfers outside the EEA" and replace the whole text under it with:

We store Aura's data in the European Union. Some of our providers — Google, Apple, Cloudflare, Resend, Netlify and Anthropic — are companies based outside the European Economic Area and may process limited data outside it. Anthropic is based in the United States. While translation is on, it processes the chat texts described in 05 outside the EEA. Where data leaves the EEA we rely on an adequacy decision of the European Commission, including the EU–US Data Privacy Framework where the provider is certified under it, or on the Commission's Standard Contractual Clauses. For Anthropic we rely on the Standard Contractual Clauses in its data processing terms. You may ask us for a copy of the relevant safeguards.

7. Section 07 "How long we keep it": add these three entries right after the "Conversations and files" entry, in the same label + text style as the other entries:

Chat settings and consent
While your account exists. Your chat language follows the language your app is set to. Turning translation off does not erase the record of your consent. When you delete your account, your chat language, your translation setting and the record of your consent are erased.
Chat translations
Kept with the messages they belong to. The English of your messages, including any note that carries it, is kept in our customer-conversation tool. The translations of advisors' replies are kept in our database. They are erased with the conversation, including when you delete your account. Turning translation off does not erase translations already made. So that a message is not translated twice, our servers also keep a copy of a translation in a short-lived cache for up to 24 hours. Deleting your account does not clear that cache; its entries expire on their own within those 24 hours.
At our translation provider
Anthropic deletes the texts it receives from us, and its translations of them, within 30 days. Texts its safety systems flag as breaking its usage policy may be kept for up to 2 years. It does not use them to train its models. Deleting your account does not reach these copies or shorten these periods.

8. Section 08: keep the heading "08 · Your rights" and replace the whole text under it with:

Under the GDPR you may ask us to give you access to your data, correct it, delete it, restrict or object to how we use it, and provide it in a portable form. Where we rely on consent, you may withdraw it at any time, without affecting processing that already took place. For your chat consent (see 04): turning off "Translate my chat" withdraws it for translation, for everything sent after that; deleting your account withdraws it for the chat as a whole.
In the app you can change your name, email address, date of birth, profile photo and marketing choice under Edit Profile. You can turn chat translation on or off under Profile → "Translate my chat", and you can delete your account from the Profile screen. For anything else — including a copy of your data — write to privacy@aura-app.cc with the phone number of your account, and we will answer within one month. If you no longer have the app, see Delete your account (/delete-account/).
If you believe we have handled your data badly, you can complain to the Estonian Data Protection Inspectorate (Andmekaitse Inspektsioon, aki.ee ) or to the supervisory authority where you live. We would rather hear from you first.

9. Section 09 "Security": insert this sentence right after the first sentence ("Traffic between the app and our servers is encrypted in transit."):

Chat texts we send to our translation provider are also encrypted in transit and carry no account identifiers.

Sections 01, 10, 11, 12 and 13, and the other subsections of 02, stay exactly as they are.
```

## 2. /delete-account/

```text
Update the "Delete your Aura account" page (https://aura-app.cc/delete-account/).

Change ONLY what is listed below, using the new text word for word. Keep everything else exactly as it is now.

1. Header: set "Last updated" to [DATE — the same day as the Privacy Policy].

2. Section 04 "What is deleted and what is kept", list "Deleted":
a) replace the item
"your conversations and the files you attached, including the copies in our customer-conversation tool;"
with
"your conversations, their translations and the files you attached, including the copies in our customer-conversation tool;"
b) add this item right after "the tarot cards dealt to you;":
"your chat language, your translation setting and the record of your chat consent;"

3. Section 04, list "Kept": add these two items right after the item about entries still in the queues (up to 8 days for a delivery that failed):
"translations of recent messages in a short-lived cache on our servers, for up to 24 hours;"
"texts our translation provider, Anthropic, received while translation was on: it deletes them within 30 days, or keeps them for up to 2 years if its safety systems flagged them;"

Sections 01–03 and the rest of section 04 stay exactly as they are.
```

После публикации: снять текст живых страниц и сверить поабзацно с этими промптами (как в `118` / `119`).
