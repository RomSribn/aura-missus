# AURAT-0139-001 — initial

Date: 2026-10-25
Slave: slave-0, branch `feature/AURAT-0139-push-check` (aura-app, from manor develop `ec9d30b`)
Brain: shared manor missus (slots have no missus worktree).

## Owner's words

> хочу протестировать пуш уведомления на мобилке через firebase, проведи меня по шагам,
> что для этого нужно, можешь запустить это задачу в свободном слейвые aura-app

## Manor brief (advisory, not the owner's words)

- ID issued by the manor: AURAT-0139. A BFF task, if needed, takes its ID from
  `aura-app-manor/active-work.md` (bump the counter first).
- Push already built: app `features/push` (AURAT-0006), BFF `modules/delivery` (AURAT-0005).
  Android verified on device in July; iOS deferred (TECH-DEBT 6), capability added in AURAT-0043,
  APNs key in Firebase probably not uploaded — ask the owner, don't assert.
- Points to cover: step-by-step checklist (consoles, devices, scenarios, which build talks to which
  BFF); a quick delivery check via Firebase Console "Send test message" needs a way to get the FCM
  token in a debug build without PII logs; iOS silent data-only push is unreliable (throttled, not
  delivered after force-quit) → visible alert push / NSE is a BFF change, separate task;
  iOS `getToken()` before the APNs token fails and the error is swallowed; Android force stop /
  OEM battery savers are a checklist item, not a bug.
- Slave does not run devices or the stack; live check is the owner's + manor's after merge.
