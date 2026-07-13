# AURAT-0008-007 — Approval

Date: 2026-07-11

User approved the spec (006) with two decisions made during discussion:

1. **D1 — advisor price lives in the DB**: new `advisors` table (`id` =
   advisorId slug, `priceMinorPerMinute`), not env config. Rationale (user):
   proper seam for future advisor registration/catalog; no config↔DB syncing;
   price changes without redeploy. Sessions snapshot the price at booking;
   unregistered advisor → 404 (no default-price fallback); no FK from
   `conversations` (free chat unaffected); manual population until the
   catalog feature (tracked in TECH-DEBT; catalog AURAD minted in app-manor
   later).
2. **Display-only pricing endpoint added**:
   `GET /v1/advisors/:advisorId/sessions/pricing` → price + per-block costs,
   same `BILLING_ENABLED` guard — the app shows exactly what the server will
   charge (raised while discussing price-tampering: the booking request
   carries only `minutes` + `idempotencyKey`, never a price; server computes
   cost inside the locked transaction).

Also discussed: PSP/Stripe product sync is a separate future feature covering
top-up packages only; per-minute advisor price stays internal to the BFF
(wallet model per AURAD-0002 — no card mid-session).

Approval scope: implementation in slave-1; code NOT committed until user
reviews in IDE (6f gate); merge/release each require separate explicit
approval.

Next: 008-execute.
