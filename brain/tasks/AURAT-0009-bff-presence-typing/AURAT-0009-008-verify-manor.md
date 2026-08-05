# AURAT-0009-008 — Verify (manor)

Date: 2026-08-05
Manor `develop` @ `8c3734e`, live stack against the dev Chatwoot.

## Confirmed by the owner

- **Typing indicator works.** Chatter types in the dashboard → the persona
  indicator appears live in the app. This is the end-to-end proof of the whole
  path: signed api-inbox webhook → `normalizeWebhookEvent` → `presence` queue →
  `TypingService` transition → WS → app. It also confirms the source-read
  premise the task was built on — Chatwoot really does deliver
  `conversation_typing_on/off` to the existing receiver with no Chatwoot-side
  configuration.
- **Presence works.** The persona online dot reflects the chosen availability
  source (polled inbox agent availability), not a static seed flag.

Both acceptance criteria from the task brief are met.

### Private note raises no indicator (check 4) — confirmed live

Chatter switched the dashboard composer to the **Private Note** tab and typed;
**no** indicator appeared in the app, and switching back to **Reply** raised it
again. The control half matters: an empty result on the private-note tab alone
would look identical to a dropped webhook, so the Reply leg is what makes it
evidence rather than absence.

### `is_private` is a real boolean end-to-end — verified from source

Worth recording because the unit test could not establish it: `webhook-events.spec.ts`
feeds `is_private: true` as a boolean, i.e. it *assumes* the type it is testing,
while the receiver filters strictly (`wire.is_private === true`). A string
`"true"` on the wire would have passed the filter and raised the indicator on a
private note. Chased through Chatwoot v4.15.1:

`ReplyBox.isPrivate()` → `isOnPrivateNote` (boolean; for an API inbox the
computed returns it directly, no other branch) → `conversation.js`
`axios.post(url, { typing_status, is_private: isPrivate })` (JSON) → Rails
`params[:is_private]` as `TrueClass` → `handle_typing_status` sets
`event.data[:is_private] || false` → `Webhooks::Trigger#perform_request`
`body = @payload.to_json`. No stringification anywhere; the strict check is
correct.

### Log cleanliness (check 9) — structurally verified, not live-grepped

Audited in code rather than against a running instance: no `console.*` anywhere
in `src/`; all ten logger call sites enumerated, of which the AURAT-0009 ones log
`{ chatwootConversationId }` or `{ err }`; `ChatwootApiError` carries status +
path only and never a response body; pino logs no request bodies and redacts the
signature and authorization headers. The decisive property is structural rather
than disciplinary: **`user` is not declared in `CwWebhookTypingWire`**, so there
is no code path that *can* read the chatter's id, name or email — not "we do not
log it" but "there is nothing to log it with".

## Still not exercised

| # | Check | Why it matters | Code-side status |
|---|---|---|---|
| 6 | Service User alone online ⇒ dot stays **off** | Otherwise every persona reads permanently online and presence is decorative | Unit-covered: `chatwoot.client.spec.ts` excludes the `/profile` id; the live half is whether `/api/v1/profile` returns the expected id on this instance |
| 3 | TTL clears the indicator when `typing_off` is lost | A stuck indicator is the failure mode the 45s TTL exists for | Unit-covered with fake timers; needs a dropped webhook to see live |
| 9 | A live `grep` of the running BFF's logs | Confirms the structural argument above against a real event stream | See above — structurally enforced, one command whenever the stack is up |

Owner closed the task on the two acceptance criteria; checks 4 and 9 followed.
