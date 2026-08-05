# AURAT-0010-009 — Approved

Date: 2026-08-04
Status: **done**

Owner ran the full device checklist from `008-device-checks` on an Android
device against the live dev stack (BFF + dev Chatwoot + seeded advisor
prices) and accepted the result. Every check passed — the table and the
closing ledger are recorded in `008`.

## What was proven on the device

- **The flag is a real switch.** With `BILLING_ENABLED` off the thread is
  byte-for-byte v1: no session bar, no picker, "Book now" still opens the
  advisor profile, and no billing endpoint is touched.
- **The server owns the money.** Blocks and prices come from the pricing
  endpoint (`$1.99/min`, matching the seeded `199`), an advisor with no
  price row is simply not bookable, and every debit was exactly
  `minutes × price`. The wallet invariant `balanceMinor == Σ ledger` held
  after all seven money movements.
- **Markers are just messages.** "Your session has started/finished" is
  stored as a SYSTEM row and rendered as the red separator inline with the
  conversation — verified against the live chatter's replies sitting either
  side of it by timestamp.
- **The countdown is derived, not decremented.** It resumed correctly after
  the app was killed mid-block, and the block ended at exactly `endsAt`
  (`finishedAt == endsAt`) — even across a BFF restart, since the delayed
  job lives in Redis and the 60s sweep backs it up.
- **Extending grows the window, not the ceremony.** One session row,
  `bookedMinutes` 2 from two separate charges, and no second pair of markers.
- **Ending early forfeits, and says so first.** The confirm names the
  non-refundable remainder; the result is `ENDED_EARLY` with no refund entry.
- **No double charges.** A double tap produced one charge (the submit guard),
  and an airplane-mode failure followed by a retry produced one charge with
  the idempotency key preserved — 5 charges, 5 distinct keys.

## Outcome

- App side of `AURAF-0007` items 006/007 is complete, and 008's App/UI too —
  the Profile balance is the real wallet and Top Up credits it (the credit
  itself stays the BFF's stub until the PSP feature).
- **`AURAF-0007` P1 is now complete end to end**, BE and app, dormant behind
  `billing_enabled` on both sides.
- Live on `develop` @ `6199939` (code `2d8c776`); `@aura/contracts` **v0.3.0**
  published and consumed by the app.

## Cleanup after the run

- App `src/shared/config/env.ts` → `BILLING_ENABLED = false` (the `true` and
  the `DEV_HOST_OVERRIDE` LAN IP stay uncommitted, as before).
- BFF `.env` → the `SESSION_BLOCK_MINUTES=1,10,20,30` line added for the
  meter check can be dropped; dev advisor price rows are harmless and may
  stay.

## Follow-ups carried out of this task

- **AURAT-0011** — the unowned `TarotBanner.tsx` layout fix found in the manor
  tree at merge time, minted rather than smuggled into `develop`.
- **`develop` is still unpushed** — `aura-app`'s origin is the HTTPS URL and
  headless sessions have no credentials; re-pointing it to SSH would end the
  standing debt (contracts pushed fine over SSH).
- Recorded, not blocking: promoting `BffSocket` to a shared multi-subscriber
  singleton if a second WS consumer appears; the advisor catalog that would
  replace manually inserted price rows (BFF TECH-DEBT 10); the iOS/APNs leg;
  a copy pass on the picker's title in the not-bookable state.

Task complete. Missus docs are committed by the manor at close; slave-1 may
be released.
