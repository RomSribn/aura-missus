# AURAS-0003 — Production deploy

Date: 2026-08-18, superseded in part 2026-08-19
Status: **the AWS half below was never executed and is on hold.** The product
runs on a Hetzner VPS with Coolify — see `AURAS-0004`, which is the document to
follow.

> **Read this first.** `terraform apply` was refused: the AWS account is on the
> free plan, which permits only 1–2 GiB instance types, and Chatwoot's rails
> alone wants more. Everything below is plan-proven (`33 to add, 0 to change,
> 0 to destroy`) and one apply away *if the account ever goes paid* — the
> Terraform, the IAM analysis, the IMDSv2 reasoning and the backup design all
> still hold. It is kept for that reason, not because it describes what is
> running.
>
> What actually runs, and how to operate it: **`AURAS-0004`**.
Feeds: `AURAT-0029` (aws-deploy). Unblocks `AURAS-0002` step 8 (the RTDN push
subscription needs a public HTTPS endpoint) and the `prod` build target that
`AURAT-0028` shipped hostless.
Source: `AURAD-0005` (hosting/topology + the 2026-08-18 provider record),
`AURAD-0004` (stack), `AURAS-0001` (the dev version of this document),
`aura-bff/deploy/` (every file this runbook drives) and
`aura-bff/deploy/terraform/` (the AWS resources themselves).

**The split to keep in mind while reading:** Terraform creates the machine and
everything around it (network, IAM, instance, volume, DNS); cloud-init and
`deploy/` describe what happens *inside* it (Docker, the compose stack, Caddy,
the backup timer). Steps 1–3 are the first half, 4 onward the second.

Stands up **one EC2 instance** running seven containers behind a TLS reverse
proxy: the BFF with its Postgres 16 and Redis 7, Chatwoot's rails and sidekiq
with their own Postgres and Redis. Data lives on a separate EBS volume, backups
go to S3, and the whole thing can be rebuilt from this file.

> **Read this before running anything.** It is written to be followed by
> someone who was not in the conversation that produced it. Where a step has a
> reason that is not obvious, the reason is in the step — those are the ones
> that cost a day when skipped.

---

## START HERE — the whole thing, in order

The rest of this document is reference. This is the sequence. Everything below
is yours to run; no session has AWS write access, by design.

**Two things block the very first step. Neither is code:**

| Blocker | Why it stops everything |
|---|---|
| **No domain** | `list-hosted-zones` is empty. Caddy asks Let's Encrypt for certificates at startup; a name that does not resolve fails the challenge and backs off. Android release builds forbid cleartext, so an http host is not "degraded" — the app cannot talk to it at all |
| **No write credentials** | The only working profile is read-only by construction. It can `plan`; it cannot create a thing |

Clear those, then:

```
 1  buy a domain, pick two names          bff.<domain>  and  chat.<domain>
 2  create a write-capable profile        step 1 below
 3  create the state bucket               step 2  (4 commands, once)
 4  terraform init / plan / apply         step 3  → ~15 min, creates the host
 5  read the public_ip output, then
    point both A records at it            at your registrar (or Route 53)
 6  put the secrets in SSM                step 4  → the longest step, ~30 min
 7  ssm start-session → pull-secrets
    → compose up                          step 5  → first boot, ~10 min
 8  provision production Chatwoot         step 6  → its OWN inbox
 9  verify the loop end to end            step 7  → app → chatter → app
10  backups on                            step 8
11  RESTORE A BACKUP                      step 9  ← the acceptance criterion
```

Steps 4–11 are one sitting, a few hours, mostly waiting. Steps 1–3 are the ones
that need decisions from you.

**Order matters in one non-obvious place.** With no Route 53 zone, DNS cannot be
created until the Elastic IP exists — so `apply` comes *before* the DNS records,
and the stack is not started until they resolve. That is why step 3 creates a
host that is deliberately running nothing.

Cost once it is up: roughly **$60–75/month**.

### Getting write credentials, concretely

The existing `claude-cli` user can only assume the read-only role. Keep that and
add a second role beside it — same shape, so nothing new to learn:

1. IAM → Roles → Create role → **Custom trust policy**, trusting the same user
   and requiring MFA (copy the read-only role's trust policy verbatim).
2. Attach the policy in step 1 below. Name it `AuraDeploy`.
3. Add a profile:

```ini
[profile aura-prod]
role_arn         = arn:aws:iam::<account>:role/AuraDeploy
source_profile   = claude-base
mfa_serial       = <the MFA Identifier shown in IAM, verbatim>
duration_seconds = 3600
region           = eu-central-1
```

Then, because Terraform cannot answer an MFA prompt (see step 3):

```bash
aws sts get-caller-identity --profile aura-prod        # in a REAL terminal
eval "$(aws configure export-credentials --profile aura-prod --format env)"
unset AWS_PROFILE
```

---

## What is yours and cannot be delegated

Account creation, billing, root MFA, buying the domain, and the DNS registrar.
Everything after those is in this file.

You need, before step 1:

- An AWS account with billing set up.
- A domain you control the DNS for, and two names chosen from it. This document
  writes them as `bff.example.com` and `chat.example.com`; substitute
  throughout, and use the same values in `stack.env`.
- **AWS CLI v2 and Terraform (>= 1.10)** on your machine — neither is installed
  on the manor Mac today. Step 2 installs them.
- An IAM identity in **this** account, configured as a local profile named
  `aura-prod` (step 1).

  **Note:** the manor Mac also carries an older SSO profile for an unrelated
  organisation. Do not use it and do not leave it exported. The Terraform config
  guards against it twice — `allowed_account_ids`, and `forbidden_account_ids`
  in the gitignored `terraform.tfvars` — because building production in someone
  else's account has no partial version.

```bash
export AWS_PROFILE=aura-prod
export AWS_REGION=eu-central-1
aws sts get-caller-identity        # confirm you are in the right account
```

---

## Architecture: arm64, and why that was decided rather than discovered

The dev Chatwoot pins `platform: linux/arm64` for the M2 Mac. An EC2 instance is
x86 unless Graviton is chosen, so this had to be settled before picking an
instance type — finding out at first boot means `exec format error` on a host
that is already carrying a DNS record.

Every image this stack pins publishes **both** `linux/amd64` and `linux/arm64`
(checked against the registry on 2026-08-18):

| Image | amd64 | arm64 |
|---|---|---|
| `chatwoot/chatwoot:v4.15.1` | yes | yes |
| `pgvector/pgvector:0.8.6-pg16` | yes | yes |
| `postgres:16-alpine`, `redis:7-alpine`, `node:22-alpine` | yes | yes |
| `caddy:2.11.4-alpine` | yes | yes |

So both are viable, and **arm64 (Graviton, `t4g.large`) is chosen**:

- It is the architecture dev already runs, so an image that works on the manor
  Mac works here. On x86 the two would differ, which is where "works on my
  machine" lives.
- Graviton is cheaper for the same memory.

`deploy/docker-compose.prod.yml` sets **no `platform:` key anywhere** — that is
what makes it work on either. `docker compose pull` selects the right manifest
from the host's own architecture. Pinning a platform is precisely what made the
dev Chatwoot compose un-liftable onto EC2, and repeating that mistake in the
other direction would be worse.

**If you choose x86 instead** (`m6i.large`), the only change is the instance
type. Nothing in `deploy/` needs editing.

### Sizing

`t4g.large` — 2 vCPU, 8 GiB. Chatwoot's rails and sidekiq are the memory-hungry
part; the BFF is one Node process. 8 GiB is the honest minimum for seven
containers: 4 GiB swaps, and the OOM killer takes Postgres. `cloud-init.yaml`
adds a 2 GiB swapfile as cheap insurance for spikes.

Storage: **30 GiB gp3 root** (disposable) and **50 GiB gp3 data** (not).

Cost is roughly **$60–75/month** at on-demand pricing — instance, 80 GiB of gp3,
S3, data transfer. This is the one number here that changes without anyone
editing the file; check the AWS calculator rather than trusting it. A one-year
Savings Plan cuts the instance roughly in half once the shape is proven.

---
## Step 1 — Account guardrails, the IAM user, and the profile

Do these once. They are boring, and they are why a mistake later is
recoverable.

1. **Root MFA on**, root access keys deleted if any exist.
2. **A budget alarm.** An instance left running is the usual way a side project
   becomes an invoice:

```bash
cat >/tmp/budget.json <<'EOF'
{ "BudgetName": "aura-prod-monthly",
  "BudgetLimit": { "Amount": "150", "Unit": "USD" },
  "TimeUnit": "MONTHLY", "BudgetType": "COST" }
EOF
aws budgets create-budget \
  --account-id "$(aws sts get-caller-identity --query Account --output text)" \
  --budget file:///tmp/budget.json
```

Add the email notification in the console (Billing → Budgets) — the CLI form is
fiddly and this is a one-off.

### Two identities, and why not one

**IAM Identity Center (SSO) is deliberately not used here.** Enabling it pulls
the account into an Organization, which is what makes it stop being a plain
standalone account; the owner's workaround — an IAM user that can do nothing but
assume a role, gated on MFA — is the standard pattern for a single-owner account
and is what this document assumes. Revisit SSO when the account is paid.

| Profile | What it is | Used for |
|---|---|---|
| **read-only** (`claude-ro`) | IAM user → `sts:AssumeRole` only → a role with `ReadOnlyAccess`, **MFA required**, 1-hour sessions | `validate`, `plan`, and every check in this document. Safe for an assistant session to run |
| **write** | whatever you configure with the policy below | `terraform apply`, and nothing else |

`var.aws_profile` defaults to `null`, so whichever is exported as `AWS_PROFILE`
is the one used — no name is hardcoded, because a single default would be wrong
for one of the two.

```bash
export AWS_PROFILE=claude-ro          # read-only, for plan/validate
export AWS_REGION=eu-central-1
aws sts get-caller-identity           # confirm the account BEFORE anything else
```

> **`mfa_serial` must match the device's Identifier verbatim.** Copy it from
> IAM → Users → *your user* → Security credentials → Multi-factor
> authentication. It ends in the **device name you typed when assigning it**,
> which is not necessarily the user name — a device registered as `iphone` gives
> `arn:aws:iam::<account>:mfa/iphone`. Get it wrong and AWS answers
> *"unable to validate MFA code"*, which reads like a bad code and is not.

> **The MFA prompt needs a real terminal, and blocks automation.** A profile
> with `mfa_serial` prompts `Enter MFA code` on the first call of each hour.
> Anything without a TTY — an automated shell, an assistant session — cannot
> answer it: `getpass` reads an empty string and the call fails with an empty
> error. Run it once in Terminal/iTerm; the temporary credentials land in
> `~/.aws/cli/cache`, which every process shares, and cover the next hour.
>
> One hour is the role's default `MaxSessionDuration`. Raising it in IAM (up to
> 12h) and setting `duration_seconds` to match trades a longer-lived credential
> for one MFA entry per day instead of per hour.

> **Set the region.** A profile that defaults to `us-east-1` answers AMI and
> instance-type questions about the wrong region perfectly happily, and the
> answers look normal. `AURAD-0005` fixes this deployment at `eu-central-1`.

> **The other profile in `~/.aws` is not this.** The manor Mac holds an older
> SSO profile for an unrelated organisation. Do not use it, and do not leave it
> exported. Two guards exist in the Terraform config, because building
> production in someone else's account has no partial version:
> `allowed_account_ids` makes the provider refuse every call if the credentials
> resolve elsewhere, and `forbidden_account_ids` catches the case where the id
> itself was mistyped.
>
> **No account id is written in this document, and none should be.** This brain
> is a **public** repository. Yours goes in `deploy/terraform/terraform.tfvars`,
> which is gitignored; `aws sts get-caller-identity` prints it on demand.

### Minimum permissions, honestly

Terraform here creates network, compute, IAM, KMS, Route 53 and SSM resources,
and reads/writes its own state bucket. The full policy is at
`aura-bff/deploy/terraform/AuraDeploy-policy.json` — attach it to the deploy
role verbatim; it names the account, region, prefix and bucket, so review those
four before pasting.

Its shape, and why each part is scoped the way it is:

| Statement | Scope | Why |
|---|---|---|
| `ec2:*`, `route53:*` | account | Enumerating EC2 verbs is a losing game — the provider calls dozens, and a missing one fails halfway through an apply. Bounded by the credential's account |
| IAM role/profile verbs | `role/aura-prod-*`, `instance-profile/aura-prod-*` | Enumerated rather than `iam:*`, **and resource-scoped**. See the escalation note below — `Resource: "*"` here is not a small difference |
| **Deny** attaching managed policies | everything except `AmazonSSMManagedInstanceCore` | The config attaches exactly one managed policy. An explicit Deny on everything else means `AdministratorAccess` cannot be attached to anything, and explicit Deny beats every Allow |
| **Deny** `sts:AssumeRole` | everything | Terraform assumes nothing once it is running. Denying it means a role created here cannot be entered even if it were given admin |
| `iam:PassRole` | **one role ARN**, and only to `ec2.amazonaws.com` | The verb that turns role-creation into privilege escalation. Pinned to the instance role, passed to nothing but EC2 |
| KMS verbs | account | `CreateKey` cannot be resource-scoped — the key does not exist yet |
| SSM parameters | `/aura/prod/*` only | Cannot read or write anyone else's parameters |
| S3 | the two named buckets | State and backups; nothing else in the account |
| Session Manager | account | The shell, since there is no SSH |

### The escalation this policy had, and the one it still has

The first draft of this policy put every IAM verb on `Resource: "*"`. That is a
**working path to administrator**, not a theoretical one:

1. `iam:CreateRole` a role whose trust policy names you,
2. `iam:AttachRolePolicy` `AdministratorAccess` to it,
3. assume it — and note that step 3 needs **no** `sts:AssumeRole` in your own
   policy, because within one account a role's trust policy alone is sufficient.

Three changes close that: the role verbs are scoped to `aura-prod-*`, attaching
any managed policy other than `AmazonSSMManagedInstanceCore` is explicitly
denied, and `sts:AssumeRole` is explicitly denied outright.

**What remains, stated rather than glossed over.** Terraform legitimately needs
`iam:PutRolePolicy` on `aura-prod-instance` — that is how the instance policy
gets installed — and it needs `iam:PassRole` for that role plus `ec2:*`. So a
holder of this credential can still rewrite the instance role's *inline* policy
to allow everything, launch an instance carrying it, and read credentials from
the metadata service. Scoping cannot fix that; the verbs are ones the deploy
actually requires.

The complete fix is a **permissions boundary**: a managed policy attached to
`aws_iam_role.instance` (`permissions_boundary`), required by a condition on
`CreateRole`/`PutRolePolicy`, capping what the instance role can *ever* be
granted no matter what is written into it. That is roughly thirty lines and one
new prerequisite (the boundary must exist before the first apply). Worth doing
before anything but a solo prototype runs here — ask if you want it.

Keep the honest framing either way: this policy raises the cost of a mistake and
of a compromised session. It does not constrain the account's owner, who also
holds root.

**The KMS block is why this policy is not the one written earlier in this
task.** The backup key (`kms.tf`) arrived after the first draft, and a policy
without those verbs fails *partway through* an apply — after the VPC and the
instance exist, which is the worst place to run out of permissions.

**"Minimal" has a floor here, and pretending otherwise would be dishonest.** A
principal that can create an IAM role and `PassRole` it to EC2 can reach
administrator by construction — it can mint a role with any permissions and
attach it to an instance it controls. This policy buys real guardrails against
*mistakes* (it cannot touch other regions' resources, other people's parameters,
or the organisation), not against a determined attacker holding the credential.
Given that, `AdministratorAccess` on an MFA-protected user is a defensible
alternative for a single-owner account; the policy above is worth using anyway
because it is the difference between "I fat-fingered a command" and "I deleted
something unrelated".

---

## Step 2 — Tooling and the Terraform state bucket

### Terraform — Homebrew, but not from core

HashiCorp relicensed Terraform under the BUSL, so it was removed from
homebrew-core. It comes from HashiCorp's own tap:

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
terraform version                  # must be >= 1.10 (S3-native state locking)
```

(`brew install opentofu` is a drop-in alternative; this configuration is
compatible with it.)

### AWS CLI — the official installer, NOT `brew install awscli`

Use AWS's own package. This is not a preference, it is what worked:

```bash
curl -o AWSCLIV2.pkg https://awscli.amazonaws.com/AWSCLIV2.pkg
sudo installer -pkg AWSCLIV2.pkg -target /
aws --version                      # expect ".. exe/arm64", the bundled build
```

**Why not Homebrew** (found the hard way on 2026-08-18, macOS 26.2): the
`awscli` formula runs on Homebrew's `python@3.14`, whose `pyexpat` module is
linked against the **system** `/usr/lib/libexpat.1.dylib`. The bottle was built
where that library exports `XML_SetAllocTrackerActivationThreshold` (expat
≥ 2.7.2); macOS 26.2 ships an older one, so every single `aws` invocation dies
before it starts:

```
aws: [ERROR]: dlopen(.../pyexpat.cpython-314-darwin.so): Symbol not found:
              _XML_SetAllocTrackerActivationThreshold
```

Nothing local fixes it: the path in the `.so` is absolute, so installing
Homebrew's `expat` does not help, both installed `python@3.14` builds fail
identically, and there is no newer bottle to upgrade to. The official package
carries its own Python and its own expat, which is the entire reason to prefer
it for something a production runbook depends on.

**Without `sudo`** (what was actually done here — the CLI ends up in
`~/aws-cli`, symlinked onto `PATH`):

```bash
cat > choices.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><array><dict>
  <key>choiceAttribute</key><string>customLocation</string>
  <key>attributeSetting</key><string>$HOME</string>
  <key>choiceIdentifier</key><string>default</string>
</dict></array></plist>
EOF
installer -pkg AWSCLIV2.pkg -target CurrentUserHomeDirectory \
  -applyChoiceChangesXML choices.xml
mkdir -p ~/.local/bin
ln -sf ~/aws-cli/aws ~/.local/bin/aws
ln -sf ~/aws-cli/aws_completer ~/.local/bin/aws_completer
```

If `brew install awscli` was already run, remove it — a broken `aws` earlier on
`PATH` shadows the working one: `brew uninstall awscli`.

### The state bucket

Terraform cannot keep its state in a bucket it has not created, so this one is
made by hand, once. **State lives in S3, not on a laptop** — the reasoning is in
`deploy/terraform/README.md`, and it comes straight from this document's own
acceptance: *"the instance can be rebuilt from the runbook without consulting a
session."* Local state means nobody else can plan or rebuild anything, and if
that machine is lost Terraform no longer knows what exists.

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
STATE_BUCKET="aura-prod-tfstate-${ACCOUNT_ID}"

aws s3api create-bucket --bucket "$STATE_BUCKET" --region eu-central-1 \
  --create-bucket-configuration LocationConstraint=eu-central-1
aws s3api put-public-access-block --bucket "$STATE_BUCKET" \
  --public-access-block-configuration \
  'BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true'
aws s3api put-bucket-versioning --bucket "$STATE_BUCKET" \
  --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket "$STATE_BUCKET" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
```

Versioning is what lets you recover a corrupted or half-written state file,
which is otherwise the failure that ends in rebuilding by hand.

**This is a different bucket from the backup bucket (step 8)**, and not by
taste: the backup bucket carries a lifecycle rule expiring objects at 180 days,
which would quietly delete the state file.

No DynamoDB table. S3 locks natively now (`use_lockfile = true`), and
DynamoDB-based locking is deprecated — adding a table to a new setup would be
inheriting a migration.

---

## Step 3 — `terraform apply`

This creates everything on the AWS side: the VPC and its public subnet, the
security group, the IAM role and instance profile, the EC2 instance with its
data volume, the Elastic IP, both Route 53 records, and the handful of
non-secret SSM parameters whose values Terraform is the thing that knows.

It does **not** create secret values, the backup bucket, or the hosted zone —
`deploy/terraform/README.md` says why for each.

```bash
cd /path/to/aura-bff/deploy/terraform

cp backend.hcl.example backend.hcl               && $EDITOR backend.hcl
cp terraform.tfvars.example terraform.tfvars     && $EDITOR terraform.tfvars

terraform init -backend-config=backend.hcl
terraform fmt -check
terraform validate
terraform plan -out=tfplan
```

> **Terraform cannot use a profile with `mfa_serial`, and the error does not
> say so.** It fails with *"assume role with MFA enabled, but
> AssumeRoleTokenProvider session option not set"*. The reason: the AWS CLI is
> Python and caches assumed-role credentials in `~/.aws/cli/cache`; the
> Terraform provider is Go and reads neither that cache nor a terminal, so it
> can neither reuse nor obtain the session. Authenticate once with the CLI in a
> real terminal, then hand the credentials over as environment variables:
>
> ```bash
> aws sts get-caller-identity --profile <profile>          # in a real terminal
> eval "$(aws configure export-credentials --profile <profile> --format env)"
> [ -n "$AWS_SESSION_TOKEN" ] && echo "credentials ok" || echo "STOP: no credentials"
> unset AWS_PROFILE     # env credentials must not be shadowed by a profile
> aws sts get-caller-identity --query Arn --output text    # confirm WHO you are
> ```
>
> This applies to `apply` exactly as much as to `plan`.
>
> **The guard line is not ceremony.** `unset AWS_PROFILE` removes the only thing
> standing between the next command and the `default` profile. If
> `export-credentials` produced nothing — expired session, mistyped profile —
> the unset hands your `terraform apply` to whatever `default` happens to be.
> Check what that is on your machine before you find out during an apply.

**Read the plan.** Expect **33 resources to add, 0 to change, 0 to destroy**
(31 without the two Route 53 records, i.e. `manage_dns = false`). Check
specifically that `aws_instance.host` shows `ami` resolved to a real id,
`instance_type = t4g.large`, and `metadata_options` with
`http_tokens = "required"` and `http_put_response_hop_limit = 1`.

A read-only `plan` of this configuration was run on 2026-08-18 and passed with
no warnings, resolving `ami-0c355ec49d386672d` — the real arm64 Ubuntu 24.04
image in `eu-central-1`. So the HCL is proven as far as a plan can prove it;
what remains untested is what only an apply exercises: quotas, IAM gaps on
create, and first-boot behaviour.

```bash
terraform apply tfplan
terraform output
```

### Why `--metadata-options` is load-bearing, not boilerplate

Do not relax either setting.

The stack sets `SAFE_FETCH_ALLOW_PRIVATE_NETWORK=true` on Chatwoot, because the
BFF has no public address and the inbox webhook points at `http://bff:3000` over
the Docker network — an address Chatwoot's SSRF filter otherwise refuses. That
flag is instance-wide: it turns off SSRF filtering for every outgoing fetch
Chatwoot makes, so a Chatwoot administrator could point a webhook or an avatar
URL at the EC2 metadata endpoint.

These two close it:

- **Hop limit 1** — a packet from inside a container crosses the Docker bridge,
  which costs a hop, so a container cannot reach `169.254.169.254` **at all**.
- **IMDSv2 required** — credentials need a PUT to obtain a token first. A plain
  GET, which is all an SSRF produces, gets nothing even from the host.

This is also why `backup.sh` and `pull-secrets.sh` run on the host under systemd
and never in a container: the host still has its one hop.

Verify it after step 5 opens a shell — this must **fail**, and its failing is
the check:

```bash
docker run --rm --network host curlimages/curl -s --max-time 3 \
  http://169.254.169.254/latest/meta-data/ ; echo "exit=$?"
```

### DNS

There are two ways to run DNS, and the choice changes the ordering of the whole
deploy. Decide it before `apply`.

**Delegating to Route 53 (recommended).** Terraform then creates both A records
in the *same* apply that allocates the Elastic IP, so there is no manual step
and no window where the host exists but its names do not. It also means a
rebuild re-points DNS by itself. Costs about $0.50/month for the zone.

The hosted zone must exist *before* `apply` — Terraform looks it up and
deliberately never creates it, so that a `destroy` cannot take the zone with it.
Do this once, early: delegation propagates while you work on other steps.

```bash
aws route53 create-hosted-zone --name <domain> --caller-reference "$(date +%s)"
aws route53 get-hosted-zone --id <id> --query 'DelegationSet.NameServers' --output text
```

Put those four nameservers into the registrar's "custom nameservers" field,
then wait until delegation is live — this is the check, and it is not optional:

```bash
dig +short NS <domain>       # must answer awsdns-*, not the registrar's
```

Only then set `manage_dns = true` and run `apply`.

**Keeping the registrar's DNS.** Leave `manage_dns = false` and create two A
records by hand *after* `apply`, pointing at the `public_ip` output. Nothing
else changes. The cost is that the ordering acquires a manual step in the
middle, and a rebuilt host needs the records checked again.

**Either way, both names must resolve before step 5.** Caddy requests
certificates the moment the stack starts; a name that does not resolve fails the
ACME challenge and then backs off, so you get a host serving nothing over a
protocol the app refuses to speak.

Terraform created both A records at TTL 60, pointing at the Elastic IP. Confirm
they resolve before the host's first `compose up` — Caddy asks Let's Encrypt for
certificates at startup, and a name that does not resolve yet fails the
challenge and backs off, leaving you waiting on a retry timer rather than
debugging anything.

```bash
dig +short bff.example.com
dig +short chat.example.com
```

If `manage_dns = false` (the domain is not in Route 53), create the two A
records at your registrar now, pointing at the `public_ip` output.

### Two behaviours that will surprise you, and should

- **Editing `cloud-init.yaml` does not re-provision the host.** cloud-init's
  `runcmd` only runs on first boot, so Terraform is deliberately configured not
  to replace the instance on a `user_data` change — otherwise a config edit
  would take production down. Applying an edit is a deliberate rebuild:
  `terraform apply -replace=aws_instance.host`.
- **A newer Ubuntu AMI does not silently replace the instance.**
  `ignore_changes = [ami]`. Otherwise an apply run to change a DNS record would
  propose destroying production to rebuild it on a newer image.

---

## Step 4 — Secrets into SSM Parameter Store

**The mechanism, and why.** Every secret lives as a `SecureString` parameter
under `/aura/prod/`; `deploy/bin/pull-secrets.sh` renders them into root-owned
`0600` files under `/srv/aura/secrets/`. Nothing is in git.

SSM rather than Secrets Manager: identical KMS envelope and IAM story, and
standard parameters are free where Secrets Manager bills per secret per month —
about twenty here. SSM rather than hand-editing the files on the box: a value
that exists only on one instance dies with it, which defeats the whole point of
putting the data on its own volume. SSM keeps the set recoverable, versioned,
and auditable through CloudTrail.

**Terraform has already written some of these, and you must not re-write them
by hand.** It owns exactly the parameters whose value is a fact about the
infrastructure it built — `BFF_HOSTNAME`, `CHATWOOT_HOSTNAME`,
`AURA_BACKUP_BUCKET`, and the three `AURA_*_DIR` paths — so the host cannot
disagree with what was actually created. `terraform output
terraform_managed_parameters` lists them; change the variable and re-apply, not
the parameter.

**Terraform writes no `SecureString`, ever.** `aws_ssm_parameter` keeps `value`
in state and reads it back decrypted on every refresh, so one managed secret
would put the Chatwoot service token, the Firebase private key and the Play
service-account key into the state file in the clear — and into the state
bucket's version history permanently. Every secret below is yours, through one
`put-parameter` call that persists nothing anywhere else.
`terraform output required_secret_parameters` prints exactly what is still
owed.

### What exists, and who produces it

| Parameter (under `/aura/prod/`) | Who sets it | Where it comes from |
|---|---|---|
| `stack/BFF_HOSTNAME`, `stack/CHATWOOT_HOSTNAME`, `stack/AURA_BACKUP_BUCKET`, `stack/AURA_*_DIR` | **Terraform** | written in step 3 from the tfvars. Do not edit by hand — change the variable and re-apply |
| `stack/ACME_EMAIL` | owner | a mailbox someone reads; Let's Encrypt expiry notices go there |
| `stack/BFF_POSTGRES_PASSWORD`, `stack/BFF_REDIS_PASSWORD`, `stack/CW_POSTGRES_PASSWORD`, `stack/CW_REDIS_PASSWORD` | owner | `openssl rand -hex 24`, once each |
| `stack/*_IMAGE`, `stack/BFF_VERSION` | owner | copy from `deploy/env/stack.env.example` |
| `bff/FIREBASE_PROJECT_ID`, `bff/FIREBASE_CLIENT_EMAIL`, `bff/FIREBASE_PRIVATE_KEY` | owner | Firebase console → service account JSON |
| `bff/ADVISOR_ASSETS_BASE_URL` | owner | the avatar bucket (`AURAT-0013`) |
| `bff/CHATWOOT_ACCOUNT_ID`, `bff/CHATWOOT_INBOX_ID`, `bff/CHATWOOT_INBOX_IDENTIFIER`, `bff/CHATWOOT_API_ACCESS_TOKEN`, `bff/CHATWOOT_WEBHOOK_SECRET` | **step 6's script** | production Chatwoot, not dev. Set *after* the first boot, so they are the one group you cannot pre-load |
| `bff/BILLING_ENABLED` | owner | `false` at first deploy — see step 11 |
| `bff/GOOGLE_PLAY_PACKAGE_NAME`, `bff/GOOGLE_PLAY_SERVICE_ACCOUNT_EMAIL`, `bff/GOOGLE_PLAY_SERVICE_ACCOUNT_KEY` | owner | `AURAS-0002` step 7. **Required together once `BILLING_ENABLED=true` in production — the BFF refuses to boot without them, on purpose** |
| `chatwoot/SECRET_KEY_BASE` | owner | `openssl rand -hex 64`, once, **never regenerated** |
| `chatwoot/ACTIVE_RECORD_ENCRYPTION_*` (3) | owner | `rails db:encryption:init`, step 5 |
| `chatwoot/ENABLE_ACCOUNT_SIGNUP`, `chatwoot/FORCE_SSL`, `chatwoot/SAFE_FETCH_ALLOW_PRIVATE_NETWORK`, `chatwoot/ACTIVE_STORAGE_SERVICE`, … | owner | copy from `deploy/env/chatwoot.env.example`, which explains each |

`deploy/env/*.example` is the authoritative list — it carries a comment per
value. This table is the ownership view of it.

### Loading them

```bash
put() { aws ssm put-parameter --name "/aura/prod/$1" --type SecureString \
          --value "$2" --overwrite >/dev/null && echo "  set $1"; }

# NOT here: BFF_HOSTNAME, CHATWOOT_HOSTNAME, AURA_BACKUP_BUCKET, AURA_*_DIR —
# Terraform owns those (step 3).
put stack/ACME_EMAIL          ops@example.com
put stack/BFF_POSTGRES_PASSWORD "$(openssl rand -hex 24)"
put stack/BFF_REDIS_PASSWORD    "$(openssl rand -hex 24)"
put stack/CW_POSTGRES_PASSWORD  "$(openssl rand -hex 24)"
put stack/CW_REDIS_PASSWORD     "$(openssl rand -hex 24)"
put chatwoot/SECRET_KEY_BASE    "$(openssl rand -hex 64)"
# ... and the rest, from deploy/env/*.example
```

`SECRET_KEY_BASE` signs cookies and encrypts stored credentials. Changing it
invalidates every session and makes anything encrypted under the old value
unreadable — generate it once and leave it alone, including when rebuilding
the host.

---

## Step 5 — First apply on the host

Open a shell on the instance (no SSH port, no key):

```bash
aws ssm start-session --target "$INSTANCE_ID"
sudo -i
```

Confirm cloud-init finished and the data volume is mounted where it should be:

```bash
cloud-init status --wait
findmnt /srv/aura          # must show the 50G volume, not the root disk
ls -la /srv/aura           # the directories, owned 999/1000 as cloud-init set them
```

If `findmnt` shows nothing, **stop.** Everything below will write to the root
volume and the next instance rebuild will lose it.

```bash
cd /opt/aura/aura-bff
./deploy/bin/pull-secrets.sh          # SSM -> /srv/aura/secrets/*.env
./deploy/bin/compose.sh config >/dev/null && echo "compose OK"
```

Chatwoot's Active Record encryption keys have to be generated by Chatwoot
itself, which needs the image but not the database:

```bash
./deploy/bin/compose.sh run --rm chatwoot-rails bundle exec rails db:encryption:init
# put the three printed keys into SSM under /aura/prod/chatwoot/, then:
./deploy/bin/pull-secrets.sh
```

Create Chatwoot's schema (once, on an empty database), then start everything:

```bash
./deploy/bin/compose.sh run --rm chatwoot-rails bundle exec rails db:chatwoot_prepare
./deploy/bin/compose.sh up -d
./deploy/bin/compose.sh ps
```

Expect the first `up` to take several minutes: images pull, Chatwoot's
entrypoint runs `bundle check`, and Caddy negotiates two certificates. The BFF
runs its Prisma migrations in the separate `bff-migrate` container and only
starts once that exits 0 — so if `bff` never starts, read `bff-migrate`'s log
first.

```bash
./deploy/bin/compose.sh logs -f caddy      # certificate issuance
./deploy/bin/compose.sh logs bff-migrate   # migrations
./deploy/bin/compose.sh logs -f bff
```

---

## Step 6 — Production's own Chatwoot environment

`AURAD-0005` requires **one `Channel::Api` inbox per environment**. Production
gets its own account, service User, inbox, identifier, hmac token, secret and
Agent Bot. Reusing dev's would put real users and test traffic in the same
conversation list on the same credentials, and rotating dev's would take
production down.

```bash
cd /opt/aura/aura-bff
./deploy/bin/compose.sh exec -T chatwoot-rails \
  bundle exec rails runner - < deploy/chatwoot/provision-prod.rb
```

It prints one line, `AURA_CHATWOOT_JSON:{...}`, whose keys are exactly the
`CHATWOOT_*` parameter names. **That output is secret** — put the values into
SSM and clear your scrollback.

```bash
put bff/CHATWOOT_ACCOUNT_ID        <account_id>
put bff/CHATWOOT_INBOX_ID          <inbox_id>
put bff/CHATWOOT_INBOX_IDENTIFIER  <inbox_identifier>
put bff/CHATWOOT_API_ACCESS_TOKEN  <service user token>
put bff/CHATWOOT_WEBHOOK_SECRET    <channel secret>

./deploy/bin/pull-secrets.sh
./deploy/bin/compose.sh up -d bff
```

The script is idempotent — re-running it creates nothing that exists and
re-prints the same values, and it repairs the webhook URL if it has drifted.

### A chatter to answer with

Production has no SMTP configured (see `deploy/env/chatwoot.env.example`), so
invitations by email do not arrive and **nobody can reset a password**. Create
the first human agent from the console instead:

```bash
./deploy/bin/compose.sh exec -T chatwoot-rails bundle exec rails runner "
  acc = Account.find_by(name: 'Aura')
  u = User.create!(name: 'Chatter One', email: 'chatter1@example.com',
                   password: 'ChangeMe1!', confirmed_at: Time.current)
  AccountUser.create!(account: acc, user: u, role: :agent)
  InboxMember.create!(inbox: Inbox.find_by(name: 'Aura (prod)'), user: u)
  puts 'created'
"
```

`role: :agent`, not `:administrator` — administrators can configure webhooks,
and with the SSRF guard relaxed that is the surface worth keeping small.
Have them change the password at first login. Configure SES and remove this
recipe the moment chatters are onboarded at any real rate.

---

## Step 7 — Verify

From **your machine**, not the instance:

```bash
# 1. TLS on both names, with a real certificate.
curl -sS -o /dev/null -w '%{http_code} %{ssl_verify_result}\n' https://bff.example.com/health
curl -sS -o /dev/null -w '%{http_code}\n' https://chat.example.com/

# 2. http redirects rather than serving.
curl -sS -o /dev/null -w '%{http_code}\n' http://bff.example.com/health   # 308

# 3. Readiness: Postgres and Redis both answering.
curl -sS https://bff.example.com/health/ready

# 4. NOTHING else is reachable. All four must fail to connect.
#    This is stated twice in the design and should be true twice over: the
#    databases publish no host port at all (compose puts them on internal
#    networks), AND the security group has no rule for them.
for p in 5432 6379 3000 3001; do
  nc -z -w3 bff.example.com $p && echo "OPEN $p  <-- FAIL" || echo "closed $p"
done
```

```bash
# 4b. The same claim from the AWS side rather than from the network: the
#     security group should list exactly six ingress rules, all 80/443.
aws ec2 describe-security-group-rules \
  --filters "Name=group-id,Values=$(cd deploy/terraform && terraform output -raw security_group_id)" \
  --query 'SecurityGroupRules[?IsEgress==`false`].[IpProtocol,FromPort,ToPort,CidrIpv4,CidrIpv6]' \
  --output table
```

Then the loop that actually matters:

5. Point a device build at `https://bff.example.com` (`AURAT-0028`'s `prod`
   target, whose `env/.env.prod` was deliberately empty until now) and send a
   message.
6. Log into `https://chat.example.com` as the chatter from step 6. The message
   is in the **`Aura (prod)`** inbox. Reply.
7. **The reply arrives in the app.** This is the one that proves the internal
   webhook: Chatwoot posted to `http://bff:3000/webhooks/chatwoot` over the
   Docker network, the signature verified, the message was stored and pushed.

If step 7 fails and the dashboard shows *"Failed to send · Hostname has no
public ip addresses"*, `SAFE_FETCH_ALLOW_PRIVATE_NETWORK` did not reach the
rails **and sidekiq** containers. Check both:

```bash
./deploy/bin/compose.sh exec chatwoot-sidekiq env | grep SAFE_FETCH
```

---

## Step 8 — Backups

Two databases, and both are unrecoverable if lost: the BFF's holds the wallet
and the append-only ledger, Chatwoot's holds every consultation ever had.
Chatwoot's uploaded attachments live on the filesystem and are in **neither**
dump, so `backup.sh` syncs them separately.

```bash
aws s3api create-bucket --bucket "$BUCKET" \
  --create-bucket-configuration LocationConstraint=eu-central-1
aws s3api put-public-access-block --bucket "$BUCKET" \
  --public-access-block-configuration \
  'BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true'
aws s3api put-bucket-versioning --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled
# Default encryption is the customer-managed KMS key Terraform created, NOT
# SSE-S3. This is the difference between "read-only cannot open a backup" and
# "read-only can read every consultation and the money ledger": SSE-S3 decrypts
# transparently for anything holding s3:GetObject, and s3:Get* is part of the
# AWS-managed ReadOnlyAccess policy. With SSE-KMS, opening an object also needs
# kms:Decrypt on this key — which ReadOnlyAccess does not grant and the instance
# role does.
#
# BucketKeyEnabled collapses KMS requests to roughly one per upload session
# instead of one per object, which matters for Chatwoot's attachment sync.
KMS_ARN=$(cd /path/to/aura-bff/deploy/terraform && terraform output -raw backup_kms_key_arn)

aws s3api put-bucket-encryption --bucket "$BUCKET" \
  --server-side-encryption-configuration "$(cat <<JSON
{"Rules":[{"ApplyServerSideEncryptionByDefault":
  {"SSEAlgorithm":"aws:kms","KMSMasterKeyID":"${KMS_ARN}"},
  "BucketKeyEnabled":true}]}
JSON
)"

cat >/tmp/lifecycle.json <<'EOF'
{ "Rules": [
  { "ID": "expire-daily-dumps", "Status": "Enabled",
    "Filter": { "Prefix": "" },
    "Transitions": [{ "Days": 30, "StorageClass": "STANDARD_IA" }],
    "Expiration": { "Days": 180 },
    "NoncurrentVersionExpiration": { "NoncurrentDays": 30 } } ] }
EOF
aws s3api put-bucket-lifecycle-configuration --bucket "$BUCKET" \
  --lifecycle-configuration file:///tmp/lifecycle.json
```

Versioning plus a role with no `DeleteObject` means neither a compromised host
nor a bug in `backup.sh` can destroy history; expiry is the service's job.

`backup.sh` and `restore-check.sh` need no change for the KMS key: `aws s3 cp`
and `aws s3 sync` apply the bucket's default encryption on the way in and
decrypt transparently on the way out, given the `kms:Decrypt` the instance role
now holds.

> **The key is the backups.** If `alias/aura-prod-backups` is ever deleted,
> every object encrypted under it becomes permanently unreadable — not
> recoverable from AWS, not from bucket versioning. Terraform marks it
> `prevent_destroy` with a 30-day deletion window for exactly that reason.

`/aura/prod/stack/AURA_BACKUP_BUCKET` is **already set** — Terraform wrote it
from `var.backup_bucket_name` in step 3, which is the same name it granted the
instance role on. If you used a different name here, change the variable and
re-apply rather than editing the parameter; a mismatch means the role has no
access to the bucket the script writes to.

On the instance:

```bash
sudo /opt/aura/aura-bff/deploy/bin/pull-secrets.sh
sudo systemctl enable --now aura-backup.timer
sudo systemctl list-timers aura-backup.timer
sudo /opt/aura/aura-bff/deploy/bin/backup.sh    # run one now, do not wait for 03:15
aws s3 ls "s3://$BUCKET/" --recursive
```

`backup.sh` verifies each dump with `pg_restore -l` **before** uploading, and
refuses to upload one that does not parse. A truncated dump sitting in the
bucket is worse than no dump: it looks like a backup in a listing.

---

## Step 9 — The restore drill *(this is the acceptance criterion)*

A backup nobody has restored is a belief. `AURAT-0027` made `ledger_entries`
append-only at the database; that guarantee is worth nothing behind a restore
that has never run, and the first time you would find out is the day it is the
only copy left.

```bash
sudo /opt/aura/aura-bff/deploy/bin/restore-check.sh
```

It downloads the newest BFF dump, restores it into a **scratch** database in
the same Postgres container (the live database is never written to), and checks
five things that each fail differently:

1. every table is present, with row counts consistent with live;
2. **`balanceMinor` equals `SUM(ledger_entries.amountMinor)` on every wallet** —
   if a restored wallet disagrees with its own ledger, the backup cannot be
   trusted with money;
3. the `ledger_entries` append-only trigger exists **and fires** — it attempts
   an `UPDATE` and requires it to be refused, because present-but-not-firing is
   the failure a count cannot see;
4. the `sessions` no-overlap exclusion constraint survived (it needs the
   `btree_gist` extension to exist in the restored database at all);
5. `_prisma_migrations` came back, so a restored database can be deployed onto
   rather than being a dead end.

It drops the scratch database on the way out, including on failure.

**Paste the printed block into the log at the bottom of this file.** A drill
whose result was not written down did not happen. Re-run it quarterly and after
any Postgres version change.

---

## Step 10 — Deploying a new version

```bash
sudo /opt/aura/aura-bff/deploy/bin/deploy.sh                 # origin/develop
sudo /opt/aura/aura-bff/deploy/bin/deploy.sh v0.2.0          # a tag
sudo /opt/aura/aura-bff/deploy/bin/deploy.sh <short-sha>     # roll back
```

It fetches, checks out, rebuilds only the BFF, runs migrations in their own
container, restarts the app, and waits for `/health/ready` — failing loudly
with the rollback command if readiness does not arrive within a minute.

Only the BFF moves. Chatwoot, Postgres, Redis and Caddy are pinned images:
upgrading Chatwoot is a separate, deliberate act — change `stack/CHATWOOT_IMAGE`
in SSM, `pull-secrets.sh`, then `compose.sh up -d`. **Back up first** (step 8);
Chatwoot upgrades run migrations of their own and are not reversible.

A migration that fails leaves the previous version serving, because `bff` is
only restarted after `bff-migrate` exits 0.

---

## Step 11 — Turning billing on

Deploy first with `BILLING_ENABLED=false`. When `AURAS-0002` step 7 has
produced the Play service account:

```bash
put bff/GOOGLE_PLAY_PACKAGE_NAME           com.example.aura
put bff/GOOGLE_PLAY_SERVICE_ACCOUNT_EMAIL  play-api@<project>.iam.gserviceaccount.com
put bff/GOOGLE_PLAY_SERVICE_ACCOUNT_KEY    "$(cat key.pem)"
put bff/BILLING_ENABLED                    true
sudo /opt/aura/aura-bff/deploy/bin/pull-secrets.sh
sudo /opt/aura/aura-bff/deploy/bin/compose.sh up -d bff
```

If any of the three is missing, **the BFF will refuse to boot** and say so.
That is deliberate: the fallback is the dev verifier, and a fake verifier that
credits real money is the one unrecoverable mistake `AURAD-0010` exists to
prevent. If the container will not start after flipping the flag, read the
config-validation error before assuming anything else broke.

On the first real purchase, check that Google returns
`obfuscatedExternalAccountId` — the "user A cannot redeem user B's token"
guarantee rests on that field arriving (`TECH-DEBT #17`).

---

## Rebuilding the host from nothing

This is the claim the whole design makes, so it is a procedure rather than an
assumption. Since the infrastructure is Terraform, it is one command:

```bash
cd /path/to/aura-bff/deploy/terraform
terraform apply -replace=aws_instance.host
```

What survives, and why you can rely on it:

- **The data volume.** `prevent_destroy` on `aws_ebs_volume.data` makes any plan
  that would remove it fail instead of succeeding quietly. The attachment is
  re-made against the new instance, and `cloud-init.yaml` gates formatting on
  `blkid` — an already-formatted volume is mounted, never reformatted.
- **The Elastic IP**, also `prevent_destroy`. DNS does not change, so the app's
  compiled-in prod origin and any Pub/Sub push subscription keep working.
- **Caddy's certificates**, which live on the data volume — no re-issue, no
  Let's Encrypt rate limit.

Then continue at **step 5**: `pull-secrets.sh`, `compose.sh up -d`. Skip
`db:chatwoot_prepare` and `provision-prod.rb` — the databases are the old ones.
Re-run `provision-prod.rb` only if you need the inbox values reprinted; it is
idempotent and will not create a second inbox.

This is also the reason the state is in S3 and not on one laptop: the command
above only works for someone who can read the state.

If the **volume** is gone too, restore from S3 instead: bring up an empty stack,
`pg_restore` each dump into its database, and `aws s3 sync` the
`chatwoot-storage/` prefix back into `/srv/aura/chatwoot-storage`.

---

## When it breaks

| Symptom | First thing to check |
|---|---|
| Caddy has no certificate | Do both names resolve to the EIP? Is port 80 open? `compose.sh logs caddy` |
| `bff` never starts | `compose.sh logs bff-migrate` — the app waits on migrations exiting 0 |
| BFF exits immediately with a list of variable names | Config validation. A parameter is missing from SSM or `pull-secrets.sh` was not re-run |
| Agent replies show "Failed to send · Hostname has no public ip addresses" | `SAFE_FETCH_ALLOW_PRIVATE_NETWORK` missing on rails **or** sidekiq |
| App gets 429s under light load | `trustProxy` regression — every device would be sharing one rate-limit budget (`src/fastify.options.ts`) |
| Disk full | `df -h /srv/aura`. Log rotation is capped in `/etc/docker/daemon.json`; the usual growth is Postgres or Chatwoot attachments |
| Everything is slow, nothing is broken | `free -m` — 8 GiB is the honest minimum. Check the swapfile is on |
| Need a shell | `aws ssm start-session --target <instance-id>`. There is no SSH |
| `AssumeRole` fails: *"MultiFactorAuthentication failed, unable to validate MFA code"* | Read the **second** sentence, not the first — the code is usually fine and the `mfa_serial` is wrong. It must match the device's **Identifier** in IAM → Users → Security credentials exactly, and that string carries the *device name you chose*, e.g. `.../mfa/iphone`, not the user name. An MFA device cannot be renamed; fix the profile, or remove and re-add the device |
| `aws` dies with `dlopen ... pyexpat ... Symbol not found` | The Homebrew `awscli` formula on a macOS whose system libexpat is older than the bottle expects. Not fixable locally — install the official package instead (step 2) |

Logs: `compose.sh logs -f <service>`, or `journalctl -u aura-backup` for
backups.

---

## What this deliberately does not do

- **No Kubernetes** (`AURAD-0005`). Revisit when an uptime requirement makes a
  rolling deploy necessary; that is also when to consider managed Postgres.
- **No CI/CD.** Deploys are `deploy.sh` on the box.
- **No multi-AZ, no autoscaling, no read replica.** One instance, one AZ. A
  failure means `terraform apply -replace` and the last backup, and the restore
  drill is what makes that a known quantity rather than a hope.
- **Terraform covers the AWS resources only** — network, IAM, instance, volume,
  DNS, non-secret parameters. What runs *inside* the machine stays in
  cloud-init and `deploy/`, and is not reimplemented in HCL.
  **Caveat that applies to this whole document:** none of it has been applied
  against a real AWS account, so the HCL is reviewed but unproven. `terraform
  validate` and reading the first `plan` (step 3) are what stand in for that —
  do not skip either.
- **No SMTP.** See step 6.
- **iOS is untouched.** The hostnames satisfy ATS, but nothing here builds or
  ships an iOS app.

---

## Restore drill log

Fill this in from step 9. Empty means the acceptance criterion of `AURAT-0029`
is **not** met, regardless of what is running.

| Date | Backup restored | Result | Run by | Notes |
|---|---|---|---|---|
| — | — | *not yet run* | — | The first apply has not happened |
