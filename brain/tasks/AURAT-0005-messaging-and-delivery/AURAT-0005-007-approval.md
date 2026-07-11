# AURAT-0005-007 — Approval

Date: 2026-07-11

User approved the spec (006) as written: **"Approve, implement"** — full scope
including the delivery module, with all five recommended decisions:

1. Delivery module (FCM + WS + device registry) in scope now.
2. Plain WebSocket (`@nestjs/platform-ws` + `ws`), not socket.io.
3. Data-only FCM payloads — no message content in push.
4. `CHATWOOT_WEBHOOK_SECRET` required at boot.
5. Presence/typing deferred to AURAT-0006 planning.

Next: execute (008) — implementation on feature/AURAT-0005-messaging-and-delivery.
