# AURAT-0107-006 — Approval

Date: 2026-10-20

Owner approved spec `005`:

- 1–7, 9, 10 — by the recommendations: 14 days from today; server blocks; inline pay on the
  profile; from the chat — the same Book sheet with the soonest free slot pre-selected; no own
  `/checkout` page in stage 1 (draft → sheet, none → catalog); Booked → "Open chat with {name}" +
  .ics, "Go to session" with row 009; no `startNow`; top nav — balance chip only; no question
  field, one copy for 400/409 + grid re-read.
- 8 — A, **as a temporary stub**: a short balance shows "top up in the Aura app"; card payment is
  attached later. In code the `PSP_ENABLED=false` branch of `PayActions` is marked temporary.
- 11 — split. `AURAT-0107` = row 006 + the payment-method port with `balance` only. Row 007 =
  `AURAT-0108` (minted in `aura-app-manor`, starts after this task merges).
- BFF gap 1 (replay checked after the 400 checks) — minted as `AURAT-0109` for `aura-bff-manor`.
  Other gaps → `AURAF-0020` backlog at task close.

Next: execute (007).
