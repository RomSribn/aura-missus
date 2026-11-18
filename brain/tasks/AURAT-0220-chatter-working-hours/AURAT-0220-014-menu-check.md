# AURAT-0220-014 — Owner's check after the bridge re-install

Date: 2026-11-18. The owner checked in the browser; relayed by the manor (manor-8e).

Owner: «та, все правильно».

- Aura Dev: «Расписание» sits in the menu list under Settings — ✓.
- Production: the «Aura» tab works as before — ✓.

Together with `012`: hours save and survive a reload, the backoffice «Расписания» shows them, the
production account has no item.

## Still open (when the owner decides; nothing runs from the slot)

1. **Live slot closing on bff-dev:** every chatter of the dev inbox has hours →
   `SESSION_WORKING_HOURS_ENABLED=true` on bff-dev (Coolify, the owner) → the manor checks availability
   and booking outside the hours, «сейчас» with nobody online, the uncovered-bookings warning → «принято».
2. **Production:** after develop is released to `main` — the bridge with
   `AGENT_DESK_ACCOUNTS=1=https://bff.aura-app.cc,2=https://bff-dev.aura-app.cc`; the flag once the
   production chatters fill in their schedules.
3. After the final approval: `…-approved`, one missus commit, ask before `wts-release`.
