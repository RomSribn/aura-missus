# AURAI-0002 — Chatwoot integration architecture for the Aura chat

Date: 2026-07-08
Method: three parallel READ-ONLY agents over the Chatwoot checkout
(`chatwoot-manor/project/manor/master/chatwoot`, **v4.15.1 / Rails 7.1.5.2**) —
(a) contact identity + HMAC + channel types, (b) the four programmatic API
surfaces and their auth/trust tiers, (c) outbound (agent→user) delivery and
real-time. Cross-read against the Aura app's current `features/chat` and
Firebase auth. Nothing in Chatwoot was modified.
Basis for: a future architecture decision (AURAD) and the real chat-backend
feature (AURAF) that replaces the `features/chat` simulation.

---

## 1. The problem, precisely

Two identity worlds must be joined:

- **Aura app** — RN 0.85. Identity is a **Firebase phone-OTP** user: a stable
  `uid` + verified `phoneNumber`, and (crucially) a **Firebase ID token** any
  server can verify with the Admin SDK. Project `aura-2781b`. There is **no
  backend yet** — `src/shared/api/` is Firebase-only, no REST client, no push
  (`@react-native-firebase/messaging` is not installed). Chat is a pure
  in-memory simulation (`features/chat/model/ChatProvider.tsx`): threads keyed
  by `advisorId`, canned replies on a 1.5s timer, explicitly marked
  "replaced wholesale when real-time chat arrives." Advisors are rich personas
  with a **per-minute USD rate** and an `online` flag.
- **Chatwoot** — a separate Rails app with its own DB, front-end and staff
  ("chatters" = Chatwoot **Agents/Users**) who answer from the Chatwoot
  dashboard. Its end-users are **Contacts**, grouped by **Account**, bound to
  an **Inbox** through a **ContactInbox**, holding **Conversations**.

The investigation determines the architecture of the *future* chat backend:
where the trust boundary sits, how an Aura user maps to a Chatwoot contact, and
how an agent's dashboard reply reaches a (usually backgrounded) phone.

---

## 2. Chatwoot integration surfaces (grounded facts, v4.15.1)

### 2.1 Channel: use `Channel::Api`, not the Web widget

`Channel::Api` is the generic programmatic channel — the app *is* the channel;
our own UI, a clean REST-in / webhook-out contract. The Web widget
(`Channel::WebWidget`) assumes you embed Chatwoot's JS SDK and its pre-chat
form — wrong fit for a native RN UI. The API channel is also the **only**
channel that lets a caller inject a message as the contact
(`message_type: incoming`) — see 2.3.

Inbox is resolved by the channel's own `identifier` (a `has_secure_token`
random string, `app/models/channel/api.rb`). The channel also carries
`webhook_url` + a signing `secret`, and `hmac_token` + `hmac_mandatory` for
contact-identity validation.

### 2.2 Contact identity & the HMAC

- `Contact.identifier` is a caller-supplied external ID, **unique per account**
  (`app/models/contact.rb:39,53`). This is where we stamp our stable identity.
- Contacts dedupe at the **account** level in priority order **identifier →
  email → phone_number** (`app/builders/contact_inbox_with_contact_builder.rb:96-118`).
  `phone_number` must be strict E.164 or it is silently dropped
  (`contact.rb:54-56,189-192`).
- **Identity validation is an HMAC**, computed request-time (there is no stored
  hash). Exactly: `hmac == OpenSSL::HMAC.hexdigest('sha256', inbox.hmac_token,
  identifier)` (`app/controllers/public/api/v1/inboxes/contacts_controller.rb:37-43`).
  The signed string is the **raw `identifier` only**; the key is the inbox's
  **secret `hmac_token`**. Enforcement toggles on the per-inbox boolean
  `hmac_mandatory` (default false).
- A verified binding sets `hmac_verified: true` on the ContactInbox, which
  widens data access to *all* of that contact's conversations rather than one
  session (`.../inboxes_controller.rb:25-31`).
- **Consequence that shapes everything:** the `hmac_token` is a server secret.
  It **cannot ship in the RN bundle** (trivially extractable). So *any* design
  that binds identity through the HMAC needs a server to compute the hash — a
  device can never do it safely.

`ContactInbox` also carries `source_id` (per-inbox session key; a `SecureRandom`
UUID for API channels) and `pubsub_token` (the ActionCable subscription token).

### 2.3 The four API surfaces and their trust tiers

Chatwoot exposes exactly four programmatic surfaces. The **same header
`api_access_token` is reused across three privilege tiers** — the tier is
decided by the token owner's type (`app/models/access_token.rb:19-22`).

| Surface | Path | Credential | Trust | Represents |
|---|---|---|---|---|
| **Application API** | `/api/v1/accounts/:id/…` | `api_access_token` = a **User** (or AgentBot) access token | server-to-server **SECRET** | an agent/bot inside one account |
| **Public Client API** | `/public/api/v1/inboxes/:inbox_identifier/…` | **no bearer auth** — `inbox_identifier` + `source_id` (+ optional HMAC `identifier_hash`) | **client-side, contact-scoped** | the contact (end user) |
| **Platform API** | `/platform/api/v1/…` | `api_access_token` = a **PlatformApp** token | super-admin **SECRET** | instance provisioning |
| **Agent Bot** | outbound webhook + Application API | bot access token (replies) + `secret` (inbound HMAC) | server-to-server **SECRET** | an automated inbox participant |

Load-bearing details:

- **Application API** authenticates the token, sets `Current.user = owner`
  (`app/controllers/concerns/access_token_auth_helper.rb:19-20`). A **User**
  token can create/patch Contacts (`identifier`, `phone_number` are settable —
  `.../accounts/contacts_controller.rb:169-171`), ContactInboxes,
  Conversations, and Messages. On a `Channel::Api` inbox a single User token can
  post **both** `message_type: incoming` (as the contact) **and** `outgoing`
  (as the agent) through one endpoint — incoming is gated to API inboxes
  (`app/builders/messages/message_builder.rb:112-118`). An **AgentBot** token is
  whitelisted to conversation/message endpoints only (cannot touch contacts).
- **Public Client API** has **no bearer auth at all**
  (`app/controllers/public_controller.rb:3-6`). Identity is *possession* of
  `inbox_identifier` + the contact's `source_id`; anyone who learns both can
  impersonate that contact. The contact may only send `message_type: incoming`
  (hard-coded — `.../public/api/v1/inboxes/messages_controller.rb:60-68`).
  Create-contact returns `source_id` + `pubsub_token`, which the client must
  persist. Binding this to real identity means enabling `hmac_mandatory` and
  computing `identifier_hash` **server-side** (secret `hmac_token`).
- **Platform API** owner must be a `PlatformApp` (super-admin); it provisions
  Users/Accounts/AccountUsers/AgentBots and can mint any user's access token
  (`platform/api/v1/users_controller.rb`). Not seeded — created via
  `rails console`. A static instance super-secret.
- **Agent Bot** attaches to an inbox via `AgentBotInbox`; its `outgoing_url`
  receives every message/conversation event and its token posts replies. Its
  webhook is the only one that **retries** (3× on 429/500).

### 2.4 Getting an agent's reply back to the phone

For a `Channel::Api` inbox there is **no dedicated send service** — `SendReplyJob`
only emits an *email* notification (`app/jobs/send_reply_job.rb:15`). **The
webhook IS the delivery mechanism.** Every agent dashboard reply is an
`outgoing` message and fires the single `MESSAGE_CREATED` event
(`app/models/message.rb`), which fans out to:

| Mechanism | Fires on agent reply | Retries? | Note |
|---|---|---|---|
| **API-inbox `webhook_url`** | yes (scoped to our inbox) | **no** | recommended primary; HMAC-signed with the channel `secret` |
| Account webhook | yes (all inboxes) | no | account-wide, less scoped |
| **Agent-bot `outgoing_url`** | yes (if a bot is attached) | **yes (3×)** | reliability upgrade over the plain webhook |
| **ActionCable** (`pubsub_token`) | yes | n/a | persistent socket; excludes private notes |
| REST poll `GET …/messages` | pull | n/a | reconciliation safety net |

`message_created` payload includes `message_type` (`"incoming"`/`"outgoing"`),
`content`, the `conversation` (with `display_id` + contact), `inbox`, `sender`
(the answering agent User), and `attachments`. Signature header is
`X-Chatwoot-Signature: sha256=HMAC(secret, "{timestamp}.{body}")`.

**Reliability caveats (must design around):** the account/api-inbox webhooks are
fire-and-forget with a **5s timeout and no retry** (`lib/webhooks/trigger.rb`);
a failed delivery just marks the message failed. There is **no cross-message
ordering guarantee** (separate Sidekiq queues) — order by message `id`/
`created_at` on our side. ActionCable is best-effort and needs reconnect-resync.
→ **A reconciliation poll is mandatory** regardless of the push channel chosen.

---

## 3. The decisive constraint: mobile push needs a server anyway

A chat on a phone must deliver an agent reply when the app is **backgrounded** —
that means a **push notification (FCM)**. Nothing but a server can send an FCM
message in response to a Chatwoot event. Combined with 2.2 (the HMAC secret
can't live on the device) and 2.4 (the webhook, received server-side, is the
delivery path for an API inbox), this means:

> **A backend component is required no matter which option we pick.** The only
> real question is how *thick* it is — a bare identity/token broker, or the
> system of record.

This single fact demolishes the main attraction of "app talks to Chatwoot
directly" (reusing Chatwoot's realtime): the app still can't be woken from
background without our server on the webhook sending the push.

---

## 4. Options considered

| Option | What it is | Complexity | Risk |
|---|---|---|---|
| **A — Thin identity broker; app → Public Client API direct** | Tiny server verifies the Firebase ID token and mints `identifier_hash`; the app then calls the Public API itself (create contact/conversation, POST incoming messages) and subscribes to Chatwoot ActionCable for replies. | Low backend, **high app** | App coupled to Chatwoot's REST + cable protocol + payload shapes; `source_id`/`pubsub_token` live on device; **still needs a server for FCM push** (§3), so the "less backend" win is largely illusory; no home for billing/per-minute/routing; hard to swap Chatwoot later; the API-channel HMAC failure raises a 500, not a clean 401. |
| **B — Backend-for-frontend proxy; Chatwoot as an internal agent desk** ⭐ | The app talks **only** to our backend (auth'd by the Firebase ID token). The backend holds a Chatwoot **User access token**, drives the Application API on a `Channel::Api` inbox (contact upsert, `incoming` for user msgs), receives agent `outgoing` replies via the api-inbox webhook, and pushes them to the phone via **FCM** + our own store/poll. | **High backend**, low app | We build a real (small) chat service + push + webhook receiver + reconciliation; we own realtime-to-phone. But: clean separation, app never knows Chatwoot exists, secrets never on device, we own the data model (billing/sessions/routing/advisor-persona all fit), Chatwoot is swappable. |
| **C — Agent-bot bridge** | Variant of B where an Agent Bot is attached to the inbox; its retrying `outgoing_url` is our webhook and its token posts automated replies. | High (B + bot) | Not a separate architecture — it's a **delivery/automation detail inside B**. The bot token can't provision contacts (still needs a User token). Worth adopting *within* B for the retrying webhook and future first-line automation. |

---

## 5. Recommendation — Option B (BFF proxy), adopting C's webhook

Build a thin **backend-for-frontend** that treats Chatwoot as an internal
"agent desk" implementation detail. The app never sees Chatwoot.

**Why B over A:** the server is unavoidable (§3), so the question is only where
to draw the line. B puts every Chatwoot secret and every payload-shape
dependency behind our own stable API, and gives the per-minute billing, session,
routing, and advisor-persona logic a natural home — none of which fits in A.
A's only advantage (less code) is undercut because it *also* needs a push
server. B is more backend now, but it is the architecture that survives contact
with the product (metered chat, advisor routing, later replacing Chatwoot).

### 5.1 Reference data flow

```
 App  ──Firebase ID token──▶  Aura backend (BFF)  ──User access token──▶  Chatwoot Application API
  ▲                              │  (verify token, upsert contact,           (Channel::Api inbox)
  │                              │   post message_type:incoming)
  │   FCM push + our REST/WS     │
  └──────────────────────────────┤◀── api-inbox webhook (message_type:outgoing) ── agent replies in dashboard
                                 └── reconciliation poll GET …/messages (safety net; order by id)
```

### 5.2 Identity mapping

- One Chatwoot **Contact per Aura user**. Set `identifier = Firebase UID`
  (the canonical thing our backend trusts from the verified ID token) and
  `phone_number = E.164 phone` (agent readability + dedupe). Dedup then resolves
  the same person stably (2.2).
- In pure B we call the Application API server-side and never expose the Public
  API to the device, so the device-facing HMAC is **not needed**; the
  ContactInbox is created `hmac_verified` via the agent-side builder. (Keep the
  HMAC option in mind only if we ever let the app hit the Public API directly.)
- A user re-registering on a new phone = new Firebase UID = new contact; a
  merge policy is a product decision (open question O5).

### 5.3 Advisor ↔ conversation mapping

- One **Conversation per (user, advisor)** under the user's single Contact,
  tagged `custom_attributes.advisor_id`. The app's per-`advisorId` thread maps
  1:1 to a Chatwoot conversation `display_id`; the backend keeps that map.
- **Personas vs answerers:** the app renders the advisor persona (name, avatar,
  per-minute rate) regardless of which chatter actually answered — the webhook's
  `sender` is the Chatwoot agent User, which the app never shows. Routing the
  conversation to the right chatter/team (per-category team, or one "advisors"
  team with the pool) is a Chatwoot-side assignment concern. **Whether a chatter
  answers *as* a persona is the key product decision** (O1).

### 5.4 Message flow

- **User → agent:** app POSTs to our backend → backend posts `message_type:
  incoming` on the conversation via the Application API. Appears in the chatter's
  dashboard.
- **Agent → user:** chatter replies in the dashboard (`outgoing`) → api-inbox
  webhook hits our backend (verify `X-Chatwoot-Signature`, filter
  `message_type=="outgoing"` && `private==false`) → store, order by `id`, send
  **FCM push** + serve over our REST/WS. Add `@react-native-firebase/messaging`
  (natural, we already run Firebase).
- **Reconciliation:** periodic `GET …/messages` after the last known id closes
  the no-retry / no-ordering gaps (§2.4). Consider attaching an **Agent Bot** so
  the delivery webhook retries (3×) and to host future first-line automation.

---

## 6. Open questions (feed the AURAD decision / AURAF feature)

- **O1 — Personas vs real agents.** Do chatters answer *as* the advisor persona
  (Mia, etc.), or is "advisor" only a routing label and the real agent identity
  is hidden? Drives sender display and routing. *(Recommended: persona in-app,
  agent identity hidden.)*
- **O2 — Metered chat / billing.** Advisors carry a per-minute rate. Is chat
  billed per message, per minute, or per session? The BFF data model must
  accommodate it even if v1 is free.
- **O3 — Backend stack & hosting.** Language/framework (Node/Nest is a natural
  fit for the RN team) and where it runs. Not decided.
- **O4 — Conversation lifecycle.** One rolling conversation per advisor, or a
  new one per session? Interacts with Chatwoot's `lock_to_single_conversation`
  inbox setting and with billing (O2).
- **O5 — Identity edge cases.** Phone-change/merge policy; multi-device;
  logout/data retention.
- **O6 — Chatter provisioning.** Manual invite in Chatwoot (fine for a small
  team, recommended for MVP) vs Platform-API automation.
- **O7 — Self-host vs Chatwoot Cloud** and account/inbox topology
  (one inbox per environment).

---

## 7. Outcome

- Recommendation: **Option B** — a backend-for-frontend proxy with Chatwoot as
  an internal agent desk behind the Application API (`Channel::Api` inbox) +
  api-inbox webhook + FCM push + reconciliation poll; adopt an Agent Bot for the
  retrying webhook.
- Feeds a future **AURAD** decision (resolve O1–O7, especially the billing model
  and backend stack) and the **AURAF** feature that replaces the
  `features/chat` simulation with the real backend client.
- No code written; Chatwoot checkout untouched (READ-ONLY).
```
