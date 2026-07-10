# AURAT-0005-001 — Check

Date: 2026-07-10

Implements the two-way messaging + delivery backend of `AURAF-0007` (items
001/002/003, BE). Obeys `AURAI-0002` §2.3–2.4 (Application API, webhook,
reliability caveats) and `AURAD-0005` (Agent Bot for the retrying webhook).

Already in place: AURAT-0004 (BFF foundation — auth, Chatwoot client, contact /
conversation mapping).

## Scope

- **Send** endpoint: user message → `message_type: incoming` on the mapped
  conversation via the Application API.
- **Message store** (Postgres) ordered by Chatwoot message `id` (no cross-message
  ordering guarantee — order on our side).
- **Webhook receiver** for the api-inbox `message_created`: verify
  `X-Chatwoot-Signature`, filter `message_type == "outgoing"` && `private ==
  false`, persist + fan out.
- **Reconciliation poll** job (BullMQ, `GET …/messages` after last id) to cover
  the 5s / no-retry / no-order webhook gaps.
- Attach an **Agent Bot** to the inbox so the delivery webhook **retries**.
- History read endpoint.

## Acceptance

An app-sent message appears in the Chatwoot dashboard; a chatter's dashboard
reply is stored by the BFF within seconds via webhook **and** recovered by the
poll if the webhook is dropped; messages are returned in correct order.

## Dependencies

AURAT-0004. Blocks AURAT-0006.

Next: AURAT-0006 (app client + push + retire the sim).
