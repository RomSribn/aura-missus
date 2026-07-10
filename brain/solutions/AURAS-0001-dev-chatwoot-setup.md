# AURAS-0001 — Dev Chatwoot setup for the BFF

Date: 2026-07-10
Status: living
Feeds: `AURAT-0004` (bff-foundation) — its "needs a dev Chatwoot instance" dependency
Source: `AURAD-0005` (hosting/topology), `AURAI-0002` (integration surfaces), and the
Chatwoot **4.15.1** checkout at `chatwoot-manor/project/manor/master/chatwoot`.

Stands up a **dev Chatwoot** instance and the integration surface the BFF drives —
one **`Channel::Api` inbox**, a **service User** token, an **Agent Bot** — then
captures the values the BFF needs in its `.env`.

> Runs in **`chatwoot-manor`** (its manor owns the Chatwoot runtime). Needs Docker.
> Produces **secrets** — server-side only, never in the app bundle (`AURAI-0002`
> §2.2). One `Channel::Api` inbox **per environment** (`AURAD-0005`); this is the
> **dev** inbox.

## Facts from the checkout (so the steps are exact)

- `channel_api` columns (`app/models/channel/api.rb`): `identifier`
  (`has_secure_token`, unique), `hmac_token` (`has_secure_token`, unique), `secret`
  (via `WebhookSecretable`), `webhook_url`, `hmac_mandatory` (default `false`).
  Editable: `webhook_url`, `hmac_mandatory`, `additional_attributes`.
- `AgentBot`: `outgoing_url` (the **retrying** delivery webhook — 3× on 429/500,
  `AURAI-0002` §2.4) + its own access token; attaches to an inbox via
  `AgentBotInbox`; cannot create contacts.
- Dev compose services (`docker-compose.yaml`): `rails` :3000, `vite` :3036,
  `sidekiq`, `postgres` (pgvector pg16) :5432, `redis` :6379, `mailhog` :8025.
  `FRONTEND_URL=http://localhost:3000`; `.env` already populated.

## Step 1 — bring up Chatwoot

```bash
cd <workspace>/chatwoot-manor/project/manor/master/chatwoot
docker compose build                                                  # first time only
docker compose run --rm rails bundle exec rails db:chatwoot_prepare   # create + seed DB
docker compose up                                                     # rails:3000, vite:3036, sidekiq, pg, redis, mailhog
```

Open `http://localhost:3000` → create the first user (becomes super admin) → create
an **Account**. Mail goes to Mailhog (`http://localhost:8025`).

## Step 2 — API inbox (`Channel::Api`)

UI: **Settings → Inboxes → Add Inbox → API**, name **`Aura (dev)`**. Chatwoot
auto-generates `identifier`, `hmac_token`, `secret`. Point the **webhook** at where
the BFF listens (from Chatwoot's container the host is `host.docker.internal`):

- `webhook_url = http://host.docker.internal:8080/webhooks/chatwoot`
- keep `hmac_mandatory = false` — the BFF calls the **Application API** server-side;
  the device never touches the Public API (`AURAI-0002` §5.2).

Read back all values (the UI hides some) via the console:

```bash
docker compose exec rails bundle exec rails runner \
  "c = Inbox.find_by(name: 'Aura (dev)').channel; \
   puts({ account_id: c.account_id, identifier: c.identifier, \
          hmac_token: c.hmac_token, secret: c.secret, webhook_url: c.webhook_url }.to_json)"
```

## Step 3 — service User + Application-API token

The BFF authenticates the Application API with a dedicated **service User** token
(not a human agent's — `AURAD-0005`). Create agent **`Aura BFF`** (Settings →
Agents → Add Agent, e.g. `bff@aura.local`, accept the invite via Mailhog), then:

```bash
docker compose exec rails bundle exec rails runner \
  "u = User.find_by(email: 'bff@aura.local'); puts u.access_token.token"
```

This token is the `api_access_token` header the BFF sends (`AURAI-0002` §2.3). A
User token can post both `message_type: incoming` (as the contact) and `outgoing`
on a `Channel::Api` inbox.

## Step 4 — Agent Bot (retrying webhook)

Attach an Agent Bot so the delivery webhook **retries**; its token can post replies
but **cannot** provision contacts (that stays on the service-User token):

```bash
docker compose exec rails bundle exec rails runner "
  acc = Account.first
  ib  = Inbox.find_by(name: 'Aura (dev)')
  bot = AgentBot.create!(account: acc, name: 'Aura BFF Bot', \
                         outgoing_url: 'http://host.docker.internal:8080/webhooks/chatwoot')
  AgentBotInbox.create!(inbox: ib, agent_bot: bot)
  puts bot.access_token.token
"
```

The bot's `outgoing_url` is the retrying webhook; the plain inbox `webhook_url` from
Step 2 is the fire-and-forget backup. The BFF reconciles regardless (`AURAI-0002`
§2.4).

## Step 5 — capture into the BFF `.env` (per-env, `AURAD-0005`)

```dotenv
# Chatwoot (dev) — server-side secrets only, never in the app bundle
CHATWOOT_BASE_URL=http://host.docker.internal:3000   # from BFF container; http://localhost:3000 if BFF runs on host
CHATWOOT_ACCOUNT_ID=<account_id>
CHATWOOT_INBOX_IDENTIFIER=<channel.identifier>
CHATWOOT_INBOX_HMAC_TOKEN=<channel.hmac_token>
CHATWOOT_WEBHOOK_SECRET=<channel.secret>             # verify X-Chatwoot-Signature = sha256({timestamp}.{body})
CHATWOOT_SERVICE_USER_TOKEN=<service User access token>
CHATWOOT_AGENT_BOT_TOKEN=<agent bot access token>
```

## Networking

- **Chatwoot → BFF** (webhook / bot `outgoing_url`): `host.docker.internal:<bff-port>`.
- **BFF → Chatwoot** (Application API): `host.docker.internal:3000` if the BFF is in
  Docker, else `localhost:3000`. Align the `webhook_url`/`outgoing_url` above with
  where the BFF actually listens (`/webhooks/chatwoot`, per the BFF build rules).

## Sanity check (optional; full loop is AURAT-0005)

Post a test `incoming` message via the Application API, confirm it appears in the
`Aura (dev)` inbox; reply from the dashboard, confirm the webhook fires to the BFF.
Order messages by `id` — no cross-message ordering guarantee (`AURAI-0002` §2.4).

## Out of scope / notes

- Staging/prod each get their **own** `Channel::Api` inbox with independent secrets
  + webhook target (`AURAD-0005`).
- Chatter provisioning (real agents) = **O6**; not needed to unblock `AURAT-0004`.
- This prepares the desk only; wiring the BFF against it is `AURAT-0004`
  (contact/conversation mapping) → `AURAT-0005` (messaging + webhook).

## Actual dev run — 2026-07-11 (faster prebuilt path, use this)

The source build (dev compose) is slow/heavy and hit a build-order snag; the
**prebuilt image** is far faster (pull only) and was used instead. What is
actually running on this machine (arm64):

- **Images:** `chatwoot/chatwoot:v4.15.1` (arm64 native) + `pgvector/pgvector:pg16`
  + `redis:alpine`. No source build.
- **Override compose:** `chatwoot-manor/docker-compose.aura-cw.yml` (compose
  project `aura-cw-dev`). postgres/redis are **internal-only** (host 5432/6379 were
  taken); **rails is on host `3001`** (host 3000 was taken by another dev server);
  empty postgres password → `POSTGRES_HOST_AUTH_METHOD=trust`; `RAILS_ENV=production`;
  `POSTGRES_HOST=postgres` + `REDIS_URL=redis://redis:6379` override the `.env`.
- **Provisioning:** `chatwoot-manor/chatwoot-provision.rb` (idempotent). Gotcha:
  Chatwoot's User password policy needs an uppercase **and** a special char (a
  plain hex string is rejected).
- **Creds captured (gitignored):** `aura-bff-manor/project/manor/master/aura-bff/.env.chatwoot.dev`.
  Chatwoot base URL here is **`:3001`**, not `:3000`.
- **Validated end-to-end:** `GET /api/v1/accounts/1/conversations` with the
  service-user token → **200**; inbox identifier resolves → **200**.

Management:

```bash
CF=chatwoot-manor/docker-compose.aura-cw.yml
docker compose -f "$CF" ps             # status
docker compose -f "$CF" up -d          # start (restart: unless-stopped survives reboots)
docker compose -f "$CF" down           # stop (keeps volumes/data; add -v to wipe)
docker compose -f "$CF" logs -f rails  # tail rails
```

Dashboard: `http://localhost:3001` (`ENABLE_ACCOUNT_SIGNUP=true`). The service User
`bff@aura.local` is an admin of account 1 but its password is random — create a
human login (self-signup joins a *new* account; to answer on the Aura inbox add a
user to **account 1** via console) to act as a chatter.
