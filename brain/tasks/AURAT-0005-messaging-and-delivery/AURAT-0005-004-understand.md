# AURAT-0005-004 — Understand

Date: 2026-07-11

Build the two-way messaging + delivery layer of the BFF on top of the
AURAT-0004 foundation. Concretely: (1) an authenticated send endpoint that
posts the user's message as `message_type: incoming` on the mapped Chatwoot
conversation; (2) a Postgres message store ordered by Chatwoot message `id`;
(3) an HMAC-verified webhook receiver for `message_created` that persists
agent replies (`outgoing`, non-private) and fans out; (4) a BullMQ
reconciliation poll that fetches messages after the last known id to cover
webhook gaps; (5) a history read endpoint; (6) Agent Bot wiring on the inbox
so the delivery webhook retries.

Acceptance: app-sent message appears in the Chatwoot dashboard; a chatter's
reply is stored within seconds via webhook AND recovered by the poll if the
webhook drops; history endpoint returns messages in correct order.

Out of scope here: FCM push + WS gateway are AURAF-0007-002's delivery leg —
whether they land in this task or AURAT-0006 needs a scope decision in the
spec (the task folder name says "messaging-and-delivery"; the spec's scope
list has fan-out but its acceptance tests only store+order). Flag in spec.

No user-facing ambiguity worth a clarifying question; scope question goes in
the spec for approval.

Next: context (005).
