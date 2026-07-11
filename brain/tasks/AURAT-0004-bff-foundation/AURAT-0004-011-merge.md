# AURAT-0004-011 — Merge

Date: 2026-07-11

- User approved changes in IDE and the merge explicitly (both gates passed).
- Code committed to feature branch: `df32e19` on
  `feature/AURAT-0004-bff-foundation` (55 files, +14175).
- `wts-finish slave-1` executed: manor **develop** now `24e6727` (merge
  commit), pushed to `origin/develop` successfully.
- Missus: "Already up to date" — expected, missus docs stay uncommitted until
  task close (single commit before release).
- Idle slaves (2–5) refreshed to the new develop.
- slave-1 remains on the feature branch for post-merge step files.

## Manor verification checklist (runtime, live stack)

Tier 1 — no Chatwoot needed:
1. In `project/manor/master/aura-bff/`: copy `.env.example` → `.env`, fill
   Firebase + placeholder Chatwoot values; `docker compose up --build`.
   Expect: `prisma migrate deploy` applies `20260711000000_init`, service
   boots, config validation passes.
2. `GET /health` → 200 ok; `GET /health/ready` → 200 database+redis true.
3. `GET /docs` → Swagger UI.

Tier 2 — needs the AURAD-0005 ops setup (dev Chatwoot + Channel::Api inbox +
service-User token):
4. With a real Firebase ID token:
   `PUT /v1/advisors/<advisorId>/conversation` → 200 `{id, advisorId}`;
   repeat → same id. In Chatwoot: one contact (identifier = UID, E.164 phone),
   one conversation tagged `custom_attributes.advisor_id`.

Next: user verifies in manor → 012-approved / 012-fix-*.
