# AURAT-0029-002 — Check existing state

Date: 2026-08-18

## Brain

- **`AURAD-0005`** — self-host Chatwoot CE, EU region, BFF + Chatwoot + their
  Postgres/Redis co-located, one Chatwoot account with one `Channel::Api` inbox
  **per environment**. Now carries the provider record: AWS `eu-central-1`, one
  VM, docker compose.
- **`AURAD-0004`** — the BFF's shape: NestJS, Postgres, Redis/BullMQ, Firebase
  Admin, FCM + WebSocket, Docker co-located with Chatwoot.
- **`AURAS-0001`** — the dev Chatwoot runbook. The production equivalent is
  largely this file with different hosts and real secrets, and it already
  records the exact provisioning steps (account, service User, `Channel::Api`
  inbox, Agent Bot, the `.env` capture).
- **`AURAS-0002`** — Play. Its step 8 (RTDN) needs a **public HTTPS endpoint**,
  which is one of the things this task creates.
- No prior task covers deployment. Fresh ground.

## What already exists, and is reusable

| | |
|---|---|
| `aura-bff/Dockerfile` | the BFF image builds today |
| `aura-bff/docker-compose.yml` | bff + postgres:16-alpine + redis:7-alpine, `build: .`, named `pgdata` volume |
| `chatwoot-manor/docker-compose.aura-cw.yml` | Chatwoot 4.15.1 prebuilt image, arm64, rails + sidekiq + postgres + redis |
| `chatwoot-manor/chatwoot-provision.rb` | scripted Chatwoot provisioning — account, service User, inbox, Agent Bot |

So the deploy is **not** a from-scratch containerisation job. It is: make these
production-shaped, put them on one host, terminate TLS, and be able to do it
again.

## Gaps this task must close

- **No TLS anywhere.** Everything in dev is plain http on localhost. Android
  release forbids cleartext and iOS ATS forbids arbitrary loads, so the app
  cannot talk to an untrusted endpoint at all.
- **No production secrets story.** Dev keeps Chatwoot creds in
  `.env.chatwoot.dev` (gitignored) and the BFF's `.env` by hand. Production adds
  the three `GOOGLE_PLAY_*` values, and the BFF **refuses to boot** with billing
  on if they are missing.
- **No backups.** Two Postgres instances hold the wallet ledger and the entire
  consultation history. `AURAD-0005` named backup/DR an ops detail; it stops
  being deferrable the moment real money is in the ledger.
- **arm64 vs x86.** The dev Chatwoot image is pinned arm64 for the M2 Mac. An
  EC2 instance is x86 unless Graviton is chosen — the image tag must be resolved
  deliberately, not discovered at first boot.
- **One inbox per environment** (`AURAD-0005`): production needs its **own**
  Chatwoot inbox, identifier, hmac token and webhook URL. Reusing dev's would
  cross real users with test traffic.

## Next

`003-understand.md`.
