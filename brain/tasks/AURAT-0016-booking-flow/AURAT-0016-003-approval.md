# AURAT-0016-003 — Approval

Date: 2026-08-14
Status: **approved — implementation may start in slave-1**

## The two open questions, answered

**Q1 — the reminder and the calendar come out.** Option (a): the Booked screen
drops "We'll remind you 30 minutes before" and its "Add to calendar" footer
button, and the Upcoming card drops "Reminder set · 30 min before". They return
together with the mechanism, which is already tracked as **`AURAF-0008-012`**
(local notification 30 min before + add-to-calendar). Nothing is lost — the
promise simply stops being made before the product can keep it.

**Q2 — the disabled card row stays on Review.** "Visa ···· 4242 — Soon" remains
as a signpost for why balance is being discussed at all. It is now backed by a
real ID: **`AURAF-0009` — Real payments (PSP)**, minted today. The PSP had been
cited across a dozen documents as the reason things were deferred, without ever
having a home; the row and the feature now point at each other.

## Everything else in `002-spec.md` stands as written

Including the parts the design does not cover and this task decides:

- the booking stack sits **above the tabs**, one definition for a flow entered
  from three of them;
- durations and every figure come from the **server**, so the device will show
  10/20/30 where the mock draws 30/45/60 — a 60-minute block needs the *server's*
  grid step to grow, which is an owner call, not an app change;
- **short balance routes to Top Up before the charge**, rather than letting a
  confirmed tap fail with 402;
- **409 "slot taken" re-reads the grid** — availability is an offer, not a
  reservation — while network failures retry on the same idempotency key.

## Standing constraints

- `AURAT-0016` and `AURAT-0018` merge in **one window** (`AURAD-0009`); whichever
  is ready first waits at the merge gate, because the server drops instant
  booking the moment it lands.
- Contract `@aura/contracts` **v0.5.1** is binding; a shape change needs a new
  tag and the other manor's agreement.

## Next

`004-execute.md` — written in slave-1 after the code, before the IDE review.
