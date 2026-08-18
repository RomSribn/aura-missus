# AURAD-0005 — Self-host Chatwoot (CE) in the EU; one account, one API inbox per environment

Date: 2026-07-09
Status: accepted (owner-ratified 2026-07-09)

## Decision

**Self-host Chatwoot Community Edition** in an **EU region, co-located with the
BFF** (`AURAD-0004`) — not Chatwoot Cloud. **One Chatwoot account**, with **one
`Channel::Api` inbox per environment** (dev / staging / prod). The BFF drives the
Application API with a dedicated **service User** access token, and an **Agent
Bot** on the inbox provides the retrying delivery webhook. Closes O7 of
`AURAI-0002`.

## How it works

- **Self-host, not Cloud:** run Chatwoot CE ourselves. At the described scale
  (hundreds of chatters, 24/7) Chatwoot Cloud's per-agent pricing is an order of
  magnitude more than self-host infra, and self-host gives PII control for EU
  users plus clean co-location with the BFF.
- **Region / provider:** one **EU region** for Chatwoot + BFF + their
  Postgres/Redis (users are EU — the Firebase SMS region work was `ES`). Default
  **GCP europe-west** for Firebase adjacency and a single cloud relationship; a
  cheaper EU alternative (Hetzner / managed VMs) is an ops call to re-check at
  full chatter scale.
- **Account / inbox topology:** **one Chatwoot account** (single product /
  tenant); **one `Channel::Api` inbox per environment**, each with its own
  `identifier` + `hmac_token` + `secret` + `webhook_url` pointing at that env's
  BFF. The BFF keeps per-env config; dev/staging/prod never share secrets or
  webhook targets.
- **Service credentials, not human tokens:** the BFF authenticates the
  Application API with a dedicated **service User** ("Aura BFF") token — not a
  real agent's token that could be deleted or rotated. An **Agent Bot** is
  attached to the inbox to get the **retrying** delivery webhook (`AURAI-0002`
  §2.4); the bot cannot create contacts, so contact/conversation provisioning
  stays on the service-User token.
- **Routing:** teams for advisor personas (`AURAD-0001`); chatters are agents in
  this one account — provisioning policy is O6.

## Why

- Per-agent Cloud pricing at hundreds of chatters dwarfs self-host infra cost —
  self-host is the only sane economics at this scale.
- EU users + sensitive consultation content → keeping PII on our own EU infra is
  the safer default, and complements the Firebase EU / SMS-region setup.
- One account + per-env API inbox isolates dev/staging/prod (independent secrets,
  independent webhook targets) while keeping agents/teams/reporting unified.
- A dedicated service User + Agent Bot separates machine credentials from humans
  and buys webhook retries.

Assumption: Community Edition suffices — the integration needs no Enterprise
features. Exact provider, k8s-vs-VM, and backup/DR are ops details under this
decision. Chatter provisioning = O6; identity / retention = O5.

Informed by `AURAI-0002`, `AURAD-0004`. Unblocks `AURAF-0007` deployment.

## Provider and topology chosen — 2026-08-18

This decision left "exact provider, k8s-vs-VM, and backup/DR" as ops details
under itself, so this is a record, not an amendment: nothing above changes.

**AWS `eu-central-1`** (Frankfurt), chosen by the owner over the GCP
europe-west default. The default's stated reasons were Firebase adjacency and a
single cloud relationship; neither survives contact:

- Firebase (phone OTP, FCM) and the Play Developer API are public HTTPS and
  behave identically from any provider — there is no technical adjacency to lose.
- A GCP project exists **regardless**, because refund notifications
  (`AURAS-0002` step 8) are Google Cloud Pub/Sub pushing to our HTTPS endpoint.
  So "one cloud" was never on the table under either choice.

What remains is operator familiarity, which is the owner's, and `eu-central-1`
keeps the EU-region requirement above intact.

**One VM running docker compose, not Kubernetes.** The whole stack is ~7
containers — the BFF (its own `Dockerfile`) with Postgres 16 and Redis 7, and
Chatwoot's rails + sidekiq with its own Postgres and Redis — and it is already
built and run that way in dev. Kubernetes would add a control plane to maintain
for capabilities not yet needed: zero-downtime deploys, autoscaling, multi-node
scheduling. Revisit when chatter count or an uptime requirement makes a rolling
deploy necessary; that is also the point to consider managed Postgres.

Implementation is `AURAT-0029`.
