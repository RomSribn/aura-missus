# AURAT-0009-001 — Check

Date: 2026-07-11
Minted during AURAT-0006 planning (owner-approved). Runs in **aura-bff-manor**.

Closes the AURAF-0007-004 backend gap deferred out of AURAT-0005 (its spec
decision 5): the BFF emits no persona presence/typing, while AURAD-0001
promises persona-level presence + typing in the app.

## Scope

- Emit WS events per `@aura/contracts@0.2.0`:
  - `typing.update {advisorId, typing}` — translate Chatwoot
    `conversation_typing_on` / `conversation_typing_off` webhook events
    (received on the existing HMAC-verified receiver) to the conversation's
    user; debounce/auto-clear (Chatwoot "off" can be lost — expire after ~10 s).
  - `presence.update {advisorId, online}` — persona-level availability.
    Source decision inside the task: simplest v1 = advisor catalog flag or
    inbox agent availability from the Application API; **never** individual
    agent identity (AURAD-0001).
- Extend the webhook receiver's accepted-event set accordingly (currently
  message-events only, others 204-ignored).
- App side is already plumbed by AURAT-0006 (graceful fallback until this
  ships): no app changes needed.

## Also record (BFF tech-debt, found in 0006)

- `GET /v1/conversations` — the app currently rebuilds its thread list by
  delta-syncing each seed advisor; give it a real list endpoint before the
  advisor catalog outgrows the seed.
- BFF still imports contracts from `src/contracts/` — migrate to
  `@aura/contracts` package (AURAD-0006 intent) when convenient.

## Acceptance

Chatter types in the dashboard → app shows the persona typing indicator
live; indicator clears on stop/timeout. Persona online dot reflects the
chosen availability source, never a concrete agent.

## Dependencies

AURAT-0005 (webhook receiver, WS gateway) — done. Contracts v0.2.0 — done
(AURAT-0006).
