# AURAT-0005-014 — Verify: manor ops fixes (user asked me to drive)

Date: 2026-07-11

## Found & fixed (manor env/config, no slave code involved)

1. **`ECONNREFUSED` on send** — `.env` had `CHATWOOT_BASE_URL=http://localhost:3001`;
   inside the bff container that's the container itself. → set to
   `http://host.docker.internal:3001`.
2. **Wrong Chatwoot account in UI** — user was creating a new inbox in account
   2 ("test"); the service token belongs to **account 1**, which already has
   the proper `Channel::Api` inbox **"Aura (dev)" (id 1)** from AURAT-0004
   verification. `.env` ids (account 1 / inbox 1) are correct; verified
   `inbox_identifier`, webhook `secret`, `hmac_token` all match `.env`.
3. **Inbox `webhook_url` pointed at port 8080** (stale) → PATCHed via
   Application API to `http://host.docker.internal:3000/webhooks/chatwoot`.
4. Recreated `bff` container.

## Live evidence

- `GET /health/ready` → `{database: true, redis: true}`.
- `bff` container → Chatwoot reachable via host.docker.internal:3001.
- **Webhook probe with real HMAC** (openssl, Chatwoot Trigger format
  `sha256=HMAC(secret,"{ts}.{body}")`): bad signature → **401**, valid →
  **204** (enqueued; unknown-conversation event is ignored by design).

The recurring `database "aura" does not exist` FATAL in postgres logs is the
old compose healthcheck probing db=user; fix (`pg_isready … -d aura_bff`) is
staged in slave-1, rides the next merge.

Remaining for user (needs their Firebase token + dashboard): Swagger send →
message appears in **account 1** inbox "Aura (dev)" (switch account in UI!);
dashboard reply → GET history (webhook, or poll ≤60s); Swagger body visible.

Next: user verdict (015: approved or fix).
