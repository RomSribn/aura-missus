# AURAT-0029-010 — Read-only AWS access, and a leak caught before it happened

Date: 2026-08-18
Status: staged, not committed.

The owner set up AWS access without SSO — enabling IAM Identity Center pulls the
account into an Organization, which is what costs the free-tier standing. The
substitute is an IAM user that can do nothing but assume one MFA-gated role
holding `ReadOnlyAccess`.

Reviewing that turned up something more urgent than the thing being reviewed.

---

## THE FINDING · `aura-missus` is a **public** GitHub repository

Checked directly, unauthenticated (`api.github.com` returns 200 for public, 404
for private):

| Repo | |
|---|---|
| `RomSribn/aura-bff` | 404 → **private** |
| `RomSribn/aura-app` | 404 → **private** |
| **`RomSribn/aura-missus`** | **200 → PUBLIC** |

The workspace `CLAUDE.md` calls `aura-bff` the "public target", which is `wts`
terminology for *the target repo* and means the opposite of what it reads like.
The brain — 255 markdown files of decisions, monetization, roadmap, and **this
runbook** — is the one that is actually world-readable.

**Nothing was leaked.** The already-committed brain is clean: no account ids, no
`AKIA*`, no PEM blocks, no bot tokens, no SSO URLs. And `AURAS-0003` had not been
committed, let alone pushed — it was still staged from step 009.

But it was about to be. The runbook and two step files carried the *other*
organisation's account id, and the next edit would have added the production one.
Both are now gone from every tracked file:

- `variables.tf` no longer hardcodes an account id. The typo-guard became
  `var.forbidden_account_ids`, set in the **gitignored** `terraform.tfvars`. The
  real guard was always `provider.allowed_account_ids`, which is unchanged.
- `AURAS-0003`, `008` and `009` describe the foreign profile without its number.
- The production account id is written **nowhere** — not in the private repo
  either. `aws sts get-caller-identity` prints it on demand.

An account id is not a credential. But with role names and a bucket convention
beside it, it is free reconnaissance, and publishing another organisation's is
simply not ours to do.

**For the owner, beyond this task:** the brain being public is a standing
decision worth making on purpose rather than by default. `AURAS-0002` (Play
Console) and `AURAS-0001` (dev Chatwoot) are operational runbooks for real
systems, and `AURAD-0002` / `AURAD-0010` describe the monetization model in
detail. All are readable by anyone today.

---

## D8 · Backups move to SSE-KMS with a customer-managed key

`ReadOnlyAccess` includes `s3:Get*`. SSE-S3 — which step 8 specified until now —
decrypts transparently, so **any** principal holding `s3:GetObject` reads the
plaintext: every consultation ever had, and the append-only ledger `AURAT-0027`
built. "Read-only, therefore harmless" is exactly the assumption that fails here,
and it only became visible because a read-only role now exists.

`kms:Decrypt` is **not** in `ReadOnlyAccess` (its KMS entries are
Describe/Get/List). So with a customer-managed key, a broad read-only principal
can list the backups and not open one.

- New `kms.tf`: the key, `enable_key_rotation`, a 30-day deletion window, and
  `prevent_destroy` — a sharper case than the data volume, since deleting the
  volume loses the live data and deleting the key loses **every copy of it**.
- `iam.tf` grants the instance role `Encrypt`/`Decrypt`/`GenerateDataKey` on that
  key alone, conditioned `kms:ViaService = s3.<region>` — permission to read
  backups, not a general decryption capability.
- `AURAS-0003` step 8 sets the bucket's **default** encryption to the key, with
  `BucketKeyEnabled` so Chatwoot's attachment sync does not pay one KMS request
  per object.
- **No script changed.** `aws s3 cp`/`sync` apply default encryption on the way
  in and decrypt on the way out.

Cost: about $1/month.

---

## Tooling, and the layer that was unproven is now proven

`terraform` and `aws` were not installed. Now:

- **Terraform v1.15.8** (`brew install hashicorp/tap/terraform` — Terraform is no
  longer in homebrew-core after the BUSL relicensing) and **aws-cli 2.36.25**.
- **`terraform fmt -check` — clean** across all 10 files.
- **`terraform validate` — Success.** Provider resolved and locked at
  **`hashicorp/aws` 6.60.0**, matching the `~> 6.0` constraint.

Neither needs AWS credentials (`init -backend=false`). This closes the caveat
`009` had to leave open: the HCL is no longer merely reviewed.

Still unproven and only an `apply` can settle it: quotas, IAM permission gaps on
create, and anything that fails at first boot. A read-only `plan` would close
most of the rest — the recipe is in `deploy/terraform/README.md` — and needs the
owner to finish steps 1–3 of their own document, none of which has been done
locally yet (no `~/.aws/credentials`, no `claude-*` profiles).

## Two identities, not one

`var.aws_profile` now defaults to **`null`** rather than a hardcoded name,
because the two operations need different credentials: `validate`/`plan` want
the read-only profile, `apply` wants a write-capable one that does not exist yet.
A single default would be wrong for one of them. `allowed_account_ids` pins the
account either way.

## Harness settings

`project/slave-1/.claude/settings.json` — **outside both git repos**, which is
load-bearing: `aura-bff` forbids Claude files by project rule, and `aura-missus`
is public. Verified invisible to both.

- `AWS_PROFILE=claude-ro`, `AWS_REGION=eu-central-1`. **Not `us-east-1`**, which
  the owner's document used throughout: a wrong-region AMI or instance-type check
  returns a plausible answer, not an error.
- 22 allow rules, all read-shaped.
- **19 deny rules, including `terraform apply` and `terraform destroy`** — the
  approval says the owner runs the first apply, and this encodes it in the
  harness rather than relying on the IAM role staying read-only forever.

## The AWS CLI had to be installed twice

`brew install awscli` succeeded and then failed at every invocation:

```
aws: [ERROR]: dlopen(.../pyexpat.cpython-314-darwin.so): Symbol not found:
              _XML_SetAllocTrackerActivationThreshold
```

Diagnosed rather than guessed at. The formula runs on Homebrew's
`python@3.14`, and `otool -L` shows its `pyexpat` linked to the **system**
`/usr/lib/libexpat.1.dylib`; `nm` shows this macOS (26.2) does not export that
symbol, so the bottle was built where a newer expat did. Nothing local fixes it:
the path in the `.so` is absolute so a Homebrew `expat` is irrelevant, **both**
installed `python@3.14` builds (3.14.6 and 3.14.7) fail identically, and
`brew outdated` is empty — there is no newer bottle.

Replaced with AWS's official package, installed **without sudo** into
`~/aws-cli` and symlinked into `~/.local/bin` (already first on `PATH`), and the
broken formula removed so it cannot shadow it. `aws --version` now reports
`exe/arm64` — the self-contained build with its own Python and its own expat,
which is the whole reason to prefer it for something a production runbook rests
on. Verified beyond `--version`: `configure list` and `configure list-profiles`
run, and the only errors left are the correct ones (the `claude-ro` profile does
not exist yet).

`AURAS-0003` step 2 now carries this — including the sudo-less variant — plus a
troubleshooting row, because the next person on macOS hits the same wall and the
error names Python, not the AWS CLI.

**Left alone:** Homebrew's `python@3.14` is still broken for anything else that
uses it. `brew reinstall --build-from-source python@3.14` would fix it by
compiling against this machine's libraries, but it is a long build unrelated to
this task, so it is flagged rather than done.

## Also worth knowing

- The MFA prompt (`Enter MFA code`) blocks any automated shell. The owner primes
  `~/.aws/cli/cache` with one command; it covers the next hour.
- `.terraform/` is 784 MB and gitignored; left in place so `plan` does not
  re-download the provider.

## Next

IDE review, then commit. **Nothing merges without explicit owner approval.**
