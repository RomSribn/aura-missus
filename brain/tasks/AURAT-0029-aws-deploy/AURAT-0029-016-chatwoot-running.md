# AURAT-0029-016 — Chatwoot is running, and three things bit on the way

Date: 2026-08-19
Status: `https://chat.aura-app.cc` serving over TLS, schema created, mail working.

## What is up

| | |
|---|---|
| rails + sidekiq | `chatwoot/chatwoot:v4.15.1`, Puma on :3000, sidekiq processing jobs |
| Public | `https://chat.aura-app.cc`, Let's Encrypt, valid to 17 Nov |
| Database | its own `chatwoot`, **92 tables, all owned by the `chatwoot` role** |
| Isolation | `chatwoot` → `aura_bff` still **denied**, and the reverse — re-checked after the schema load |
| Attachments | Cloudflare R2, EU jurisdiction, `s3_compatible` |
| Redis | shared instance, db 0 |
| Mail | Resend, domain verified, **a real message was delivered** |

Deployed by Coolify from `deploy/coolify/chatwoot.compose.yml` in this
repository — one compose, in git, no copy pasted into a panel to drift.

## 1 · The schema needs three superuser extensions, and I had provided one

`db:chatwoot_prepare` died on schema load:

```
PG::InsufficientPrivilege: permission denied to create extension
"pg_stat_statements" — Must be superuser to create this extension
```

`db/schema.rb` enables **five**: `pg_stat_statements`, `pg_trgm`, `pgcrypto`,
`plpgsql`, `vector`. Three of them require a superuser, and the `chatwoot` role
deliberately is not one — that is the whole point of `014`. I had pre-created
only `vector`, having checked what Chatwoot needed for its *vector columns*
rather than reading the extension list.

Fixed by creating all five as `postgres`. Rails issues
`CREATE EXTENSION IF NOT EXISTS`, so its own statements became no-ops. Now a
documented prerequisite at the top of the compose file, because a rebuilt
database would hit it again.

**The diagnosis was harder than the fix, and that is the transferable part.**
Coolify removes a failed deployment's containers *and its network*, so by the
time the failure was visible the logs were gone with them. The error had to be
reproduced by running the migration step in an isolated container against
Coolify's own generated compose. Worth knowing before the next failure: read
**Deployment Logs in the panel immediately**, or watch the container while it
runs.

## 2 · Coolify seeds one `${...}` per line

Counting the environment variables Coolify created from the compose gave
**11 where the file has 12**. The missing one was `CW_REDIS_HOST`, and the line
explains it:

```yaml
REDIS_URL: redis://:${CW_REDIS_PASSWORD}@${CW_REDIS_HOST}:6379/0
```

Two substitutions on one line; the second is dropped. The URL would have been
assembled with an **empty host** and Redis would simply never have connected —
after a deploy that reported success.

Now a single `CW_REDIS_URL` carrying the whole string, which is also what the
BFF already does. Caught by counting rows in Coolify's database before the
first deploy rather than by debugging a silent failure after it.

## 3 · Provisioning by account *name* would have split the installation

`provision-prod.rb` inherited `Account.find_by(name: 'Aura') || create!` from
the dev script. The owner's account is named **`Silvermind`** — so the script
would have created a *second* account and put the `Channel::Api` inbox where
nobody works.

There was never a requirement that the account be called `Aura`: the BFF
addresses Chatwoot by **`CHATWOOT_ACCOUNT_ID`**, a number. The name is for the
humans running the desk. The script now takes the first existing account (or an
explicit `AURA_ACCOUNT_ID`) and prints which one it chose.

## Mail: configured rather than deferred

`AURAS-0003` recorded "no SMTP, and the consequence is that nobody can reset a
password". With real colleagues about to be onboarded that stops being an
acceptable note: without mail Chatwoot cannot invite an agent, cannot reset a
password, and cannot tell an operator that a conversation is waiting — and all
three fail **silently**.

**Resend**, free tier (3,000/month, 100/day, one domain), region **Ireland
(eu-west-1)** — EU, consistent with the server and both buckets. DKIM, SPF and
the MX for bounce handling verified; Resend configured the records in Cloudflare
itself, since it holds the zone.

The API key is scoped to **sending only** and to **`aura-app.cc` alone** rather
than "all domains" — the same reasoning as the per-bucket R2 tokens and the
per-database Postgres roles: it lives in Chatwoot's environment, and a
permission that widens by itself as new domains are added is not a permission
anyone chose.

Proven by sending an actual message through `ActionMailer` and getting
`ОТПРАВЛЕНО`, not by reading the settings back.

## Next

- `provision-prod.rb`: the production `Channel::Api` inbox, service User and
  Agent Bot, with the webhook pointed at the BFF over the Docker network. Its
  output is the five `CHATWOOT_*` the BFF still lacks.
- Firebase Admin credentials — the owner's, and the last thing missing before
  the BFF can boot at all.
