# AURAT-0220-009 — Execute: fixes from the manor review (`008`)

Date: 2026-11-18
Slot: slave-2, branch `feature/AURAT-0220-chatter-working-hours`. Still **not committed**, staged.
Behaviour for the client and the chatter is unchanged — this is structure only.

## Done

1. **Intervals in common.** New `src/common/time/intervals.ts`: `TimeInterval`, `unionIntervals`,
   `covers`, `gapsIn`, with `intervals.spec.ts`.
   - `slot-grid.ts` imports them; `BusyInterval` there is now an alias of `TimeInterval` for busy windows.
   - `working-hours`, `agent-desk.service` and the backoffice import from common.
   - `working-hours` no longer imports anything from `sessions`.
2. **One roster read.** `ChatwootClient.fetchInboxAgents()` is the only `GET /assignable_agents`.
   `fetchInboxAvailability()` is derived from it: `onlineAgentCount` = count of `online`. "Who is
   online" is decided in one place.
3. **Shared client code.** `client/desk-common.ts` holds `el`/`append`/`showState`, the whole sign-in
   through the bridge (`requestSignIn`, `handleSignInReply`, `sessionRefused`, `isFromDesk`,
   `deskSession`) and `API`/`deskOrigin`/`root`. `desk.ts` and `schedule.ts` import it.
   `compile.ts` builds each asset as `desk-common` + the page, in one module scope; the
   `import … from './desk-common'` line is removed and `export` is dropped from the shared code. Two
   rules are enforced by the build itself: a page must not redeclare top-level names of `desk-common`,
   and only a named import is allowed. The assets contain no `import`/`export`.
4. **Split `requireStaffed`.** It is now two explicit calls: `requireStartableNow` (via `canStartNow`)
   for "now", and `requireCovered` (via `isCovered`) for booking and rescheduling. `getAvailability`
   computes window coverage once and adds only `anyoneOnline()` — and asks it only when the hours
   apply at all.
5. **`InboxRoster`** (`working-hours/inbox-roster.ts`) — a separate provider: 30 s cache, one read in
   flight at a time, the last good list is kept on failure, an empty list if there was never a read;
   plus `anyoneOnline()` and `includes()`. `WorkingHoursService` keeps the schedules, the coverage and
   the counts.
6. **Small fixes:**
   - `scheduleProblem(hours, { stepMinutes, horizonDays, now })` — the clock is a parameter,
     `scheduleProblemOn` is removed; `problemOf`/`save` take `now`;
   - `DeskScheduleService.coverage` slices counts per day explicitly;
   - `SessionsService.listUpcomingBookings()` — the schedule page and the backoffice read bookings
     through the sessions service, not through its repository.

## Migration

The migration is renamed to **`20261118130000_chatter_working_hours`** (it was `20261118120000`, the
same timestamp as `20261118120000_consents` in AURAT-0216). Neither task is in develop yet; with the
later timestamp the order is unambiguous whichever merges first (the tables are independent). The
second merge still resolves conflicts in the shared files and reruns the tests.

## Not touched (as `008` says)

HTTP exceptions in services; importing `chatwoot.types` outside the chatwoot module.

## Follow-up from the manor (after its re-check, optional)

- `compile.ts` now fails the build if any line starting with `import`/`export` is left in the built
  asset (`export { … }`, enum, a new import form), so this no longer surfaces only in the browser.
- The test `ships assets with no import or export left in them` checks the same thing in both
  committed assets.
- The `export {}` stripping in the jsdom specs is removed: the asset runs as it is.

## Checks

`npm run typecheck` (0 errors), `npm run lint` (clean), `nest build`. `npx jest`: 205 suites, 3140
tests, all green.

Next: the owner's review in the IDE → commit to the feature branch → merge only with the owner's "yes".
