# AURAT-0009-005 — Approval

Date: 2026-08-05
Status: **approved** — all four spec decisions ratified as recommended.

| # | Decision | Owner's call |
|---|---|---|
| D2 | Typing TTL | **45 s** (`TYPING_TTL_SECONDS`). 10 s rejected — source-disproven (`003-context` C2). |
| D6 | `GET /v1/conversations` | **Deferred.** Only the internal `listAdvisorIdsByUser` lands here; the endpoint + contract + Chats-tab adoption become a follow-up to mint in `aura-app-manor`. |
| D7 | `@aura/contracts` migration | **Deferred.** Mirror v0.3.0 field-for-field in `src/contracts/`, lock with a shape test, record as TECH-DEBT. |
| D4/D5 | Presence source | **Chatwoot inbox agent availability**, one value across all personas; advisors never messaged keep the app's seed dot. Advisor-catalog flag rejected. |

Spec `AURAT-0009-004-spec.md` Status → approved. Proceeding to implementation
under slave rules (lint / typecheck / build / pure unit tests only; runtime
proof in the manor after merge).
