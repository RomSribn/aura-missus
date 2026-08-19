# AURAT-0029-013 — The host actually exists: Hetzner + Coolify, stage 1 done

Date: 2026-08-19
Status: infrastructure up and verified. **AWS is out of the picture entirely.**

This is the first thing in this task that is *running* rather than planned.

## What was chosen, and the number that decided it

The AWS pivot went to a VPS + Coolify. The first attempt priced Hetzner's
**Ashburn** location: `CPX31` (4 vCPU / 8 GB) at **$88.92/month**, with 2 GB
costing $24.79 — DigitalOcean money, not Hetzner money. My earlier "~$17" was
the *European* price, quoted without checking the US premium.

Same specification in **Helsinki**, Cost-Optimized line: **`CX33` — 4 vCPU,
8 GB, 80 GB, 20 TB traffic, $12.09/month.** Seven times cheaper for the identical
machine, plus 20 TB of transfer instead of 3 TB.

**So the region question answered itself.** `AURAD-0005` fixes an EU region on
PII grounds — European users, psychological-consultation content — and the only
argument for the US was latency. US → Helsinki is ~100 ms, which is nothing for
a chat app over WebSocket, and it was going to cost $77/month *plus* an
amendment overturning a ratified decision about where personal data lives. The
amendment is no longer needed: **Helsinki is EU, `AURAD-0005` holds unchanged.**

x86 rather than Arm, deliberately reversing my own advice once real prices were
visible: Arm saves ~$4/month, `CX33` is already inside budget, and Chatwoot on
x86 is the path thousands of deployments have already walked. Not the place to
spend risk.

## What is running

| | |
|---|---|
| Host | Hetzner `CX33`, Helsinki (verified `country: FI`), Ubuntu 24.04.4 |
| Resources | 4 vCPU, 7.7 GB usable, 71 GB free |
| Coolify | **4.3.9**, four containers all `healthy` |
| Memory in use | **1.27 GB of 7.75** — ~6.4 GB left for the actual stack |
| Cost | **$12.81/month** ($12.09 + $0.73 IPv4) |

Hardening applied by `coolify-server-prep.sh`, each verified after the fact
rather than assumed: 4 GB swap active (`swappiness=10`), **SSH password auth
off** (`passwordauthentication no`, root `without-password`), fail2ban active,
unattended security upgrades on, Docker log rotation capped at 3×10 MB.

The swap is not decoration: Chatwoot's rails and sidekiq spike, and on an 8 GB
box the difference between a slow minute and the OOM killer taking Postgres is
often exactly that file.

## DNS: `aura-app.cc`, and AWS finally leaves

The domain was registered at Spaceship and had been delegated to **Route 53**
during the AWS attempt — the one remaining AWS dependency, and an absurd one for
a stack with no AWS in it: a $0.50/month zone plus an MFA prompt for every A
record.

Moved to **Cloudflare**, which the project needs anyway for R2 (stage 4). Now
the whole deployment is Hetzner + Cloudflare.

Delegation verified **at the `.cc` registry**, not at a resolver — the lesson
from the Route 53 round, where `dig NS` answered with the *old* nameservers
because it asks whoever is currently authoritative, and they naturally name
themselves. The registry and whois both show `jasper` / `rayne.ns.cloudflare.com`.

Three A records, all resolving to `37.27.199.90` from Cloudflare's own
nameservers and from `1.1.1.1` / `8.8.8.8`:

| Record | Purpose |
|---|---|
| `bff.aura-app.cc` | what the app talks to (`AURAT-0028`'s prod target) |
| `chat.aura-app.cc` | Chatwoot dashboard for chatters |
| `coolify.aura-app.cc` | the panel |

**Proxy deliberately OFF (grey cloud) on all three.** With Cloudflare proxying,
TLS terminates at their edge, Traefik never sees the ACME challenge, and
certificate issuance fails — silently, with an error that names nothing useful.
Revisit only alongside an origin certificate.

## The panel is behind TLS, and the ports it used are shut

Coolify installs on `:8000` over plain http — the admin password crosses the
network in clear text, and the first visitor to reach that port can register as
administrator. So the panel was moved to `https://coolify.aura-app.cc` and the
ports closed. Verified from outside:

| Port | State | |
|---|---|---|
| 22, 80, 443 | open | as intended |
| **8000, 6001, 6002** | **closed** | panel now reachable only over TLS |
| 5432, 6379 | closed | Coolify's own datastores never were exposed |

Certificate issued by Let's Encrypt (`CN = coolify.aura-app.cc`, valid to
17 Nov 2026), chain verifies (`ssl_verify_result 0`), http 302s to https, panel
answers **200 in 0.43 s**.

A side benefit worth naming: the firewall no longer depends on the owner's home
IP. It is a residential DIGI Spain address whose PTR *claims* `static-` but sits
in an `ES-RESIDENTIAL` block — the kind that changes on a router reboot. Pinning
the panel to it would have meant losing access to the server at the least
convenient moment.

Port 22 is open to the world on purpose: key-only authentication is the control
that matters there, and locking SSH to a volatile address is how people lock
themselves out.

## Owed, and not yet done

- **`.env` of Coolify is backed up locally** (`/data/coolify/source/.env` →
  `~/coolify-env-backup.txt`). It holds the key that encrypts every environment
  variable stored in the panel; without it, a restored server cannot decrypt its
  own secrets. It must go into a password manager and the local copy deleted —
  that is the owner's, and it is not confirmed done.
- **AWS teardown.** `aura-aws-cleanup.sh` is written and unrun: an unattached
  Elastic IP, a 50 GB volume and a KMS key, ~$9/month for nothing. The Route 53
  zone can now go too — it no longer serves the domain. Nothing in it holds data.

## An architecture decision due before stage 2

`AURAD-0004` says Chatwoot runs its **own** Postgres — we do not share one. The
new brief proposes single shared Postgres and Redis instances, which on 8 GB is
the pragmatic call.

The middle ground preserves the boundary at near-zero cost: **one Postgres
server, two databases, two roles**, with Chatwoot's role holding no privileges
on `aura_bff`. That matters more here than in a typical two-app deployment,
because `aura_bff` contains the append-only ledger with real money in it
(`AURAT-0027`), and Chatwoot is a large third-party Rails application with a
much bigger attack surface than the BFF.

To be settled at stage 2, before the databases are created — retrofitting role
separation after both applications are live is a migration rather than a choice.

## Next

Stage 2: NestJS on Coolify. The `Dockerfile` already exists (multi-stage,
`runtime` stage without the Prisma CLI, migrations in their own container) and
needs adapting to how Coolify builds from GitHub.
