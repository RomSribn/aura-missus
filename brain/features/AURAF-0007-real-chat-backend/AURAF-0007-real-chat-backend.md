# AURAF-0007 — Real chat backend (Chatwoot-backed)
Type: technical
Status: draft
Priority: P1
Source spec: AURAI-0002, AURAD-0001, AURAD-0002, AURAD-0003

## What

Replace the in-memory chat simulation with a real backend: an Aura
backend-for-frontend (BFF) fronts Chatwoot as an internal "agent desk", so a
user's message reaches a real human chatter and the chatter's reply comes back
live and as a push. Free chat is the baseline; paid fixed-minute sessions layer
on behind a flag.

## Scope

| # | Src | Own | App | UI | BE | Del | Item |
|---|-----|-----|-----|----|----|-----|------|
| AURAF-0007-001 | spec | ✓ | ✓ | ✗ | ✗ |   | Message an advisor and reach a real human chatter |
| AURAF-0007-002 | spec | ✓ | ✓ | ✗ | ✗ |   | Get the chatter's real reply live, and as a push when the app is backgrounded |
| AURAF-0007-003 | spec | ✓ | ✓ | ✗ | ✗ |   | Chat history persists across restarts and devices (one durable thread per advisor) |
| AURAF-0007-004 | spec | ✓ | ✓ | ✗ | ✗ |   | Start a free chat from the advisor profile; see persona-level presence + typing |
| AURAF-0007-005 | dev  | ✓ | ✓ | ✗ | ✗ | ✗ | Retire the in-memory chat simulation (canned replies / 1.5s timers) |
| AURAF-0007-006 | spec | ✓ | — | ✗ | ✗ |   | Book a paid session as a fixed minute-block ("Book now"), prepaid from the wallet, with red start/finish markers |
| AURAF-0007-007 | spec | ✓ | — | ✗ | ✗ |   | Near the end, extend / book another block; end a session early (block non-refundable) |
| AURAF-0007-008 | spec | ✓ | — | ✗ | ✗ |   | Top up and see the USD wallet balance (wire the existing Top Up sheet to the real wallet) |

Rows 006–008 ship behind the `billing_enabled` flag (`AURAD-0002`); **v1 launches
with 001–005 only (free chat)** — owner-ratified 2026-07-09 — enabling paid
sessions later with no migration.

## NOT in scope

- **The Chatwoot dashboard & chatter tooling** (canned responses, inline
  translation, per-shift paid-minute reporting) — Chatwoot config + ops, not our
  app to build.
- **Payment-provider (PSP) integration** for real top-ups — a separate feature;
  this only wires the wallet + Top Up UI to the backend.
- **Scheduling a session for later** — sessions start immediately only
  (`AURAD-0002/0003`).
- **Voice / video calls** and **automated bot first-line replies** (Agent Bot
  automation is an optional later add).
- **Chatter provisioning automation (O6), instance topology (O7), identity
  merge / retention (O5)** — decided/handled outside this feature.

## Context

- **Architecture = `AURAI-0002` Option B (BFF proxy).** The app talks only to
  our backend (every call authenticated by the Firebase ID token). The backend
  holds a Chatwoot **User access token** (server secret), drives the Application
  API on a **`Channel::Api`** inbox (contact upsert with `identifier = Firebase
  UID`; user messages as `message_type: incoming`), receives agent `outgoing`
  replies via the **api-inbox `webhook_url`** (verify `X-Chatwoot-Signature`,
  filter `outgoing` + non-private), and pushes to the phone via **FCM** + its own
  store. A **reconciliation poll** (`GET …/messages` after last id) covers the
  webhook's no-retry / no-ordering gaps.
- **Implements the decisions:** `AURAD-0001` (advisor = persona, pool of chatters,
  identity hidden, persona-level presence/typing), `AURAD-0002` (free chat +
  paid fixed-minute sessions vs a prepaid USD wallet, `billing_enabled` flag),
  `AURAD-0003` (one durable rolling conversation per (user, advisor), tagged
  `custom_attributes.advisor_id`; sessions are windows inside it; inbox keeps
  `lock_to_single_conversation` OFF, BFF owns dedupe).
- **App-side changes:** replace `features/chat` `ChatProvider` (in-memory,
  canned replies) with a real backend client; add `@react-native-firebase/
  messaging` (FCM — currently only Firebase app+auth are installed); add the
  REST/realtime client (`shared/api` is Firebase-only today). The app's
  per-`advisorId` thread maps 1:1 to a backend conversation.
- **Backend (stack = O3, undecided):** app-facing REST + realtime/push; Chatwoot
  token vault; webhook receiver; session + wallet ledger (append-only; blocks
  non-refundable per `AURAD-0002`); FCM sender; session state pushed back to
  Chatwoot as conversation
  `custom_attributes` so chatters see the live meter, and session start/finish
  posted as activity lines into the conversation.
- **Depends on:** O3 (stack, `AURAD-0004`) ✓ and O7 (self-host + topology,
  `AURAD-0005`) ✓ are resolved — implementation is unblocked. A PSP choice gates
  real top-ups; O5 (identity / retention) + O6 (chatter provisioning) are
  production-hardening follow-ups.
- **Cut into `AURAT` tasks (2026-07-10, see `brain/tasks/`):** v1 free chat =
  **AURAT-0004** bff-foundation → **AURAT-0005** messaging-and-delivery →
  **AURAT-0006** app-real-chat-client (retires the sim); then behind the
  `billing_enabled` flag **AURAT-0007** wallet-and-topup and **AURAT-0008**
  paid-sessions. Dependency chain: 0004 → 0005 → 0006; 0004 → 0007;
  {0005,0006,0007} → 0008.
