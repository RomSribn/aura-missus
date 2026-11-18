# AURAT-0220-007 — Execute (aura-bff, slave-2)

Date: 2026-11-18
Slot: `aura-bff-manor` slave-2, branch `feature/AURAT-0220-chatter-working-hours` (from develop `cd0975b`).
Status: code done, **not committed** — staged for the owner's review.

Before writing code I checked the spec against the code: client and chatter behaviour and scope match
spec `005`, so no question went to the owner. Small decisions within the spec are below.

## What was built

- **Data:** `ChatterSchedule` (agent id, IANA zone), `ChatterWeeklyInterval`, `ChatterDateOverride` and
  `ChatterDateOverrideInterval` — migration `20261118120000_chatter_working_hours`, four new tables,
  nothing existing touched.
- **Coverage** (pure functions):
  - `working-hours/working-hours.ts`: `expandWorkingHours` uses the zone's wall clock (`zonedWallTime`
    in `common/time`, two passes like `startOfZonedDay`), `poolCoverage`, `scheduleProblem` (step, bounds,
    overlaps, override dates).
  - `sessions/slot-grid.ts`: `unionIntervals`, `covers`, `gapsIn`; `fitsInterval` / `markAvailability`
    take `coverage` (`null` = 24/7). The "24/7 grid" comment is rewritten (AURAD-0025).
- **Where it applies** (`SessionsService`):
  - grid and `instantAvailable` — for "now", coverage **and** `online > 0`;
  - `book` (scheduled and `startNow`) and `reschedule` are re-checked on the server; outside the hours the
    answer is the same 409 "That slot has just been taken" (one constant).
- **Module `working-hours`** (no routes): repository + `WorkingHoursService`:
  - pool = schedules of the agents in the inbox;
  - `coverageFor` / `canStartNow` / `isCovered` for the grid;
  - `uncovered`, `workingCounts`, `save` with validation.
- **Chatwoot:** `listInboxAgents()` in the port (`{id, name, online}`, the same `assignable_agents` read
  as `onlineAgentCount`); `deskConversationUrlByNumber()` for the backoffice link, so the Chatwoot address
  stays inside the adapter (rule 1).
- **Agent desk:**
  - the guard puts `deskAgent` on the request (`@CurrentDeskAgent()`);
  - `GET/PUT agent-desk/api/schedule`, `POST …/schedule/preview`, `GET …/schedule/coverage?days&tz` —
    always the agent's own schedule from the session, coverage as counts with no names;
  - page `GET /agent-desk/schedule` (`client/schedule.ts` → `assets/schedule.js`, same `desk:build`, same
    sign-in through the bridge). On it: zone, week with "на будни", the next N days (own hours / day off /
    "вернуть по неделе"), heat map of a week by hour, save with `confirm` "N броней останутся без покрытия";
  - the widget calendar shows the block "Никто не работает — клиенту не забронировать" (`closed` in
    `advisor-calendar`, `null` while the flag is off).
- **Bridge** `install-agent-desk-bridge.rb`:
  - `AGENT_DESK_ACCOUNTS=1=https://bff.aura-app.cc,2=https://bff-dev.aura-app.cc` (accounts from
    AURAD-0016; every origin must be in `AGENT_DESK_ORIGINS`);
  - "Расписание" item in the sidebar + `MutationObserver`, a floating button if no anchor is found;
  - panel with an iframe; ×, Esc and route change close it;
  - without `AGENT_DESK_ACCOUNTS` the block is byte-for-byte the old one; the sign-in hand-over is unchanged.
- **Backoffice "Расписания":**
  - chatters (name, online, zone, week, changed days), plus schedules of agents no longer in the inbox;
  - gaps on the horizon;
  - bookings with no coverage (persona, time, link);
  - edit form on a chatter's behalf (text `09:00-18:00, …`, days as `2026-11-20: выходной`).
- **Flag** `SESSION_WORKING_HOURS_ENABLED` (env, `false`), in `bff.env.example`. README: module, section
  "Chatters' working hours", install of the menu item; `deploy/README` — "After a Chatwoot upgrade"
  checklist with "пункт меню «Расписание» на месте".

## Decisions made during execution

1. **Pool = the `assignable_agents` of this environment's inbox**, the same list as `onlineAgentCount`
   (the spec said "in the account" and "reuse that list"; in code that list is the inbox's). The page
   shows "you are not in the inbox — your hours don't count".
2. **Roster cache — 30 s**, in memory, one read in flight at a time.
   - If a read fails, the last good list is used.
   - If no read has ever succeeded, the pool is empty and slots are closed (fail-closed).
   - Schedules are not cached: a save shows up in the very next answer.
3. **Past day overrides — no cleanup job.** Reads skip dates before "yesterday" in the schedule's zone;
   a save carries the whole horizon and replaces the schedule whole, so old rows drop out on the next save.
4. **"Uncovered" bookings are only SCHEDULED ones starting from now** (a running one is already being
   handled). Counted whether the flag is on or off, so schedules can be filled in before it is switched on.
5. **Extension (`extend`) is not limited by working hours** — the spec doesn't mention it; the chatter is
   already in the session.
6. **Midnight shift** — in the week editor, "end earlier than start" is split into a stretch up to 24:00
   and 00:00–… on the next weekday. Changed days can't cross midnight (two days are set separately).
7. **`schedule.js` is a separate self-contained asset** from the same `compile.ts`. There is no bundler,
   and imports between assets would break the hashed addresses; the short sign-in code is duplicated
   from `desk.ts`, and `desk.ts` was not refactored.
8. **Esc inside the iframe** doesn't reach Chatwoot: the page sends `aura-desk:close`. The bridge accepts
   it only from the panel's own frame and at its origin; it is not sent while there are unsaved changes.
9. **Backoffice:**
   - the tab is always visible, not behind `billing_enabled` or the flag;
   - a save from the backoffice goes through the same `WorkingHoursService.save` as the chatter's;
   - last write wins, no versioning;
   - who changed a schedule (chatter or operator) is not logged.

## Checks in the slot

`npm run typecheck`, `npm run lint`, `nest build`, `prisma validate` — clean. `npx jest`: 204 suites,
3137 tests, all green. New tests:

- `working-hours.spec` — DST forward (Kyiv) and back (New York), midnight, changed day, day off,
  17:45–18:15 at the seam, validation;
- `working-hours.service.spec` — roster cache and failure, "now" without anyone online, uncovered,
  counts by inbox;
- `sessions.service.spec` "working hours" — flag on/off, grid, whole block, seam, agent removed from the
  inbox, 409 on book / reschedule / "now";
- smoke `agent-desk` — page, 401, own schedule only, 400, preview, coverage without names;
- `schedule-page.spec` (jsdom);
- `desk-bridge.spec` — installer under `ruby` + script in jsdom; skipped when `ruby` is not available;
- backoffice — form parser, views, smoke.

## Open issues / for the manor after merge

- **Migration order:** slave-1 (AURAT-0216) also adds a migration and edits `sessions.service.ts`,
  `sessions.repository.ts`, `schema.prisma`, `env.schema.ts`. Whoever merges second pulls develop and puts
  their migration after the other one.
- **The sidebar anchor in Chatwoot v4.15.1 is not checked against real markup.** The heuristic is the
  `<nav>`/`<aside>` with the most links to `/app/accounts/<id>/`. Check on dev; if it doesn't work, the
  floating button shows. Installing the bridge is a manor step with the owner, on the shared installation.
- Manor check (`005` §9):
  - the "Расписание" item on the dev account;
  - saving hours;
  - slots outside the hours closed (flag on dev);
  - "now" goes off when nobody is online;
  - the uncovered-bookings warning;
  - the backoffice sees the schedules.
- The flag on prod is the owner's decision, after the chatters fill in their schedules.

Next: the owner reviews the diff in the IDE → commit to the feature branch → merge only with the owner's
"yes".
