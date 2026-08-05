# AURAT-0010-005 — Approval

Date: 2026-08-04
Status: **approved** (owner, via in-session decision gate)

Owner approved `004-spec` in full, taking the recommended option on all four
open decisions:

1. **G1 naming** — the paid session ships as **`features/paid-session`**
   (FSD: a verb the user performs, its data shape imported from
   `@aura/contracts`). `entities/session` — the Sessions-tab seed bookings
   of designs 12/13 — is left untouched; the two concepts never meet in one
   layer. Renaming the seed entity to `entities/booking` stays available if
   the Sessions tab ever gets a real backend.
2. **G2 live sync** — **no WS `session.updated` subscription in v1**. Every
   transition is either the app's own call or the meter firing exactly at
   `endsAt`, so a local countdown plus a refetch on mount / foreground /
   countdown-zero is as accurate as the push. `ChatProvider` is fixed to
   ignore the event explicitly (it would otherwise corrupt `presence` once
   the union grows). Promoting the socket to a shared multi-subscriber
   singleton is recorded as the follow-up if a second consumer appears.
3. **G3 wallet scope** — **read + stub top-up**: `GET /v1/wallet` powers the
   booking pre-check *and* the Profile card's real balance, and the existing
   Top Up sheet is wired to the BFF's stub credit — all behind the client
   flag, so nothing changes with billing off. Manor verification becomes a
   pure device flow (no curl/SQL to fund a wallet). PSP remains out of scope.
4. **G4 contracts** — align `session.ts` / `wallet.ts` to the BFF as-built,
   add `'system'` + `session.updated` to `chat.ts`, **delete the unused
   `Money` and `Advisor` shapes**, and **publish `v0.3.0` — commit, tag and
   push `main` + tag to `github.com/RomSribn/aura-contracts` authorized** —
   then move the app dependency to `#v0.3.0`.

Next: execute on `feature/AURAT-0010-app-paid-sessions` (slave-1). Slave
gates only (lint / typecheck / unit tests); device behaviour is verified in
the manor after the merge, which stays behind the wts merge gate.
