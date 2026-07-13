# AURAT-0006-008 — Device verification (Android, manor)

Date: 2026-07-12
Device: Samsung SM-A505FN (Android 11), USB; dev stack: BFF :3000,
Chatwoot :3001, `adb reverse tcp:3000` + manor-local `DEV_HOST_OVERRIDE =
'localhost'` in `shared/config/env.ts` (uncommitted, for device runs).

## Verified working

- Build/install: `run-android` clean (1m34s); Metro OK.
- Auth → hydration: on start the app delta-syncs all 6 seed advisors
  (`GET /v1/advisors/:id/messages?limit=50` ×2 batches — mount + WS open).
- Send: Start free chat (mijina) → `PUT …/conversation` + `POST …/messages`
  → message in the Chatwoot dashboard (owner-driven, live).
- Reply → live: outgoing message via Application API → HMAC webhook 204 →
  stored (direction ADVISOR) → WS delivery.
- Reply → push (app backgrounded): FCM data ping → headless handler →
  notifee notification on the `messages` channel, importance HIGH
  (confirmed via `dumpsys notification`).
- History across restart: force-stop → relaunch → threads rebuilt from BFF.

## Two blockers found & fixed on the way

1. **Chatwoot SSRF guard blocked all webhook delivery to the BFF.**
   Symptom: dashboard messages "Failed to send", tooltip *"Hostname
   'host.docker.internal' has no public ip addresses"*, conversations
   kicked out of bot mode. Chatwoot ≥4.15 routes webhook/agent-bot POSTs
   through SafeFetch/ssrf_filter which rejects private IPs; our dev
   `webhook_url` targets `host.docker.internal`. Fix (dev-only):
   `SAFE_FETCH_ALLOW_PRIVATE_NETWORK: 'true'` added to
   `chatwoot-manor/docker-compose.aura-cw.yml` base env (gate confirmed in
   Chatwoot source: `lib/safe_fetch.rb` + `fetcher.rb:43`), containers
   recreated. **Never set in production** — there the BFF webhook URL is
   public anyway. → AURAS-0001 runbook must gain this env (recorded here;
   runbook update pending).
   Note: earlier "failed" agent messages stay failed in Chatwoot — retry
   them from the dashboard or send new ones.

2. **BFF 414 on device-token registration.** `PUT /v1/devices/:token`
   rejected real FCM tokens (~160 chars) — Fastify's default
   `maxParamLength` is 100; `device_tokens` stayed empty and `FcmSender`
   silently no-opped (empty token list). Invisible in unit/smoke tests
   (short fake tokens) and swallowed by the app's silent registration
   catch. Fix: `new FastifyAdapter({ maxParamLength: 512 })` (contract cap)
   — aura-bff `develop` commit `62b0575` (manor, trivial-fix rule), image
   rebuilt; token registered on next app start.

## Follow-ups

- **Push `62b0575`** to aura-bff origin (develop push = merge-gate item).
- **AURAS-0001**: add `SAFE_FETCH_ALLOW_PRIVATE_NETWORK=true` to the dev
  compose section of the runbook.
- App-side: registration failure is fully silent (by design v1) — consider
  a PII-free `console.warn` or debug hook in a follow-up slave task; the
  414 hunt needed a temporary patch to surface the reason.
- Notification tap → thread deep link: not cleanly exercised this session
  (shade interaction opened the app manually); verify on next device run.
- iOS leg (APNs key + entitlement + pod install) still pending — separate
  device session.

Remaining before `*-approved`: owner acceptance pass per 001-check on the
device (send → chatter reply live + push, history across reinstall).
