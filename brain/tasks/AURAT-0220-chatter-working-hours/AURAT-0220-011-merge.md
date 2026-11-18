# AURAT-0220-011 — BFF: merge into `develop`

Date: 2026-11-18. Owner: «Да, мёрж». `wts-finish slave-2` was run by the manor (manor-8e).

- Branch `feature/AURAT-0220-chatter-working-hours` → manor `develop` `4968c3e`
  (`Merge feature/AURAT-0220-chatter-working-hours`); pushed `df94915..4968c3e` to origin.
- Before the merge the manor checked the last two commits against the code:
  - `fb54a68` (develop merged in): conflicts only in `SessionsService` and its spec. `book` keeps the
    consent from 0216 and `requireStartableNow` / `requireCovered`; the module imports `ConsentsModule`
    and `WorkingHoursModule`;
  - `2410d46`: a plain rename to `20261118160000_chatter_working_hours`, nothing refers to the old name.
- Run on `2410d46`: lint, typecheck, `prisma validate`, `desk:build` (no changes), `nest build`, jest
  (205 suites / 3171 tests) — all green.
- Missus: the brain is not committed (as intended); steps 007–011 are staged in the slot.
- The slot stays on the branch for the steps after the merge.

## Next (manor, with the owner — nothing is run from the slot)

1. Roll `develop` `4968c3e` out to bff-dev: migration `20261118160000_chatter_working_hours`, flag
   `SESSION_WORKING_HOURS_ENABLED=false` by default.
2. Install the bridge `install-agent-desk-bridge.rb` with `AGENT_DESK_ACCOUNTS` on the shared Chatwoot
   (AURAD-0016).
3. Check on bff-dev (`005` §9):
   - the «Расписание» menu item opens the schedule page; the sidebar anchor has not been checked
     against Chatwoot v4.15.1 markup — if it is not found, the floating button should show;
   - saving hours;
   - the widget calendar;
   - the backoffice «Расписания» tab.
4. `SESSION_WORKING_HOURS_ENABLED` is switched on once the chatters fill in their schedules: bff-dev
   first, prod is the owner's decision.
5. After the final approval: `012-approved`, one missus commit, ask before `wts-release`.
