# AURAT-0023-006 — Approval

Date: 2026-08-14

**Approved**, all four open items decided as recommended in `005-spec`:

| # | Decision |
|---|---|
| D1 | **Explicit `startNow` flag.** `startsAt` becomes optional; exactly one of the two, otherwise 400. The server stamps the instant start from its own clock — the client's clock never enters the instant path. |
| D2 | **`AvailabilityQuery.minutes` optional**, defaulting to the shortest configured block (the most permissive read), so both halves can merge in one window without a dead minute. |
| D3 | **`AvailabilityResponse.instantAvailable`** ships — the app can derive neither the clock nor other clients' bookings, and an honest "Now" is the point of `AURAT-0024`. |
| D4 | **The first-session credit is spent when it is consumed.** Eligibility becomes "no session ever carried a credit" (`creditMinor > 0`); cancelling no longer hands it back. This closes the free book→cancel→book cycle that instant booking would have pointed at *now*. |

D4 is a product decision and was the owner's; the rest are the contract shape
`AURAT-0024` is blocked on. The shape is written up for the app manor in
`007-contract.md` so `@aura/contracts` v0.6.0 can be cut against it.

Next: 007-contract, then implementation.
