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

## Not separately exercised

Recorded honestly rather than assumed — each is a case where a defect would be
*silent* rather than visible, so none is disproven by the two checks above:

| # | Check | Why it matters | Code-side status |
|---|---|---|---|
| 4 | Typing on a **private note** raises no indicator | A chatter drafting an internal note would leak as "the advisor is typing to you" | Unit-covered: `webhook-events.spec.ts` drops `is_private: true` for both on and off |
| 6 | Service User alone online ⇒ dot stays **off** | Otherwise every persona reads permanently online and presence is decorative | Unit-covered: `chatwoot.client.spec.ts` excludes the `/profile` id; the live half is whether `/api/v1/profile` returns the expected id on this instance |
| 3 | TTL clears the indicator when `typing_off` is lost | A stuck indicator is the failure mode the 45s TTL exists for | Unit-covered with fake timers; needs a dropped webhook to see live |
| 9 | No agent name / email / id in logs | The typing payload carries all three on the wire (AURAD-0001, build rule 3) | Structurally enforced: `user` is not declared in `CwWebhookTypingWire`, so no code path can read it |

Checks 4, 6 and 9 are worth a minute in the manor whenever the stack is next up
— they are the ones a user would never report as broken.

Owner closed the task on the two confirmed criteria.
