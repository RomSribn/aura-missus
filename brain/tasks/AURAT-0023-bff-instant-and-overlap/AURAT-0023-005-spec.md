# AURAT-0023-005 — Spec

Date: 2026-08-14
Kind: **task** (executes `AURAD-0009` second amendment; no new feature file —
`AURAF-0008` rows 006/011 are where the scope table moves)

## 1. The change in one paragraph

A session stops occupying a *cell* and starts occupying an *interval*.
Everything the advisor has live is `[startsAt, endsAt)`; "is this free" is "does
any of it overlap what I want". From that, `startsAt = now` becomes a legal
booking — created **`ACTIVE`**, not `SCHEDULED` with a delayed activation — the
grid step stops being tied to block length, and availability has to be told how
long the session is.

## 2. Contract shape — `@aura/contracts` v0.6.0

The package is cut in `aura-app-manor`; this task writes the BFF's mirror
(`src/contracts/`, `TECH-DEBT #11`) and pins it in `session.spec.ts`. **The shape
is agreed with the owner before either side builds.** Three questions, with the
recommendation first.

### D1 — how "start now" is expressed → **an explicit flag**

```ts
bookSessionRequestSchema = z.object({
  // Absent on the instant path — the server stamps its own clock.
  startsAt: z.string().optional(),
  // Explicit intent: "I am here, start it". Exactly one of the two.
  startNow: z.boolean().optional(),
  minutes: z.number().int().positive(),
  idempotencyKey: z.string().uuid(),
})
```

Refined: `startNow === true` ⇒ `startsAt` must be **absent**; otherwise
`startsAt` is **required**. Both, or neither, is a 400 — never a guess.

The alternative the spec offers (accept an unaligned `startsAt` and infer the
intent) does not survive contact with the clock. The server compares the slot to
its own `now` at processing time, so a client-sent `startsAt = now` is *already
past* when it lands — the manor watched exactly that fail at `lead = 0`. Inferring
"they meant now" would mean a tolerance window measured in network latency, and
the server would be taking the start time from the client on the one path where
the client's clock is least trustworthy. A flag says the intent; the server keeps
the clock (build rule 4).

Additive, so a v0.5.x client that always sends `startsAt` is unaffected. A
missing `startsAt` **is not** silently read as "now": that would turn a client
bug into a charged, running session.

### D2 — `minutes` in `AvailabilityQuery` → **optional, defaults to the shortest block**

```ts
availabilityQuerySchema = z.object({
  days: z.coerce.number().int().min(1).max(14).default(14),
  tz: z.string().optional(),
  // Validated against SESSION_BLOCK_MINUTES like booking's, 400 otherwise.
  minutes: z.coerce.number().int().positive().optional(),
})
```

Omitted ⇒ the shortest configured block, i.e. the most permissive read: a slot
that fits nothing at all is still refused, and a slot that fits ten but not
thirty is offered to a caller that never said thirty. Required would 400 every
shipped client the moment this merges, and the two halves have to be able to
merge in one window (`AURAD-0009` §Sequencing) without a dead minute between them.
Availability was always an offer and never a reservation — booking re-checks.

### D3 — does the response say whether **now** is bookable → **yes, one boolean**

```ts
availabilityResponseSchema = z.object({
  // Could a session of `minutes` start this second: advisor free, caller free.
  instantAvailable: z.boolean(),
  days: [...unchanged...],
})
```

`AURAT-0024` wants the quick sheet to read "start now" **only when it is**, and
the app can derive neither half — it owns neither the clock (`AURAF-0008-001`)
nor any view of other clients' bookings. Without it the sheet offers a Now that
409s. One boolean, computed from the same reads the day grid already does.

## 3. Server rules — two paths, one booking

| | scheduled (`startsAt`) | instant (`startNow: true`) |
|---|---|---|
| start | the client's slot | **the server's clock**, never the client's |
| grid alignment | required (availability offers grid instants; booking takes one) | **exempt** |
| lead time | required | **exempt** — the lead exists so a chatter is not ambushed by a slot appearing unannounced; a user saying "I am here" is not that |
| horizon | required | n/a |
| created as | `SCHEDULED` + delayed `activate` job | **`ACTIVE`**, `startedAt = startsAt`, inside the same transaction as the debit |
| after commit | `sync` job, `session.updated` push | the **existing** activation fan-out |
| cancel / reschedule | as today | 409 — it is already running, and a started block is non-refundable (`AURAD-0002`) |

Everything else — price resolution, the credit, the debit, `idempotencyKey`,
402/409 mapping — is untouched on both paths.

## 4. Occupancy

**In the transaction** (unchanged shape, changed predicate): `SELECT … FOR
UPDATE` on the advisor row, then *"any live session of this advisor overlapping
`[startsAt, endsAt)`"* in place of *"any live session at `startsAt`"*. Same for
`reschedule` (excluding itself) and for `convergeBookRace`. `extend`'s
"must not overrun the next booking" becomes a plain overlap against the extended
window, which is strictly stronger than today's read — it also catches a session
that started before this one and runs long.

**Plus the caller's own calendar.** `book` will refuse when the user already has
a live session overlapping the window (409). Today booking checks nothing
user-side — availability marks it, booking allows it — and an instant session
born `ACTIVE` would hit `sessions_one_active_per_conversation` as a raw P2002 that
`convergeBookRace` reports as an idempotency conflict. The wallet row is already
locked in that transaction, which is precisely what serializes one user's
concurrent bookings, so the check is sound where it sits.

**DB-level belt.** The partial unique index `sessions_one_live_per_advisor_slot`
is equality-shaped and cannot express overlap. It is replaced, as `AURAD-0009`
names, by

```sql
CREATE EXTENSION IF NOT EXISTS btree_gist;
ALTER TABLE "sessions" ADD CONSTRAINT "sessions_no_overlap_per_advisor"
  EXCLUDE USING gist ("advisorId" WITH =, tsrange("startsAt", "endsAt") WITH &&)
  WHERE ("status" IN ('SCHEDULED', 'ACTIVE'));
```

`23P01` maps to the same `SlotTakenError` / `ExtendOverlapsNextBookingError` the
lock path raises, so a race that escapes the lock is still a clean 409.
**Deploy note:** this needs `btree_gist`, which the compose Postgres has and a
managed instance grants to the owner role; it is the one thing in this task that
can fail at migrate time rather than at test time. If an environment cannot
install it, the constraint is droppable without touching a line of application
code — the lock is the guarantee, this is the belt.

## 5. Two activation paths, one activation

The instant path does not re-implement activation. The tail of `activateIfDue` —
arm the run-down (`finish` job), enqueue the `started` announcement, push
`session.updated` — moves into one private method that both callers use. The
marker, the Chatwoot attribute sync and the transcript divider therefore behave
identically whether the meter started the session or the booking did.

## 6. Config

The boot cross-check in `env.schema.ts` (blocks may not exceed the step) goes:
it exists only to keep one booking inside one cell, and that is the invariant
being replaced. `SESSION_SLOT_STEP_MINUTES` stays, now meaning *the spacing of
the offered grid*; `SESSION_SLOT_LEAD_MINUTES` stays, now meaning *how soon a
**scheduled** slot may be picked*. The manor's `1,10,20,30` blocks with a 30-min
step stop being a special case and become ordinary.

## 7. Tests — the bulk of the work

Pure, in-slave. `slot-grid.spec.ts`'s five equality cases are rewritten as
intervals and the service suite grows the instant path:

- a gap that fits 10 and not 30 (the same grid, two `minutes`, two answers)
- back-to-back: a session ending exactly at a slot's start leaves it free
- overlap at the exact boundary, both directions
- a booking that straddles a taken one (starts before, ends inside)
- an advisor busy from *before* the window and still running into it
- the caller's own live session closing an otherwise free slot
- `instantAvailable`: free advisor / advisor busy right now / caller busy
- instant booking: no `activate` job, session comes back `ACTIVE`, `finish`
  armed, `started` announced, `session.updated` pushed
- instant booking is exempt from alignment and lead; scheduled booking is not
- instant booking while the caller has a live session → 409
- an instant replay (same `idempotencyKey`) announces nothing and pushes nothing

**Not in a slave:** two clients racing into one gap, a real reschedule onto a
straddling interval, and the exclusion constraint firing. Those are transaction
behaviour and go on the manor list (§10).

## 8. Raised, not decided — the free-booking cycle

Found while reading the money path, verified live in the manor, and made sharper
by this task. `creditForBooking` clamps the $5 credit to the subtotal, so a block
cheaper than $5 costs **0**; eligibility is "no `SCHEDULED|ACTIVE|FINISHED`
session", and **`CANCELLED` is not in that set**, so cancelling restores it. A
fresh account can book free, cancel, book free again, without limit. No money
moves (the credit is a discount on the charge, never a ledger credit — and
`session-policy.ts` explains why it must stay that way), but **advisor time does**:
each cycle takes a slot from someone who would have paid for it. Today that slot
is in the future. With instant booking it is **now**.

Options, cheapest first:

1. **Spend the credit when it is consumed** — eligibility becomes "no session
   ever carried a credit" (`creditMinor > 0`), so a cancelled first booking does
   not hand it back. One predicate in the repository. Cost: someone who cancels
   their genuine first booking loses the $5.
2. **Minimum charge per booking** — a floor (e.g. $1) that the credit cannot take
   below, so the cycle costs real money. Touches the pricing response too, and
   the app renders the floor.
3. **Record it and leave it** — billing is off in every environment; revisit
   before it is turned on.

Recommendation: **1**. It is the smallest change, it kills the cycle rather than
pricing it, and "first session" reading as "first booking that took the credit"
is defensible to a user. **This is a product call and is the owner's.**

## 9. Out of scope

Card/PSP, the app half (`AURAT-0024`), publishing `v0.6.0` (minted in
`aura-app-manor`), pagination (`TECH-DEBT #14`), the horizon duplication
(`TECH-DEBT #15`), and any change to refund tiers, the reschedule cutoff or the
credit amount.

## 10. Manor verification list (after merge)

1. Migration on a populated DB: `btree_gist` installs, the constraint is created,
   existing rows survive.
2. Instant booking end to end at `minutes=1`: 201 with `status: ACTIVE`, the
   started divider in the thread, `session.updated` on the socket, the block
   finishing by itself a minute later.
3. Two clients into the same gap — one 201, one 409.
4. Back-to-back: book `[14:00,14:10)`, then `[14:10,14:20)` — both accepted.
5. A straddling booking refused; `extend` into the next booking still 409.
6. Instant booking while the caller has a live session → 409, not a 500.
7. `balance == Σ ledger` after the run, and the `AURAT-0018` regression set
   (debit, both refund tiers, replay, 402, list order) still 25/25.

Next: 006-approval.
