# AURAT-0029-005 — Spec

Date: 2026-08-18
Executes in: **`aura-bff-manor`** (a live stack is needed; the RN manor forbids
that in its slaves)
Status: **awaiting owner approval — no code written**

## Goal

The BFF and Chatwoot running on one AWS `eu-central-1` instance, reachable over
TLS, restorable from backup, and standable-up again from a written runbook.

## Scope

### 1 · Decide where the production artifacts live (do this first)

One host, two repos, two manors. Pick one and write down why:

| | |
|---|---|
| **`aura-bff` owns it** | The deploy unit that talks to Chatwoot owns the host; Chatwoot's compose is vendored or referenced. Fits `AURAD-0006`'s one-manor-per-deploy-unit reading. |
| **`chatwoot-manor` owns it** | It already holds `docker-compose.aura-cw.yml` and `chatwoot-provision.rb`, so the Chatwoot half is there today. |
| **A third `deploy` location** | Honest about it being neither, at the cost of a place nobody looks. |

Whichever wins, there must be exactly **one** production compose, and the other
manor points at it rather than keeping a second copy that drifts.

### 2 · Production compose

Both stacks on one host: BFF + its Postgres/Redis, Chatwoot rails + sidekiq +
its Postgres/Redis. Differences from dev that must be deliberate:

- **Pinned image tags**, and the **architecture resolved** — check whether the
  pinned Chatwoot version publishes arm64 before choosing Graviton over x86.
- **Data on a separate EBS volume**, so the instance is disposable and the data
  is not.
- **Nothing published to the public interface except the reverse proxy.** Both
  Postgres and both Redis stay on the internal network; Chatwoot's webhook
  reaches the BFF internally, and the inbox's `webhook_url` records that
  internal address.
- Restart policies, health checks, and log rotation — a box that fills its disk
  with logs is the classic first outage.

### 3 · TLS and hostnames

Reverse proxy (Caddy or nginx + certbot) terminating TLS for two names: the BFF
and Chatwoot. **This is a hard requirement, not polish** — Android release
forbids cleartext and iOS ATS forbids arbitrary loads, so an http host is
unusable by the app and fails only in release.

The BFF hostname is what `AURAT-0028`'s prod target will be pointed at, and what
`AURAS-0002` step 8 needs for the Pub/Sub push subscription.

### 4 · Secrets

No secret in git. Decide the mechanism (SSM Parameter Store / Secrets Manager /
a root-owned env file on the box) and write which values exist and who sets them:
Chatwoot secret key base and service-User token, Firebase Admin credential,
Postgres passwords, and the three `GOOGLE_PLAY_*` — without which the BFF
**refuses to boot** with billing on, deliberately.

### 5 · Its own Chatwoot environment

`AURAD-0005` requires **one `Channel::Api` inbox per environment**. Production
gets its own account setup, service User, inbox, identifier, hmac token, Agent
Bot and webhook URL — not dev's. `chatwoot-provision.rb` already scripts this;
reuse it rather than clicking through the UI.

### 6 · Backups, and a restore that actually ran

Nightly dumps of **both** Postgres instances to S3 with a retention policy, and
— the part that matters — **one documented restore into a scratch database**,
with the result recorded. `AURAT-0027` made `ledger_entries` append-only at the
database; that guarantee is worth nothing behind a backup nobody has restored.

### 7 · The runbook

Mint **`AURAS-0003`** (bump the counter first) with the owner-executed steps:
account and IAM, key pair, DNS records, first apply, and how to deploy a new
version. Same shape as `AURAS-0001`, which is the dev version of this document.

## Out of scope

Kubernetes (`AURAD-0005`). CI/CD. Multi-AZ, autoscaling, managed Postgres —
revisit when an uptime requirement exists. iOS anything.

## Acceptance

- The app's prod target, built by `AURAT-0028`, reaches the BFF over https from
  a real device.
- Chatwoot reachable over https; a chatter can answer; the reply arrives in the
  app via the production inbox's webhook.
- Neither Postgres nor either Redis is reachable from outside the host.
- A backup has been **restored** and the result written down.
- The instance can be rebuilt from the runbook without consulting a session.

## Open question for the owner

**Who runs the first apply?** Everything above can be written by a session, but
creating resources on your account needs credentials. Options: you run it from
the runbook (safest, slowest); or you provision a scoped, revocable IAM role and
a session drives it while you watch. Account creation, billing, root MFA and DNS
registrar changes are yours either way.
