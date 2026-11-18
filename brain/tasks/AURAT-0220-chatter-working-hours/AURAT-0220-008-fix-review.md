# AURAT-0220-008 — Fix: manor code review

Date: 2026-11-18
Source: manor's code review (the owner asked to check code cleanliness, readability and Nest
structure), sent to the slot through a cross-session message. No blocking bugs; lint, typecheck and
jest are green on the manor side.

## To fix

1. Intervals go to `common/time/intervals.ts` (`TimeInterval`, `unionIntervals`, `covers`, `gapsIn`).
   `slot-grid` and `working-hours` take them from common — no mutual dependency between sessions ↔
   working-hours.
2. One roster read. `onlineAgentCount` is derived from the `fetchInboxAgents()` list; "who is online"
   is decided in one place.
3. Shared client code (`el`, `append`, the whole sign-in through the bridge) goes to
   `client/desk-common.ts`. `compile.ts` builds each asset together with the shared file.
4. `requireStaffed(…, startNow)` is replaced by two explicit calls: `canStartNow` and `isCovered`.
   `getAvailability` reuses the window coverage and adds only "somebody is online".

## Optional — also doing

5. The roster cache moves to a separate `InboxRoster` provider.
6. Small fixes:
   - `scheduleProblem` takes `now` as a parameter, so `scheduleProblemOn` goes away;
   - counts are sliced per day explicitly;
   - `listUpcomingBookings` goes through `SessionsService`.

## Not touching (debt of the whole repo)

HTTP exceptions in services; importing `chatwoot.types` outside the chatwoot module.

## Before the merge

My migration `20261118120000` has the same timestamp as AURAT-0216's `consents`. Whoever merges second
renames theirs and resolves the conflicts in the shared files.
