# AURAT-0029-014 — Postgres and Redis, with the money kept behind a wall

Date: 2026-08-19
Status: both running and verified.

## The decision that had to be made first

The brief proposed one shared Postgres and one shared Redis — sensible on 8 GB.
`AURAD-0004` says the opposite: Chatwoot runs its **own** Postgres, we do not
share one.

**Owner ratified the middle ground: one Postgres server, two databases, two
roles**, with neither role able to reach the other's database. Memory is shared;
access is not.

This matters more here than in a typical two-app deployment. `aura_bff` holds
the append-only ledger with real money in it (`AURAT-0027`), and Chatwoot is a
large third-party Rails application with a far bigger attack surface than the
BFF. Sharing an instance is a memory decision; sharing a *role* would have meant
a hole in Chatwoot reaches the ledger.

It had to be settled before the databases existed — retrofitting role separation
onto two live applications is a migration, not a setting.

## The line that does the actual work

```sql
REVOKE CONNECT ON DATABASE aura_bff FROM PUBLIC;
```

**In PostgreSQL, `PUBLIC` holds `CONNECT` on every database by default.** Two
roles and two databases without this are decorative: `chatwoot` could open
`aura_bff` and read it. Ownership does not restrict connection; only this does.

Extensions are created by the superuser up front — `vector` in `chatwoot`,
`btree_gist` in `aura_bff` — because `CREATE EXTENSION` needs privileges the
application roles deliberately do not have. Rails' `enable_extension` issues
`CREATE EXTENSION IF NOT EXISTS`, so Chatwoot's own migration becomes a no-op
rather than an error.

## Verified, in both directions

Not assumed from the grants — actually attempted:

| Attempt | Result |
|---|---|
| `chatwoot` → `aura_bff` | **`FATAL: permission denied ... User does not have CONNECT privilege`** |
| `aura` → `aura_bff` | connects |
| `chatwoot` → `chatwoot` | connects |
| `aura` → `chatwoot` | **denied, same error** |

## The image had to be pinned, and Coolify offers no pg16 + pgvector

Chatwoot requires **pgvector** — this is not optional. Its base `schema.rb`
carries `enable_extension "vector"` and `t.vector "embedding", limit: 1536`, so
`db:chatwoot_prepare` fails outright on stock Postgres. Their own production
compose pins `pgvector/pgvector:pg16`.

Coolify's picker offers PGVector **17** and **18**, no 16 (the cards map straight
to image strings — read out of `select.blade.php` rather than guessed). The
image field is editable, so it was set to `pgvector/pgvector:pg16` before first
start.

**Pinned to 16 rather than accepting 17**, because a Postgres major version
cannot be changed afterwards — that is a dump and restore. The evidence points
at 16 from both sides: Chatwoot pins it upstream and our dev instance ran on it
(`AURAS-0001`), and the BFF's 402 tests plus the manor verification all ran
against `postgres:16-alpine`. For 17 there is no evidence, only the expectation
that Rails and Prisma are usually tolerant. That expectation has been wrong
enough times in this task to not spend it on a database that cannot be changed.

Running: **PostgreSQL 16.15**, `vector 0.8.6`, `btree_gist 1.7`.

## Redis: one instance, and one setting that is not a default

`redis:7.2`. Chatwoot on `db 0`, BFF on `db 1`. No role separation here: the
contents are queues and cache, there is no money in it, and Redis ACLs cost
considerably more effort for the same boundary. The residual risk is named
rather than hidden — a `FLUSHALL` from Chatwoot's side would wipe the BFF's
queues. Closeable later with an ACL if it ever matters.

Two settings applied before first start:

```
maxmemory 512mb
maxmemory-policy noeviction
```

**`noeviction`, not the `allkeys-lru` in Coolify's placeholder.** Under memory
pressure LRU silently discards keys; if one of them is a BullMQ job, a message
is never delivered and nothing appears in any log. `noeviction` makes the write
fail loudly instead. Without any `maxmemory` at all, Redis grows until the OOM
killer picks a victim — and on this box the victim would be Postgres.

## State of the host

| | |
|---|---|
| Memory | **1.2 GB of 7.75 used** — ~6.5 GB free for Chatwoot and the BFF |
| Exposed | 22, 80, 443 only; 5432 and 6379 confirmed closed from outside |
| Cost | $12.81/month |

## Credentials

Generated on the server, never printed into a transcript, handed to the owner
through a scratchpad file for a password manager. The Coolify-generated
`postgres` superuser password stays administrative — it goes into no
application.

## Next

Stage 2: the NestJS application on Coolify.
