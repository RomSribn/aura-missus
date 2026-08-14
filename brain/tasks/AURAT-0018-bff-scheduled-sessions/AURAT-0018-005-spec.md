# AURAT-0018-005 — Spec

Date: 2026-08-14
Decision: `AURAD-0009` · Feature: `AURAF-0008` rows 006–011 (BE half)
Contract: `@aura/contracts` **v0.5.0** (`aura-contracts` @ `0c1b9ac`, tagged) — binding
Slave: slave-1, `feature/AURAT-0018-bff-scheduled-sessions` off develop `b0ee16a`
Status: **awaiting owner approval — no code written**

## Goal

Turn the paid session from an instant block into a **scheduled slot**: booked and
prepaid from the wallet for a future time, started by the server's own meter,
reschedulable, cancellable **with a real refund**, priced with a flat first-session
credit the server computes, offered from a real availability read, and listable.

Everything stays behind `billing_enabled`. Everything money-shaped keeps the
`AURAT-0007/0008` discipline: locked rows, append-only ledger, `balance == Σ ledger`,
server as the only authority.

## Owner decisions taken before this spec (2026-08-14)

- **O1 — the grid is 24/7.** An advisor is available to the client round the clock.
  Chatter shifts (15–24, 24–9, 9–15) are an operational matter and are **not**
  modelled in the BFF. No working-hours table, no per-advisor schedule.
- **O2 — a booking takes the slot globally for that advisor.** If someone books
  Olivia at 15:00, no other client can book Olivia at 15:00. This is what makes
  advisor-level locking and a DB-level double-book guard necessary.

## 1 · The slot grid

Slots are **anchored in UTC** at multiples of `SESSION_SLOT_STEP_MINUTES` from UTC
midnight. The anchor is deliberately not the viewer's timezone: occupancy is global
(O2), so every client must be talking about the *same* instants.

A slot is `available` when **all** of:

1. it starts at or after `now + SESSION_SLOT_LEAD_MINUTES` (the design's rule that
   anything inside the next 30 minutes counts as past);
2. it is within the booking horizon;
3. **no** `SCHEDULED`/`ACTIVE` session of **that advisor** occupies it (O2);
4. the **requesting user** has no `SCHEDULED`/`ACTIVE` session overlapping it with
   *any* advisor — you cannot sit in two paid sessions at once, and offering a slot
   the server would then refuse is worse than not offering it.

`GET /v1/advisors/:advisorId/sessions/availability?days=N` returns whole days
including fully-taken ones (contract). `days` defaults to and is capped at
`SESSION_BOOKING_HORIZON_DAYS` (14); above the cap → 400, never a silent trim.

**Day grouping** uses `SESSION_SLOT_TIMEZONE` (IANA, boot-validated). The contract
calls `date` "`YYYY-MM-DD` in the advisor's booking timezone"; with one product-wide
grid that is one configured zone. The endpoint also accepts an **optional `tz`**
query param so the app's date strip can group by the device's zone — additive, does
not change the response shape, and does not move any slot instant (only which day a
slot is listed under). **This must be relayed to the app manor**: if `AURAT-0016`
never sends `tz`, a user east or west of the configured zone sees slots filed under
the neighbouring day. Availability is duration-independent — see §2.

## 2 · One booking occupies exactly one slot

Enforced at boot: **every `SESSION_BLOCK_MINUTES` value must be ≤
`SESSION_SLOT_STEP_MINUTES`** (10/20/30 ≤ 30 today). Cross-field check in the env
schema, fail fast (build rule 3).

That single constraint buys the whole design: every booking covers exactly one grid
slot, so occupancy is an equality on `startsAt`, availability needs no duration
argument, and the double-book guard can be a plain partial unique index instead of a
range-exclusion constraint.

If a longer block is ever wanted, the step grows with it — the boot check makes the
mismatch impossible to deploy rather than a subtly wrong grid.

## 3 · Schema (`sessions`)

| Column | Change | Why |
|---|---|---|
| `status` | enum gains `SCHEDULED`, `CANCELLED`; default becomes `SCHEDULED` | the state machine of `AURAD-0009` |
| `startsAt` | **new**, non-null | the booked slot; the only time a `SCHEDULED` session has |
| `startedAt` | becomes **nullable** | server clock at the meter transition, null until then |
| `advisorId` | **new**, non-null, **no FK** | O2 needs advisor-scoped occupancy and locking. No FK for the same reason `conversations.advisorId` has none (`AURAT-0013`): a retired advisor must never break past sessions |
| `creditMinor` | **new**, default 0 | what the first-session credit took off this booking — the audit trail of a discount that leaves no ledger row |
| `cancelledAt` | **new**, nullable | when it was cancelled |
| `refundedMinor` | **new**, nullable | what actually went back, beside the ledger entry that moved it |

Indexes:

- keep `sessions_one_active_per_conversation` (`WHERE status = 'ACTIVE'`) — it
  already tolerates many `SCHEDULED` rows plus one running session.
- **new** `sessions_one_live_per_advisor_slot`: `UNIQUE (advisorId, startsAt) WHERE
  status IN ('SCHEDULED','ACTIVE')` — hand-written SQL, the DB-level answer to O2.
- `@@index([status, startsAt])` for the activation sweep (mirrors `[status, endsAt]`).
- `@@index([advisorId, startsAt])` for the availability read.

`LedgerEntryType` gains **`SESSION_REFUND`** (positive amounts).

### Migration shape — two files, deliberately

Postgres refuses to *use* an enum value added in the same transaction, and Prisma
wraps each migration in one. So:

1. `..._scheduled_sessions_enums` — `ALTER TYPE "SessionStatus" ADD VALUE …` ×2 and
   `ALTER TYPE "LedgerEntryType" ADD VALUE 'SESSION_REFUND'`, nothing else.
2. `..._scheduled_sessions` — columns, backfill, defaults, indexes.

Backfill for rows that exist on the dev/manor DB: `startsAt := startedAt`,
`advisorId :=` the join through `conversations`. Existing `ACTIVE`/`FINISHED` rows
keep their status, so no past session is reinterpreted.

## 4 · Money

### 4.1 First-session credit — a discount, not a credit entry

`costMinor = max(0, minutes × priceMinorPerMinute − FIRST_SESSION_CREDIT_MINOR)`,
one `SESSION_CHARGE` entry for the discounted amount, `creditMinor` stored on the row.

**The credit never becomes wallet balance.** If it did, book → cancel → refund would
hand the user $5 of real balance they never paid for, once per cycle. As a discount
the refund can only ever return what actually left the wallet. This answers
`AURAF-0008` open question 2, and matches v0.5.0's per-duration `subtotalMinor /
creditMinor / costMinor` breakdown.

**Eligible** when the user has no session in `SCHEDULED`, `ACTIVE` or `FINISHED` —
i.e. never booked, or only ever cancelled. Evaluated **inside** the booking
transaction under the locks, so two simultaneous first bookings cannot both claim it.
A charge of 0 writes **no** ledger entry: the ledger records money movement, and the
session row already records that the block was covered by credit.

`GET …/sessions/pricing` therefore becomes **per-user** (it is already behind the
auth guard; it simply never looked at the caller before).

### 4.2 Refunds — the new direction

Cancel is allowed **only while `SCHEDULED`**. A running session is refused with 409,
never silently refunded at zero (contract, and `AURAD-0002` unchanged for a started
block).

- `startsAt − now ≥ 24h` → refund `costMinor` in full.
- `< 24h` → `Math.floor(costMinor / 2)`. Floor, so a refund can never exceed what was
  paid; the odd cent stays with the house and the figure is deterministic.
- Both computed **server-side** from stored `costMinor` — the app renders the number.

The refund runs in the **same transactional shape as the debit**: wallet row
`SELECT … FOR UPDATE`, append a positive `SESSION_REFUND` entry with
`balanceAfterMinor`, update the cached balance, flip the status — one transaction, no
`UPDATE` on any existing ledger row. Idempotency has two layers: the status
transition is conditional on `status = 'SCHEDULED'`, and the entry's
`idempotencyKey = "session-refund:{sessionId}"` is unique per wallet. A refund of 0
writes no entry.

### 4.3 Lock order

`advisors` row `FOR UPDATE` → wallet row `FOR UPDATE`, in that order, in every
transaction that can take or move a slot (book, extend, reschedule). The advisor lock
is what actually serializes two *different* users racing for one slot — the wallet
lock cannot, because they have different wallets. The unique index stays as the
belt-and-braces guarantee. Cancel takes the wallet lock only: it frees a slot and
conflicts with nothing.

Always the same order, so the paths cannot deadlock against each other.

## 5 · State machine & the meter

```
SCHEDULED ──(slot arrives, server)──▶ ACTIVE ──(meter / early end)──▶ FINISHED
    │
    └──(cancel, refund)──▶ CANCELLED
```

- **Booking** creates the row `SCHEDULED`, debits, and enqueues a delayed
  `activate` job for `startsAt`. No marker is posted and no divider appears in the
  transcript — the thread's boundaries stay "started"/"finished" (`AURAT-0015`); an
  upcoming slot is visible to the chatter through conversation attributes instead.
- **Activation** (`activate` job, plus the 60s sweep as backstop — same philosophy as
  the finish job): conditional `SCHEDULED → ACTIVE` where `startsAt <= now`, sets
  `startedAt = now` and **recomputes `endsAt = startedAt + bookedMinutes`**, so a late
  sweep never eats minutes the user paid for. Then it schedules the finish job, posts
  the **started** marker and pushes `session.updated` — the transition the app cannot
  predict because it can happen while the user is elsewhere (contract note).
  - Before transitioning, activation finishes the conversation's own ACTIVE session if
    it is already past `endsAt` — otherwise back-to-back slots would collide on
    `sessions_one_active_per_conversation`. A unique violation is left to the BullMQ
    retry as the second line.
  - **Accepted edge:** recomputing `endsAt` from a late `startedAt` can overrun the
    next slot by the activation latency (seconds). Bounded, and preferable to
    charging for minutes not delivered.
- **Extend** is untouched by `AURAD-0009` and stays, with one new refusal: extending
  past the **start of that advisor's next `SCHEDULED`/`ACTIVE` session** is a 409.
  Checked under the advisor lock, which is what makes the check race-free.
- **Reschedule** (`PATCH /v1/sessions/:id`): `SCHEDULED` only, refused inside
  `4h` of the **current** `startsAt`, target slot re-validated exactly like a booking
  (aligned, beyond lead time, inside the horizon, free). No money moves. Re-enqueues
  `activate`; the stale job no-ops because its guard reads status + `startsAt`.
- **Cancel** (`POST /v1/sessions/:id/cancel`): §4.2. The stale `activate` job no-ops
  on the same guard.
- **Finish early** unchanged: remainder forfeited, no money moves.

## 6 · Endpoints (all behind `BillingEnabledGuard`)

| Method | Path | Note |
|---|---|---|
| GET | `advisors/:id/sessions/availability?days=N[&tz=]` | **new** — §1 |
| GET | `advisors/:id/sessions/pricing` | now per-user: `subtotalMinor` / `creditMinor` / `costMinor` |
| GET | `advisors/:id/sessions/active` | unchanged; `ACTIVE` only, by name and by contract |
| GET | `sessions` | **new** — every session of the caller, newest `startsAt` first, all statuses |
| POST | `advisors/:id/sessions` | body gains `startsAt`; **this is where instant booking dies** |
| PATCH | `sessions/:id` | **new** — reschedule |
| POST | `sessions/:id/cancel` | **new** — refund |
| POST | `sessions/:id/extend` | unchanged + the overrun refusal |
| POST | `sessions/:id/finish` | unchanged |

`GET /v1/sessions` has no pagination in v0.5.0, so it is capped server-side at **100**
sessions, newest first, and the cap is written into TECH-DEBT rather than left as a
silent truncation.

Errors: 400 misaligned/late/out-of-horizon slot or unknown block · 402 insufficient
funds · 404 advisor not bookable / session not the caller's (ownership by 404, as
today) · 409 slot taken, wrong state for cancel/reschedule, reschedule inside 4h,
extend past the next slot.

## 7 · Chatwoot mirror

`ConversationSessionState` gains `'scheduled'` and `startsAt`, so the desk shows an
upcoming slot in `custom_attributes` (`aura_session_status`,
`aura_session_starts_at`). Still transitions only, never per-minute, still inside the
sealed adapter (build rule 1).

## 8 · Config (new, boot-validated)

`SESSION_SLOT_STEP_MINUTES` (30) · `SESSION_SLOT_LEAD_MINUTES` (30) ·
`SESSION_BOOKING_HORIZON_DAYS` (14) · `SESSION_SLOT_TIMEZONE` (IANA, `UTC`).

The **policy** numbers of `AURAD-0009` — 24h full / half refund, the 4h reschedule
cutoff, the flat $5 credit — are **constants in the sessions module**, not env. They
are a ratified product policy; making them per-environment invites staging and
production to disagree about refunds. Grid mechanics are deployment config; policy is
not.

## 9 · Contracts

Mirror v0.5.0 into `src/contracts/session.ts` in the BFF's own naming (`sessionSchema`
+ `SessionDto`), update `contracts/openapi.ts`, and extend `contracts/session.spec.ts`
to pin every field of the new shape — that spec file is the only thing standing
between a mistyped mirror and a silent `safeParse` failure in the app (TECH-DEBT #11).
The package itself is **not** adopted here; that stays a dedicated pass.

## 10 · Tests (pure — slave)

Grid generation and day grouping across timezones · slot alignment / lead / horizon
validation · availability subtraction (advisor-global and own-overlap) · refund tiers
and the floor · credit eligibility, cap at subtotal, and the zero-cost path ·
reschedule cutoff · state-machine transitions and their conditional guards ·
activation recompute of `endsAt` · extend overrun refusal · contract parity with
v0.5.0.

Transactional behaviour (locks, races, the ledger invariant) needs a real Postgres and
is manor work.

## 11 · Verification in the manor (after merge)

1. Both migrations apply on the populated dev DB, backfill correct, old sessions intact.
2. `balance == Σ ledger` holds across book → cancel (both tiers) and book → activate →
   finish.
3. Cancel twice → one refund. Cancel a running session → 409.
4. Two clients racing the same advisor slot → exactly one wins.
5. A booked slot actually activates on time, posts the marker, pushes `session.updated`.
6. Chatwoot attributes show `scheduled` then `active` then `none`.

## Out of scope

PSP / card payment · notifications and add-to-calendar (`AURAF-0008-012`, app-side) ·
adopting the `@aura/contracts` package · per-advisor schedules or capacity beyond O2 ·
`GET /v1/conversations` (TECH-DEBT #12).

## Open item flagged, not silently taken

The **`tz` query param** on availability is additive and the app does not know about
it (v0.5.0 was cut before this spec). Either the app manor is told and `AURAT-0016`
sends the device zone, or every client sees days grouped by `SESSION_SLOT_TIMEZONE`.
Worth one message to the other manor.
