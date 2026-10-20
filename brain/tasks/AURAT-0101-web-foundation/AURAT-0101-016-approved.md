# AURAT-0101-016 — Approved

Date: 2026-10-20
Owner: «Принято» after the manor verify of `develop` `9d2aa22`.

Done — aura-web foundation: Vite + React 19 + TS strict, data router, RTK + RTK Query,
`@aura/contracts` v0.22.0, ESLint + Steiger + Prettier + Vitest, shared (tokens, breakpoints,
routes, env, base query, ws client, ui atoms), app (shell, guards, dialog host), i18n for English
+ 23 EU languages, guest-only start without Firebase env, favicon.

Commits on `develop`: `594e56c` (foundation, merge `3b49ccd`), `c7cc932` (favicon, merge `9d2aa22`).

Open items carried forward:
- npm audit: 12 advisories in dev tooling and in firestore (not imported by the app).
- Back button closing the open dialog — with the auth dialog task.
- Firebase Web App registration (API key + app id) — owner's action; until then guest only.
- BFF CORS for the web origin — AURAT-0102.
- Translations not reviewed by native speakers.
