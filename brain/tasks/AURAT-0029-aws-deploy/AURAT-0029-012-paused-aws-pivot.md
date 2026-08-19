# AURAT-0029-012 — AWS paused, stack pivots to a VPS + Coolify

Date: 2026-08-19
Status: **paused, not abandoned.** Everything built here is preserved and
runnable; nothing is deleted from the repository.

## Why it stopped

`terraform apply` reached AWS and was refused:

```
InvalidParameterCombination: The specified instance type is not eligible for Free Tier
```

The account is on the AWS free plan, which permits only free-tier-eligible
instance types. **This stack does not fit in that envelope, and no amount of
tuning changes it:** free-tier types are 1–2 GiB (`t2.micro`, `t3.micro`,
`t4g.small`), and the deployment is seven containers of which Chatwoot's rails
alone wants ~2 GiB. On 1–2 GiB the OOM killer takes Postgres during boot.

That is a fact about the account, not a defect in the configuration. But it was
**my omission**: I sized the host at 8 GiB and priced it at ~$60–75/month
without checking whether the account could launch such a type at all. The check
costs one API call and belonged before the first apply, not after it.

The owner's decision: move to a **VPS + Coolify** stack (Hetzner/DigitalOcean,
US region, ~$13–25/month), keeping the same four components. New task, not this
one.

## What is preserved, and what is still true in it

`aura-bff/deploy/` stays in the repository in full. Two thirds of it is not
AWS-specific and carries straight over:

| Still valid anywhere | AWS-only |
|---|---|
| `docker-compose.prod.yml` — the seven services, internal networks, healthchecks | `terraform/` — VPC, EC2, EBS, IAM, KMS, Route 53 |
| `Caddyfile` — TLS for two hostnames, WS passthrough | `bootstrap/cloud-init.yaml` — EC2 user-data |
| `chatwoot/provision-prod.rb` — production's own inbox | `bin/pull-secrets.sh` — SSM Parameter Store |
| `bin/backup.sh`, `bin/restore-check.sh` — the restore drill, S3-compatible | `AuraDeploy-policy.json` and the IAM analysis |
| `bin/compose.sh`, `bin/deploy.sh` | |
| `Dockerfile` runtime stage, `.dockerignore`, `trustProxy` | |

The Terraform half is **proven as far as a plan can prove it**: `validate`
clean, and a real `plan` against the account returned `33 to add, 0 to change,
0 to destroy` with the AMI, instance type and IMDSv2 settings all resolved. If
the account ever goes paid, this is a working `apply` away.

Coolify replaces the *reverse proxy* and the *secret delivery* (it brings its
own Traefik and its own env-var store), so `Caddyfile` and `pull-secrets.sh`
become optional there rather than wrong.

## Left running in AWS on purpose

- **The Route 53 hosted zone for `aura-app.cc`.** The domain's nameservers at
  Spaceship are delegated to it (verified at the `.cc` registry). Deleting the
  zone takes the domain offline. ~$0.50/month, and it is provider-independent —
  the new host's IP goes in as an A record. Keeping it is the cheaper move.
- Both S3 buckets: empty, effectively $0. The state bucket still holds the
  Terraform state, which is what makes the pause resumable.
- The IAM users, roles and MFA: not billed.

**Torn down** (script: `aura-aws-cleanup.sh`): the partially-created stack — an
*unattached* Elastic IP (~$3.60/mo, AWS bills precisely for idle ones), a 50 GB
gp3 volume (~$4), the KMS key (~$1). About $9/month for nothing. There was no
data in any of them: the apply died before the instance existed.

`prevent_destroy` guards the volume, the EIP and the key, so the cleanup script
flips them off, destroys, and restores the config — the guards are protecting
empty resources at this point, and they must stay in the file for the day this
resumes.

## Two defects found in the final apply, both fixed

1. **Invalid security-group description.** `"Caddy's redirect"` — AWS rejects an
   apostrophe in a rule description. Fixed, and all nine descriptions were then
   checked against the permitted character set programmatically rather than by
   eye.
2. **`backend_override.tf` survived a cleanup that claimed to have removed it.**
   The `rm` was written as `rm -f backend_override.tf terraform.tfstate*`, and
   in zsh a glob that matches nothing aborts the *entire* command — so nothing
   was removed, while the `echo` after it printed success. The stale override
   pointed the backend at `local`, which is why `init` rejected `backend.hcl`.
   This is exactly the hazard `terraform/README.md` flags in bold; it surfaced
   at `init` rather than at `apply`, which is the lucky ordering — the other way
   round, production state would have gone to a file on one laptop. The plan and
   apply scripts now refuse to run while any `*_override.tf` exists.

## Recorded for the record: the region question is now live

`AURAD-0005` fixes an **EU** region, with a stated reason: EU users, and PII
from psychological consultations kept on EU infrastructure (the Firebase SMS
work was `ES`). The new brief targets **US** for latency.

That is the owner's call and it is now made — but it is a change to a ratified
decision, not a configuration detail, and it deserves an amendment recording
the trade (latency vs. where consultation content lives). The ID is minted in
`aura-app-manor`.

## Next

A new task for the VPS + Coolify deployment. This one stays open at `paused`
until the AWS resources are actually torn down; then it can close.
