# AURAT-0021-001 — Check existing state

Date: 2026-08-14
Slave: slave-1, `feature/AURAT-0021-sessions-tab-real-data` off develop `057bac2`

Scope taken: the half of `AURAT-0016` that `AURAD-0008` did **not** park —
collapsing the app's two session models and putting real data on the Sessions
tab. Rows 006–012 (Book → Review → Booked, reschedule, cancel) stay parked; they
need a PSP and a decision superseding `AURAD-0008`.

## Brain

- **`AURAD-0002`** (in force) — a paid session is an **instant** block, prepaid
  from the wallet, non-refundable once started.
- **`AURAD-0008`** (ratified today, option B) — the scheduled/card/refundable
  variant is designed but **not adopted**.
- **`AURAF-0008`** context section already names this: *"Two session shapes exist
  in the app right now… Collapsing these is a prerequisite for rows 006–010."*

## Code (ground truth)

- `entities/session/` is still the **pre-BFF seed**: `config/sessions.ts` holds
  `UPCOMING_SESSIONS` / `PAST_SESSIONS` as constants, and
  `model/types.ts` documents `kind` as `"1:1 video"` — a format the product does
  not have at all (`AURAF-0008`: `Session.type` is always `'Chat'`; the `video`
  and `mic` icons ship unused).
- `screens/sessions/model/use-sessions.ts` reads those constants directly. So
  with `BILLING_ENABLED` on, a user books a real block, watches it run in the
  chat with its banner and dividers, and the Sessions tab shows **invented
  bookings for a video call that cannot exist** — and nothing about the session
  they actually paid for.
- The live flow uses `Session` from `@aura/contracts` (`AURAT-0010`).

## The dependency, checked before speccing

The BFF **cannot report a user's sessions**. Verified in
`aura-bff/src/modules/sessions/sessions.controller.ts`: the only reads are
`GET advisors/:id/sessions/pricing` and `GET advisors/:id/sessions/active`;
everything else is POST (book / extend / finish). There is no list, per advisor
or otherwise.

The **data exists** — `prisma/schema.prisma` `model Session` keeps every row with
`startedAt`, `endsAt`, `finishedAt`, `finishReason`, `costMinor`,
`bookedMinutes`, joined to `Conversation` (which carries the advisor) — so this
is a missing endpoint, not missing history.

## The consequence that shapes the spec

Under `AURAD-0002` the tab's two segments do not both have meaning:

- **Upcoming is empty by construction.** A block starts the instant it is
  booked, so nothing is ever "upcoming". The only thing that could occupy that
  segment is the session running *right now*.
- **Past is real, and unreachable.** The history is in Postgres and the app has
  no way to ask for it.

So this is not "swap the seed for real data": the tab's shape was drawn for the
scheduled model that was deferred. Two things need the owner (see `002-spec.md`):
what the tab becomes under the ratified model, and whether the BFF history
endpoint is minted now as its own task.

## Next

`002-spec.md`.
