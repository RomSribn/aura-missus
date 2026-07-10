# AURAD-0003 — One durable conversation per (user, advisor); sessions are windows inside it

Date: 2026-07-08
Status: accepted (owner-ratified 2026-07-09)

## Decision

There is exactly **one durable, rolling Chatwoot conversation per (user,
advisor) pair** — created on first contact, never per-session, never deleted.
Paid sessions (`AURAD-0002`) are metered windows *inside* it, and Chatwoot's
open/resolved status is an internal queue signal, **not** a boundary the user
sees. Closes O4 of `AURAI-0002`.

## How it works

- One **Contact per user** (`identifier = Firebase UID`); under it **one
  conversation per advisor**, tagged `custom_attributes.advisor_id` (`AURAI-0002`
  §5.3, `AURAD-0001`). The app's per-`advisorId` thread maps 1:1 to that
  conversation's `display_id`.
- The **BFF owns the `(userId, advisorId) → conversation` map** and reuses it,
  creating a conversation only when none exists. The Chatwoot inbox keeps
  **`lock_to_single_conversation` OFF** — a single contact must hold *many*
  advisor conversations, so we cannot let Chatwoot collapse them into one;
  dedupe is the BFF's job, not the inbox's.
- **First contact** ("Start free chat" from the advisor profile, or the first
  message) creates the conversation; thereafter every free message **and** every
  session posts into the same one.
- **Status ≠ lifecycle:** chatters/automation may `resolve` a conversation for
  queue hygiene; the BFF still reuses it and a new incoming message reopens it
  (Chatwoot default). The app never shows status — only the rolling thread.
- **Sessions are windows, not conversations:** many paid blocks (`AURAD-0002`)
  come and go inside one conversation, each bracketed by the session markers; the
  free "bait" messages between them share the same thread.
- **History is durable:** the full free + paid history persists (context for
  continuity and re-engagement) until account deletion (retention = O5).

## Why

- The product is a *relationship* with a persona, not a series of disposable
  tickets — one persistent thread is what makes free re-engagement and repeat
  sessions (`AURAD-0002`) possible.
- Per-advisor (not per-contact) conversations match the app's existing
  per-`advisorId` threads and let one user keep parallel relationships with
  several advisors at once.
- Separating the **durable conversation** from the **transient session** and from
  **Chatwoot's queue status** keeps billing, UX and agent-queue concerns
  independent — each can change without touching the others.

Assumption: scoped to a single identity — phone-change / account merge and data
retention are O5 (still open in `AURAI-0002`). `lock_to_single_conversation` is
OFF because all advisors share one API inbox and dedupe is BFF-side; the
alternative (one `contact_inbox` per pair with the lock ON) is viable if advisors
are ever split across inboxes — revisit then.

Informed by `AURAI-0002`, `AURAD-0001`, `AURAD-0002`. Implemented by the future
`AURAF` chat backend.
