# AURAT-0005-015 — Approved

Date: 2026-07-11
Status: **done**

User verified the live loop in the manor and accepted («да, пришло»):

- Swagger send (`POST /v1/advisors/mia/messages`, body now documented) →
  conversation + message in Chatwoot **account 1 / inbox "Aura (dev)"**
  (`display_id 1`, `custom_attributes.advisor_id=mia`).
- Dashboard reply → delivered to the BFF (HMAC-verified webhook), stored,
  returned by `GET /v1/advisors/mia/messages`. Signed-probe evidence earlier:
  bad HMAC → 401, valid → 204.
- `/health/ready` green (DB + Redis) in the compose stack.

## Acceptance vs 001-check

| Criterion | Result |
|---|---|
| App-sent message appears in Chatwoot dashboard | ✓ live |
| Chatter reply stored within seconds via webhook | ✓ live |
| Recovered by poll if webhook dropped | ✓ smoke drive + probe (poll runs every 60s in stack) |
| Messages returned in correct order | ✓ live + unit/smoke |

FCM/WS legs: implemented + verified by unit tests and smoke drive; on-device
end-to-end lands with AURAT-0006 (app client), as specced.

## Manor ops fixed along the way (013/014)

DB role (user ran host PG first), `CHATWOOT_BASE_URL` for compose, inbox
`webhook_url` (was :8080), user added to account 1 as administrator. Compose
healthcheck noise fix (`pg_isready -d`) committed on the feature branch —
rides `wts-release` into develop.

Remaining mechanics: missus docs commit → `wts-release slave-1` →
active-work.md update.
