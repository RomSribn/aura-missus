# AURAT-0018-002 — Check existing state

Date: 2026-08-14

## In the shared brain

- **No `AURAT-0018-*` folder** — fresh task, nothing to resume. Slave-1 was idle
  (detached at `b0ee16a`); `wts-start slave-1 feature/AURAT-0018-bff-scheduled-sessions`
  bootstrapped both repos, `active-work.md` marked busy.
- Governing decision **`AURAD-0009`** is present and owner-ratified (2026-08-14),
  superseding `AURAD-0008`, amending `AURAD-0002` on start-time, refunds, change
  and discount.
- **`AURAF-0008`** is present and still says *"rows 006–012 parked per `AURAD-0008`
  option B"* — **stale**, `AURAD-0009` un-parked exactly those rows. The feature
  file needs the split section rewritten and the BE column filled as this task
  lands (step 6e).
- **`AURAT-0021-sessions-tab-real-data`** exists with only `001-check` +
  `002-superseded` — it is the task that discovered the missing sessions-list read
  and was superseded by `AURAD-0009`. Its finding is an input here, not work to
  redo.
- `AURAT-0015` (session surface in chat) is **done** and deliberately left
  `'scheduled'` out of the app's `sessionState`, noting it "arrives together with
  the flow that can produce it" — this task is the server half of that flow.
- `AURAT-0008` (paid sessions, BFF) is the code this task rewrites: booking,
  meter, markers, wallet debit.

## Decisive finding — the contract already exists

`@aura/contracts` **v0.5.0** is already published and tagged in the sibling repo
`/Volumes/Work/personal/ai-manors/aura-contracts` (commit `0c1b9ac`, *"Scheduled
sessions on the wallet"*, `main` in sync with origin). The app manor cut it
**before** this task started.

So the shape the manor brief asked to "publish early" is **already published**, and
the BFF's job is to implement it exactly rather than propose one. What v0.5.0 pins:

- `SessionStatus = SCHEDULED | ACTIVE | FINISHED | CANCELLED`.
- `Session` splits the timestamps: `startsAt` (the booked slot, the only time a
  `SCHEDULED` session has), `startedAt` **nullable** (server clock at the moment
  the meter began), `endsAt` (planned end while scheduled, moves on extend).
  `costMinor` widened to **nonnegative** — a fully-credited block can cost 0.
- `BookSessionRequest` gains `startsAt`; `ExtendSessionRequest` deliberately keeps
  no slot.
- `RescheduleSessionRequest = { startsAt }` → `PATCH /v1/sessions/:id`.
- `CancelSessionResponse = { session, refundedMinor, balanceMinor }` →
  `POST /v1/sessions/:id/cancel`; cancelling a *started* session is refused (409),
  not silently refunded at zero.
- `SessionsResponse = { sessions }` → `GET /v1/sessions`, newest `startsAt` first,
  all advisors, `CANCELLED` included so the app never infers an absence.
- `AvailabilityResponse = { days: [{ date, slots: [{ startsAt, available }] }] }` →
  `GET /v1/advisors/:id/sessions/availability?days=N`; whole days come back,
  including full ones.
- `SessionPricing.blocks[]` gains `subtotalMinor` / `creditMinor` / `costMinor`
  — **the first-session credit is a discount on the charge**, per duration, and
  `creditMinor` is `0` once the user has had a session. That answers `AURAF-0008`
  open question 2 and makes pricing **per-user**, which today's endpoint is not.
- `session.updated` (WS) needs no shape change but now also carries the
  `SCHEDULED → ACTIVE` transition the meter makes by itself.

The BFF keeps a **hand-copy** of this in `src/contracts/` (TECH-DEBT #11), so
landing v0.5.0 here means mirroring it, not installing it — and the drift risk
that debt describes is exactly what this task must not add to.

## Next

Step 003 — understand.
