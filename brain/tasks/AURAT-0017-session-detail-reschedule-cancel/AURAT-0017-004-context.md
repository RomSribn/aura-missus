# AURAT-0017-004 — Context

Date: 2026-08-14
Sources: `AURAD-0009`, `AURAD-0002`, `AURAF-0008`, `AURAT-0016`/`0022`/`0024`
task docs, `SESSIONS_BOOKING.md` §5/§5b/§6/§7, `@aura/contracts`, slave-1 tree.

## Findings

**1 · The refund figure is the one real gap.** `Session` carries `costMinor`,
`startsAt`, `bookedMinutes`, `priceMinorPerMinute` and `status`, so the tier is
*derivable* — and the app already owns a server clock (`AURAT-0015`). But
`CancelSessionResponse.refundedMinor` arrives only **after** the cancel, and the
contract states the policy is the server's. Three ways out, weighed in `005`:
compute a display-only preview from the documented rule; show the tier without a
figure and the amount after; or mint a BFF preview endpoint.

**2 · Reschedule must reuse `features/booking`, not fork it.** `DateStrip`,
`SlotGrid` and `use-booking` already handle the 14-day horizon, the UTC-anchored
grid, `minutes`-aware availability (`AURAT-0024`) and past-slot dropping on the
**server's** clock (`AURAT-0022`). A second copy would silently drift from all
four. `use-booking-confirm` similarly owns the idempotency key, the 409 and the
short-balance route — reschedule's 409 (slot taken) belongs in the same place.

**3 · The 4-hour rule is the server's, and the app must not pre-judge it.**
`rescheduleSession` is documented "refused inside 4h of its current start". The
app should *show* the policy and let the server refuse — the same discipline
`AURAT-0024` arrived at for `instantAvailable`, where the client owns neither the
clock nor other clients' bookings. Hiding the button on a client-side estimate
would repeat the bug `AURAT-0022` fixed in the slot grid.

**4 · Navigation shape is undecided.** Detail is reachable from three places —
the Sessions card, the chat `SessionBanner` (`AURAT-0015` left `onPress` for
exactly this) and, per the handoff, the Booked confirmation's "View session".
`BookingStackParamList` currently lives under a `BOOKING` stack; Sessions is a
tab. Whether detail joins the booking stack or gets its own decides whether
"back" from detail lands on the Sessions list or inside the booking flow.

**5 · `AURAT-0016` left two placeholders that this task retires**: the parked
Reschedule/Join buttons and the "rows tap into the chat thread for now".

## Contradictions logged

- **Design vs contract** on the refund figure (finding 1).
- **Design vs shipped blocks**: the handoff's detail rows show "30 min" and
  "$54.70" with a −$5 first-session credit; live config sells `1,10,20,30`
  minutes and the credit is not in `Session`. Render the server's numbers, as
  `AURAT-0016` already established for the duration picker.
- **Design vs `AURAD-0009`** on the Paid row: the handoff assumes a card charge;
  here it is a wallet debit. Label accordingly.

## Next

`005-spec.md`.
