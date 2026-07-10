# AURAT-0006-001 — Check

Date: 2026-07-10

Implements the app side of `AURAF-0007` (items 002/003/004 App/UI + 005 delete).
Obeys `AURAD-0001` (render the persona, not the agent) and `AURAD-0003` (one
durable thread per advisor). This is the milestone that makes **free chat real
end-to-end**.

Already in place: AURAT-0004/0005 (BFF messaging + delivery). App has the
`features/chat` in-memory `ChatProvider` (to replace), Firebase auth, and only
`@react-native-firebase/app` + `/auth` installed.

## Scope

- Replace the in-memory `ChatProvider` with a **real BFF client**: REST for
  history/send + a **WebSocket** for live foreground updates.
- Add **`@react-native-firebase/messaging`** (FCM) for background delivery —
  register the token with the BFF, handle notification → open the thread.
- Render the **advisor persona** (from `entities/advisor`) regardless of sender;
  persona-level **presence + typing** from the BFF.
- **Durable history** load across restart / devices; keep the per-`advisorId`
  thread keyed to the BFF conversation id.
- **Delete** the canned-replies / 1.5s-timer simulation + dead config
  (`AURAF-0007-005`, Del).

## Acceptance

On device: user sends → a real chatter replies → the reply arrives **live**
(foreground) and as a **push** (background); history persists after kill /
reinstall; no canned replies remain anywhere.

## Dependencies

AURAT-0004, AURAT-0005. Completes `AURAF-0007` v1 (free chat, items 001–005).

Next: AURAT-0007 (wallet, behind the flag).
