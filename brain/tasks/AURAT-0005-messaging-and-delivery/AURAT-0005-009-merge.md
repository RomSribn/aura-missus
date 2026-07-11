# AURAT-0005-009 — Merge

Date: 2026-07-11

## Result

- Feature branch: `feature/AURAT-0005-messaging-and-delivery`
  (code commit `8e4578c` + merge commit `7e9704e`).
- Manor master (develop) after merge: **`8b228ab`**, pushed to
  `origin/develop` ✓ (012c18e..8b228ab).
- Missus: "no commits to merge" as expected — docs stay uncommitted on the
  slave branch until task close.
- Idle slaves 3/4/5 refreshed to the new develop.

## Integration conflict (expected, resolved in slave)

Slave-2's **AURAT-0007** (wallet + ledger + `BILLING_ENABLED`) merged into
develop (`012c18e`) while this task was in flight — the collision predicted in
005-context #4. First `wts-finish` hit conflicts in the manor; **aborted the
manor merge**, merged develop into the feature branch in slave-1 instead, and
union-resolved 5 files there (schema.prisma — User gets both `deviceTokens` +
`wallet`, all four new models kept; contracts/index.ts; env.schema.spec.ts;
README.md; TECH-DEBT.md — renumbered 1–9, wallet's append-only item is now #7).
Full gates re-ran on the merged tree **before** re-running `wts-finish`:
typecheck ✓ lint ✓ **97 tests / 17 suites** ✓ build ✓.

Note: both tasks' migrations share the `20260711100000_` timestamp prefix;
folder-name ordering keeps `migrate deploy` deterministic (messages before
wallet). Harmless.

## To verify in manor

1. `docker compose up --build` — boot requires the new `CHATWOOT_WEBHOOK_SECRET`
   env; `prisma migrate deploy` applies both new migrations.
2. Point the dev Chatwoot inbox `webhook_url` at `<bff>/webhooks/chatwoot`;
   confirm real webhook headers verify (X-Chatwoot-Signature/-Timestamp).
   If attaching the Agent Bot: check whether its webhook signs with a
   different secret → `CHATWOOT_WEBHOOK_SECRET_SECONDARY`.
3. Send via `POST /v1/advisors/mia/messages` (Firebase token) → message
   appears in the Chatwoot dashboard.
4. Reply from the dashboard → stored within seconds (webhook) → visible in
   `GET .../messages`; WS client on `/ws?token=` receives `message.new`.
5. Drop the webhook (temporarily wrong URL) → reply recovered by the 60s
   reconciliation poll.
6. `PUT /v1/devices/:token` + background FCM ping on reply (data-only).

Next: user verification in manor (010).
