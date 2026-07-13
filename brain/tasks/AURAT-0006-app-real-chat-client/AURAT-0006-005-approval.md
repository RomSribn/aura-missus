# AURAT-0006-005 — Approval

Date: 2026-07-11
Status: **approved** (owner, via in-session decision gate)

Owner approved 004-spec in full:

1. `@aura/contracts` updated to BFF as-built + forward presence/typing
   events; tag `v0.2.0`; **commit + push to GitHub `main` authorized**;
   app consumes via the git tag.
2. Push UX with `@notifee/react-native` (persona notification rendered
   app-side from the data-only ping).
3. Presence/typing plumbed app-side now; **AURAT-0009 bff-presence-typing
   minted** (BFF manor) for the emission side. Counter bumped to 0010.
4. Chats list rebuilt via per-seed-advisor delta sync;
   `GET /v1/conversations` recorded as BFF tech-debt (in AURAT-0009 check
   notes).
5. Greeting = UI-only intro bubble; only threads with real messages are
   listed.

Next: execute on `feature/AURAT-0006-app-real-chat-client` (slave-1).
Merge into develop stays behind the wts merge gate as always.
