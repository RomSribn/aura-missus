# AURAT-0108-006 — Approval

Date: 2026-10-20

Owner approved spec `005` («апрув») — all decisions by the recommendations:

1. А — the fake credits through the dev stub `POST /v1/wallet/top-ups` (key = `paymentId`); a stub
   error leaves the top-up `pending` (→ `processing`). No BFF task (owner, on the spec's review
   before this approval: «Не нужна»): end-to-end success is checked by the tests and on the local BFF stack; on bff-dev only
   the failure branches.
2. А — `VITE_PSP_ENABLED=true` in the manor's `.env.development.local` (not `.env.local` —
   corrected in `010`) + dev-server restart; a production build
   ignores the flag while the provider is fake.
3. Б — no "Use balance" toggle: only the shortfall is topped up.
4. А — card = redirect to the hosted page, return to `/checkout?payment=`.
5. А — `/checkout` is the return page only (summary, status, outcome); no record → as before.
6. Poll every 2 s, "Still confirming…" after 10 s, `processing` after 60 s, no booking later.
7. А — the sandbox is an app page `/psp-sandbox` (lazy, only with the flag). **Amended by the owner
   in `aura-web-build-rules.md` rule 9** (2026-10-20): dev-only tooling that never reaches a
   production build — the fake PSP sandbox page and its test wallet sheet — is **English-only**.
   Everything a real person sees (plan line, buttons, outcomes, `/checkout`) is in 24 languages.

Next: execute (007).
