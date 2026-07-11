# AURAT-0004-002 — Initial (BFF-manor execution start)

Date: 2026-07-11

## User input

`/wts-task AURAT-0004` — invoked in the manor session, redirected to slave-1.
Run the full wts-task lifecycle for the task. The spec already exists in the
shared brain (`brain/tasks/AURAT-0004-bff-foundation/AURAT-0004-001-check.md`,
minted by `aura-app-manor`). Do not mint new AURA* IDs here.

## Context

- Slave: **slave-1**, branch `feature/AURAT-0004-bff-foundation` (both repos),
  created from manor `develop` @ `60874dc` (master) and manor missus `master`
  @ `0941e4f`.
- Slave-1 was idle (detached HEAD); auto-bootstrap per skill Step 0a.
- Tooling fix on the way in: `bin/wts-start`, `wts-finish`, `wts-release`,
  `wts-run` hardcoded `master` as the manor integration branch; they now honor
  `MASTER_BRANCH` (`develop` for aura-bff) and `MISSUS_BRANCH` from
  `.wts/config`. Workspace is not a git repo — local-only change.

## Next

003 — check existing state (brain scan beyond the 001-check already present).
