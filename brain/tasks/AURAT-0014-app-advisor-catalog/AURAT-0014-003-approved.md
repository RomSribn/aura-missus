# AURAT-0014 — 003 approved

**Date:** 2026-08-13 · **Owner-approved after a device pass run by the owner.**

## Status

Done. The app no longer ships advisor data: the catalog comes from
`GET /v1/advisors` (AURAT-0013, aura-bff `develop` @ `b0ee16a`) through
`@aura/contracts` v0.4.0.

Merged into aura-app `develop` as `482a1a8` (feature commit `f333f32`,
user-approved merge gate) and **pushed** — `origin/develop` back in sync, and
the stranded iOS build fix `da1eec1` went out with it.

## Verification

- **Slave:** tsc ✓ · eslint ✓ · jest 34 suites / 142 tests ✓ (was 33 / 140).
- **Manor:** re-installed for contracts v0.4.0; tsc ✓ · jest 34 / 142 ✓.
- **Device:** run by the owner, reported good. Per-item results were not
  captured here — the owner ran the pass directly rather than reporting against
  the checklist in `001-check`, so treat "all seven acceptance points
  individually confirmed" as **not** on the record. What is on the record: the
  owner exercised the app on a device against the live BFF and found nothing
  wrong.

## What the next reader needs to know

- **Presence looks broken and is not.** The catalog has no `online` field —
  liveness only arrives over the WS `presence.update` event. Until a chatter is
  actually available, nothing is online, the "Online" segment is empty, and
  profiles read "Away". Presence is also still inbox-wide (BFF TECH-DEBT #13),
  so every persona shares one state.
- **An empty advisor list points at BFF TECH-DEBT #11 first.** The package's
  `AdvisorId` is `z.string().min(1)`; the BFF is stricter
  (`[A-Za-z0-9_-]{1,64}`). This slice parses with `parse`, not `safeParse`, so
  drift surfaces as the retryable error state rather than an empty list — but
  the underlying mismatch is still unfixed and is the first thing to check.
- **`src/test-support/` is not an FSD layer.** Nothing in the app imports it, so
  it never reaches a bundle. It exists because screen tests must now supply
  personas; `seedAdvisorCatalog` drives the real path (mocked `bffRequest` plus
  the actual zod parse), not a hand-placed snapshot.

## Follow-ups (not minted)

- BFF **TECH-DEBT #11** — align `AdvisorId` charset between package and BFF.
- BFF **TECH-DEBT #12** — `GET /v1/conversations`; the Chats list is still
  rebuilt by delta-syncing every advisor in the catalog.
- BFF **TECH-DEBT #13** — per-persona presence.
- The catalog is memory-only: it refetches on every cold start and a launch
  with no network shows the failed-load state. A persisted cache would fix both
  and would also let the FCM background handler name a persona offline. Worth a
  task if it bites.
- `entities/session` seed bookings are still hardcoded design data (re-pointed
  at live advisor ids here); they go when a bookings API exists.
