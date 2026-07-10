# AURAD-0001 — An advisor is a persona answered by a pool of chatters, not one human

Date: 2026-07-08
Status: accepted (owner-ratified 2026-07-09)

## Decision

Each advisor is a **curated persona** (name, avatar, bio, specialties, rate),
not a real named person. **Behind an advisor sits a Chatwoot chatter** (any one
of a pool); the app only ever receives the persona, and the chatter's real
Chatwoot identity (the `sender` field in Chatwoot's webhook) is **discarded at
our backend**, never sent to the app. Closes O1 of `AURAI-0002`.

## How it works

- The persona lives in `entities/advisor`; a Chatwoot **conversation per
  (user, advisor)** is tagged `custom_attributes.advisor_id` (see
  `AURAI-0002` §5.3).
- Routing: each persona maps to a Chatwoot **team** (or one "Advisors" team +
  assignment rules); chatters pick threads from the team queue. Any chatter on
  that team may answer any thread for that persona.
- On every inbound webhook the BFF **discards the real `sender`** (the Chatwoot
  agent User) and re-labels the message as the advisor persona from *our* advisor
  data before storing/pushing — so as different chatters rotate across shifts on
  one persona, the app still shows a single, consistent advisor. Note Chatwoot
  sends the real agent identity by default, so discarding it is an active step,
  not automatic.
- **Presence and typing are persona-level**, computed backend-side, not from one
  agent: `advisor.online` = "at least one chatter is available for that
  persona's team"; a Chatwoot `conversation_typing_on` from any agent → persona
  typing.
- **Continuity:** several chatters may answer one persona thread over its life;
  the Chatwoot conversation history plus a per-persona voice guide keep tone
  consistent.
- **Chatter tooling:** chatters answer through the Chatwoot dashboard with the
  composer augmented by **canned responses and inline translation**, which holds
  the persona's voice steady across a large, around-the-clock pool.

## Why

- The design ships curated personas (names, avatars, ratings, bios, per-minute
  rate) — the value proposition is the persona, not the individual worker.
- 1 persona = 1 human does not scale and breaks the moment that human is
  offline. In practice a persona is served by a large, 24/7 chatter pool (order
  of hundreds of people across shifts, high concurrent volume) — it cannot be a
  single human; a pool keeps every advisor "always answerable."
- Keeps the app fully decoupled from Chatwoot staffing, per `AURAI-0002`
  Option B — Chatwoot is a swappable agent desk.

Assumption: shared-pool operation with voice guidelines. If advisors later
become real, named 1:1 practitioners, open a superseding decision.

Informed by `AURAI-0002`. Implemented by the future `AURAF` chat backend.
