# AURAT-0006-010 — Approved

Date: 2026-07-13
Status: **done** (owner accepted)

Owner verified on the Android device (SM-A505FN) and accepted:
«назад работает, тап по нотификации тоже — можно закрывать таску».

## Acceptance vs 001-check

| Criterion | Result |
|---|---|
| Send → real chatter (dashboard) | ✓ live (008) |
| Reply arrives live in foreground (WS) | ✓ live (008) |
| Reply arrives as push in background | ✓ live (008: notifee persona notification) |
| Notification tap → opens the thread | ✓ owner-verified (with 009 deep-link fix) |
| History persists across restart | ✓ live (008) |
| No canned replies remain | ✓ (006 execute; repo-wide zero matches) |

Back-from-thread lands on the Chats list (009 fix) — owner-verified.

## Scope notes at close

- Persona presence/typing render seed/silent until **AURAT-0009** (BFF
  emission) — app side already plumbed, no app change needed then.
- iOS leg deferred by owner: APNs key + push entitlement + `pod install`
  + device run — pick up before any iOS build milestone.
- Dev-infra learnings captured: `SAFE_FETCH_ALLOW_PRIVATE_NETWORK` in the
  dev-Chatwoot compose (AURAS-0001 updated), BFF `maxParamLength` 414 fix
  (`62b0575`, pushed).
- Manor working-copy keeps a local `DEV_HOST_OVERRIDE='localhost'` in
  `shared/config/env.ts` for USB device runs (with `adb reverse tcp:3000`);
  intentionally uncommitted.

Completes AURAF-0007 v1 (free chat, items 001–005; 004's live
presence/typing pending AURAT-0009). Next in the feature: AURAT-0007
wallet UI wiring / AURAT-0008 paid sessions (behind `billing_enabled`).
