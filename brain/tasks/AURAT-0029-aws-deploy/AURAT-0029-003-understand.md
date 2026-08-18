# AURAT-0029-003 — Understand

Date: 2026-08-18

## What the user wants

The backend and Chatwoot running on their own AWS in `eu-central-1`, reachable
over TLS, so the product can exist outside the manor Mac.

## What that means concretely

One EC2 instance in `eu-central-1` running the same seven containers dev already
runs, behind a reverse proxy that terminates TLS for two hostnames — the BFF and
Chatwoot — with data on a separate volume and a backup that has been restored at
least once.

## What it is not

- **Not Kubernetes.** Recorded in `AURAD-0005`; revisit at scale.
- **Not a CI/CD pipeline.** Getting it running and repeatable comes first; who
  pushes the button is a later question.
- **Not the payment test's blocker.** `AURAT-0028` owns that. If this task slips,
  the Play rail can still be proven through a tunnel.

## The split that has to be decided, not assumed

Deployment spans two repos that live in two manors — `aura-bff` and Chatwoot's
compose in `chatwoot-manor` — while landing on **one** host. Where the
production compose and the runbook live is a real question with no obvious
answer, and getting it wrong means the next person edits the wrong copy. Options
are weighed in `005-spec.md`.

## The part that is not ours to run

Creating the AWS account, billing, root MFA, the domain and its DNS are the
owner's, and no session can do them. The task's job is to make everything after
those steps mechanical and written down.

## Next

`004-context.md`.
