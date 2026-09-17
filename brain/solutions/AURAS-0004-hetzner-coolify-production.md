# AURAS-0004 — Production: Hetzner + Coolify, and how to operate it

Date: 2026-08-19 · updated 2026-09-16
Status: **running — two environments on one host: `production` (created
2026-09-14 … 16, no real users yet) and `development` (test data).** This is the
document to follow; `AURAS-0003` (AWS) is on hold and describes infrastructure
that was never applied.

> **History in two lines.** On 2026-09-14 the host's only environment turned out
> to hold test data, so it was renamed `production` → `development` and its BFF
> moved to `bff-dev.aura-app.cc` (`AURAD-0015`). Production was then created from
> scratch next to it, and Chatwoot moved to production, serving both environments
> through one account each (`AURAD-0016`). *Environments* below has the mechanics.
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
| Panel | Coolify **4.3.19** (as of 2026-09-14) at `https://coolify.aura-app.cc` |
| Proxy | Traefik (Coolify's), Let's Encrypt |
| **Cost** | **$12.81/month** |

Same specification in Hetzner's **Ashburn** location priced at **$88.92**. The
seven-fold difference is the location, not the hardware — and choosing Helsinki
also keeps `AURAD-0005`'s EU requirement intact, so no amendment was needed.

### Services

Coolify project **`aura`**, two environments:

| Environment | Resource | What | Address |
|---|---|---|---|
| `production` | `aura-bff` | NestJS, Dockerfile build pack, branch `main` | `https://bff.aura-app.cc` |
| `production` | `aura-chatwoot` | rails + sidekiq, Docker Compose build pack, branch `main` — **serves both environments** (`AURAD-0016`) | `https://chat.aura-app.cc` |
| `production` | `aura-postgres` | `pgvector/pgvector:pg16` — databases `aura_bff`, `chatwoot` | internal only |
| `production` | `aura-redis` | `redis:7.2`, 256 MB — the BFF | internal only |
| `production` | `aura-chatwoot-redis` | `redis:7.2`, 256 MB — Chatwoot | internal only |
| `development` | `aura-bff` | NestJS, Dockerfile build pack, branch `develop` | `https://bff-dev.aura-app.cc` |
| `development` | `aura-postgres` | `pgvector/pgvector:pg16` — database `aura_bff` | internal only |
| `development` | `aura-redis` | `redis:7.2`, 512 MB — the BFF on db 1 | internal only |

These are the Coolify resources, and they are **not** everything answering on
`aura-app.cc`: the legal pages live on Netlify, off this host entirely — see
*The legal pages are not on this host* below.

Every application deploys from **`RomSribn/aura-bff`** — the BFF from the root
`Dockerfile`, Chatwoot from `deploy/coolify/chatwoot.compose.yml`. One
repository, no copy pasted into a panel to drift.

Measured at idle on 2026-09-08 (`AURAI-0004`), before production existed: 2.5 of 7.6 GiB used, disk 17 of
75 G, load 0.06. Chatwoot is the heavy half (rails + sidekiq ≈ 961 MB); BFF,
Postgres and Redis together ≈ 188 MB; the panel itself ≈ 376 MB. A floor, not a
working load — measure again once real traffic arrives.

### Exposed surface

Ports **22, 80, 443** only, at Hetzner's cloud firewall — not `ufw`, because
Docker writes its own iptables rules and bypasses it. Postgres and Redis publish
no host port at all, and 8000/6001/6002 were closed once the panel moved behind
TLS.

---

## Data layout, and the one line that makes it real

**One Postgres server per environment; inside production, two databases and two
roles.** `AURAD-0004` wants Chatwoot on its own database; 8 GB does not want a
third server. Production's `aura-postgres` holds `aura_bff` (role `aura`) and
`chatwoot` (role `chatwoot`); development's holds only its own `aura_bff` (role
`aura`, a different password). The split inside production is not cosmetic:
`aura_bff` holds the append-only money ledger, and Chatwoot is a large
third-party Rails app with a much bigger attack surface.

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

Test isolation **over the Docker network** (from another container), never from
inside the Postgres container: the official image trusts loopback
(`host all all 127.0.0.1/32 trust`), so any password "works" there. Production
was checked this way on 2026-09-14 and 16: `aura` and `chatwoot` each reach only
their own database, and development's `aura` password is refused.

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

**One instance per consumer in production** — `aura-redis` for the BFF,
`aura-chatwoot-redis` for Chatwoot, 256 MB each — so a `FLUSHALL` or a runaway
queue on one side cannot touch the other. Development keeps one `aura-redis`
(512 MB) with the BFF on db 1; db 0 held Chatwoot until 2026-09-16 and is empty.
No ACL — the contents are queues and cache. Every instance runs:

```
maxmemory <256mb|512mb>
maxmemory-policy noeviction
```

**`noeviction`, not Coolify's placeholder `allkeys-lru`.** Under pressure LRU
silently discards keys; if one is a BullMQ job, a message is never delivered and
nothing appears in any log. `noeviction` fails the write loudly instead. With no
`maxmemory` at all, Redis grows until the OOM killer picks a victim — here that
would be Postgres.

**What the queues keep is on disk too, so it has a term** (`AURAT-0074`). Every
instance snapshots `dump.rdb` into its docker volume (not into the R2 backup),
and a job's data can be personal. The BFF keeps a finished job's record a
**day** once completed and **7 days** once failed; an hourly `queue-retention`
job cleans every queue, because BullMQ's own `age` only acts when the next job
in the same queue finishes. Bound: the term plus an hour. Chatwoot's Sidekiq
keeps no completed jobs, but its **dead set** holds failed jobs with their
arguments for 180 days by default — trimmed to 7 days by a scheduled task, see
*Chatwoot specifics*.

---

## Backups

Coolify's scheduled backups to **Cloudflare R2** (`aura-backups`, EU
jurisdiction), one schedule per Postgres server:

| Server | Databases | When (UTC) | Retention |
|---|---|---|---|
| production `aura-postgres` | `aura_bff`, `chatwoot` | `30 3 * * *` | local 3 copies / 7 days / 5 GB; S3 14 copies / 30 days, size unlimited |
| development `aura-postgres` | `aura_bff` | `0 3 * * *` | **none set** — the panel stores zeros, i.e. unlimited |

Production's schedule was created 2026-09-16 and run once by hand: both dumps
`success`, uploaded to R2. Until that day this document gave development the
production retention values, but the panel had never held them; set them if its
local copies start to matter for disk.

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
bucket and its own durability story. That story has one sharp edge, learned
2026-09-16: **deleting a Chatwoot inbox deletes its conversations in the
background and purges their files from R2.** A dump taken an hour earlier
restored every row and none of the 35 files. Before deleting an inbox whose
attachments matter, copy the bucket objects first.

### A restore brings deleted accounts back

Since `AURAT-0042` a person can delete their account, and a dump taken before
that still holds their conversations, profile and push tokens. The retention
above is therefore also how long a deletion can be undone by a restore — 30
days in production, which the privacy policy names; development has no limit
set at all — and **the restore has to put it right**.

The record of what to repeat lives outside the database and outside the
container (`AURAT-0073`): every deletion writes one object to the **erasure
journal** bucket — `aura-erasure-journal` (development),
`aura-erasure-journal-prod` (production) — holding the account's `userId`,
when, and who asked. The `account erased` log line is not it: container logs
are gone on every deploy, and `account_erasures` is inside the dump. The
bucket's lifecycle rule removes entries after **45 days**, past the 30 days
backups are kept.

Production was checked on 2026-09-17, before the first release that needs it:
- the token reads, writes and deletes in `aura-erasure-journal-prod`;
- it gets `AccessDenied` on the development bucket, and the development token
  gets `AccessDenied` on this one;
- a new object carries `Expiration … rule-id="expire-45d"`.

The rule was missing at first: a new bucket has none. **The header on a fresh
object is the proof, because an object-scoped token cannot read the lifecycle
configuration.** The four variables arrived flagged build-time and were set to
runtime-only before any deploy.

1. **Before** restoring, if the current database can still be read, write down
   the `userId` of every `account_erasures` row with `"completedAt" IS NULL`,
   however recent. An erasure is completed only once its journal entry is
   written, so an incomplete one may be missing from the journal (R2 down), and
   the youngest are the likeliest. An extra id costs nothing: `--user` answers
   `was already erased`, or `no account with id …` for an account the dump
   does not hold.
2. Restore the dump.
3. **Before letting traffic onto it**, inside the BFF container:

   ```bash
   node dist/account-erasure.js --journal
   node dist/account-erasure.js --user <userId>   # each id from step 1, if any
   ```

   `--journal` erases again every account the journal names that the dump
   brought back, and queues the Firebase identity, the desk contact and the
   photograph again — each of those treats "already gone" as done. It prints a
   line per account (`erased`, `was already erased`, `not in this database`,
   `refused: …`, `failed: …`) and a summary. A refusal — a paid session live in
   the restored data — does not stop the run; it exits 1, and running it again
   later skips what is done.

---

## Deploys

Push to the deployed branch → GitHub webhook → Coolify rebuilds → the entrypoint
runs `prisma migrate deploy` → the app starts. `migrate deploy` applies only
pending migrations, never generates or resets, takes an advisory lock, and is a
no-op when there is nothing to apply. On failure the container never starts and
the previous version keeps serving.

Three things to know:

- **The branch decides the environment**, always the branch's latest commit
  (`git_commit_sha = HEAD`), auto-deploy on:
  - `develop` → development's `aura-bff`. `wts-finish` into `develop` deploys
    there and nowhere else.
  - `main` → production's `aura-bff` **and** `aura-chatwoot`. A release is a
    merge `develop` → `main`, approved by the owner each time. `main` was created
    2026-09-14 at `daf42bd` and fast-forwarded to `1fa9fbe` for production's
    first deploy.
- **A push to `main` redeploys BOTH production services.** Chatwoot is
  git-backed too (`docker_compose_location = /deploy/coolify/chatwoot.compose.yml`)
  and Coolify re-reads that file on every push, so a release touching only the
  BFF still recreates the Chatwoot containers — about a minute of chat downtime.
  Editing the compose in the repo *is* deploying it. Until 2026-09-14 Chatwoot
  tracked `develop`, so every feature merge restarted the chat; it no longer does.
- **There is no gate.** A push with a bad migration reaches whatever environment tracks that branch.
- **Rolling updates do not wait for the new container to be healthy.** There
  is no healthcheck, so Coolify removes the old container under a second after
  the new one *starts*, not after it answers (`AURAT-0073-013`).
  - **A new container that dies at boot leaves the environment with no BFF.**
    The env schema refuses a missing required variable, so **add every new
    required variable before the release**. `development` went down exactly
    this way on 2026-09-16.
  - **Even a good release shows a gap.** On the 2026-09-17 release (`abe2039`)
    the BFF answered `502` for about 4 s while the migration ran and Nest
    booted.
  - An additive migration survives the overlap; a destructive one does not. Use
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

## Environments

In Coolify an **environment is a folder for resources, not a machine.** It does
not decide where a resource runs (each resource's server / destination does) and
isolates nothing: every container on this host shares the `coolify` Docker
network and resolves `aura-postgres`, `aura-redis` and `chatwoot-rails` by name.
A **Source** is the GitHub connection — one, shared by every application.

### Now (since 2026-09-16): two environments

| | `production` | `development` |
|---|---|---|
| BFF | `https://bff.aura-app.cc`, branch `main` | `https://bff-dev.aura-app.cc`, branch `develop` |
| App target | `prod` (`aab:prod` not created yet) | `staging` — `npm run aab:staging` / `apk:staging` |
| Chatwoot account | 1 «Aura»: inbox `Aura (prod)` (#2), bot #2, `bff-prod@aura.internal`; owner + chatters | 2 «Aura Dev»: inbox `Aura` (#3), bot #3, `bff-dev@aura.internal`; owner only |
| Postgres / Redis | own `aura-postgres`; `aura-redis`, `aura-chatwoot-redis` | own `aura-postgres`, `aura-redis` |
| Avatar bucket | `aura-user-media-prod` | `aura-user-media` |
| Erasure journal bucket (`AURAT-0073`) | `aura-erasure-journal-prod` | `aura-erasure-journal` |
| Data | seeded catalogue; no users yet | test data, restored 2026-09-16 (below) |

Isolation between them is Chatwoot's account boundary, checked with real
requests: development's token → account 1 `401`, production's → account 2 `401`.

A host that no application claims answers **`503 no available server`**, not
404 — Coolify's catch-all (`/data/coolify/proxy/dynamic/default_redirect_503.yaml`,
`PathPrefix(/)` at priority −1000). That is what `bff.aura-app.cc` returned between 2026-09-14 and production's first deploy.
Domain changes reach Traefik only on Redeploy; before dropping one, the BFF
request log's `host` field shows whether anything still arrives on it.

Moving the BFF's public host touches exactly four places: the Coolify domain,
the Cloudflare A record (DNS-only), the inbox `webhook_url` **and** the bot
`outgoing_url`, and the app's env target. Nothing at Google points at the BFF —
the refund Pub/Sub subscriber was never built.

### How production was created (2026-09-14 … 16)

`AURAD-0015` has the decision; this is what was done, in order.

1. **`main` fast-forwarded** to `develop`, so production did not start on code
   older than development.
2. **An empty environment `production`** — never *Clone Environment* (below).
3. **Its own Postgres.** Picker card *PGVector 17*, image edited to
   `pgvector/pgvector:pg16` **before first start** — the *PostgreSQL 16* card is
   `postgres:16-alpine`, whose musl collation would order text indexes
   differently from development's Debian image. Default user `postgres`; role
   `aura` and database `aura_bff` created by hand, `REVOKE CONNECT … FROM
   PUBLIC`, `btree_gist` as `postgres`.
4. **Its own Redis per consumer**, `maxmemory` + `noeviction`.
5. **`aura-user-media-prod`** and a token scoped to it alone.
6. **`aura-bff` from `main`.** Two defaults had to be undone: the build pack came
   up as **Railpack**, which would skip our `Dockerfile` and with it the
   migrations and the seed; and the domain as a generated `sslip.io` host.
   Variables pasted in the *Developer view* arrive marked build-time like any
   others — un-mark every one.
7. **Chatwoot moved to production** — the next sections.
8. **Backups** for production's Postgres (*Backups*).

Checked after the first deploy: all migrations and the seed applied, `/health`
`200`, unsigned webhook `401`, unauthenticated API `401`, `/docs` `404`, and the
container talks to its own Postgres and Redis only. The very first deploy failed
cloning the private repository without credentials (`could not read Username`);
the retry with unchanged settings passed.

`provision-prod.rb` finds inbox and bot **by name**, reuses the service User **by
email**, takes the **first** account unless told otherwise, and defaults the
webhook to the Docker-network address that never worked. Always pass
`AURA_ACCOUNT_ID`, `AURA_INBOX_NAME`, `AURA_WEBHOOK_URL` and
`AURA_SERVICE_USER_EMAIL`. An extra administrator service User does not disturb
presence: availability is set only over ActionCable and `auto_offline` defaults to
`true`, so an API-only user always reads `offline` — as long as nobody signs into
the dashboard as it.

### Do not use *Clone Environment*

Read against Coolify 4.3.19's source (`app/Livewire/Project/CloneMe.php`,
`clone_application` in `bootstrap/helpers/applications.php`), it makes a second
copy of this environment, not a new one:

- **variables are copied verbatim** — a cloned BFF gets this `DATABASE_URL` and
  `REDIS_URL`, runs `migrate deploy` and the seed against them at start, and its
  workers consume the same BullMQ queues; tokens, keys and `NODE_ENV` come along;
- **domains**: a compose application's are copied as they are
  (`chat.aura-app.cc`); a Dockerfile application keeps its FQDN unless readonly
  labels are on;
- a Chatwoot clone on the same host claims the same `chatwoot-rails` alias, and
  its sidekiq works the same database;
- same repository and branch, so a push can deploy the clones;
- databases keep their passwords and get **a copy of the backup schedule**;
- **"Clone volume data" stops the source databases and applications** for the
  copy, and carries their data across.

Clones are created `exited`, so nothing happens until the first deploy — the only
mercy. Three resources created by hand are less work than undoing this.

It happened anyway on 2026-09-14: a clone of `aura-chatwoot` appeared in
`production` with the same domains, alias, database and Redis. It stayed harmless
because its first deploy failed (the repository field had been changed to a
Chatwoot fork without our compose file) and auto-deploy was switched off before
the next push. Repointed at `aura-bff`, it was deployed on purpose as a second
replica of the same configuration, and the original was **stopped** — a handover
without downtime. That clone *is* production's `aura-chatwoot` now.

### Moving Chatwoot's data between servers (2026-09-16)

About two minutes of chat downtime; the order is what makes it safe.

1. Create role and database on the target, and the four extensions as `postgres`
   (`pg_stat_statements`, `pg_trgm`, `pgcrypto`, `vector`). An "empty" target is
   then one whose only `public` objects are the two `pg_stat_statements` views.
2. Check sidekiq has nothing queued, retried or dead — Redis is switched, not
   copied.
3. Stop `aura-chatwoot`; confirm zero connections to the source database.
4. `pg_dump -Fc`, then `pg_restore --no-owner --no-privileges` **as the
   `chatwoot` role** so it owns every table, with the dump's `EXTENSION` entries
   filtered out of the list. Compare exact row counts table by table, and the id
   sequences.
5. Change only `CW_POSTGRES_HOST`, `CW_POSTGRES_PASSWORD`, `CW_REDIS_URL`,
   `CW_REDIS_PASSWORD` — **never** `CW_SECRET_KEY_BASE` or the `CW_AR_*` keys,
   which would leave encrypted columns unreadable — and deploy.

### Moving conversations between Chatwoot accounts (2026-09-16)

Development's history lived in account 1; it was re-created in account 2 with its
original ids, so the BFF's stored references kept working.

- Ids of contacts, contact inboxes, conversations and messages are **global**
  sequences, so freed ids can be inserted again as they were.
- The BFF stores a conversation's **`display_id`**, numbered **per account** by
  trigger `conversations_before_insert_row_tr`, which always overwrites it from
  `conv_dpid_seq_<account_id>`. Insert under `SET LOCAL session_replication_role
  = replica` — which also switches foreign keys off, so check for orphans
  afterwards — then `setval('conv_dpid_seq_<account>', max(display_id))`.
- Rewrite `account_id` and `inbox_id`, clear assignees who are not members of the
  target account, and remap message senders whose user no longer exists.
- Attachment rows were left out: their files had already been purged.

Deleting a User with `destroy!` enqueues `Agents::DestroyJob`, which then fails
for ever with `undefined method 'notification_settings' for nil`. Confirm nothing
references the user and remove the job from `retry`.

---

## The legal pages are not on this host

`https://aura-app.cc/terms/` and `/privacy/` — plus the site root — are served by
**Netlify**, not by anything described above. This is the project's **fourth
platform** after Hetzner (the host), Cloudflare (the zone) and R2 (objects and
dumps), and until this entry it was written down nowhere.

Measured 2026-08-27/28, not inferred from a panel:

| | |
|---|---|
| `aura-app.cc` (apex) | `A → 75.2.60.5` (Netlify), **DNS-only** in Cloudflare |
| `www.aura-app.cc` | `CNAME → aura-app-landing.netlify.app` |
| Response | `server: Netlify`, no `Set-Cookie` |
| `/terms`, `/privacy` | `301` → the trailing-slash form; both `200` |
| `/faq/` | **`404`** — the page does not exist; the app's row was hidden instead (`AURAT-0040-004`) |
| `bff.` `chat.` `coolify.` | unchanged: `37.27.199.90`, DNS-only. Verified **after** the apex record appeared |

Nothing here touches the Coolify stack. The apex was empty before this — no A,
no CNAME, no MX, no TXT — so adding it broke nothing, and that was checked
rather than assumed.

### How it is operated, and why that is the real entry

- **Account: the owner's personal Netlify account.**
- **Deploy: drag-and-drop.** No git remote, no build, no webhook, no CI.
- **There is no source. Anywhere.** The pages exist only as the artifact that
  was dropped in.

Three consequences, and they are the reason this section exists:

1. **Nobody but the owner can publish a change**, including a correction that a
   Play review demands.
2. **There is no history.** Nothing can answer "what did the policy say last
   month" or even "did it change" — and a privacy policy is a document whose
   version and effective date are the point.
3. **Editing means rebuilding, not editing.** The deployed page is a
   self-contained bundle — a `__bundler` runtime, React and twelve WOFF2 fonts
   inlined as base64 in a single ~547 KB HTML file. Changing a sentence means
   going back to whatever produced it and dropping a new artifact.

And the policy **will** need changing: `AURAT-0040-007` found eleven places
where it disagrees with the code, one of which (it promises an account-deletion
screen that does not exist) is a Play listing blocker.

### The text is recoverable, so it is not actually lost

Worth knowing before anyone panics about (2): the **prose is in the HTML** as
ordinary escaped string literals. Only the fonts and React are inside the
compressed blobs. So the published text can always be pulled back:

```bash
curl -s https://aura-app.cc/privacy/ \
  | sed 's/[A-Za-z0-9+/=]\{200,\}//g' \
  | node -e 'let h="";process.stdin.on("data",d=>h+=d).on("end",()=>{
      h=h.replace(/\\u002F/gi,"/").replace(/\\n/g,"\n");
      h=h.replace(/<style[\s\S]*?<\/style>/gi," ").replace(/<[^>]+>/g," ");
      console.log(h.replace(/[ \t]+/g," "));})'
```

A copy taken 2026-08-27 — both pages, full text — is kept in
`AURAT-0040-009-published-text-recovered.md`, so there is at least one version
under version control to diff the next one against.

### Mail for the domain: Spacemail, DNS in Cloudflare (2026-09-17)

Until 2026-09-17 the domain had no mail at all, while the live pages print
`info@aura-app.cc` and `support@aura-app.cc`. Now:
- **Mailbox:** `support@aura-app.cc` at Spacemail (Spaceship). Aliases
  `privacy@` and `info@` can send as well as receive.
- **Spaceship is only the registrar.** The nameservers are Cloudflare's, so the
  records Spaceship shows under *Inactive records* were copied into Cloudflare
  by hand.
- **Never press *Change nameservers* there.** Every host above would move with
  them.
- **The Spaceship *Default record group*** (A `@` 75.2.60.5, CNAME `www`) is
  parking and was **not** copied: Cloudflare's root and `www` already point at
  Netlify.

| Type | Name | Value |
|---|---|---|
| MX | `@` | `mx1.spacemail.com`, `mx2.spacemail.com`, priority 0 |
| TXT | `@` | `v=spf1 include:spf.spacemail.com ~all` — the only SPF on the root |
| TXT | `spacemail._domainkey` | Spacemail's key, RSA 2048 (checked: decodes) |
| SRV | `_autodiscover._tcp` | `0 0 443 autoconfig.spacemail.com` |
| TXT | `_dmarc` | `v=DMARC1; p=none` |

Checked against `jasper.ns.cloudflare.com`. Resend's records on
`send.aura-app.cc` and `resend._domainkey` were left untouched: a subdomain does
not collide with the root.

**Port 25 does not work for a check.** It is closed outbound both from the host
(Hetzner) and from the manor's network. Delivery is proven by a message from an
outside address, and the `Authentication-Results` header of a reply shows SPF,
DKIM and DMARC.

**Inbound proven 2026-09-17.** Messages from Gmail to `support@`, `privacy@` and
`info@` all arrived. The mailbox address came at once; the just-created aliases
took several minutes, with no bounce. So an alias that seems silent right after
it is created is waiting, not broken. **Outbound from an alias**
(`Authentication-Results` of a reply) is not yet checked.

### If this is ever moved

Put the source in `RomSribn/aura-bff` and deploy it the way everything else
here is deployed, or keep Netlify but connect it to a repository. Either ends
all three consequences above. What must **not** happen is a second hand-managed
copy: `deploy/Caddyfile` and `deploy/terraform/` are already a directory that
describes a stand which does not run (`AURAS-0003`), and that trap does not need
a sequel.

## Chatwoot specifics

- **One installation, one account per environment** (`AURAD-0016`): account 1
  **`Aura`** for production, account 2 **`Aura Dev`** for development. The BFF
  addresses Chatwoot by **`CHATWOOT_ACCOUNT_ID`**, a number — the name is for the
  humans at the desk, who switch accounts from the name in the top left corner.
- Each account has its **own** `Channel::Api` inbox, service User and Agent Bot,
  provisioned by `deploy/chatwoot/provision-prod.rb` with explicit parameters
  (see *Environments*). Each webhook points at its environment's **public**
  hostname — `https://bff.aura-app.cc/webhooks/chatwoot` and
  `https://bff-dev.aura-app.cc/webhooks/chatwoot` — deliberately, and it is
  **proven**: real deliveries returned `204` with the signature verified on
  2026-08-20, on 2026-09-14 (an agent's reply stored 0.3 s after Chatwoot created
  it, i.e. by webhook rather than by the poll) and in `Aura Dev` on 2026-09-16 in
  both directions.

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
- **The Agent Bot is attached but its inbox link is INACTIVE — on purpose.**
  It was added for one thing: its `outgoing_url` retries (only on 429/500 —
  `Webhooks::Trigger::RETRYABLE_AGENT_BOT_STATUSES`), while the inbox webhook is
  fire-and-forget. The catch nobody priced in: attaching *any* agent bot marks
  the inbox bot-driven, and every conversation is then born **`pending`**
  (`Conversation#ensure_conversation_status`, carrying Chatwoot's own TODO
  calling it an assumption). `pending` conversations are absent from the default
  Open filter, and an incoming message does **not** open them — only a manual
  toggle does.

  So a bot attached purely for retries would have hidden real messages from the
  chatters. It never did, for an unlovely reason: the bot's webhook was failing
  — it signs with `agent_bot.secret`, not the channel secret, so the BFF
  answered 401 — and Chatwoot force-opens a conversation when its bot errors.
  The visible conversation list was a product of the breakage.

  The retry is redundant anyway: the reconciliation poll covers gaps and has
  already carried a complete webhook outage here. The link is therefore
  `inactive`; the bot record and its token stay, so re-enabling is one field.
  Turn it back on only when there is a **real** bot — something that answers or
  routes before a human — and make it hand off to `open` itself. `AURAD-0005`
  attached the bot; this narrows *how*, not whether.

  If it is ever re-enabled, the BFF also needs
  `CHATWOOT_WEBHOOK_SECRET_SECONDARY` set to the bot's secret — the verifier
  already accepts a second secret for exactly this.
- **Attachments go to R2** (`s3_compatible`, `STORAGE_ENDPOINT` with the `.eu`
  segment EU-jurisdiction buckets require). A container filesystem is not
  storage: it is lost on every redeploy.

  **`AWS_REQUEST_CHECKSUM_CALCULATION=when_required` is load-bearing. Without it
  not one attachment can be stored.** `aws-sdk-s3` 1.208 defaults
  `request_checksum_calculation` to `when_supported`, so it attaches its own
  CRC32 to every PutObject — while ActiveStorage independently sends
  `Content-MD5`. R2 accepts one checksum, not two, and rejects the request:
  `InvalidRequest: You can only specify one non-default checksum at a time.`

  Budget an hour if you meet this without knowing it, because **every signal
  lies**. At `info`, Rails logged `S3 Storage … Uploaded file to key: …` for the
  upload that just failed — ActiveStorage's instrumentation logs its event even
  when the block inside raised (at `warn` it logs nothing either way). The message row keeps an attachment pointing at an object
  that does not exist. Chatwoot answers `422` and the dashboard shows the file as
  **sent**, so the chatter believes it arrived. The only honest signal is the
  response body, and it is not in the logs: reproduce the POST with
  `api_access_token` and read it.

  Diagnose it by **outcome, not by log**: `ActiveStorage::Blob.service.exist?
  (blob.key)`. If blob rows exist and the objects do not, this is it.

  **CORS on the bucket is NOT the cause and is not needed.** This was an hour's
  wrong turn on 2026-08-20: the `direct_uploads` route is mounted and blob rows
  carry a checksum, which together look exactly like browser-direct upload. They
  are not. Chatwoot's dashboard posts the file as ordinary multipart to Rails —
  `POST …/messages` with `"attachments" => [ActionDispatch::Http::UploadedFile]`
  — and Rails uploads it server-side, where CORS never applies. The request log
  settled it that day; it is gone since Chatwoot logs at `warn` (below), so
  reproduce the POST instead — inference from the route table does not settle it.
- **Logs at `warn`, not `info`** (`AURAT-0074`). At `info` both containers
  write personal data on the ordinary path: rails logs the `Parameters:` of
  every request — the text of each message the BFF sends, contacts' phone
  numbers — and ActiveJob logs the arguments of every job. Chatwoot's parameter
  filter covers only passwords, tokens and keys. `LOG_LEVEL: warn` sits in the
  compose (`x-chatwoot` → `environment`), read by rails
  (`config/environments/production.rb`) and by sidekiq
  (`config/initializers/sidekiq.rb`) alike. It takes effect with a release to
  `main`, like any compose change.

  - **Fatal when wrong.** Anything but a Ruby Logger level name — `warning`, an
    empty string — raises `NameError` at boot, and rails **and** sidekiq
    restart-loop. That is why it is not a panel variable.
  - **Not everything goes.** A job that fails reaches Sidekiq's default error
    handler, which writes the whole job — arguments included, so possibly a
    phone number and message data — at **WARN**. The ordinary path is silent;
    a failure is not. The likeliest failure is `ActionCableBroadcastJob` finding
    no conversation after an account was deleted. Also still logged: SMTP errors
    (operators' addresses) and unhandled request exceptions (class, message,
    backtrace — no parameters). The Agent Bot's webhook job would log its whole
    payload on 429/5xx, which is one more reason its link stays `inactive`.
  - **Diagnosis without a request log.** The request lines (`Started`,
    `Parameters:`, `Completed 500`) are gone. Reproduce the call with
    `api_access_token` and read the response body; check outcomes in
    `rails console`. Do not raise the level to look: it is a commit and a
    release, and it brings the personal data back until reverted.

  **Dead jobs are kept a week, not 180 days.** After `:max_retries: 3` (minutes)
  a failed job moves to Sidekiq's dead set with its arguments, kept by default
  for 180 days / 10 000 jobs. There is no variable for that, and Sidekiq trims
  the set only when the next job dies — so a daily **Scheduled Task** in Coolify
  does it instead:

  Task `sidekiq-dead-set-7-days` (uuid `1dr8c4gpajt6v9bbruriw3pk`) on application
  `aura-chatwoot`, container `sidekiq`, frequency `30 3 * * *` (the instance runs
  on UTC), timeout 300 s, command:

  ```
  bundle exec rails runner 'Sidekiq::DeadSet.new.each { |job| job.delete if job.at < 7.days.ago }'
  ```

  Bound: 7 days plus a day. The cost: a dead job older than a week can no longer
  be retried from the Sidekiq UI.

  **Created 2026-09-16 and run once through Coolify's own job** — execution
  `success` in 7 s. The container field takes the **compose service name**:
  `ScheduledTaskJob` matches running containers by the prefix
  `<container>-<application uuid>`, i.e. `sidekiq-forqvdvibl9wjec2yk0mqkeo…`, and
  wraps the command in `sh -c '…'` with single quotes escaped, so the command
  above goes in as written. Before that, the same command ran by hand in the
  container (about 6 s for the Rails boot; the dead set was empty, so nothing
  was deleted). It was created with `php artisan tinker` in the `coolify`
  container, setting the same fields the API's create endpoint sets, because the
  instance has no API token; it shows under the application's *Scheduled Tasks*
  like any other. Its executions (status and output) are on the task's page, or
  `ScheduledTask::where('uuid', '1dr8c4gpajt6v9bbruriw3pk')->first()->executions`.

  **Deletion proven 2026-09-17.** The first scheduled run (03:30 UTC) succeeded.
  To see it actually delete, two fake entries went into the dead set:
  - `AuraProbe::DeadSetRetention`, 8 days old;
  - the same, stamped now.

  Then the command went through `ScheduledTaskJob` once more. Result: the old
  entry was gone, the fresh one stayed, and both probes were removed afterwards.
  **There is exactly one such task.** A duplicate made that morning without
  looking at the list was deleted. Check *Scheduled Tasks* before adding one.
- **Mail via Resend** — free tier, EU region, domain verified, an actual message
  delivered. Without it Chatwoot cannot invite an agent, reset a password, or
  tell an operator a conversation is waiting, and all three fail silently.
  Adding a colleague: **Settings → Agents → Add Agent**, role **Agent** — not
  Administrator, since administrators can configure webhooks. An agent must also
  be **added to the inbox explicitly**, or they cannot reply in it.
  **Then turn off the quoting emails for them.** Chatwoot gives every new
  account member `email_conversation_assignment` by default
  (`AccountUser#create_notification_setting`). That email, and the
  `…_creation` and `…_mention` ones, quote the latest messages, which makes
  Resend a recipient of message texts. On 2026-09-16 all three were switched off
  for every operator in both accounts (`AURAT-0042-115`). The
  `…_new_message` emails carry no text and may stay. The operator can re-enable
  them under Profile → Notifications, so tell them not to. The same day
  `captain_tasks` was disabled on both accounts: with no OpenAI key it does
  nothing, but a key added later would send texts to OpenAI.

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

### R2 tokens: one per bucket, verified

All buckets live in one Cloudflare account, each reached by its own
**Account** token scoped to that bucket alone. Verified 2026-09-14 by having
every in-use key list every bucket:

| Key held by | Can read |
|---|---|
| development BFF (`AVATAR_STORAGE_*`) | `aura-user-media` only |
| production BFF (`AVATAR_STORAGE_*`) | `aura-user-media-prod` only (checked 2026-09-14) |
| Chatwoot (`CW_STORAGE_*`) | `aura-chatwoot` only |
| Coolify backups (`r2-backups`) | `aura-backups` only |
| development BFF (`ERASURE_JOURNAL_*`) | `aura-erasure-journal` only (`AURAT-0073`, step A) |
| production BFF (`ERASURE_JOURNAL_*`) | `aura-erasure-journal-prod` only (`AURAT-0073`, step B) |

`aura-assets` (public, `assets.aura-app.cc`) has **no** standing write token:
the one-off `aura-assets-storage` was deleted that day, and no token scoped to
all buckets exists. Upload through the dashboard, or mint a token with a TTL for
the one operation. An R2 Access Key ID *is* the token's ID, so a key found in a
container matches the ID in its dashboard URL.

`aura-assets` and `aura-chatwoot` are shared by both environments. Backup
database lists are explicit — Coolify does not pick a new database up by itself.

Production's values were assembled on the host in `/root/aura-prod` (mode 0600)
while being pasted into Coolify, and deleted afterwards. What remains there are
two dumps taken before the 2026-09-16 moves — development's BFF and the old
Chatwoot database. Delete them once they stop being a safety net: they hold test
users' conversations.

---

## When it breaks

| Symptom | First thing to check |
|---|---|
| Deployment failed and the logs are gone | Coolify removes a failed deployment's containers **and its network**. Read Deployment Logs in the panel immediately, or reproduce the step in an isolated container against the generated compose in `/data/coolify/applications/<uuid>/` |
| BFF exits listing variable names | Config validation. A variable is missing or empty in the panel |
| BFF exits naming a private key | The key does not parse. Read it **inside the container**, not in the panel — see the escaping trap above |
| Every authenticated route 401s, `/health` green, app shows "couldn't load advisors" | Firebase credential, not the token. The guard logs the reason: `app/invalid-credential` is ours to fix, `auth/*` is the caller's. Response body length also tells them apart — 74 bytes is a missing header, 78 a rejected token |
| `EAI_AGAIN chatwoot-rails` in BFF logs | The alias is gone. Coolify's only automatic alias is the bare service name `rails`; `chatwoot-rails` is claimed explicitly in the compose |
| Attachment shows as sent in Chatwoot but the image is broken | The object is not in R2. Check `ActiveStorage::Blob.service.exist?(blob.key)`, **not** the log — at `info` Rails printed "Uploaded file to key" for uploads that raised, at `warn` it prints nothing. Almost always the double-checksum trap above |
| Chatwoot rails and sidekiq both restart-loop with `NameError` right after a compose change | `LOG_LEVEL` is not a Logger level name (`warning`, empty). Only `debug`/`info`/`warn`/`error`/`fatal` boot |
| Need to see what a Chatwoot request carried | There is no request log at `warn`. Reproduce the call with `api_access_token` and read the body; do not raise `LOG_LEVEL` to look |
| `422` on `POST …/messages` with an attachment | Read the response body, it carries the real reason. `You can only specify one non-default checksum at a time` = `AWS_REQUEST_CHECKSUM_CALCULATION` is missing |
| Tempted to configure CORS on the R2 bucket | Don't. Uploads are server-side multipart; CORS applies to nothing here |
| `sh: nest: not found` | A build-time `NODE_ENV=production`; see the Dockerfile note above |
| Agent reply marked "Failed to send", but the app received it anyway | The reconciliation poll covered for a broken webhook — exactly what it is for. Check the inbox `webhook_url` and the Agent Bot `outgoing_url`; both must be the public URL |
| `Could not resolve hostname 'bff'` on a message | The webhook is pointed at a Docker-network name. Coolify cannot give this application one — use the environment's public host: `https://bff.aura-app.cc/webhooks/chatwoot` or `https://bff-dev.aura-app.cc/webhooks/chatwoot` |
| Agent replies reach the app only after a delay, since the BFF's domain changed | The webhook still names the old host and the reconciliation poll is covering. Update the inbox `webhook_url` **and** the bot `outgoing_url` |
| `503 no available server` on one of our hostnames | No application claims that host, so Coolify's catch-all answers. Check the application's Domains in the panel, then Redeploy |
| Chatwoot deploy fails with `Docker Compose file not found at: /deploy/coolify/chatwoot.compose.yml` | The application's repository is no longer `RomSribn/aura-bff` — a Chatwoot fork has no such file. Repoint it and check `repository_project_id` matches the BFF's |
| Two containers answer `chatwoot-rails` or `chat.aura-app.cc` | A clone of `aura-chatwoot` is running. With identical settings it is a harmless replica; stop one, never the serving one before the other is up |
| A service token gets `401 You are not authorized to access this account` | Expected across environments: each service User belongs to one account only. Within its own environment, check `CHATWOOT_ACCOUNT_ID` |
| "Conversation was marked open by system due to an error with the agent bot" | The agent bot's webhook failed. It should not be running at all — check `AgentBotInbox.status` is `inactive` |
| Chatters see nothing under "Open" while users are writing | An agent bot is active on the inbox, so conversations are born `pending`. Deactivate the link, then open the stranded ones |
| App gets 429s under light load | `trustProxy` regression — every device sharing one rate-limit budget |
| Wallet routes answer 404 | `BILLING_ENABLED` is false. 401 is the healthy answer |
| Purchase charged but not credited | Play financial permission — probe as above |
| Disk filling | `df -h`; Docker log rotation is capped at 3×10 MB in `/etc/docker/daemon.json` |
| Shell on the host | `ssh root@<ip>` — key-only, passwords disabled |

---

## Not yet proven

- ~~The chat loop has never run end to end~~ — **proven 2026-08-20**: app → BFF
  → Chatwoot → chatter's reply → app, with the inbox webhook returning `204` on a
  verified signature. It took three fixes to get there, each disguised as
  something else, all recorded above: the Firebase key mangled by Coolify's
  escaping, a webhook aimed at a hostname Coolify cannot provide, and an agent
  bot attached for retries that was quietly hiding conversations.

  Two things this proved that were only assertions before. The **reconciliation
  poll earns its place**: it carried a complete webhook outage, delivering the
  chatter's reply to the phone while every webhook delivery was failing — and in
  doing so hid the outage, which is worth remembering when a symptom looks like
  "it works, mostly". And an agent's messages are **not** role-filtered anywhere;
  a role that looks like it is losing messages is losing *attachment-only*
  messages, which the BFF drops by design (`AURAF-0011`).
- **Attachments reach Chatwoot but stop there.** Storing them in R2 works as of
  2026-08-20, verified by downloading the object back byte-for-byte. The BFF
  carries none of it: `message-normalizer.ts` drops any message without text, and
  the word `attachment` appears once in the whole source — in the comment saying
  so. `AURAF-0011` / `AURAT-0031` / `AURAT-0032` cover it, blocked on how the app
  is to receive the bytes (Chatwoot's own attachment URL is **public and
  unauthenticated** — verified — so it must never be handed to a device).
- **Every purchase so far was a test order** — confirmed by the owner in Play
  Console → Order management, 2026-09-14. The ledger's 10 Play top-ups ($260,
  2026-08-20 … 09-01) passed the **real** verifier (under
  `NODE_ENV=production` the fake refuses), so the rail works against Google;
  the BFF stores no test flag, which is why the console had to answer this. No
  real-money purchase has happened yet.
- **No real purchase has been verified** (written 2026-08-19, before the
  top-ups above). `TECH-DEBT #17` is only partly paid —
  the verifier has spoken to Google and been correctly refused, but no genuine
  token has been redeemed. On the first one, check that
  `obfuscatedExternalAccountId` comes back: the "user A cannot redeem user B's
  token" guarantee rests on that field arriving.
- **Play Console reports an issue with the payments profile**, which blocks real
  purchases independently of everything here.
- **The restore drill needs repeating** against populated databases. The
  2026-09-16 moves restored real data (row counts per table and wallet balances
  against the ledger matched), but the append-only trigger was not made to fire.
- **Chatwoot logs at `warn`: a message from the app is the one check left**
  (`AURAT-0074`). Released to `main` 2026-09-17 (`abe2039`); already confirmed:
  - both containers booted with `LOG_LEVEL=warn`;
  - `rails runner 'Rails.logger.warn("probe-warn"); Rails.logger.info("probe-info")'`
    prints only `probe-warn`;
  - neither log has a `Started`, `Parameters:`, `with arguments` or `INFO` line,
    or anything shaped like a phone number, while the BFF polls the API.

  After the next message from the app, check that neither log gained
  `Parameters:` or `with arguments`. The dead-set Scheduled Task needs nothing
  more (*Chatwoot specifics*).
- **Production end to end.** Its BFF, Chatwoot account and webhook are checked
  piece by piece, but no build pointed at `bff.aura-app.cc` has yet sent a message
  and received a chatter's reply, and `aab:prod` does not exist.
