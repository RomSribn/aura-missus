# AURAT-0008-009 — Merge

Date: 2026-07-12

- Feature branch: `feature/AURAT-0008-paid-sessions` (slave-1), code commit
  `0fe722d` (user-reviewed in IDE, approved).
- `wts-finish slave-1`: manor **develop `5919f8b` → `61f66f9`**, pushed to
  origin (`5919f8b..61f66f9 develop -> develop`). Missus: nothing to merge at
  this stage (expected — single missus commit happens at task close). Idle
  slaves 2–5 refreshed.
- Slave-1 stays on the feature branch for post-merge docs.

## Manor verification — what to check (spec §12)

Prep: manor `.env` → `BILLING_ENABLED=true`, `SESSION_BLOCK_MINUTES=1,10,20,30`
(the `1` makes the live meter testable), restart the stack (migration
`20260711130000_sessions` applies on `docker compose up`); seed a dev advisor:
`INSERT INTO advisors (id, "priceMinorPerMinute", "createdAt", "updatedAt")
VALUES ('<advisorId>', 100, now(), now());` mint an ID token
(`manor/secrets/mint-id-token.cjs`).

1. Flag off (before prep): every `/v1/…sessions…` route → 404, nothing else
   changed.
2. `GET /v1/advisors/<id>/sessions/pricing` → table price × blocks; an
   unseeded advisorId → 404 on pricing AND booking.
3. Top up (stub), `POST /v1/advisors/<id>/sessions {minutes:1, idempotencyKey}`
   → 201; wallet debited exactly 100; `ledger_entries` has SESSION_CHARGE
   −100; invariant `balanceMinor == Σ amountMinor` holds.
4. **Activity line**: "Your session has started" visible in the Chatwoot
   dashboard → records that `message_type: 'activity'` is accepted. If the
   POST fails (announce job errors in logs) — flip the one-line fallback to a
   private note in `chatwoot.client.ts` (spec §5) via a manor trivial fix.
5. Conversation custom attributes show `aura_session_status=active`,
   `aura_session_ends_at`, `aura_paid_minutes_total`; `advisor_id` intact.
6. `GET /v1/advisors/<id>/messages` history contains the marker with
   `direction: "system"`, ordered inline.
7. After ~60–120s: session flips FINISHED/EXHAUSTED (`GET …/sessions/active`
   → null), "finished" line + attrs `status=none`; WS `session.updated` seen
   if a socket is attached.
8. Early end: book 10-min block, `POST /v1/sessions/:id/finish` → forfeited
   (no refund entry), idempotent on repeat.
9. Extend: book, `POST /v1/sessions/:id/extend {minutes:1}` → second
   SESSION_CHARGE, endsAt moved, stale finish job no-ops, no extra marker.
10. Replays: same idempotencyKey on book/extend → one ledger row each, no
    double debit; booking while active → 409; insufficient funds → 402.

**Pending AURAT-0006 (recorded, not verified here):** red markers rendered in
the app; no session UI when the flag is off.

Next: user verification → 010 (approved / fix-…).
