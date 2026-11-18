# AURAT-0220-013 — Second merge (menu item fix) and bridge re-install for account 2

Date: 2026-11-18. Done by the manor (manor-8e). Owner: «Да, мёрж», «Да, переустанови».

- The manor reviewed `6e252a8`: OK. One remark, not a blocker: `fits` checks that the item is in the list,
  not that it is last. If Chatwoot later appends its own item after ours, «Расписание» ends up above it.
  It does not matter for v4.15.1, where Settings is always last. Left as is.
- Run on `6e252a8`: lint, typecheck, `desk:build` (no changes), `nest build`, jest 205 / 3177 — green.
- `wts-finish slave-2`: develop `ffb3c58`, pushed `4968c3e..ffb3c58`. The bridge script in develop is
  `6e252a8`'s.
- The bridge was re-run with the same command (`AGENT_DESK_ORIGINS` prod + dev,
  `AGENT_DESK_ACCOUNTS=2=https://bff-dev.aura-app.cc`) and printed «bridge installed…» and «schedule menu
  item for account 2 -> https://bff-dev.aura-app.cc».
- `DASHBOARD_SCRIPTS` after: 12469 characters, one marker pair, ALLOWED unchanged, ACCOUNTS `{"2":…}`, the
  new code in place (`menuList`, `makeListItem`), nothing outside the markers. The manor keeps the
  previous value for a rollback.

## Next

1. The owner checks in the browser:
   - in Aura Dev the item sits in the list under Settings;
   - the «Aura» tab in production works as before.
2. `SESSION_WORKING_HOURS_ENABLED` stays off until the chatters fill in their hours (bff-dev first).
3. After the owner's final approval: `014-approved`, one missus commit, ask before `wts-release`.
