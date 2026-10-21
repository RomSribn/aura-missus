# AURAT-0108-011 — Approved

Date: 2026-10-21
Status: done

Owner checked in the manor: on the local BFF stack (`localhost:3010`, the stub open) a session is
booked through the fake top-up and cancelled; on bff-dev the stub answers 503 and the poll ends as
`processing`, as designed. Closed by the owner (AskUserQuestion: «Закрыть и выпустить»).

- `AURAF-0020-007` UI ✓ — card and wallet on the fake provider behind `PSP_ENABLED` (a build
  constant: a production build has neither the fake nor `/psp-sandbox`), `/checkout` as the return
  route, "Still confirming…" poll. aura-web `develop`: `ca6bdca` (code `edff725`, tests `27bbaae`,
  `de9ea5d`), then `d70639f` via `wts-release` (`acb436a` — `.env.development.local` for overrides,
  `010`).
- Fixes during review and verification: `008` (build constant, same-origin return path, bfcache,
  `HydrateFallback`, own commits for the tests), `010` (overrides of `.env.development` go to
  `.env.development.local`; the local BFF is published on host port 3010).
- No BFF task for the test top-up (owner): on bff-dev only the failure branches can be checked;
  what it would take (the stub behind its own env flag, not `NODE_ENV`) was explained to the owner.
- Backlog of the real PSP's gaps: `AURAF-0020-037…041` (036 was taken meanwhile; IDs —
  `aura-app-manor`).
