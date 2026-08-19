# AURAT-0029-017 — The BFF is serving, and two defects the platform found

Date: 2026-08-19
Status: `https://bff.aura-app.cc` answering, database and Redis reachable.

```
GET /health        → {"status":"ok"}
GET /health/ready  → {"status":"ok","checks":{"database":true,"redis":true}}
```

Migrations applied by the entrypoint before the app listened; `aura_bff` has its
tables and `_prisma_migrations` is populated. The whole stack now runs on one
€12/month host: BFF, Chatwoot, one Postgres with two isolated databases, one
Redis, Coolify and Traefik.

## Deployment shape

Built from the repository on push (`is_auto_deploy_enabled`), Dockerfile build
pack, `runtime` stage. Worth stating plainly because it is now automatic:

**A push to the deployed branch applies migrations to production.** The
entrypoint runs `prisma migrate deploy` before the app starts. That command only
applies pending migrations — it never generates or resets — takes an advisory
lock, and is a no-op when there is nothing to apply. A failure exits non-zero,
so the container never starts, the deployment is marked failed, and the previous
version keeps serving.

Three properties of that arrangement that are fine today and worth revisiting
when there are users:

- The deployed branch is `feature/AURAT-0029-aws-deploy`. **After the merge,
  Coolify must be pointed at `develop`** or it will keep deploying the feature
  branch.
- There is no gate. A push carrying a bad migration reaches production directly.
- Rolling updates mean the new container starts while the old one is still
  serving. An additive migration survives that window; a destructive one
  (dropping a column the old version still selects) would not. None of the
  current migrations are of that kind, but the first one that is needs the
  two-step expand/contract treatment.

## Defect 1 — the build stage was sensitive to ambient environment

```
sh: nest: not found
```

Coolify injects the application's environment into the image build as build
args, so `NODE_ENV=production` reached `npm ci` in the **build** stage. npm
honours it and skips devDependencies — including `@nestjs/cli`, which is the
compiler.

The dependency layout was never wrong: `@nestjs/cli` belongs in
devDependencies, the multi-stage build installs everything in `build`, compiles,
and copies only `dist/` plus a production-only tree into `runtime`. What was
wrong is that a stage which *requires* dev dependencies asked for them
implicitly, and an external actor could flip the default.

`npm ci --include=dev` states the intent. Verified by building the stage with
`--build-arg NODE_ENV=production` — the case that failed.

Fixing it in the panel instead (unchecking "available at buildtime") would have
been the band-aid: the repository would still build wrong anywhere else.

## Defect 2 — an empty environment variable is not an absent one

The first successful build then refused to boot:

```
CHATWOOT_SERVICE_AGENT_ID: Number must be greater than 0
GOOGLE_PLAY_PACKAGE_NAME: String must contain at least 1 character(s)
```

**A deployment panel cannot express "absent".** Coolify — like every key/value
form — stores an unset variable as an empty string. Zod's `.optional()` means
"may be undefined", so `''` arrived as a present value and failed `.min(1)`.

Every one of those four is deliberately unset in v1: billing is off, and the
service agent id is resolved from `GET /profile` at first use. The schema was
refusing precisely the configuration the product ships.

`validateEnv` now drops empty-valued keys before parsing. Two behaviours are
asserted rather than assumed:

- **`AURAD-0010`'s guard is intact** — empty `GOOGLE_PLAY_*` still refuses to
  boot when billing is ON in production. Empty means unset, and unset is exactly
  what must not run with billing enabled.
- A variable that has a default now takes it when the field is left blank.

That second one **changed an existing test**, which asserted the opposite for
`SESSION_BLOCK_MINUTES`. Updated deliberately, with the reason written into the
test: before, `''` could only come from someone typing it; now it also means
"blank field in a panel".

406 tests (was 402).

## Secrets were being baked into image layers

Docker warned twelve times during the failed build:

```
SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data
  (ARG "FIREBASE_PRIVATE_KEY") (ARG "CHATWOOT_API_ACCESS_TOKEN") …
```

Coolify marks every variable build-time by default, and build args **persist in
image metadata** — `docker history` would have shown the Firebase private key
and the Chatwoot service token in clear text to anyone who could read the image.

The build needs none of them: it compiles source, it does not connect to
anything. All 26 are now runtime-only. This is not a workaround for defect 1 —
that is fixed in the Dockerfile — it is the correct state, which the default was
not.

Chatwoot's 40 remain build-time and are harmless there: its resource uses a
prebuilt image, so nothing is baked. Worth revisiting only if it is ever built
from source.

## Not yet closed

- **The loop is unproven.** A message from the app through the BFF to a chatter
  and back has not been exercised. That needs the app pointed at
  `bff.aura-app.cc` — the `.env.prod` one-liner `AURAS-0002` predicted.
- **The restore drill was run on empty databases** (`015`). Now that both
  schemas exist it should be repeated with the ledger assertions.
- **Chatwoot's inbox webhook has never fired**, so
  `SAFE_FETCH_ALLOW_PRIVATE_NETWORK` is still a claim rather than an observation.
