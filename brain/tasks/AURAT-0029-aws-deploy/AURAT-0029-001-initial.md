# AURAT-0029-001 — Initial

Date: 2026-08-18
Context: minted from **manor** (this workspace is the ID counter authority per
`AURAD-0006`). **Executed in `aura-bff-manor`**, not here — the deploy needs a
live stack, which the RN manor's rules forbid in its slaves, and the BFF manor
already runs one.

## What the user asked

> «eu-central-1, заводи задачу на деплой»

following «а я смогу залить бекенд, чатвут и все что нужно для этого залить на
авс? или нужно в кубернетес заливать?»

## What was settled before this file

`AURAD-0005` already scoped provider and k8s-vs-VM as ops details under itself,
so no new decision was minted — the choice is **recorded** in that file:
**AWS `eu-central-1`**, **one VM running docker compose, not Kubernetes**.

## Why it exists

Nothing of this product is deployed anywhere. Dev runs on the manor Mac: the
BFF from `npm run start:dev` behind a compose Postgres/Redis, Chatwoot from
`chatwoot-manor/docker-compose.aura-cw.yml`. There is no production host, no
TLS, no backups, and no runbook for standing any of it up again.

## Scope boundary set at mint time

This task does **not** unblock the Google Play payment test — `AURAT-0028` does,
by making the app's backend address configurable, and its third build target
lets a tunnel to the manor Mac prove the rail before any of this exists. These
two run independently and must not be sequenced against each other.

## Next

`002-check.md`.
