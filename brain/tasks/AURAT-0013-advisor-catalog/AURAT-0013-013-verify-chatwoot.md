# AURAT-0013-013 — The Chatwoot leg, verified after the fact

Date: 2026-08-13
Ran from: manor, `develop` @ `b0ee16a`, after the owner started the dev Chatwoot
Status: **the two gaps left open by step 011 are now closed** — plus one real
misconfiguration found in the dev inbox

Step 011 could not exercise Chatwoot and said so. The owner brought it up, so this
closes the same two items honestly rather than leaving them as "not verified".

## First: `localhost` was never going to work

Chatwoot answered `200` from the host and **connection refused** from inside the
bff container — inside a container `localhost` is the container. Repointed the
manor `.env` at `http://host.docker.internal:3001` (backup:
`.env.bak-before-chatwoot`) and restarted. Every `fetch failed` in the log —
presence poll, reconciliation — stopped at once. **This was never a Chatwoot
outage; the config could not have worked from the container in any state.**

## Provisioning — ✓ (this is what step 011 substituted a fixture for)

Booked `sunshine` (fresh advisor, no map row) so `ensureConversation` had to go all
the way to Chatwoot. **201**, price `260`/min → `2600`, balance 6800 → 4200.

On our side: `conversations` row with a real `chatwootConversationId = 8`.
On Chatwoot's side, checked through the API, not inferred:

- Contact `identifier` **equals the Firebase UID** — the identity mapping holds.
- `custom_attributes.advisor_id = "sunshine"` — the per-advisor tag is set.
- `lock_to_single_conversation` is **false** on the inbox, as AURAD-0003 requires:
  dedupe stays BFF-side.

Sending a second time reused conversation 8 — still exactly one row, no second
Chatwoot conversation. Provisioning is idempotent against a live Chatwoot, not
just in unit tests.

## Session markers — ✓

- Booking posted message **66**, `message_type: 2` (**activity**, not a chat
  message), "Your session has started".
- `custom_attributes` carried the live meter: `aura_session_status: "active"`,
  `aura_session_ends_at`, `aura_paid_minutes_total: 10`.
- Finishing posted **67**, "Your session has finished", and reset the meter to
  `aura_session_status: "none"`, `aura_session_ends_at: ""`.

So AURAT-0008's claim that `message_type: 'activity'` is accepted holds on this
instance, and the meter is written and cleared rather than left stale.

## The full loop — ✓

User → agent: **68**, `message_type: 0` (incoming), stored `USER`.
Agent → user: posted an outgoing reply as an agent; **70** arrived and was stored
`ADVISOR`. History orders by `chatwootMessageId`: 66, 67, 68, 70. It arrived on the
**inbox webhook** within seconds — the log shows the `/webhooks/chatwoot` hits and
no reconciliation warnings, so this was the live path, not the 60s poll covering
for it.

## Found: the Agent Bot points at the wrong port

Chatwoot wrote its own activity line into the conversation — *"Диалог был открыт
системой из-за ошибки бота агента"*. The cause:

| | configured | listening |
|---|---|---|
| inbox `webhook_url` | `http://host.docker.internal:3000/webhooks/chatwoot` | ✓ the BFF |
| agent bot `outgoing_url` | `http://host.docker.internal:**8080**/webhooks/chatwoot` | ✗ nothing |

**Consequence:** the *retrying* delivery leg is dead in dev. Agent replies still
arrive, but only via the inbox webhook — which per AURAI-0002 §2.4 has a 5s
timeout, no retry and no ordering guarantee — with the reconciliation poll as the
only backstop. That is exactly the redundancy the agent bot exists to provide, so
dev is currently running on one leg and does not represent the intended topology.
Config only, no code involved; **not fixed here** — changing the owner's Chatwoot
is theirs to authorise.

## Found: the cleanup was BFF-side only

Step 011's SQL emptied our tables. Chatwoot still holds **8** conversations,
including the retired personas (`mia` ×2, `laura`, `mijina`, `sol`, `iris`) and
`advisoor-test-1`. They are now orphaned: no BFF map row points at them. Harmless
while nobody writes to them, but a message posted into one of those conversations
would arrive on the webhook with no conversation to map it to. Worth a deliberate
decision — delete them in Chatwoot, or leave them and accept unmappable inbound.

## Net

Nothing in this section changes AURAT-0013's verdict — the advisor catalog was
already proven in step 011, and none of the Chatwoot behaviour above belongs to
this task. What changes is that the "unverified" list from step 011 is now empty:
provisioning and session markers both work against a live Chatwoot.
