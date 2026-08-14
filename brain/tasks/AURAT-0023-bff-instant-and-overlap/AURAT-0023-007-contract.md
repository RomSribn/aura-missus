# AURAT-0023-007 — The v0.6.0 shape, for the app manor

Date: 2026-08-14
Audience: **`aura-app-manor`** — this is the shape to cut `@aura/contracts`
**v0.6.0** against, and what `AURAT-0024` was blocked on. Owner-agreed
(`006-approval`). The BFF implements exactly this in its mirror
(`src/contracts/session.ts`, `TECH-DEBT #11`).

Everything below is **additive**: a v0.5.1 client keeps working against a BFF on
this shape, which is what lets the two halves merge in one window
(`AURAD-0009` §Sequencing).

## 1. `BookSessionRequest` — "now" is a flag, not a timestamp

```ts
export const bookSessionRequestSchema = z
  .object({
    // The scheduled path: a slot availability offered. Absent when startNow.
    startsAt: z.string().optional(),
    // The instant path: "I am here, start it". The server stamps the start
    // from its own clock — this is never a client timestamp.
    startNow: z.boolean().optional(),
    minutes: z.number().int().positive(),
    idempotencyKey: z.string().uuid('idempotencyKey must be a UUID'),
  })
  .superRefine(/* exactly one of startsAt / startNow:true */);
```

- `startNow: true` **and** `startsAt` → 400.
- neither → 400. A missing `startsAt` is **never** read as "now": that would turn
  a forgotten field into a charged, running session.
- `startNow: false` is the same as omitting it.

Why not simply accept an unaligned `startsAt = now`: the server compares the
slot to its own clock when it processes the request, so a client-sent "now" is
already in the past on arrival — the manor watched exactly that fail with
`startsAt must be at least 0 minutes from now` at `lead = 0`. Inferring the
intent would mean a tolerance window the width of the network.

**Server rules for the instant path:** exempt from grid alignment, exempt from
`SESSION_SLOT_LEAD_MINUTES`, horizon irrelevant. The session comes back
**`status: 'ACTIVE'`** with `startedAt` set — not `SCHEDULED` — so the app's
banner, divider and countdown are live on the booking response itself. It is
therefore **not cancellable and not reschedulable** (409): a started block is
non-refundable (`AURAD-0002`).

The scheduled path is unchanged in every respect.

## 2. `AvailabilityQuery` — carries the duration

```ts
export const availabilityQuerySchema = z.object({
  days: z.coerce.number().int().min(1).max(14).default(14),
  tz: z.string().optional(),
  // How long the session is. Validated against the deployment's bookable
  // blocks — an unknown value is a 400, exactly like booking's `minutes`.
  minutes: z.coerce.number().int().positive().optional(),
});
```

Omitted ⇒ the server reads against its **shortest** bookable block (the most
permissive answer). `AURAT-0024` should always send it: under interval occupancy
a gap can fit ten minutes and not thirty, so the read must be re-run when the
duration changes, and **the selected slot cleared** — a time that fitted the old
block may not fit the new one.

## 3. `AvailabilityResponse` — says whether *now* is bookable

```ts
export const availabilityResponseSchema = z.object({
  // Could a session of `minutes` start this second: this advisor free for the
  // whole window, and the caller not already in a live session.
  instantAvailable: z.boolean(),
  days: z.array(/* unchanged: { date, slots: [{ startsAt, available }] } */),
});
```

The app can derive neither half — it owns neither the clock (`AURAF-0008-001`)
nor any view of other clients' bookings. Without it the quick sheet offers a
"Now" that 409s. It is computed for the query's `minutes`, so it moves with the
duration like the grid does.

Slots themselves are unchanged: still `{ startsAt, available }`, still whole
days including full ones, and `available` now means *"a session of `minutes`
fits here"* rather than *"this cell is free"*.

## 4. Nothing else moves

`Session`, `SessionStatus`, `ExtendSessionRequest`, `RescheduleSessionRequest`,
`CancelSessionResponse`, `SessionsResponse`, `SessionPricing` are byte-identical
to v0.5.1. No refund tier, reschedule cutoff or credit amount changes.

## 5. One behaviour change with no shape change

The **first-session credit is now spent when it is consumed**: eligibility is
"no session ever carried a credit", so cancelling a first booking no longer
hands the $5 back (owner decision, `006-approval` D4). `SessionPricing` already
reports `creditMinor` per block, so the app needs no change — it will simply
read 0 where it used to read 500 for a user who cancelled their first booking.

Next: implementation, then `008-execute`.
