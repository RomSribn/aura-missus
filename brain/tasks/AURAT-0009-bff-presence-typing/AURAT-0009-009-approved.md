# AURAT-0009-009 — Approved

Date: 2026-08-05
Status: **done** — owner-approved after manor verification.

Persona presence and typing are live: the chatter's typing raises the persona
indicator in the app, and the persona online dot follows polled inbox agent
availability. `AURAF-0007-004`'s BE column is ✓ — **v1 free chat (items 001–005)
is now complete with nothing deferred inside it.**

Shipped on manor `develop` @ `8c3734e` (feature commit `1944e18`; 36 files,
+1344/−19; lint, typecheck, build, 190 tests).

## What this closes

The last gap of `AURAF-0007-004`, deferred twice (out of `AURAT-0005` by its
spec decision 5, then out of `AURAT-0006` planning). The app had handled both
events since `AURAT-0006` and had never received either.

## Carried forward (recorded in `TECH-DEBT.md`, not lost)

| # | Item | Where it goes next |
|---|---|---|
| 11 | `src/contracts/` is still a hand-kept copy of `@aura/contracts` (AURAD-0006). Drift fails **silently** — the app's `safeParse` returns early on a mismatch; `contracts/message.spec.ts` pins the shape as a stopgap | A contracts release carrying the BFF-only shapes (`EnsureConversationResponse`), then one dedicated migration pass |
| 12 | `GET /v1/conversations` — the repository half (`listAdvisorIdsByUser`) shipped for presence fan-out; the endpoint did not | App-side conversations-list task, **ID to mint in `aura-app-manor`**: endpoint + contracts bump + Chats-tab adoption, retiring the per-seed-advisor delta sync |
| 13 | Presence is inbox-wide; advisors a user never messaged keep the app's seed dot | Persona→team routing in Chatwoot + the advisor-catalog feature (pairs with #10) |
| — | Manor checks 4 / 6 / 9 (private-note typing, service-User-only availability, log cleanliness) not separately exercised | `008-verify-manor` — a minute's work next time the stack is up |

## Worth remembering beyond this task

Two behaviours were established by reading the Chatwoot v4.15.1 source rather
than its docs, and both changed the design:

- For a `Channel::Api` inbox, `deliver_api_inbox_webhooks` posts **every** event
  to the inbox `webhook_url` — the receiver was already getting typing events
  and 204ing them. Any future "we need event X from Chatwoot" is likely code,
  not configuration.
- The dashboard fires `conversation_typing_on` **once per burst** and never
  refreshes it. Any timeout built on the opposite assumption (the original ~10s)
  hides a live indicator instead of protecting against a stuck one.
