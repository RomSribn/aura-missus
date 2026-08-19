# AURAS-0004 — Production: Hetzner + Coolify, and how to operate it

Date: 2026-08-19
Status: **running.** This is the document to follow; `AURAS-0003` (AWS) is on
hold and describes infrastructure that was never applied.
Feeds: `AURAT-0029`. Sources: `AURAD-0005` (one VM, EU, docker compose),
`AURAD-0004` (stack), `AURAS-0001` (dev Chatwoot), `AURAS-0002` (Play).

Everything below exists and has been exercised. Where something is asserted but
not observed, it says so.

---

## What is running, and what it costs

| | |
|---|---|
| Host | Hetzner **CX33** — 4 vCPU, 8 GB, 80 GB, **Helsinki** (EU) |
| OS | Ubuntu 24.04 LTS, 4 GB swap, unattended security upgrades, fail2ban |
| Panel | Coolify 4.3.9 at `https://coolify.aura-app.cc` |
| Proxy | Traefik (Coolify's), Let's Encrypt |
| **Cost** | **$12.81/month** |

Same specification in Hetzner's **Ashburn** location priced at **$88.92**. The
seven-fold difference is the location, not the hardware — and choosing Helsinki
also keeps `AURAD-0005`'s EU requirement intact, so no amendment was needed.

### Services

| Resource | What | Address |
|---|---|---|
| `aura-bff` | NestJS, Dockerfile build pack | `https://bff.aura-app.cc` |
| `aura-chatwoot` | rails + sidekiq, Docker Compose build pack | `https://chat.aura-app.cc` |
| `aura-postgres` | `pgvector/pgvector:pg16` | internal only |
| `aura-redis` | `redis:7.2` | internal only |

Both applications deploy from **`RomSribn/aura-bff`** — the BFF from the root
`Dockerfile`, Chatwoot from `deploy/coolify/chatwoot.compose.yml`. One
repository, one production configuration, no copy pasted into a panel to drift.

### Exposed surface

Ports **22, 80, 443** only, at Hetzner's cloud firewall — not `ufw`, because
Docker writes its own iptables rules and bypasses it. Postgres and Redis publish
no host port at all, and 8000/6001/6002 were closed once the panel moved behind
TLS.

---

## Data layout, and the one line that makes it real

**One Postgres server, two databases, two roles.** `AURAD-0004` wants Chatwoot
on its own database; 8 GB does not want two servers. This is the middle ground,
and it is not cosmetic: `aura_bff` holds the append-only money ledger, and
Chatwoot is a large third-party Rails app with a much bigger attack surface.

```sql
REVOKE CONNECT ON DATABASE aura_bff FROM PUBLIC;
```

**In PostgreSQL, `PUBLIC` holds `CONNECT` on every database by default.** Two
roles without this line are decorative. Verified in both directions, by
attempting the connections rather than reading the grants:

```
chatwoot → aura_bff : FATAL: permission denied ... does not have CONNECT privilege
aura     → chatwoot : same
```

### Extensions must be created by the superuser, before first boot

Chatwoot's `db/schema.rb` enables five, three of which need superuser. Its
migrations die on schema load without them. Run against the `chatwoot` database
as `postgres`:

```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS vector;
```

and `btree_gist` against `aura_bff` (the `interval_occupancy` migration needs
it). Rails issues `CREATE EXTENSION IF NOT EXISTS`, so pre-creating makes its
own statements no-ops.

The image is pinned to **`pgvector/pgvector:pg16`** — Coolify's picker offers
PGVector 17 and 18 but no 16, and the image field was edited before first start.
16 because Chatwoot pins it upstream and every BFF test and manor verification
ran against it. A Postgres major version cannot be changed afterwards.

### Redis

One instance. **Chatwoot on db 0, BFF on db 1.** No ACL — the contents are
queues and cache. The residual risk is named rather than hidden: a `FLUSHALL`
from Chatwoot's side would wipe the BFF's BullMQ queues.

```
maxmemory 512mb
maxmemory-policy noeviction
```

**`noeviction`, not Coolify's placeholder `allkeys-lru`.** Under pressure LRU
silently discards keys; if one is a BullMQ job, a message is never delivered and
nothing appears in any log. `noeviction` fails the write loudly instead. With no
`maxmemory` at all, Redis grows until the OOM killer picks a victim — here that
would be Postgres.

---

## Backups

Coolify's scheduled backup, **both databases**, `0 3 * * *` UTC, to **Cloudflare
R2** (`aura-backups`, EU jurisdiction). Local retention 3 copies / 7 days / 5 GB;
S3 retention 14 copies / 30 days, size unlimited.

The retention split is deliberate. Locally the size cap is a **fuse**: 80 GB is
shared with both databases, Docker and logs, and filling it takes Postgres down.
In S3 it is left unlimited because "first limit reached wins", and a size cap is
the only one whose trigger point is unpredictable — as the database grows it
would silently cut history short of the 30 days, discovered exactly when someone
reaches for a week-old backup.

### The restore drill

**Run it. A backup nobody has restored is a belief.** `AURAT-0027` made
`ledger_entries` append-only at the database; that guarantee is worth nothing
behind an unexercised restore.

```bash
PG=<postgres container>
docker exec $PG psql -U postgres -c "CREATE DATABASE restore_drill OWNER <role>;"
docker cp /data/coolify/backups/databases/<...>/pg-dump-aura_bff-<ts>.dmp $PG:/tmp/d.dmp
docker exec $PG pg_restore -U postgres -d restore_drill --no-owner --no-privileges /tmp/d.dmp
```

Then check, in the **scratch** database:

- `balanceMinor` equals `SUM(ledger_entries.amountMinor)` on every wallet;
- the `ledger_entries` append-only trigger exists **and fires** — attempt an
  `UPDATE` and require it to be refused; present-but-not-firing is what a count
  cannot see;
- the `sessions` gist exclusion constraint survived;
- `_prisma_migrations` came back, so the restore can be deployed onto.

Drop the scratch database afterwards.

**Done once (2026-08-19) on near-empty databases** — `pg_restore` exit 0, and
`btree_gist` present in the restored copy, so the dump carries real state. Both
objects confirmed in the R2 bucket, byte sizes matching. **Repeat now that
Chatwoot has ~92 tables and the BFF its migrations** — the assertions above are
what make it meaningful, and they need data to be meaningful about.

Attachments are **not** in these dumps: they live in `aura-chatwoot`, its own
bucket and its own durability story.

---

## Deploys

Push to the deployed branch → GitHub webhook → Coolify rebuilds → the entrypoint
runs `prisma migrate deploy` → the app starts. `migrate deploy` applies only
pending migrations, never generates or resets, takes an advisory lock, and is a
no-op when there is nothing to apply. On failure the container never starts and
the previous version keeps serving.

Three things to know:

- **The deployed branch is `feature/AURAT-0029-aws-deploy`.** After the merge,
  point Coolify at `develop` or it keeps deploying the feature branch.
- **One push redeploys BOTH services.** The Chatwoot application is git-backed
  too — same repository, same branch, `docker_compose_location =
  /deploy/coolify/chatwoot.compose.yml`. Coolify re-reads that file on every
  push, so a commit touching only the BFF still recreates the Chatwoot
  containers. Convenient (editing the compose in the repo *is* deploying it)
  and easy to forget: there is no such thing here as a push that touches only
  one service.
- **There is no gate.** A push with a bad migration reaches production.
- **Rolling updates**: the new container starts while the old one serves. An
  additive migration survives that window; a destructive one does not. Use
  expand/contract when the first destructive migration appears.

### Three traps this platform sets

**Coolify injects the environment into the image build.** `NODE_ENV=production`
reached `npm ci` in the build stage, npm skipped devDependencies, and the build
died on `sh: nest: not found`. Fixed in the Dockerfile with `npm ci
--include=dev` — in the repository, so the image builds identically anywhere,
rather than in a panel checkbox.

**Build-time variables are baked into image metadata.** Coolify marks every
variable build-time by default; Docker warns
`SecretsUsedInArgOrEnv`, and `docker history` would show the Firebase key and
Chatwoot token in clear text. The build needs none of them — **all
runtime-only**.

**Coolify escapes the backslash when it writes the generated `.env`.** A PEM
private key stored correctly in its database as `\n` arrives in the container
as `\\n`. A single unescape then leaves a stray backslash at the end of every
PEM line and the key stops parsing — 1760 characters where the stored value has
1732, one extra per line. This cost an evening, because of how it fails: the
Firebase app is built **lazily**, so `cert()` throws on the first request rather
than at boot, a bare `catch` in the auth guard rendered it as `Invalid or
expired token`, and the service answered 401 to **every** user while `/health`
stayed green and the panel showed it healthy. The app just said "couldn't load
advisors".

Fixed at the boundary, not in each consumer: `pemPrivateKey()` in
`env.schema.ts` collapses escaped newlines however many times the platform
escaped them and **proves the key parses**, so a bad key now fails the boot
instead of every request. Two consequences worth keeping: never "fix" such a
value by hand in the panel — Coolify re-escapes it on the next regeneration, so
the normaliser is the only durable fix; and after changing anything about a key,
check the *container's* value, not the panel's, since they differ by design.

Related and separate: **a panel cannot express "absent"**. An unset variable is
stored as an empty string, and `validateEnv` now drops empty values before
parsing, because Zod's `.optional()` means "may be undefined" and `''` is a
present value that fails `.min(1)`.

---

## Chatwoot specifics

- Account **`Aura`** (id 1). The BFF addresses Chatwoot by
  **`CHATWOOT_ACCOUNT_ID`**, a number — the name is for the humans at the desk,
  and `provision-prod.rb` now takes the existing account rather than looking one
  up by name (which would have created a second one).
- Its **own** `Channel::Api` inbox (`AURAD-0005`: one per environment), service
  User and Agent Bot, provisioned by `deploy/chatwoot/provision-prod.rb`. The
  webhook points at **`https://bff.aura-app.cc/webhooks/chatwoot`** — the
  public hostname, deliberately, and it is **proven**: a real delivery returned
  `204` with the signature verified.

  It started as `http://bff:3000/webhooks/chatwoot` and never worked, because
  **Coolify gives a Dockerfile application no stable network name**. Its only
  alias is the container name with the deploy id appended
  (`mtnsnawmogikfwm0uvl1g1yc-223125307803`), which changes on every deploy, and
  `--network-alias` is not among the custom docker run options Coolify accepts
  (`convertDockerRunToCompose` allows `--cap-add`, `--sysctl`, `--hostname`,
  `--dns` and a handful more — not that one). A compose-based application can
  claim an alias, which is how the BFF reaches Chatwoot; the reverse direction
  has no such lever.

  So the webhook takes the public hostname and hairpins back through Traefik.
  Nothing is newly exposed — the BFF already serves that host — and the
  endpoint verifies `X-Chatwoot-Signature` before trusting a byte: an unsigned
  POST gets `401`.

- **`SAFE_FETCH_ALLOW_PRIVATE_NETWORK` is no longer needed.** Chatwoot ≥4.15
  routes every outgoing webhook through SafeFetch/ssrf_filter, which refuses
  private addresses — which is why the flag went in while the webhook used a
  Docker-network address. With a public webhook URL that reason is simply gone,
  so `AURAS-0001`'s rule ("never outside dev") applies again unweakened and the
  flag is removed from the compose. Turning Chatwoot's SSRF protection back on
  is the point; it is not a cleanup.
- **Attachments go to R2** (`s3_compatible`, `STORAGE_ENDPOINT` with the `.eu`
  segment EU-jurisdiction buckets require). A container filesystem is not
  storage: it is lost on every redeploy.
- **Mail via Resend** — free tier, EU region, domain verified, an actual message
  delivered. Without it Chatwoot cannot invite an agent, reset a password, or
  tell an operator a conversation is waiting, and all three fail silently.
  Adding a colleague: **Settings → Agents → Add Agent**, role **Agent** — not
  Administrator, since administrators can configure webhooks and the SSRF guard
  is relaxed here.

---

## Google Play billing

`BILLING_ENABLED=true`, package `cc.silvermind.aura`, service account
**`play-billing-api@aura-2781b`** — the **same GCP project as Firebase but a
different service account**. The Firebase one verifies ID tokens; this one
verifies purchases. Confusing them costs an hour.

### Verify the credential before turning the flag on

A valid key without app access authenticates fine and then 401s on every
purchase — the buyer is charged and the wallet is not credited. Probe with an
invalid token:

| Status | Meaning |
|---|---|
| **400 / 404** | correct — Google accepted the request and rejected the token |
| 401 / 403 | no access to this app, or the grant has not propagated |
| failure before a status | the key itself is wrong |

Comparing against `POST /applications/<pkg>/edits` separates the causes: 200
there with 401 on purchases means specifically the **financial** permission.
Propagation took ~12 minutes; Google documents up to 24 hours.

Setup, as it works now: the service account is created in **Google Cloud
Console** (Play Console's "Setup → API access" page no longer exists) and
granted access in **Play Console → Users and permissions → Invite new users**,
with app-level *View financial data* and *Manage orders and subscriptions*.
Account-level permissions are not needed. Note that a service account can exist
with **`No keys`** — creating the account and creating its key are separate
steps, and the key is shown once.

---

## Secrets

No secret is in git. They live in Coolify's own encrypted store, entered by
hand. **Two must be backed up outside the server**, because losing them is not
recoverable by redeploying:

- **`/data/coolify/source/.env`** — the key Coolify encrypts every application
  variable with. A rebuilt server cannot decrypt its own secrets without it.
- **Chatwoot's `SECRET_KEY_BASE`** — changing it invalidates every session and
  makes anything encrypted under the old value unreadable.

Private keys (Firebase, Play) go in as **one line with escaped `\n`, in
quotes**. A multi-line value cannot be carried in an environment variable at
all; the services unescape them.

---

## When it breaks

| Symptom | First thing to check |
|---|---|
| Deployment failed and the logs are gone | Coolify removes a failed deployment's containers **and its network**. Read Deployment Logs in the panel immediately, or reproduce the step in an isolated container against the generated compose in `/data/coolify/applications/<uuid>/` |
| BFF exits listing variable names | Config validation. A variable is missing or empty in the panel |
| BFF exits naming a private key | The key does not parse. Read it **inside the container**, not in the panel — see the escaping trap above |
| Every authenticated route 401s, `/health` green, app shows "couldn't load advisors" | Firebase credential, not the token. The guard logs the reason: `app/invalid-credential` is ours to fix, `auth/*` is the caller's. Response body length also tells them apart — 74 bytes is a missing header, 78 a rejected token |
| `EAI_AGAIN chatwoot-rails` in BFF logs | The alias is gone. Coolify's only automatic alias is the bare service name `rails`; `chatwoot-rails` is claimed explicitly in the compose |
| `sh: nest: not found` | A build-time `NODE_ENV=production`; see the Dockerfile note above |
| Agent reply marked "Failed to send", but the app received it anyway | The reconciliation poll covered for a broken webhook — exactly what it is for. Check the inbox `webhook_url` and the Agent Bot `outgoing_url`; both must be the public URL |
| `Could not resolve hostname 'bff'` on a message | The webhook is pointed at a Docker-network name. Coolify cannot give this application one — use `https://bff.aura-app.cc/webhooks/chatwoot` |
| App gets 429s under light load | `trustProxy` regression — every device sharing one rate-limit budget |
| Wallet routes answer 404 | `BILLING_ENABLED` is false. 401 is the healthy answer |
| Purchase charged but not credited | Play financial permission — probe as above |
| Disk filling | `df -h`; Docker log rotation is capped at 3×10 MB in `/etc/docker/daemon.json` |
| Shell on the host | `ssh root@<ip>` — key-only, passwords disabled |

---

## Not yet proven

- **The chat loop has never run end to end**: app → BFF → Chatwoot → chatter's
  reply → app. With it goes the first real exercise of the inbox webhook. Until
  2026-08-20 it could not have: `CHATWOOT_BASE_URL` named a host that did not
  resolve, so every BFF→Chatwoot call failed. The name now resolves and answers
  200 from inside the BFF, which makes the loop *possible* — not proven.
- **No real purchase has been verified.** `TECH-DEBT #17` is only partly paid —
  the verifier has spoken to Google and been correctly refused, but no genuine
  token has been redeemed. On the first one, check that
  `obfuscatedExternalAccountId` comes back: the "user A cannot redeem user B's
  token" guarantee rests on that field arriving.
- **Play Console reports an issue with the payments profile**, which blocks real
  purchases independently of everything here.
- **The restore drill needs repeating** against populated databases.
