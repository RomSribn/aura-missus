# AURAT-0010-001 — Check

Date: 2026-08-04
Slave: slave-1, branch `feature/AURAT-0010-app-paid-sessions`

App side of `AURAF-0007` **P1** (items 006/007, and the read half of 008) —
the half `AURAT-0008` left behind. Implements `AURAD-0002` (fixed
non-refundable minute blocks, red start/finish markers, `billing_enabled`
rollout flag) and `AURAD-0003` (a session is a window inside the one durable
per-advisor thread — never a separate conversation).

Already in place: the BFF sessions module is live on aura-bff `develop`
(`AURAT-0008`, owner-approved 2026-07-13) and dormant behind
`BILLING_ENABLED`; the app runs on the real BFF chat client (`AURAT-0006`).

## Scope (owner-chosen 2026-08-04 — full P1 UI, not the marker-only slice)

- **Book now** opens a block picker driven by `GET …/sessions/pricing`
  (server prices, never client-computed).
- **Balance pre-check** before booking; insufficient funds is a first-class
  UI state, not an error toast.
- **Booking** with a client-generated `idempotencyKey`, safe to retry.
- **Live countdown** derived locally from `endsAt` (no server ticks).
- **Extend prompt** near the end of the block.
- **Early finish** with an explicit non-refundable warning.
- **Red session markers** in the thread (SYSTEM messages from history + WS).
- **Client `billing_enabled` flag** in `shared/config/env.ts` that hides all
  session UI when off (v1 free chat unchanged).

Two sub-items carried by this task:

- **`@aura/contracts` → v0.3.0.** The package's `session.ts` is still the v0
  placeholder (lowercase status, no `costMinor` / `finishReason` /
  pricing / book / extend / finish shapes) while the BFF shipped on its own
  local as-built copy; `wallet.ts` drifted the same way after `AURAT-0007`.
  Align, tag, push, bump the app dependency.
- **Naming collision.** `entities/session` is already the Sessions-tab seed
  bookings (designs 12/13) — a different concept from a paid chat session.
  Needs a naming decision (see 003/004).

## Acceptance

With `BILLING_ENABLED` **off** (both flags): the app is byte-for-byte the
v1 free-chat experience — no session bar, no picker, Book now behaves as
today.

With the flag **on**, on device (manor, after merge): Book now → block
picker showing the server's per-minute price and block costs → booking
debits the wallet once → the thread shows the red "Your session has
started" marker → a live countdown runs down → near the end the app offers
to extend → extending moves the end without a second marker → ending early
warns that the remainder is forfeited → the red "finished" marker lands.
Booking twice with the same key debits once. Killing/reopening the app
restores the running session and its countdown.

## Dependencies

`AURAT-0006` (app chat client) ✓, `AURAT-0007` (wallet BE) ✓,
`AURAT-0008` (sessions BE) ✓. Closes the App column of `AURAF-0007`
006/007 — the feature's P1 then stands complete except PSP top-ups.

## Out of scope

BFF changes of any kind; PSP / real payments; advisor catalog (BFF advisor
price rows stay manual SQL, TECH-DEBT row 10); scheduling a block for
later (`AURAD-0002`: blocks start immediately); the Sessions tab's seed
bookings; presence/typing (`AURAT-0009`); iOS APNs.
