# AURAD-0002 — Free chat is the baseline; a paid session is a metered window inside the same thread

Date: 2026-07-08
Status: accepted (owner-ratified 2026-07-09)

## Decision

Chat with an advisor is **free and open-ended**. A **paid session** is a
**fixed block of minutes the user books in advance** (e.g. 10 / 20 / 30 min),
prepaid from a **prepaid USD wallet** and consumed inside the same chat thread,
bracketed by "Your session has started / finished" system lines. Free and paid
messages look identical except those markers, and a chatter may keep messaging
**for free between sessions** (deliberate re-engagement). Wallet + metering live
in **our backend, not Chatwoot**, gated by a flag so v1 can ship free. Closes O2
of `AURAI-0002`.

## How it works

- **Baseline free chat:** the ongoing Chatwoot conversation; every message (user
  and chatter) is free and **unmetered** — including the messages a chatter
  sends *after* a session to pull the user into another one ("bait").
- **Paid session = a booked block:** via the existing **"Book now"** CTA the
  user picks a **fixed block** (e.g. 10 / 20 / 30 min); its cost
  (`minutes × advisor.price`) is **debited from the wallet up front**. Our
  backend opens a `session` (start ts + booked minutes), runs it down, and closes
  it (end ts) when the block is exhausted or on early end. A **block is
  non-refundable once started** — ending early forfeits the remaining minutes. To
  continue, the user books another block ("extend"). **Many sessions** can occur
  over one chat's life; billing is **per booked block, never per conversation.**
- **Session markers:** on start/end the backend posts a system/activity line
  ("Your session has started / finished") into the conversation, so **both** the
  app (rendered as the red separator) and the chatter's dashboard see the
  boundary. Everything else renders identically to free chat.
- **Wallet:** prepaid USD, our source of truth, topped up via the Profile → Top
  Up sheet; starting a block requires balance ≥ its cost; only the wallet is
  debited, never a card mid-session; near the block's end the app prompts to
  **extend / book another block** before it finishes.
- **Chatter visibility:** live session state + accumulated paid minutes surface
  to the chatter (Chatwoot conversation **custom attributes** / companion view);
  **per-shift** paid-minute totals are backend reporting for chatters/managers.
- **Ledger:** an append-only ledger of top-ups and block charges; wallet balance
  = Σ top-ups − Σ block charges.
- **Rollout:** built from day one but gated by a `billing_enabled` flag — v1 can
  ship with only free chat and enable paid sessions later with no migration.

## Why

- Matches how these operations actually run (ref: PsychicBook-style apps): free
  chat hooks and re-engages, discrete paid sessions monetize, and the *only* UX
  difference is the red start/finish markers in one shared thread.
- Free re-engagement between sessions is a deliberate growth loop, so metering
  **must** be per-session (leaving post-session free messaging open) — not a
  single meter over the whole conversation.
- Keeping wallet + metering in our backend (not Chatwoot) follows `AURAI-0002`
  Option B: Chatwoot only needs to *see* session boundaries, not run billing.
- Flag-gated rollout de-risks launch (ship free).

Assumption: "Book now" starts the booked block **immediately** — advisors are an
always-answerable 24/7 pool (`AURAD-0001`); scheduling a block for a later time
is a possible extension tied to O4 (conversation lifecycle, still open in
`AURAI-0002`). Early-end policy: a **block is non-refundable once started**
(owner-ratified 2026-07-09) — ending early forfeits the remaining minutes.

Informed by `AURAI-0002`, `AURAD-0001`. Implemented by the future `AURAF` chat
backend.
