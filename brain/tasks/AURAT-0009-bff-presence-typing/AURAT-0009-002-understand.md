# AURAT-0009-002 — Understand

Date: 2026-08-05
Slave: `slave-1` (aura-bff-manor), branch
`feature/AURAT-0009-bff-presence-typing` (paired master + missus).
Brain at `70b083d`. ID minted in `aura-app-manor` — nothing minted here.

## What the owner wants

Close the last BFF gap of `AURAF-0007-004`: the app already renders
persona-level typing and presence, but nothing ever emits those events. The
BFF must start producing them.

1. **`typing.update {advisorId, typing}`** — translated from Chatwoot's
   `conversation_typing_on` / `conversation_typing_off` webhook events on the
   existing HMAC-verified receiver, debounced, with an auto-clear timeout
   because Chatwoot's "off" can be lost.
2. **`presence.update {advisorId, online}`** — persona-level. The availability
   source is mine to choose and justify in the spec (advisor-catalog flag vs
   inbox agent availability via the Application API). The individual chatter's
   identity must never reach the app under any circumstance (`AURAD-0001`).
3. **Widen the webhook receiver's accepted-event set** — today it only handles
   message events and silently 204s everything else.

Plus two recorded debts to rule on in the spec (take now or defer):

- `GET /v1/conversations` — the app rebuilds its thread list by delta-syncing
  every seed advisor and has no conversation list of its own (`AURAT-0006` G4).
- The BFF still keeps a local copy of the contracts in `src/contracts/`
  instead of the `@aura/contracts` package (`AURAD-0006` intent).

## Correction to 001-check

001-check says contracts `0.2.0`. **Stale** — `@aura/contracts` is at **v0.3.0**
(aligned to the as-built BFF during `AURAT-0010`; the app depends on
`github:RomSribn/aura-contracts#v0.3.0`). Both `presence.update` and
`typing.update` already exist in its `WsServerEvent` union — verified by
reading the installed package, not by trusting the note.

## Acceptance (owner's words)

A chatter types in the dashboard → the persona typing indicator appears live in
the app, and clears on stop or on timeout. The persona online dot reflects the
chosen availability source and never a concrete agent.

## Constraints

Slave rules: code edits, lint, build, typecheck, pure unit tests only. No stack,
no `docker compose up`, no live Postgres / Redis / Chatwoot. Runtime proof
(webhook → WS → FCM) happens in the manor after merge. Spec → owner approval →
code → IDE review → commit → merge gate.
