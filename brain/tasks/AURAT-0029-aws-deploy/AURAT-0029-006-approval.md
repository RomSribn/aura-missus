# AURAT-0029-006 — Approval

Date: 2026-08-18
Status: **approved — implementation may start in `aura-bff-manor`**

## What the owner approved

`005-spec.md` as written: decide where the production artifacts live before
writing them, a production compose on one AWS `eu-central-1` instance, TLS for
both hostnames, a secrets mechanism, production's own Chatwoot environment,
backups with a restore actually performed, and an `AURAS-0003` runbook.

## The open question, answered

**The owner runs the first apply**, from the runbook. So this task's deliverable
is everything *up to* that moment: the compose, the proxy config, the backup
scripts, the Terraform or the console steps, and the runbook itself — written
well enough that someone who was not in this conversation can stand the host up.

No session touches the AWS account. No credentials are requested, and none exist
on the manor machine: the only `~/.aws` there is a June 2022 SSO profile for an
unrelated organisation, and it is not to be used.

That makes the runbook the deliverable rather than a byproduct. It has to be
followable without a session to ask.

## Standing constraints carried into execution

- **TLS is a hard requirement, not polish.** Android release forbids cleartext
  and iOS ATS forbids arbitrary loads, so an http host is unusable by the app —
  and it fails only in release, which is the worst place to discover it.
- **Production gets its own Chatwoot inbox** (`AURAD-0005`: one `Channel::Api`
  inbox per environment). Reusing dev's would cross real users with test traffic.
- **Resolve the image architecture deliberately** — the dev Chatwoot image is
  pinned arm64 for the M2 Mac; EC2 is x86 unless Graviton is chosen.
- **A backup nobody has restored is a belief.** The acceptance is a restore that
  ran, not dumps that exist. `AURAT-0027` made `ledger_entries` append-only at
  the database, and that guarantee lives or dies with the restore.
- **One production compose.** Whichever manor owns it, the other points at it —
  a second copy will drift.
- This task does **not** gate the Google Play payment test; `AURAT-0028` does.
  They run independently.
- Nothing merges to the integration branch without explicit in-the-moment owner
  approval.

## Next

`007-execute.md` — written in the `aura-bff-manor` slave.
