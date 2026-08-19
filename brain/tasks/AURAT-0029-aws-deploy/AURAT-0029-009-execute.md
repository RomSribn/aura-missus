# AURAT-0029-009 — Execute: `deploy/terraform/`

Date: 2026-08-18
Slave: `aura-bff-manor` / **slave-1**, branch `feature/AURAT-0029-aws-deploy`.
Staged, **not committed** — awaiting IDE review.

Additive. Nothing from `007-execute.md` was rewritten: the compose file, the
Caddyfile, the three env templates, `provision-prod.rb`, the five host scripts
and the systemd units are untouched. `cloud-init.yaml` gained one thing
(below). The runbook was renumbered, because Terraform replaced four of its
steps with one.

---

## D5 · State lives in S3, with S3-native locking — no DynamoDB

The owner's second constraint, answered.

**Local state was rejected on the spec's own terms.** `AURAT-0029`'s acceptance
includes *"the instance can be rebuilt from the runbook without consulting a
session"*, and a state file on one laptop defeats that twice: nobody else can
plan or rebuild anything, and if that machine is lost Terraform no longer knows
what exists — the rebuild becomes archaeology against the console, on the day
you can least afford it. It would make the runbook a document about a machine
only one person can drive, which is the failure mode this whole task exists to
avoid.

**No DynamoDB**: S3 now locks natively (`use_lockfile = true`) and
DynamoDB-based locking is deprecated in current Terraform. Creating a table for
it in a brand-new setup would be inheriting a migration.

Two consequences written into the artifacts:

- **The state bucket is separate from the backup bucket**, and not by taste:
  the backup bucket carries a lifecycle rule expiring objects at 180 days,
  which would quietly delete the state file.
- **The state bucket is created by hand, once**, before the first `init` —
  Terraform cannot keep state in a bucket it has not created. Four commands, in
  `AURAS-0003` step 2. It is versioned, which is what allows recovery from a
  corrupted or half-written state file.

Backend config is **partial** (`backend "s3" {}` + `backend.hcl`), so no tracked
file names one particular AWS account.

## D6 · Terraform writes no `SecureString`, and the split that replaces it

The owner's first constraint, answered — and the reason is worth being exact
about, because "create at most the structure" has a trap in it.

`aws_ssm_parameter` stores `value` in state **and reads it back decrypted on
every refresh**. So the obvious version of "structure only" — create the
parameter with a placeholder and `ignore_changes = [value]` — does not work: the
next `terraform refresh` pulls the owner's real Chatwoot service token, Firebase
private key and Play service-account key into the state file in the clear, and
from there into the state bucket's version history permanently. Encrypting the
bucket does not help; anyone who can run `terraform show` reads them.

So the split is by **who knows the value**, not by who typed it first:

| | |
|---|---|
| **Terraform writes** | values that are facts about the infrastructure it built: `BFF_HOSTNAME`, `CHATWOOT_HOSTNAME` (it created the Route 53 records), `AURA_BACKUP_BUCKET` (it granted the role on it), the three `AURA_*_DIR` paths. Type `String`. None is secret — all are already in the clear in `stack.env.example` |
| **The owner writes** | every secret, via `aws ssm put-parameter --type SecureString`. The value passes through one command and is persisted by nothing in this repository |

This is better than a documentation-only list, which is what "structure" would
otherwise have meant: it removes a real class of bug where the hostname in SSM
and the hostname in the DNS record drift apart. And the checklist survives —
`terraform output required_secret_parameters` prints the 32 names still owed,
so the owner is not reading a table to find out what is missing.

> Terraform 1.11's write-only arguments (`value_wo`) were considered and
> rejected: they keep the value out of state, but it still has to reach
> Terraform from a tfvars file or an environment variable — moving the secret
> onto the operator's disk rather than removing it. `put-parameter` is a shorter
> path with no state at all.

## D7 · The account guard

`~/.aws` on this machine carries an SSO profile for an unrelated organisation.
Building Aura's production stack inside someone else's AWS account has no
partial version and no clean undo, so it is guarded twice:

1. `provider.allowed_account_ids = [var.aws_account_id]` — the provider refuses
   to make **any** call if the resolved credentials belong elsewhere. This is
   the real guard.
2. `var.forbidden_account_ids`, set in the gitignored `terraform.tfvars` — a
   typo-catcher for the case where `aws_account_id` is itself wrong.

**No account id is written in any tracked file**, here or in the config. That
started as tidiness and became necessary: `aura-missus` is a **public** GitHub
repository (checked, 2026-08-18), so a number in this file is a published
number. See `010-fix-public-brain-and-kms.md`.

Requested profile name: **`aura-prod`** — the default of `var.aws_profile`, the
value in `backend.hcl.example`, and what the runbook exports, so nothing has to
be passed on a command line.

---

## What was built

`aura-bff/deploy/terraform/` — 9 `.tf` files, 21 resource blocks expanding to
about 25 resources.

| File | Contents |
|---|---|
| `versions.tf` | `required_version >= 1.10` (for `use_lockfile`), AWS provider `~> 6.0`, partial S3 backend |
| `providers.tf` | region, profile, **`allowed_account_ids`**, default tags |
| `variables.tf` | 21 variables, each with a reason; validations on account id, architecture, DNS |
| `network.tf` | VPC, public subnet, IGW, route table, security group + the ingress table |
| `compute.tf` | instance, AMI lookup, `metadata_options`, data volume, EIP |
| `iam.tf` | role, policy, instance profile |
| `dns.tf` | two A records in a looked-up zone |
| `ssm.tf` | the six non-secret parameters, and the 32-name checklist |
| `outputs.tf` | 9 outputs, including `required_secret_parameters` and `security_group_id` |

Plus `README.md`, `terraform.tfvars.example`, `backend.hcl.example`.

### Decisions inside the config that will otherwise surprise someone

- **`user_data = file("../bootstrap/cloud-init.yaml")`** — the same file, not a
  copy and not reimplemented in HCL. One description of the boot sequence.
- **`user_data_replace_on_change` left at `false`.** Editing cloud-init then
  updates the attribute without destroying the instance. Deliberate: cloud-init's
  `runcmd` only runs on first boot, so a replacement would be the only way to
  apply an edit — and doing that automatically on a config change would take
  production down. Rebuilding is `terraform apply -replace=aws_instance.host`.
- **`lifecycle { ignore_changes = [ami] }`** on the instance. Canonical
  publishes new AMIs constantly; without it, an apply run to change a DNS record
  would propose destroying production to rebuild it on a newer image.
- **`prevent_destroy` on the data volume and the Elastic IP.** The volume is the
  entire point of the disposable-instance design; the address is baked into two
  DNS records, the app's compiled-in prod origin (`AURAT-0028`) and a future
  Pub/Sub push subscription. `terraform destroy` fails on both, on purpose.
- **`stop_instance_before_detaching`** on the volume attachment — never yank a
  mounted filesystem out from under two running Postgres instances.
- **`map_public_ip_on_launch = false`** + an Elastic IP. Assigning both would
  swap the address moments into boot, which is exactly when cloud-init runs apt.
- **Egress is open**, and that is a decision: the host must reach Firebase, FCM,
  the Play API, Let's Encrypt, Docker Hub, Ubuntu's archives, SSM and S3.
  Enumerating those as CIDRs is a list that rots silently and takes the service
  down when a provider renumbers.
- **The security group states the acceptance criterion in the negative.** There
  is no rule for 5432, 6379 or 22, and the file says so where the rules are. The
  databases are unreachable **twice over** — they publish no host port at all
  (compose puts them on `internal: true` networks) and the SG has no rule
  either. `AURAS-0003` step 7 now checks both: a port probe from outside, and
  `describe-security-group-rules` from the AWS side.
- **`metadata_options`** moved here from the CLI command, with the reasoning
  intact: IMDSv2 required and hop limit 1 are what pay for
  `SAFE_FETCH_ALLOW_PRIVATE_NETWORK` being on.

### The one change to an existing `deploy/` file

`cloud-init.yaml` gained a `bootcmd` that waits (bounded, 2 minutes) for
outbound connectivity before `package_update` runs. Forced by the Terraform
topology: with `map_public_ip_on_launch = false`, egress arrives when the EIP is
associated. That is normally seconds after "running" and well before apt — but
if it were ever late, `package_update` fails, **cloud-init does not retry it**,
and the failure surfaces much later as `docker: command not found`. Eight lines
against a first-apply failure that would look like something else entirely.

Its header comment now also records that editing the file does not re-provision
a running host.

## Runbook changes (`AURAS-0003`)

Four CLI steps became one Terraform step, so the sections were renumbered:

| Was | Now |
|---|---|
| 1 Account guardrails | **1** Account guardrails, the IAM user, and the profile *(extended: profile name, the `devqa-profile` warning, a scoped IAM policy)* |
| — | **2** Tooling and the Terraform state bucket *(new)* |
| 2 Security group · 3 Instance role · 4 Instance/volume/EIP · 5 DNS | **3** `terraform apply` |
| 6 Secrets | **4** *(now says which parameters Terraform already owns)* |
| 7 First apply | **5** |
| 8 Chatwoot environment | **6** |
| 9 Verify | **7** *(gained the security-group-side check)* |
| 10 Backups | **8** *(no longer sets `AURA_BACKUP_BUCKET` by hand)* |
| 11 Restore drill | **9** |
| 12 Deploy a new version | **10** |
| 13 Billing on | **11** |

"Rebuilding the host from nothing" became one command. "What this deliberately
does not do" lost its **No Terraform** bullet and gained the honest caveat that
none of this has been applied against a real account.

Cross-references were repointed throughout — including the four step numbers
cited in `007-execute.md`, which would otherwise now point at the wrong
sections. That file's prose is untouched; only the numbers moved.

## Also updated

- `deploy/README.md` — the tree, and a new "the two layers, and the line between
  them" section.
- `aura-bff/README.md` — the deploy section names both layers.
- `.gitignore` — `.terraform/`, `*.tfstate*`, `terraform.tfvars`, `backend.hcl`.
  **`.terraform.lock.hcl` is deliberately NOT ignored**: the provider versions
  actually applied are part of the deployment, and a per-machine lock file is
  how two operators plan different infrastructure from the same commit.

## Verified here

- `lint`, `typecheck`, `build`, `jest` — unchanged and green (**402 tests**). No
  `src/` file was touched by this step.
- Brace/bracket/paren balance across all 9 `.tf` files; resource inventory
  matches the ~25 the runbook tells the owner to expect in the plan.
- `.gitignore` does not swallow `.terraform.lock.hcl`.
- Provider version and the S3 backend's native locking were checked against the
  registry and HashiCorp's backend documentation rather than recalled — the AWS
  provider's current major is **6.x**, and `dynamodb_table` is deprecated.

## NOT verified, and why

**`terraform validate`, `fmt -check` and `plan` have not been run: neither
`terraform` nor `aws` is installed on this machine.** Both `validate` and
`fmt -check` need no AWS credentials (`init -backend=false` downloads only the
provider), so they *can* be run here the moment Terraform is installed — say the
word and I will install it and run them.

Until then the HCL is reviewed but unproven, which is the same caveat `D4`
raised and the runbook now states in "what this deliberately does not do".
Reading the first `plan` is what stands in for it.

## What the owner needs to do (answers to the two questions)

- **Profile name: `aura-prod`.** It is already the default everywhere.
- **Minimum permissions:** a concrete scoped policy is in `AURAS-0003` step 1 —
  EC2/VPC, Route 53, the IAM role-and-instance-profile verbs including
  `PassRole`, SSM parameters under `/aura/prod/*` plus read on Canonical's
  public AMI parameter, S3 for the state bucket, budgets, and Session Manager.
  With the honest note attached: a principal that can create an IAM role and
  `PassRole` it to EC2 can reach administrator by construction, so that policy
  buys guardrails against *mistakes*, not against a determined attacker holding
  the credential.

## Next

IDE review, then commit. **Nothing merges without explicit owner approval.**
