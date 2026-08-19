# AURAT-0029-007 — Execute

Date: 2026-08-18
Slave: `aura-bff-manor` / **slave-1**, branch `feature/AURAT-0029-aws-deploy`
(off `develop` `cead5c5`). Staged, **not committed** — awaiting IDE review.

> Two later notes, so this file is not read as current on its own:
> **D4 ("No Terraform") was reversed by the owner** — see `008-add-terraform.md`
> and `009-execute.md`. And the `AURAS-0003` step numbers cited below were
> repointed when that renumbered the runbook; only the numbers changed.

Everything up to the first apply. No AWS account was touched, no credentials
were requested, and none were used (`006-approval.md`).

---

## D1 · Where the production compose lives — **`aura-bff` owns it**

Decided before anything was written, as the spec required. Full reasoning in
`aura-bff/deploy/README.md`; the decisive facts:

- **`chatwoot-manor`'s deploy artifacts are in no git repository at all.**
  `docker-compose.aura-cw.yml` and `chatwoot-provision.rb` sit at that
  workspace's *root*, and `git rev-parse` there fails — they are untracked local
  files on one Mac. A production deploy whose only copy dies with a laptop is
  not a deploy. This was checked, not assumed.
- **That manor's `master` is a clone of upstream Chatwoot**, so committing our
  config there means carrying a fork and rebasing it on every upstream pull.
- **`aura-bff` is cloned everywhere it is needed, has a remote, and is the thing
  that changes on a release.** "Deploy a new version" is `git pull` in this
  repo; a second repo to pull is a second chance to be out of step.
- A third `deploy` repo was rejected: a new repo, a new manor, a new clone, and
  a place nobody has a reason to open.

**One production compose, and the other manor points at it.** Added
`chatwoot-manor/PRODUCTION.md` and a `## Production` section to that workspace's
`CLAUDE.md`, both naming `aura-bff/deploy/docker-compose.prod.yml` as the only
production source and marking `docker-compose.aura-cw.yml` explicitly dev-only.
No copy was made anywhere.

> **Not an `AURAD`.** This manor cannot mint IDs (`AURAD-0006`). If the owner
> wants it ratified rather than recorded, the ID comes from `aura-app-manor`.
> It does not contradict `AURAD-0006` — it settles a case that decision did not
> anticipate.

## D2 · Architecture — **arm64 / Graviton**, resolved by evidence

The spec called this out because discovering it at first boot means
`exec format error` on a host that already has a DNS record. Checked against the
registry rather than assumed: `chatwoot/chatwoot:v4.15.1`,
`pgvector/pgvector:0.8.6-pg16` and `caddy:2.11.4-alpine` all publish **both**
`linux/amd64` and `linux/arm64`, as do the official postgres/redis/node tags.

So both work, and arm64 wins: it is what dev already runs (an image that works
on the M2 works here; on x86 the two differ, which is where "works on my
machine" lives) and Graviton is cheaper. `t4g.large` — 8 GiB is the honest
minimum for seven containers.

The compose file sets **no `platform:` key at all**, which is what makes it
work either way. Choosing x86 later changes the instance type and nothing else.

## D3 · Secrets — **SSM Parameter Store**, rendered to root-owned files

Source of truth is `SecureString` under `/aura/prod/`;
`deploy/bin/pull-secrets.sh` renders `/srv/aura/secrets/*.env` at `0600`.
SSM over Secrets Manager: same KMS envelope and IAM, and standard parameters
are free where the other bills per secret per month for ~20 secrets. SSM over
hand-editing the box: a value that exists only on one instance dies with it,
which defeats the point of putting the data on its own volume.

The full inventory — every value, who produces it, where it comes from — is a
table in `AURAS-0003` step 4, backed by per-value comments in
`deploy/env/*.example`. That includes the three `GOOGLE_PLAY_*` without which
the BFF **refuses to boot** with billing on; step 11 makes flipping the flag a
separate deliberate act, and says what the refusal looks like so it is not
mistaken for a different failure.

## D4 · No Terraform, on purpose — **REVERSED by the owner, see `008`**

The spec allowed "the Terraform **or** the console steps". Chosen: explicit
`aws` CLI commands in the runbook. Nothing here has ever been applied against a
real account, and untested HCL reads as authoritative while being unverified —
the owner would be debugging a plan, not a deploy. CLI commands fail one at a
time, visibly. Recorded as a follow-up once one real apply proves the shape.

---

## What was built

### `aura-bff/deploy/` (new)

| File | What it is |
|---|---|
| `README.md` | the placement decision, host layout, and why `deploy/` is not a build-rule-1 breach |
| `docker-compose.prod.yml` | seven containers + Caddy; pinned tags, healthchecks, `restart: unless-stopped`, bind mounts on the data volume |
| `Caddyfile` | TLS for both hostnames, HSTS, WebSocket passthrough |
| `env/stack.env.example` | infra values **and** compose's `--env-file` |
| `env/bff.env.example` | the BFF's own config; every value annotated |
| `env/chatwoot.env.example` | Chatwoot's; carries the SSRF-guard explanation |
| `chatwoot/provision-prod.rb` | production's **own** inbox, internal webhook, idempotent |
| `bin/compose.sh` | the only correct compose invocation |
| `bin/pull-secrets.sh` | SSM → root-owned env files |
| `bin/deploy.sh` | release/rollback, waits on `/health/ready` |
| `bin/backup.sh` | both Postgres + Chatwoot attachments → S3 |
| `bin/restore-check.sh` | **the acceptance test** |
| `systemd/aura-backup.{service,timer}` | nightly 03:15 UTC, `Persistent=true` |
| `bootstrap/cloud-init.yaml` | docker, data volume, log rotation, swap, repo |

### `aura-bff` (changed)

- **`Dockerfile`** — now ends in a named `runtime` stage from an
  `--omit=dev --ignore-scripts` tree, running as `node`, with no sources and no
  Prisma CLI; the `build` stage is targeted by the `bff-migrate` service so
  migrations never run in the serving container. **Pays TECH-DEBT #5.**
  (`--ignore-scripts` is required, not tidiness: `postinstall` runs
  `prisma generate` and the CLI is a devDependency.)
- **`.dockerignore`** (new) — the build stage does `COPY . .`, so until now a
  manor developer's real `.env` was baked into an image layer.
- **`src/fastify.options.ts`** (new) + `src/main.ts` — see the defect below.
- **`src/fastify.options.spec.ts`** (new) — 4 tests.
- `README.md`, `TECH-DEBT.md`.

### Shared brain

- **`solutions/AURAS-0003-aws-production-deploy.md`** (new) — the runbook.
  Counter bumped **first** in `aura-app-manor/active-work.md`
  (`AURAS: next free = AURAS-0004`), which is the ID authority.
- `solutions/AURAS-0001-dev-chatwoot-setup.md` — amended; see below.
- `aura-bff-manor/active-work.md` — slave-1 marked busy.

---

## Two defects found on the way, and fixed

**1 · Behind the proxy, every device would have shared one rate-limit budget.**
`@fastify/rate-limit` keys on `req.ip`, and Fastify had no `trustProxy`, so with
Caddy in front *every* request arrives from the proxy's address: all users
together get 120 requests/minute, not each. The app would start 429ing under
ordinary load — **in the deployed environment only**, which is the same failure
shape as the cleartext trap this task already had to design around. Logs would
also have recorded the proxy for every request.

Fixed with `trustProxy: 1` in a new `src/fastify.options.ts`. **`1`, not
`true`**: `true` trusts the leftmost `X-Forwarded-For` entry, which the client
writes, so anyone could claim any address and exhaust someone else's budget.
One hop takes the address the proxy actually observed. Requests with no
`X-Forwarded-For` keep their socket address — which is the path Chatwoot's
webhook takes, since it never goes through the proxy.

Pinned by four tests that drive real requests through `fastify.inject()`,
including the spoofing case and the no-header case, rather than comparing an
options literal.

**2 · `.env` was being copied into every image.** No `.dockerignore` existed and
the build stage does `COPY . .`. On the production host the file would not
exist (it clones from git), but the manor builds with `docker compose up
--build` and its `.env` holds live Chatwoot credentials.

## A contradiction in the brain, resolved rather than papered over

`AURAS-0001` says of `SAFE_FETCH_ALLOW_PRIVATE_NETWORK`: *"Never set it in
staging/prod — there the BFF webhook URL is public."*

This task's topology deliberately gives the BFF **no** public URL: Chatwoot
reaches it at `http://bff:3000/webhooks/chatwoot` over the Docker network, and
that is what the inbox records. Verified in the Chatwoot checkout that
`lib/webhooks/trigger.rb` routes **every** outgoing webhook through
`SafeFetch.fetch`, and that the flag replaces the filter wholesale
(`lib/safe_fetch/fetcher.rb`). So production must set it, or every agent reply
fails with *"Hostname has no public ip addresses"* — silently, right after a
chatter typed a real answer.

The flag is instance-wide, so the risk is real: a Chatwoot administrator could
point a webhook at the EC2 metadata endpoint. Paid for at the instance instead
of ignored — **IMDSv2 required** and **metadata hop limit 1**, which means a
container cannot reach `169.254.169.254` at all (the Docker bridge costs the
one hop). That is also why `backup.sh` and `pull-secrets.sh` run on the host
under systemd rather than in containers: the host still has its one hop.
`AURAS-0001` now carries the amendment, and `AURAS-0003` step 3 gives a check
whose *failing* is the pass.

---

## Verified here (a slave, so: no live stack)

- `npm run lint`, `npm run typecheck`, `npm run build` — clean.
- `npx jest` — **34 suites, 402 tests** (was 398; +4 new).
- `docker build --target runtime` and `--target build` both succeed, and
  `docker run` on the runtime image with **no environment** reaches config
  validation and lists the missing variables — so nothing the app loads was
  pruned away. `node_modules/.bin/prisma --version` works in the `build` stage,
  which is what `bff-migrate` runs. Verification images deleted afterwards.
  (Image builds need no Postgres/Redis/Chatwoot, so this stays inside the slave
  rules; nothing was started.)
- `docker compose config` parses and interpolates the whole file, and reports
  **exactly three published ports — 80, 443/tcp, 443/udp, all on `caddy`** —
  with `bff-data` and `chatwoot-data` rendered `internal: true`.
- `bash -n` on all five scripts; `ruby -c` on `provision-prod.rb`.

## Not verified, and cannot be from here

Everything that needs the AWS account: the CLI commands in `AURAS-0003`, the
cloud-init run, certificate issuance, the Chatwoot production provisioning, the
webhook loop over the real network, the backup upload — **and the restore
drill, which is the acceptance criterion**. `AURAS-0003` is marked
`not yet executed` and its restore-drill log is empty on purpose: an empty log
means acceptance is not met, whatever is running.

The first apply is the owner's.

## Follow-ups (no IDs — mint in `aura-app-manor`)

- **Terraform**, once one real apply proves the shape (D4).
- **SMTP/SES.** Nothing in the Aura loop needs mail, so it is unconfigured and
  said so out loud in `chatwoot.env.example`: **nobody can reset a password**,
  and chatters are created from the console (`AURAS-0003` step 6) until it is.
- **TECH-DEBT #18** (new): `maxParamLength` as a root Fastify option is
  deprecated (`FSTDEP022`) and removed in Fastify 6. Pre-existing; surfaced by
  the new spec. Not changed here — reshaping router options inside a deploy
  task is risk with no deploy benefit.
- `AURAS-0002` **step 8** (the RTDN push subscription) is unblocked by this
  task's public HTTPS endpoint, which in turn unblocks the refund subscriber
  (`AURAF-0010-006`) that had no topic to subscribe to.

## Next

IDE review, then commit. **Nothing merges without explicit owner approval.**
