# AURAT-0029-008 — Add: the AWS resources are described in Terraform

Date: 2026-08-18
Status: owner decision, taken after `007-execute.md` was staged for review.

## What the owner decided

> «инфраструктура AWS описывается Terraform»

An **addition**, explicitly not a rewrite. `deploy/` — compose, Caddyfile,
cloud-init, systemd, `bin/*.sh` — stays as it is; it describes what happens
*inside* the machine. Terraform closes the layer that did not exist: **what
creates the AWS resources themselves.**

## Scope, as given

In:

- VPC, subnet, security groups — only 80/443 outward; both Postgres and both
  Redis unreachable from outside (the spec's acceptance, stated in the negative)
- an EC2 instance in `eu-central-1` + the EBS volume for `/srv/aura`
- cloud-init attached as `user_data`, **not** reimplemented in HCL
- Route 53 records for the two hosts Caddy terminates
- an IAM instance profile that can read `/aura/prod/` from SSM Parameter Store,
  which `bin/pull-secrets.sh` requires

Out: compose, Caddy, systemd — those stay in cloud-init.

`AURAD-0005` is **not** reopened: one VM, not Kubernetes.

## Two constraints the owner attached

1. **No secret values in Terraform.** A `SecureString` value would land in state
   in the clear. Create at most the *structure*; values are placed by the owner
   or by `pull-secrets.sh`.
2. **Decide and write down where state lives** — local file or S3 (+DynamoDB).
   The spec requires "rebuild the instance from the runbook without consulting a
   session", and state on one machine contradicts that.

## What this supersedes

`007-execute.md` recorded **D4 · No Terraform, on purpose**, whose argument was
that untested HCL reads as authoritative while being unverified, so explicit CLI
commands were safer for an owner-run first apply.

**That decision is the owner's to make and it is now made the other way.** The
concern behind it does not disappear and is not being quietly dropped — nothing
here has still ever been applied against a real AWS account. It is answered
instead of avoided:

- `terraform validate` and `terraform fmt -check` are steps in the runbook, not
  suggestions, and both run with **no AWS credentials at all** (`init
  -backend=false`).
- `plan -out` then `apply tfplan`, with "read the plan" written as the
  instruction — the first plan is also the first review.
- `AURAS-0003`'s "what this does not do" now carries the caveat explicitly
  rather than the old "No Terraform" bullet.

What Terraform buys in exchange is exactly what the CLI version could not: the
rebuild claim becomes one command against shared state instead of fifteen
commands someone has to re-derive.

## The state question, answered

**S3 with S3-native locking (`use_lockfile = true`). No DynamoDB.** Reasoning in
`009-execute.md` and `deploy/terraform/README.md`.

## Access, as of today

Nobody has AWS access. `aws` and `terraform` are **not installed** on the manor
Mac, and the only profile in `~/.aws` is an SSO login for an unrelated
organisation, which must not be used. The owner will create the IAM user and
configure the profile; the requested profile name and the minimum permission set
are in `009-execute.md` and in `AURAS-0003` step 1.

*(Superseded in part by `010`: the owner set up a read-only IAM path instead of
SSO, and tooling is now installed.)*

## Next

`009-execute.md`.
