# AURAT-0202-001 — правка политики под перевод чата (текст для Claude Design)

Дата: 2026-11-08 · Status: черновик готов, ждёт решений владельца и публикации

Владелец: на предложение координатора «Могу подготовить текст правки политики в бриф (§04–§06 по разбору `AURAI-0012-legal`), чтобы ты вставил его в Claude Design» — «да, подготовь». Задача 9 `AURAI-0012`, поправка к решению 6 (на карточке согласия — «внешний сервис», без имени; имя, США и SCC — в политике).

Подготовлено воркфлоу (факты по коду BFF и приложения → черновик → проверка). Это не юридическая консультация.

## Как применять

- **Основа — живой текст от 1 октября 2026** (`AURAT-0042-119`: Apple / App Store), не снимок `118` и не бриф. Бриф `AURAT-0042-claude-design-brief.md` устарел (там «No App Store / Apple … anywhere»): пересборка из него удалит строку Apple.
- В Claude Design: дать живую страницу и правки ниже по разделам. Остальной текст не трогать.
- **Опубликовать до того, как пользователи получат 38** (с прод-BFF карточка согласия появляется сразу), и в любом случае до включения `TRANSLATION_CHAT_*`. Дату публикации — в «Last updated» обеих страниц.
- После публикации — снимок текста в брейн (как `118` / `119`).

## /privacy/ — правки по разделам

### Header meta — Last updated (/privacy/) — `replace`

```text
Last updated
[PUBLICATION DATE]
```

### 02 · What we collect — ### What you share in Aura — `replace`

```text
The messages you send to advisors and the files you attach — photos, images, videos, audio files and documents. The tarot cards dealt to you and the choices you make in a reading. Reviews you write: your star rating, any text you add, and whether you posted it anonymously.
Your chat language: the language your app is set to when you send a message. Your chat settings: whether "Translate my chat" is on, and a record of your chat consent — which version of the consent text you agreed to, and when. While translation is on, the machine translations of your chat: your messages in English, and advisors' replies in your language.
```

### 03 · Why we use it, and on what legal basis — table — `replace-row + add-rows`

```text
1) Replace the row "Showing your name and profile photo to our advisor team | Performance of a contract" with:
| Showing your name, phone number, profile photo and chat language to our advisor team | Performance of a contract |

2) Insert directly after the row "Delivering readings, keeping your conversations and files":
| Using sensitive details you choose to share in chat, such as your health, love life or beliefs, to deliver your readings | Performance of a contract; for those details, your explicit consent (GDPR Art. 9(2)(a)) — see 04 |
| Machine translation of your chat, while "Translate my chat" is on | Performance of a contract, at your choice; for sensitive details in your chat, your explicit consent (GDPR Art. 9(2)(a)) — see 04 |
| Keeping a record of your chat consent: which text you agreed to, and when | Legal obligation (to be able to show that you consented, GDPR Art. 7(1)) |
```

### 04 · Readings are not health data — `replace`

```text
## 04 · Readings are not health data
Aura is an entertainment service. We never ask you for medical, psychiatric, religious, political or biometric information. But a reading is a conversation, and you may choose to tell an advisor about your health, your love life or your beliefs. The GDPR calls these special categories of data. We use them only with your explicit consent (GDPR Art. 9(2)(a)), and only to deliver your readings.
The app asks for this consent before your first message, with a box above the message field. The box reads: "I agree that Aura may use sensitive details I choose to share in chat, like health, love life or beliefs, for my readings, and that my chat is machine-translated by an external translation service. I can turn translation off or withdraw this consent at any time in my profile." We keep a record of which version of this text you agreed to and when. If we change the text, we ask again, and your chat is not translated until you agree to the new version. Without this consent, nothing from your chat is ever sent for translation.
Our advisor team writes in English, and the same consent covers machine translation of your chat. If your app is set to a language other than English, your messages are translated into English for the advisor team, and their replies into your language. The language used is the one your app is set to, not the one you write in. If your app is set to English, nothing is translated. A machine does the translation, run by an external service: Anthropic, a company in the United States, which acts as our processor (see 05 and 06). Anthropic does not use your chat to train its models. A translated reply is marked "Machine-translated", and you can always show the original. Your own messages appear to you as you wrote them. The advisor team sees them in English and can open what you wrote.
If your app is set to another language, translation turns on when you tick the box. You can turn it off at any time under Profile → "Translate my chat". From then on, new messages are not sent for translation in either direction: your messages reach the advisor team as you wrote them, and replies reach you in English. Translations made earlier are not erased. They stay with their messages, and you still see them (see 07). You can turn translation back on later without ticking the box again.
Turning translation off is how you withdraw your consent to translation. It does not stop us keeping your chat, including any sensitive details in it, so that you and the advisor team can come back to it. To withdraw your consent for the chat as a whole, delete your account, under Profile or by writing to privacy@aura-app.cc (see Delete your account (/delete-account/)). Your conversations are then erased as described in 07. Withdrawing consent does not affect what we processed before.
Please do not send us more than a reading requires, especially about other people. Whatever you write is read by our advisor team and, while translation is on, sent for translation.
```

### 05 · Who sees your data — advisor-team paragraph — `replace`

```text
Our advisor team sees your conversations with advisors and the files you attach, together with your name, your phone number, your profile photo and your chat language. While translation is on, they see your messages machine-translated into English and can open what you wrote; sometimes the English is added as a separate note in the conversation. They do not see your email address or your date of birth. They work in a customer-conversation tool that we run on our own servers.
```

### 05 · Who sees your data — service-provider list — `add-item`

```text
Add after "Resend — …". The "Apple — the App Store, in-app purchases and push notification delivery on iOS" line added on 1 October stays where it is.
- Anthropic (USA) — machine translation of the chat, only while "Translate my chat" is on (see 04). For each message it translates, it receives:
  - the text of that message (for a file, only its caption);
  - up to four earlier messages from the same chat as context, each cut to 500 characters;
  - whether each was written by you or by the advisor;
  - the language to translate into.
It does not receive your files. No name, phone number, email address, profile photo, or account or conversation identifier is attached to the text, but it does receive whatever you write in those messages yourself. It acts as our processor under its data processing terms and does not use this data to train its models.
```

### 06 · Transfers outside the EEA — `replace`

```text
## 06 · Transfers outside the EEA
We store Aura's data in the European Union. Some of our providers — Google, Apple, Cloudflare, Resend, Netlify and Anthropic — are companies based outside the European Economic Area and may process limited data outside it. Anthropic is based in the United States. While translation is on, it processes the chat texts described in 05 outside the EEA. Where data leaves the EEA we rely on an adequacy decision of the European Commission, including the EU–US Data Privacy Framework where the provider is certified under it, or on the Commission's Standard Contractual Clauses. For Anthropic we rely on the Standard Contractual Clauses in its data processing terms. You may ask us for a copy of the relevant safeguards.
```

### 07 · How long we keep it — new entries — `add-item`

```text
Add after "Conversations and files":
Chat settings and consent
While your account exists. Your chat language follows the language your app is set to. Turning translation off does not erase the record of your consent. When you delete your account, your chat language, your translation setting and the record of your consent are erased.
Chat translations
Kept with the messages they belong to. The English of your messages, including any note that carries it, is kept in our customer-conversation tool. The translations of advisors' replies are kept in our database. They are erased with the conversation, including when you delete your account. Turning translation off does not erase translations already made. So that a message is not translated twice, our servers also keep a copy of a translation in a short-lived cache for up to 24 hours. Deleting your account does not clear that cache; its entries expire on their own within those 24 hours.
At our translation provider
Anthropic deletes the texts it receives from us, and its translations of them, within 30 days. Texts its safety systems flag as breaking its usage policy may be kept for up to 2 years. It does not use them to train its models. Deleting your account does not reach these copies or shorten these periods.
```

### 08 · Your rights — `replace`

```text
## 08 · Your rights
Under the GDPR you may ask us to give you access to your data, correct it, delete it, restrict or object to how we use it, and provide it in a portable form. Where we rely on consent, you may withdraw it at any time, without affecting processing that already took place. For your chat consent (see 04): turning off "Translate my chat" withdraws it for translation, for everything sent after that; deleting your account withdraws it for the chat as a whole.
In the app you can change your name, email address, date of birth, profile photo and marketing choice under Edit Profile. You can turn chat translation on or off under Profile → "Translate my chat", and you can delete your account from the Profile screen. For anything else — including a copy of your data — write to privacy@aura-app.cc with the phone number of your account, and we will answer within one month. If you no longer have the app, see Delete your account (/delete-account/).
If you believe we have handled your data badly, you can complain to the Estonian Data Protection Inspectorate (Andmekaitse Inspektsioon, aki.ee ) or to the supervisory authority where you live. We would rather hear from you first.
```

### 09 · Security — `add-item`

```text
Insert after the first sentence ("Traffic between the app and our servers is encrypted in transit."):
Chat texts we send to our translation provider are also encrypted in transit and carry no account identifiers.
```

### 01, 10, 11, 12, 13 and the §02 subsections Account and profile / Payments, balance and sessions / Technical data — `unchanged`

```text
No change. Keep the live 1 October wording, including the App Store text in §02 Payments and "or the App Store" in §12.
```

## /delete-account/

Changes to /delete-account/. Start from the live text: the 1 October edit changed only /privacy/ and /terms/, so this page still reads "Last updated 17 September 2026".

1. Meta: change "Last updated 17 September 2026" to "Last updated [PUBLICATION DATE]", the same day as /privacy/.

2. §04 "Deleted": replace the item
"- your conversations and the files you attached, including the copies in our customer-conversation tool;"
with
"- your conversations, their translations and the files you attached, including the copies in our customer-conversation tool;"
Then add after "- the tarot cards dealt to you;":
"- your chat language, your translation setting and the record of your chat consent;"

3. §04 "Kept": add after the queues item ("entries still in the queues … up to 8 days for a delivery that failed;"):
"- translations of recent messages in a short-lived cache on our servers, for up to 24 hours;
- texts our translation provider, Anthropic, received while translation was on: it deletes them within 30 days, or keeps them for up to 2 years if its safety systems flagged them;"

4. §01–§03 and the rest of §04: no change.

The in-app delete sheet ("Your profile, photo, conversations and attachments will be erased") does not contradict this, so no app change is needed. Adding "and their translations" is optional and would be a 24-language legal-copy change.

## Что сделать или решить владельцу

- Publish the new /privacy/ and /delete-account/ on or before the day TRANSLATION_CHAT_TO_DESK / TRANSLATION_CHAT_REPLIES go on in prod, and put that date in both pages.
- Edit from the live 1 October 2026 text (AURAT-0042-119), not from the 118 snapshot or the design brief. Regenerating from the brief would delete the Apple processor line and the App Store payment wording. Update AURAT-0042-claude-design-brief.md, which still says 'No App Store / Apple … anywhere', before you use Claude Design again.
- After publishing, check the live pages paragraph by paragraph against this text, and save a new snapshot in the brain, as was done in AURAT-0042-118 and 119.
- Write the DPIA (Art. 35) with the Art. 30 record inside it, and a 1–2-page TIA for the Anthropic transfer under SCC. None of these exists yet. The DPIA should record these risks: data about third parties; full withdrawal only by deleting the account (Art. 7(3)); the tick as a condition of chatting at all (Art. 7(4)); older builds that chat with no consent; context messages written before consent or while translation was off; and 'Special categories: None' in Anthropic's DPA Annex 1.
- Keep the exact consent-card text for each consent version in the brain or the DPIA. Version 1 is the 2026-11-08 text. The server stores only the version number, so this is your only proof of what people agreed to.
- On release day, check Anthropic's current pages (privacy center, the API data-retention doc, the DPA, the Commercial Terms) against the policy: deletion within 30 days, flagged content kept up to 2 years, no training. Save dated copies.
- Optional (recommended in AURAI-0012): write once to Anthropic's privacy team that users may put special-category data in chat texts, and keep the reply.
- Check the production Chatwoot desk before release: its built-in Google Translate integration and any AI features ('Captain' or OpenAI-based) must be off. If one is on, a chatter's click sends chat text to a processor that §05/§06 do not list.
- Decide how to keep the card's promise 'withdraw this consent at any time in my profile'. Today it means the switch (translation) plus Delete account (everything). Either accept that, since the policy now says so plainly, or add a real withdrawal control before release. The card text can still change under version 1 only while no consents exist in prod.
- Decide whether to close the old-build gap: the server accepts sends without consent. Options are server-side enforcement or a forced app update. Without one, people on old builds share sensitive details with no explicit consent, which is the weak 'volunteered' basis AURAI-0012 rejected.
- Play Console Data safety: review it. Messages are already declared, and a processor acting on our behalf does not count as 'sharing', so probably nothing changes. Check that chat language or the consent record does not need a new data type. Do the same for the App Store privacy labels when iOS translation arrives (AURAT-0190).
- Terms of Service §09: consider making the licence 'store, transmit, translate and display', and bump the terms date if you change it.
- §13 promise: tell existing users about the material change in advance (an in-app notice or similar). They will meet the new consent card anyway.
- Consider making the Profile switch hint ('Advisors' replies in your language, machine-translated') cover both directions, since the switch also stops your own messages being sent to the team in English. This is a 24-language legal-copy change.
- Have native speakers review the consent card and the switch strings before marketing in each country (legal copy, AURAI-0010 decision 7).

## Открытые вопросы

- Where Anthropic processes: the code sets no region, base URL or Bedrock, so calls go to Anthropic's default API. The policy now says 'based in the United States … processes outside the EEA' and does not claim US-only processing. Does Anthropic offer a US-only inference setting for the API? If so, should we turn it on so the card's 'USA' reading is exact?
- Provider retention: should the policy also name the classifier scores (up to 7 years) next to the 30-day and 2-year figures? It depends on what Anthropic's pages say on release day.
- Context: up to 4 earlier messages are sent, with no time filter, so messages written before the consent or while the switch was off can reach Anthropic once translation is on. Should context start at the consent or switch-on time? The §05 wording is true either way.
- Redis: the desk cache (24 h) and the job-result cache (1 h) hold translated text, and account erasure does not clear them. The policy now says they expire on their own. Does bff-redis (AOF on disk) fall outside the daily 30-day backups, as §07 says for the queues? Or should erasure clear these keys instead?
- Chatwoot: deleting the contact removes conversations by destroy_async. Does that also remove content_attributes.translations.en and the 'Translation (EN)' private notes, as the code reading suggests? Check once on staging.
- §03 Art. 6 basis for translation: the draft keeps 'contract, at your choice', with Anthropic as a processor (AURAI-0012 decision 6). Is that the final position, rather than consent under Art. 6 as well?
- Art. 7(4): the current app holds the first message until the tick, and the one tick also covers translation that an English-interface or iOS user never gets. Is a single bundled tick acceptable, or should translation get its own choice?
- The consent record is erased on account deletion (CLEARED_PROFILE), so no proof of consent outlives the account. Is that intended, given Art. 7(1)?
- §04 heading 'Readings are not health data' now sits above a section on sensitive details and consent. Rename it, for example to '04 · Sensitive details and chat translation'? The #s04 anchor would still work.
- Anthropic's DPF certification has not been checked, so the policy relies on the SCC only for Anthropic. Should we check it and add DPF later?

## Факты из кода (на чём стоит текст)

**Что уходит провайдеру:** Base paths: BFF = /Volumes/Work/personal/ai-manors/aura-bff-manor/project/manor/master/aura-bff, APP = /Volumes/Work/personal/ai-manors/aura-app-manor/project/manor/master/aura-app, CONTRACTS = /Volumes/Work/personal/ai-manors/aura-contracts.

ONE CALL = one chat message, on the `chat` translation profile (BFF src/modules/chat/chat-translation.service.ts:505-512: items=[{id:'message', text, form:'message'}], plus speaker and context). Request body built in src/modules/translation/claude/claude.translator.ts:111-128. It contains: model, max_tokens 16000, system (a fixed prompt with no per-request data, claude-prompt.ts:18-38, cache_control only on this block, claude-prompt.ts:135-137), one user turn of two text blocks, thinking, output_config (effort + JSON schema), and on Opus/Sonnet the beta `fallbacks:'default'`. There is NO `metadata` / `metadata.user_id` field. No user id, firebase uid, phone, display name, email, conversation id, Chatwoot id or message id goes to the provider. The only id sent is the literal item id "message" (chat-translation.service.ts:81). The client is `new Anthropic({ apiKey, maxRetries: 0 })` (claude.translator.ts:68). It sets no baseURL and no inference-geo/region parameter, so calls go to the default Anthropic API endpoint (api.anthropic.com). BFF config has no Bedrock/EU option (env.schema.ts:419-436).

User turn (claude-prompt.ts:80-117):
(1) <target_language>, plus the glossary's register rules for that language (address, pronouns, button form);
(2) <source_language>: 'unknown, detect it' for the person's messages, 'en' for replies;
(3) glossary terms (replies only);
(4) <speaker>: 'client' for the person's message. For a reply it is 'advisor' plus the advisor PERSONA's gender (female/male) (chat-translation.service.ts:402-406, claude-prompt.ts:94-97);
(5) <context>: JSON of the earlier messages, as {role:'client'|'advisor', text};
(6) <texts>: [{id:'message', text, form:'message'}].

Context: up to CONTEXT_MESSAGES = 4 (the port comment says 2–4; the code takes up to 4). Each is cut to 500 characters (chat-translation.rules.ts:67-80). They are the 4 latest non-deleted USER/ADVISOR messages before this one in the same conversation, with empty-text messages and system markers excluded (prisma-messages.repository.ts:362-383). The context therefore holds BOTH sides in their original wording: the person's own earlier messages in their language, and the advisor's English. Only role and text are sent; no timestamps, names or ids. Attachments (files, images, voice) are never sent; only the text or caption is. The message text has a cap of 8000 characters (translation.service.ts:37, 399-402). Longer replies are not sent (chat-translation.service.ts:324). Text with no letters (emoji, numbers, bare links) is never sent (rules.ts:63-65).

Directions:
- person→desk: from 'auto' to 'en'. It runs synchronously before the message is posted to Chatwoot, waiting at most TRANSLATION_CHAT_TIMEOUT_MS (default 6 s) (chat-translation.service.ts:156-234; chat.service.ts:141-146). If a retryable failure happens, a 'desk-note' job translates the same text again later (≤1 h after the message, service.ts:88, 260-303).
- advisor→person: from 'en' to the person's chatLanguage, in a queued job (service.ts:364-429).

Model: whichever of claude-opus-5-5 / claude-sonnet-5-5 / claude-haiku-5-5 is set in TRANSLATION_CHAT_MODEL (claude-thinking.ts:9). The staging proposal is claude-haiku-5-5, thinking off, effort low (deploy/env/bff.env.example:149-152). The prod value is not in the repo. On Opus/Sonnet a classifier refusal can be re-run by Anthropic on another Anthropic model (claude-thinking.ts:15-22). Both directions are off by default: TRANSLATION_CHAT_PROVIDER=off, TRANSLATION_CHAT_TO_DESK / _REPLIES=false (env.schema.ts:419-431).

Our logs: one structured line per call with profile, engine, target language, counts, cost and timings, and never the text (translation.service.ts:266-279, 340-354). The provider's error wording is never kept (translator.port.ts:81-107).

**Где хранится:**

- Advisor reply translation: target language, status PENDING/TRANSLATED/FAILED, translated text, engine label (e.g. claude:claude-haiku-5-5), requeued flag, timestamps — Postgres table message_translations (MessageTranslation), one row per (messageId, language); срок: As long as the message: kept after the person turns the switch off, and still served in history (chat.service.ts:240-252 reads what is stored). Removed when the desk deletes the message (prisma-messages.repository.ts:461) or when the account is deleted. Postgres backups keep it up to 30 days.; при удалении аккаунта: Yes. Erasure runs tx.message.deleteMany for all the person's conversations (prisma-account-erasure.repository.ts:213), and message_translations has FK ON DELETE CASCADE (prisma/migrations/20261108120000_message_translations/migration.sql:32; schema.prisma:178-180). (BFF prisma/schema.prisma:175-198; prisma-messages.repository.ts:385-407 (settleTranslation))
- Only replies are stored translated. The person's own message is NOT stored translated in our DB ("no copy of that is kept here", decision 2). Our messages table keeps only the original text. — Postgres messages.content (original only); срок: While the account exists; при удалении аккаунта: Yes (deleteMany on messages) (schema.prisma:169-174 (comment on MessageTranslation); prisma-account-erasure.repository.ts:213)
- English translation of the person's message, stored on the Chatwoot message as content_attributes.translations.en. The original stays in content. The chatter's bubble shows the English with "View original". — Chatwoot (self-hosted, Hetzner FI), messages table of the conversation; срок: As long as the Chatwoot message/conversation. It stays after the switch is turned off.; при удалении аккаунта: Yes, indirectly. The erasure job deletes the Chatwoot contact (account-erasure.service.ts:80-89; chatwoot-contact.service.ts:55-64; chatwoot.client.ts:352-370). Chatwoot then removes the conversations and their messages in background jobs (chatwoot/app/models/contact.rb:59 has_many :conversations, dependent: :destroy_async; conversation.rb:113 messages dependent: :destroy_async). It is asynchronous and retried, and a 422 (contact online) is retried too. The final pass runs after 5 min and also deletes any contact found by the Firebase UID (account-erasure.service.ts:85-89). (BFF src/modules/chatwoot/chatwoot.client.ts:173-189)
- Desk note: a Chatwoot private note "Translation (EN): <English text>", posted when the send went out without its English (timeout or other retryable failure). It is posted only within 1 h of the message and only if consent and switch are still active when the job runs. — Chatwoot conversation, as a private message (visible to the advisor team only). Never ingested into our DB: private notes normalize to null (message-normalizer.ts:16).; срок: As long as the Chatwoot conversation. The switch being off later does not remove it.; при удалении аккаунта: Yes, with the contact's conversations (destroy_async, as above) (chat-translation.rules.ts:117-119; chat-translation.service.ts:260-303; chatwoot-messaging.service.ts:103-114)
- Person's chat language (chatLanguage, a language code). It is the app's INTERFACE language, written from the ?lang of every message send. It is written whether or not consent was given or translation is on. — Postgres users.chatLanguage; срок: While the account exists; the latest send overwrites it; при удалении аккаунта: Yes, set to null (prisma-account-erasure.repository.ts:48) (schema.prisma:50-52; chat.service.ts:122-123; chat-settings.service.ts:52-56; prisma-users.repository.ts:161-176; APP src/shared/api/bff/http-client.ts:52-57, src/features/chat/api/chat-api.ts:33-39 (sent when the build has i18n enabled))
- client_language contact attribute: the English NAME of the chat language (e.g. "German", also "English"), pushed whenever chatLanguage changes and a contact exists. It does not depend on consent or the switch. — Chatwoot contact custom_attributes.client_language (also offered as a contact filter list); срок: While the Chatwoot contact exists; при удалении аккаунта: Yes, with the contact (deleteContact) (chatwoot/desk-attributes.ts:121-129; chat-settings.service.ts:52-73, 96-102; chatwoot-contact.service.ts:41-50; jobs/queues.ts:91-95)
- Consent record: chatConsentVersion (currently 1) and chatConsentGivenAt (server clock). Switch: chatTranslationEnabled. — Postgres users.chatConsentVersion / chatConsentGivenAt / chatTranslationEnabled; срок: While the account exists. The consent is never cleared by any user action: there is no API to remove it. Turning the switch off only sets chatTranslationEnabled=false.; при удалении аккаунта: Yes: version/time set to null, switch to false (prisma-account-erasure.repository.ts:46-51) (schema.prisma:53-60; prisma-users.repository.ts:186-198 (givenAt = new Date() at :194, written only over none or an older version))
- Desk translation cache: JSON {text: English translation | null} for one send. The key is a SHA-256 of conversationId + idempotency key + original text, so the key holds no id or text. — BFF Redis (bff-redis, AOF on Hetzner disk), key chat-translation:desk:<sha256>; срок: 24 h TTL (DESK_CACHE_SECONDS); при удалении аккаунта: No. No erasure code touches it; it expires by TTL within 24 h. (chat-translation.rules.ts:87-98; chat-translation.service.ts:356-358, 677-683; deploy/docker-compose.prod.yml:137-142)
- Job result cache: JSON {result: {text, engine, sourceLanguage} | null}. This is the translated text of a reply, or the English for a desk note, kept so a job retry does not pay twice. — BFF Redis, key chat-translation:result:<reply|desk-note>:<our messageId>; срок: 1 h TTL (RESULT_CACHE_SECONDS); при удалении аккаунта: No; expires within 1 h (chat-translation.service.ts:90-95, 530-549, 691-693)
- Send hold marker: a random UUID token only, no text — BFF Redis, key chat-translation:desk-busy:<sha256(conversationId, idempotencyKey)>; срок: At most timeout + 130 s (≈136 s by default), usually released at once; при удалении аккаунта: No; expires by itself (no personal content) (chat-translation.rules.ts:107-114; chat-translation.service.ts:110, 571-629)
- Queue jobs 'reply' and 'desk-note' (payload: our messageId only, no text), plus the contact-attributes push job (payload: userId only) — BullMQ on BFF Redis, queues chat-translation and contact-attributes; срок: Completed jobs 24 h, failed jobs 7 days (KEEP_COMPLETED_SECONDS / KEEP_FAILED_SECONDS). This matches the policy's existing 25 h / 8 days.; при удалении аккаунта: No (same as the existing delivery queues sentence); they carry no text (jobs/queues.ts:163-164, 341-368, 410-413, 506-512)
- Monthly spend and circuit-breaker counters per profile (money and state only) — BFF Redis; срок: Rolling budget period; при удалении аккаунта: N/A, not personal (translation.service.ts:120-133; translation-budget.ts)
- Inputs and outputs at the provider — Anthropic (USA); срок: According to AURAI-0012-legal (not verifiable in code): API inputs/outputs deleted within 30 days (privacy center); per the API docs not retained by default except Covered Models; up to 2 years if flagged by safety systems; classifier scores up to 7 years; not used for training; no ZDR. The prompt cache covers only the fixed system prompt (claude-prompt.ts:135-137), so no chat text sits in the prompt cache.; при удалении аккаунта: No. Our deletion cannot reach it; it ages out on Anthropic's own schedule. (AURAI-0012-legal.md:79-91)

**Кто что видит:** ADVISOR TEAM (Chatwoot), new with this feature:
(a) For each translated message from the person, the bubble shows the English machine translation, and the person's original is one tap away ("View original"). The conversation-list preview still shows the original (chatwoot.client.ts:173-189).
(b) Sometimes a private note "Translation (EN): …" in the conversation feed (rules.ts:117-119).
(c) The contact attribute client_language with the English name of the person's app language, set for everyone whose app sends ?lang. It is set regardless of consent or the switch, and also when the language is English. Chatwoot offers it as a contact filter (desk-attributes.ts:121-140).
The advisor's own reply is stored in Chatwoot in English only; its translation is stored only in our database. The team does not see the provider, the engine or the translation status of replies.

PERSON (app): under an advisor reply, "Machine-translated · Show original" (toggle to "Original · Show translation"). They also see "Translating…" while pending and a quiet "Not translated" when it failed. A reply translated into a different language than the one now on screen shows "Translation · <language> · Show" (APP src/screens/chat-thread/ui/TranslationNote.tsx:20-67; config/locales/en.ts:73-90). The person never sees the English the desk received for their own messages. Their own bubbles show what they wrote. The words "AI" and "Anthropic" appear nowhere in the app (APP src/features/chat-settings/config/locales/en.ts:1-10, 28-31).

PROFILE: the "Translate my chat" row appears only once a current consent exists (use-translation-switch.ts:44). Its hint is "Advisors' replies in your language, machine-translated" (en.ts:40), but the switch also controls sending the person's own messages to the desk in English.

**Согласие и переключатель:** STORAGE: PATCH /v1/me/chat-settings {consentVersion:1} writes users.chatConsentVersion=1 and chatConsentGivenAt=now by the SERVER clock. It is written only over no consent or an older version, so a repeated tick does not move the time (prisma-users.repository.ts:186-198; chat-settings.ts:63-90). CHAT_CONSENT_VERSION = 1 (CONTRACTS src/chat-settings.ts:28). The owner's 2026-11-08 text change kept version 1 because no consents exist in prod yet (AURAI-0012-legal.md:51). The consent text itself is not stored server-side, only its version number.

TICK → SWITCH ON: a consent of the current version turns chatTranslationEnabled on in the same request unless the body says false (chat-settings.ts:79-80). That is the "on by default after the tick".

TRANSLATION RUNS ONLY IF ALL of these hold:
- the direction's env switch is on;
- the chat profile is not 'off';
- chatTranslationEnabled is true;
- chatConsentVersion equals the current version;
- chatLanguage is set, is not 'en', and is still enabled/supported.
(chat-translation.rules.ts:31-53; chat-settings.ts:24-29)

So a person whose interface is English is never sent to Anthropic in either direction, even after ticking. A future consent version 2 silently turns translation off for everyone until they tick again.

SWITCH OFF (translationEnabled:false, always accepted): new messages are no longer translated either way. A reply still PENDING settles FAILED without a call (chat-translation.service.ts:376-387). A queued desk note re-checks and does nothing (service.ts:272-274). A call already in flight completes. Nothing already translated is deleted: message_translations rows stay and are still shown, and the English in Chatwoot content_attributes and the private notes stay.

WITHDRAW: in the product today, "withdraw" exists only as the translation switch. There is no control or API to withdraw the consent itself. The PATCH schema accepts only consentVersion ≥1 and translationEnabled (CONTRACTS chat-settings.ts:84-106). The consent record stays and the switch can be turned back on without a new tick. The contract says outright: "Switching it off is how translation is withdrawn … The chat as a whole is withdrawn by deleting the account" (CONTRACTS chat-settings.ts:57, 101-102). The legal note records this as unresolved (AURAI-0012-legal.md:64-65). Account deletion clears the consent fields.

WITHOUT CONSENT:
- The current app blocks sending while consent is required: the card stands above the input and send/retry are disabled (APP screens/chat-thread/model/use-chat-thread.ts:228-264; use-chat-consent.ts:70-71).
- The SERVER never refuses a send without consent. Older builds, and any client that does not show the card, keep chatting without translation (CONTRACTS chat-settings.ts:66-69; BFF openapi.ts:887).
- If the server lacks the route or the version (400/404), the app drops the card for the run and lets the person chat (use-chat-consent.ts:10-16, 83-86).
- Without consent nothing goes to Anthropic, but chatLanguage and client_language are still recorded and sent to Chatwoot.

**Условия провайдера:** From AURAI-0012-legal.md (decision 7, lines 74-106; not verifiable from code):
- Anthropic acts as processor. The DPA is incorporated by reference into the Commercial Terms, so nothing has to be signed separately.
- The DPA contains SCC Module 2 (controller→processor) and Module 3, plus UK and Swiss addenda. Transfer basis chosen: SCC plus a short TIA. Not DPF: the DPA does not mention DPF and certification could not be checked.
- Breach notice: without undue delay, within 48 h at most.
- On termination, data is deleted within 30 days.
- Retention: the privacy center says API inputs/outputs are deleted automatically within 30 days. The API docs say they are not retained by default except for Covered Models, which are not used.
- Safety-flagged content is kept up to 2 years; classifier scores up to 7 years.
- No training without express permission. ZDR is only via sales and is not in place.
- DPA Annex 1 lists "Special categories: None". The legal note suggests telling Anthropic privacy once and keeping the reply.
- Main Anthropic API, not EU Bedrock; Bedrock EU is the fallback plan.
- DPIA (Art. 35) and an Art. 30 record are needed. Neither DPIA, TIA nor record has been drafted yet (line 4).

Draft policy additions (lines 139-146):
- §04: point to the explicit-consent tick.
- §05: Anthropic for machine translation; "receives the message text only, never your name, phone number or account identifiers".
- §06: Anthropic (USA), SCC.
- §07: translations stored and deleted with the conversation; Anthropic deletes inputs within 30 days (up to 2 years if flagged).

**Неожиданное:**

- The 'verbatim' source is out of date. AURAT-0042-118 shows the policy as 'Last updated 17 September 2026'. On 1 October 2026 the live /privacy/ and /terms/ were changed (AURAT-0042-119-legal-pages-apple.md:18-28): App Store payment wording, 'store account password', and a new processor line 'Apple — the App Store, in-app purchases and push notification delivery on iOS'. The design brief (AURAT-0042-claude-design-brief.md:40) still says 'No App Store / Apple badges or links anywhere'. Regenerating from the brief or the snapshot would silently remove the Apple processor. Start from the live 1 October text.
- Anthropic gets MORE than 'the message text only'. Each call carries up to 4 earlier messages of the same conversation as context (both the person's and the advisor's, each up to 500 chars) with speaker roles, plus the advisor persona's gender on replies. So the person's own words also go to Anthropic when the ADVISOR's reply is translated. The 'never your name, phone number or account identifiers' claim is true only for metadata. There is no metadata.user_id or any id, but anything the person types (their name, a relative's illness, a phone number) is in the text. Wording should be 'the message and a few earlier messages of the same chat, without your name, phone number or account identifiers attached'.
- The consent card promises 'withdraw this consent at any time in my profile', but the product can only switch translation off. The consent record stays, the switch can be turned back on without a new tick, and the Art. 9 sensitive-data part can be withdrawn only by deleting the account or emailing privacy@ (CONTRACTS chat-settings.ts:57, 101-102). The policy must not say that withdrawal in the profile stops sensitive-data processing. Either describe it as it works (switch = translation; full withdrawal = deletion or email) or the app needs a real withdrawal control first. The legal note itself flags Art. 7(3) as unresolved (AURAI-0012-legal.md:64-65).
- Turning the switch off (or 'withdrawing') does not delete past translations. message_translations rows stay and are still shown in history. The English copies in Chatwoot (content_attributes.translations.en) and the 'Translation (EN):' private notes stay until the message, conversation or account is deleted. What was already sent to Anthropic stays under Anthropic's retention.
- Language data is collected and shared with the advisor team INDEPENDENTLY of consent and of the switch. Every message send from an i18n-enabled build records users.chatLanguage (the interface language), and on change it pushes the language name to the Chatwoot contact as client_language. This is new data in §02 and new team-visible data in §05, which currently says the team sees only 'name, phone number and profile photo'. It applies also to people who never ticked or whose language is English.
- Redis caches holding translated text are NOT removed by account deletion: chat-translation:desk:* keeps the English for 24 h and chat-translation:result:* keeps the translated text for 1 h. The legal draft for §07 ('translations are stored and deleted with the conversation') is incomplete. Like the queues sentence, it must say short-lived copies may outlive deletion by up to 24 h. The legal note mentions only the 24 h cache, not the 1 h one. Queue jobs for translation carry only a message id (no text), with 24 h / 7 d retention.
- The person's own message is NOT stored translated in our database, only in Chatwoot (the English for the desk). Only advisor replies get a MessageTranslation row. A policy saying 'translations are stored in our database' for both directions would be wrong.
- Translation never runs when the person's app language is English, or has never been set, even after the tick. chatLanguage is the INTERFACE language, not the language the person writes in (contract decision 3). So someone with an English interface who writes in German is not translated either way.
- The server does not enforce 'consent before the first message'. Only the current app blocks sending. Older builds and clients without the card can chat freely, just with no translation. If the server rejects the consent version or lacks the route, the app drops the card and lets the person chat (use-chat-consent.ts:10-16). The policy must not claim nobody can chat without ticking. It should say translation, not chatting, depends on the consent.
- The switch hint ('Advisors' replies in your language, machine-translated') describes only one direction. The switch also stops the person's own messages being machine-translated into English for the advisor team. The policy should describe both directions.
- No region pinning. The Anthropic SDK is created with only an apiKey: no baseURL, no inference-geo, no Bedrock. Processing is on Anthropic's default (US) API, which matches the 'USA + SCC' plan. Nothing in code supports an EU processing claim.
- Anthropic is also used by the campaign profile, to translate owner-written offer texts (no personal data). If the policy says Anthropic is used 'only for chat', that is accurate for personal data only.
- Unverified, needs a check before the policy says the team works only with our translation: Chatwoot has a built-in Google Translate button for incoming messages (AURAI-0012-chat-ai-translation.md:37). If that integration is enabled on the production desk, a chatter pressing it sends message text to Google. That is a different processor, not in §05.
- The legal note names the columns chatTranslationConsentAt / chatTranslationConsentVersion, but the code has chatConsentVersion / chatConsentGivenAt. Only the version number is stored, not the text. Keep the exact card text per version in the brain or the DPIA as proof of what was agreed.
- Policy §04's heading and stance ('Readings are not health data … We never ask you for medical … information') now sits beside a consent card that names health, love life and beliefs as examples. §04 and §03 need a row for the explicit-consent basis covering both sensitive details and the external machine translation. Today §03 lists no consent-based purpose except marketing.

**Исправлено при проверке черновика:**

- Baseline date: the live /privacy/ says 'Last updated 1 October 2026' (AURAT-0042-119), not 17 September. /delete-account/ still says 17 September 2026, because the 1 October edit did not touch it.
- §04 said 'The message is sent only after you tick it'. That is not true: the server never refuses a send without consent, and older builds chat with no tick. The sentence is replaced by what the code does guarantee: without consent, nothing is ever sent for translation.
- §04 did not name the USA or the no-training term. The card leaves the provider to the policy, so the consent is informed only if §04 says these. Both are added.
- §04 and §08 described switching off as withdrawal without saying that the consent record stays and the switch can be turned back on without a new tick. Both now say so, and give full withdrawal as account deletion (in the app or by email) only.
- §04 did not say that the translation language is the app's interface language, not the language the person writes in. Added.
- §05 (team): 'the English translation of each of your messages next to what you wrote' was wrong on two points. Not every message is translated, and the desk shows the English with the original one tap away. When the English could not go with the message, it is posted as a separate private note. The text now describes this.
- §05 (Anthropic): 'It receives only what the message text itself says' could read as 'no personal data'. The text now says plainly that the content of the message and of up to 4 earlier messages from both sides goes to Anthropic, and so does anything the person typed. Captions and the target language are added.
- §03: the explicit Art. 9 consent was put in the 'Legal basis (GDPR Art. 6)' column on its own. It is now paired with contract as the Art. 6 basis. Chat language, which is recorded for everyone and shown to the team even without consent, had no purpose row; it was added, and the row also names the phone number that §05 already lists.
- §06 left Apple out, although §05 has named Apple since 1 October. Apple is added. The 'sent … and processed outside the EEA' wording now says processing is outside the EEA, without claiming it happens only in the US, since the code pins no region.
- §07: the draft did not say that the translation caches survive account deletion. Erasure clears neither the 24 h desk cache nor the 1 h result cache. The text now says so. The 'Translation (EN)' private notes and the fact that switching off keeps the consent record are added too.
- §08: 'withdraws it for translation straight away' is now 'for everything sent after that'. A call in flight still completes, and earlier translations stay.
