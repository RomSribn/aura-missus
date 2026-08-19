# AURAT-0029-011 — The HCL was run against a real AWS account, read-only

Date: 2026-08-18
Status: staged, not committed. **Nothing was created.**

The owner finished the read-only credential path, which turned `009`'s open
caveat — *"reviewed but unproven"* — into something that could actually be
settled.

## Result

```
Plan: 31 to add, 0 to change, 0 to destroy
```

No warnings. 31 because that run had `manage_dns = false` (see below); with the
two Route 53 records it is 33. Confirmed in the plan output, not inferred:

| | |
|---|---|
| `ami` | `ami-0c355ec49d386672d` — resolved, not a guess |
| `instance_type` | `t4g.large` |
| `http_tokens` | `"required"` |
| `http_put_response_hop_limit` | `1` |
| KMS key | `deletion_window_in_days = 30`, `enable_key_rotation = true` |

Everything was read-only: `plan` with a local backend override and
`-lock=false`, touching neither the state bucket nor any resource.

## The four facts that could only be settled live

1. **The Canonical AMI parameter path is correct** — the single highest-risk
   line in the config, built from documentation. Both architectures resolve in
   `eu-central-1`: arm64 → `ami-0c355ec49d386672d`, amd64 →
   `ami-04bc554a9635a77c8`. `describe-images` confirms the arm64 one really is
   `arm64`, Ubuntu noble 24.04, gp3, ENA — so the image matches the instance
   type rather than merely existing. The path template was also checked against
   Canonical's own documentation and is now quoted in `compute.tf`.
2. **`t4g.large` is offered in `eu-central-1a`** — not every type is in every
   AZ, and the data volume must share the instance's AZ.
3. **`allowed_account_ids` accepted the credentials**, so the account guard is
   wired the way it was meant to be rather than merely present.
4. **There is no Route 53 hosted zone in this account.** See below.

## Three defects found by running it, all in things I wrote

**1 · The dry-run recipe in `deploy/terraform/README.md` was invalid HCL.**
It told the reader to write `terraform { backend "local" {} }` on one line,
which Terraform rejects — *"A single-line block definition can contain only a
single argument."* The owner would have hit it verbatim. Fixed to the
multi-line form. This is the exact failure mode `009`'s D4 warned about, in a
snippet rather than in the config.

**2 · Terraform cannot use a profile with `mfa_serial` — and I had assumed it
could.** In `010` I wrote that `~/.aws/cli/cache` is "shared for all processes".
That is true of the AWS CLI and **false of Terraform**: the CLI is Python and
writes that cache, the provider is Go and reads neither it nor a terminal. It
fails with *"assume role with MFA enabled, but AssumeRoleTokenProvider session
option not set"*, which names nothing useful.

The fix is to authenticate once with the CLI in a real terminal and hand the
credentials over as environment variables:

```bash
eval "$(aws configure export-credentials --profile claude-ro --format env)"
unset AWS_PROFILE
```

Recorded in both `AURAS-0003` step 3 and the terraform README, with the reason —
**and it applies to `apply` exactly as much as to `plan`**, so the owner would
have hit it at the worst moment.

**3 · `backend_override.tf` is dangerous to leave behind.** Gitignored, so
nothing warns; present during an `apply`, production state goes to a file on one
laptop — the precise failure the S3 backend exists to prevent. Deleted, and the
README now says so in bold rather than as a trailing command.

## The prerequisite that is not met

**`aws route53 list-hosted-zones` is empty.** The domain is not registered, or
is registered elsewhere and not delegated. Consequences:

- `manage_dns` must stay `false` until it is fixed; the two A records are made
  at the registrar against the `public_ip` output.
- **This blocks step 5, not step 3.** Caddy requests certificates at startup and
  a name that does not resolve fails the ACME challenge, then backs off — so the
  host comes up without TLS and the app cannot talk to it at all.

Recorded as a prerequisite check in `AURAS-0003` step 3.

## Also corrected

`AURAS-0003` said "expect roughly 25 resources". It is 33 (31 without DNS) —
now the real number, so a plan that differs is a signal rather than noise.

## What is still unproven, and only an apply settles

Service quotas, IAM permission gaps that appear on create rather than on read,
and everything that first-boot exercises: cloud-init, the volume mount, ACME,
`db:chatwoot_prepare`, the webhook loop. The restore drill — the acceptance
criterion — is downstream of all of it.

## Next

IDE review, then commit. **Nothing merges without explicit owner approval.**
