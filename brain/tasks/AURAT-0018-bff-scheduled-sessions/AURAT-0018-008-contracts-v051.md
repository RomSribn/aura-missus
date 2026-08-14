# AURAT-0018-008 — Contract bumped to v0.5.1 (the `tz` flag came back typed)

Date: 2026-08-14
Gates after the change: **lint ✓ · typecheck ✓ · build ✓ · jest 294/294 ✓**
Still uncommitted — this lands in the same review as `007`.

## What happened

`007` flagged that the availability endpoint's `tz` param was a BFF-only extension,
because `@aura/contracts` v0.5.0 was cut before this task and carried no timezone.
The app manor picked the flag up the same hour and published **v0.5.1**
(`aura-contracts` @ `9ee43b2`, tagged): *"An untyped query param that changes what
the user sees is folklore, so it joins the boundary the way `HistoryQuery` already
does."*

So the param is no longer an extension — it is the contract, and the mirror had to
follow it rather than the other way round.

## What changed here

- `src/contracts/session.ts` — `availabilityQuerySchema` now matches the package
  exactly: `days: z.coerce.number().int().min(1).max(14).default(14)`,
  `tz: z.string().optional()`. Mine had `days` optional with no cap and a
  `min/max`-bounded `tz`; both are gone in favour of the published shape. Header
  and the `date` comment updated to v0.5.1.
- `sessions.service.ts` — `days` is always present now, so the `?? horizon` fallback
  is gone. **The horizon check stays**: see the parity note below.
- `session.spec.ts` — pins the default (`{}` → `days: 14`) and the rejection of
  `days=30`.
- `sessions.service.spec.ts` — the three calls that relied on an optional `days`
  now pass it explicitly.
- `TECH-DEBT #15` rewritten: it was "the `tz` param is BFF-only"; that debt is paid.
  What remains is the new one it created — see below.

## Full parity check against v0.5.1

Field by field, every exported shape: `SessionStatus`, `SessionFinishReason`,
`Session`, `BookSessionRequest`, `ExtendSessionRequest`,
`RescheduleSessionRequest`, `BookSessionResponse`, `FinishSessionResponse`,
`CancelSessionResponse`, `ActiveSessionResponse`, `SessionsResponse`,
`SessionSlot`, `AvailabilityQuery`, `AvailabilityResponse`, `SessionPricing`. All
match, including the nullability of `startedAt`, the nonnegative widening of
`costMinor` and `refundedMinor`, and the per-duration pricing breakdown.

Two deliberate, pre-existing divergences (not introduced here):

- **Naming.** The BFF keeps `sessionSchema` + `SessionDto` where the package uses
  `Session` for both schema and type — the same convention gap `TECH-DEBT #11`
  already describes.
- **`advisorIdSchema` vs `AdvisorId`.** Noted as drifting since `AURAT-0013`;
  untouched by this task.

## The debt this trade created

The booking horizon now lives in **two** places: the contract's literal `max(14)`
and the server's `SESSION_BOOKING_HORIZON_DAYS` (env, up to 60). They agree at 14
today, so nothing is broken — but whichever moves first breaks the other, and the
service therefore keeps its own check rather than trusting the pipe:

- horizon **lowered** (say 7) → the app's schema still thinks 14 is valid, and the
  server answers 400 instead of offering days it will not sell. Correct, and only
  the service check makes it so.
- horizon **raised** (say 30) → no client can ask past 14, because their own copy
  refuses to send it.

Recorded as `TECH-DEBT #15`; the fix is to pick one authority — publish the horizon
in a response, or accept the contract literal as the product constant and drop the
env knob.

## Next

Review in the IDE (step 6f), then the merge gate.
