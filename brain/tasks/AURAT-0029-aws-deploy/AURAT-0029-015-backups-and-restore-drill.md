# AURAT-0029-015 — Backups to R2, and a restore that actually ran

Date: 2026-08-19
Status: mechanism proven end to end. **The drill must be repeated once real
data exists** — see the honest caveat at the bottom.

## Why this was done before the applications, not after

The acceptance criterion of this task has never changed with the provider: *a
backup that has been restored*, not dumps that exist. Doing it now — while both
databases are nearly empty — means the mechanism is proven cheaply, on a
database where a mistake costs nothing, instead of being exercised for the first
time on the day it is the only copy left.

## Cloudflare R2, EU jurisdiction

Two buckets, both **`Specify jurisdiction: EU`** rather than `Automatic`.
Automatic is a *hint* — Cloudflare states it "chose Western Europe" but reserves
the right to place objects elsewhere. EU jurisdiction is a guarantee, and
**bucket jurisdiction cannot be changed afterwards**. Same reasoning as the
server location: attachments and dumps carry consultation content (`AURAD-0005`).

| Bucket | Contents |
|---|---|
| `aura-backups` | Postgres dumps |
| `aura-chatwoot` | Chatwoot attachments (stage 3) |

**Two separate API tokens, one per bucket**, not one token for both. Chatwoot's
token would otherwise reach the database dumps — including the dump of
`aura_bff`, the database its own Postgres role is deliberately denied. That is
the same boundary drawn in `014`; handing it back through an S3 key would make
the Postgres work decorative.

Both are **Account** tokens rather than **User** tokens: Cloudflare's own
description says user tokens go inactive if the user leaves the organisation.
For a production credential that is a silent future outage.

The endpoint for EU-jurisdiction buckets carries an extra `.eu` segment —
`https://<account>.eu.r2.cloudflarestorage.com`. Without it requests reach the
wrong jurisdiction and simply do not find the bucket.

## Schedule

Coolify's native `ScheduledDatabaseBackup` (it has `save_s3` and an
`s3_storage_id`, so no hand-written cron was needed):

| | |
|---|---|
| Frequency | `0 3 * * *` UTC — quiet for EU users |
| Databases | **`aura_bff,chatwoot`** — both, explicitly |
| S3 | enabled, target `r2-backups` |
| Local retention | 3 copies / 7 days / 5 GB |
| S3 retention | 14 copies / 30 days / unlimited size |

**Both databases had to be named.** The default backs up one; `chatwoot` holds
every consultation ever had and is no more expendable than the ledger.

The retention split is deliberate and asymmetric. Locally, the size cap is a
**fuse**: 80 GB of disk is shared with both databases, Docker and logs, and
filling it takes Postgres down. In S3 the size cap is left unlimited on purpose
— of the three limits, "first one reached wins", and a size cap is the only one
whose trigger point is unpredictable. As the database grows it would silently
start cutting history short of the 30 days, and that is discovered exactly when
someone reaches for a week-old backup. Count and age state an intent; gigabytes
state an accident.

## The drill

Run against the real dump Coolify produced, not a hand-made one:

1. `pg_restore` into a **scratch** database (`restore_drill`) beside the live
   one — the live database is never written to.
2. **Exit code 0.**
3. The restored database contains **`btree_gist`** — the extension installed by
   the superuser in `014`. So the dump carries real state rather than an empty
   shell, and extension objects survive the round trip.
4. Scratch database and role dropped.

Independently confirmed in the Cloudflare dashboard: **both objects present in
`aura-backups`**, 1.29 KB and 1.28 KB, matching the local files byte for byte.
That last check is the owner's and cannot be delegated — the bucket keys are
deliberately not on this machine, so Coolify's own `success` status is its word
about itself, and only the dashboard shows the file.

## What this does NOT prove

The databases hold no tables yet: the BFF's migrations have not run and Chatwoot
has not created its schema. **1.3 KB dumps prove the pipeline, not the payload.**

Repeat the drill once Chatwoot has its ~90 tables and the BFF's migrations are
applied, and check specifically:

- `balanceMinor` equals `SUM(ledger_entries.amountMinor)` on every wallet;
- the `ledger_entries` append-only trigger is present **and fires** — a count
  cannot see a trigger that exists but does nothing;
- the `sessions` gist exclusion constraint survived.

Those checks already exist as `deploy/bin/restore-check.sh`, written for the AWS
deployment. It needs a small adaptation to Coolify's dump layout; the assertions
carry over unchanged.

Attachments are **not** in these dumps. They live in `aura-chatwoot`, which is
its own bucket and its own durability story — a restored Chatwoot with an empty
attachment bucket shows conversations whose files 404.

## Next

Stage 3: Chatwoot itself.
