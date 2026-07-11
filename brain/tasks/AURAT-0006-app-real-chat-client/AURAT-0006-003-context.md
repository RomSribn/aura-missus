# AURAT-0006-003 — Context (gaps & decisions needed)

Date: 2026-07-11

## G1 — Contracts diverged

`@aura/contracts` on GitHub is the v0 scaffold (`text`, `clientToken`,
`AdvisorPresence`) while the BFF implemented its real device-facing schemas
in `aura-bff/src/contracts/` (`content`, no client token, ws envelope) with
a "→ @aura/contracts later" note. AURAD-0006 says shared types travel via
the versioned package, not re-declared. **Proposal:** update
`@aura/contracts` to the BFF as-built shapes (message/device/ws + keep the
v0 session/wallet stubs), bump to 0.2.0, push to `main`, consume in the app
as a git dependency (`github:RomSribn/aura-contracts`) + `zod` (its peer).
BFF switches its imports to the package later (BFF-side follow-up, not this
task).

## G2 — Push UX needs a local-notification lib

The BFF ping is data-only by design; the OS shows nothing by itself.
For "reply arrives as a push → tap opens the thread" the app must render
the notification locally (persona title from `entities/advisor` via
`advisorId` — exactly what the BFF comment expects). **Proposal:** add
`@notifee/react-native` (display + tap events, headless-safe); FCM
background handler → notifee notification → tap navigates to the thread.
iOS caveat: data-only pushes are best-effort (content-available); good
enough for v1, verified on device in manor.

## G3 — Presence/typing: BFF emits nothing yet

Deferred out of AURAT-0005 by its spec (decision 5). The persona online dot
today renders from the `entities/advisor` seed; the typing indicator was
driven by the sim. **Proposal:** define `presence.update` / `typing.update`
WS events in `@aura/contracts` now; app subscribes and handles them
gracefully (absence = advisor seed for presence, no typing indicator).
Mint **AURAT-0009 bff-presence-typing** (BFF manor: map Chatwoot
`conversation_typing_on/off` webhooks + an availability source to persona
events). App needs no further change when it lands.

## G4 — No "list conversations" endpoint

The Chats tab must rebuild the thread list after reinstall/new device, but
the BFF only exposes per-advisor history. **Proposal (v1):** on auth, delta
sync history for each of the ~8 seed advisors (`limit` page per advisor,
parallel) — small, correct, works today. Record BFF tech-debt:
`GET /v1/conversations` for when the advisor catalog outgrows the seed.

## Smaller calls (in spec)

- Greeting: no longer seeded into history (was sim-only). Rendered as a
  UI-only intro bubble in an empty thread; Chats list shows only threads
  with real messages.
- `startThread` keeps its name but becomes "ensure BFF conversation"
  (PUT, fire-and-forget; send also creates on first use).
- Base URLs: no env lib installed — `shared/config/env.ts` with `__DEV__`
  platform defaults (iOS sim `http://localhost:3000`, Android emulator
  `http://10.0.2.2:3000`) + single override point for device testing.
- Send is optimistic: pending bubble → replaced by the stored DTO;
  failure → "Not delivered · tap to resend" state on the bubble.
- View model keeps `{id, from, text, time}` (+ `status`) so screen UI
  churn stays minimal; `MessageDto → ChatMessage` mapping in
  `features/chat/lib`.
