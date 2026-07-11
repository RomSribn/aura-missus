# AURAT-0004-004 — Understand

Date: 2026-07-11

Stand up the Aura BFF foundation in the greenfield `aura-bff` repo: a NestJS
(Fastify) TypeScript-strict service with Postgres (Prisma) + Redis (BullMQ)
wired, a Firebase Admin ID-token guard on every request, and the Chatwoot
adapter that can idempotently provision a Contact (identifier = Firebase UID)
and a per-(user, advisor) Conversation, owning the mapping table BFF-side.

Acceptance is one flow: an authenticated app request for a given advisor
ensures contact + conversation in Chatwoot and returns **our** conversation id;
repeat calls reuse the same rows (idempotent).

Explicitly NOT in this task: webhook receiver + messaging (AURAT-0005), app
client (AURAT-0006), wallet/sessions (AURAT-0007/0008, `billing_enabled`).
Runtime verification (live Chatwoot/DB) happens in the manor after merge —
slave work is code + pure unit tests only.

Next: 005-context.
