# AURAT-0101-006 — Approval

Date: 2026-10-20
Owner: **approved** the spec (`005-spec.md`).

Decisions:
1. Guest and BFF — owner: «если все запросы публичные — не ок; если адвайзоров показывать гостю — ок».
   Resolved strictly: an endpoint opts in to guest access explicitly (`extraOptions: { public: true }`,
   only for the BFF's `@Public` routes of `AURAT-0102`). Any other request without a token fails as
   `401` before the network — exactly the app's `bffRequest`. A signed-in user always sends the token.
2. `Field`, `Toggle` — kept (one-time exception to rule 5 for the foundation; covered by tests).
3. Firebase Web App registration in `aura-2781b` + `VITE_FIREBASE_*` in the manor's `.env.local` —
   owner's action before `npm run dev` in the manor.

Next: 007-execute.
