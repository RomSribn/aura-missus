# AURAT-0220-012 — Check on bff-dev: bridge for account 2, menu item fix

Date: 2026-11-18. The owner checked in the browser; the manor relayed it (manor-8e).

## Bridge installed for account 2 only

- Owner to the manor: «Да, ставь для аккаунта 2». Shared Chatwoot v4.15.1 (`37.27.199.90`), script from
  develop `4968c3e`; `AGENT_DESK_ORIGINS` = prod + dev (unchanged), `AGENT_DESK_ACCOUNTS=2=https://bff-dev.aura-app.cc`.
- Account 1 is left out on purpose: production does not have `/agent-desk/schedule` yet (develop is not
  released to `main`).
- `DASHBOARD_SCRIPTS`: before, 1387 characters, only the old bridge; after, 10065 characters, one marker
  pair, ALLOWED unchanged, ACCOUNTS `{"2":…}`, nothing outside the markers. The manor keeps the old value
  for an exact rollback.
- bff-dev: the live `schedule.js` is byte-for-byte develop; `/agent-desk/schedule` answers 200.

## Owner's check

Owner: «часы остались, расписание в бекофисе появилось, в проде расписания нет».

1. The «Расписание» item in Aura Dev is there and opens the page — but **in the wrong place**: outside
   the menu list, at the bottom of the screen. No floating button — the sidebar was found.
2. Hours save and survive a reload — ✓.
3. Backoffice bff-dev → «Расписания» shows them — ✓.
4. No item in the production account — ✓. That the «Aura» tab in production still works — the manor
   asked the owner; not confirmed yet.

Console: one error, Chatwoot's own (`GET /enterprise/api/v1/accounts/2/limits` 404 from the community
build, `UpgradePage.vue`); neither the bridge nor the page is in the stack.

«Есть несохранённые изменения» right on opening: by the code the page opens clean (the browser's zone
for a chatter with no schedule is a suggestion, not a change); only an edit sets it. The console also had
two `'change' handler took …ms` warnings, i.e. a change event did fire. A test now pins it:
`opens with nothing unsaved` (with a saved schedule and with none).

## Fix — commit `6e252a8` on the branch (owner: «Коммит сейчас»)

Cause: in v4.15.1 the sidebar `<nav>` is a grid whose first row is the menu `<ul>`; the item was appended
to the `<nav>` after that `<ul>`, so it became a grid row of its own at the bottom.

- The item now goes **last into the box's first `<ul>`** as an `<li>` with the classes of Chatwoot's
  leaves (`li.grid.gap-1.text-sm…` > `div[role=button].flex…h-8…`, icon wrapper,
  `span.truncate.text-body-main`). The icon stays our SVG: an icon class Chatwoot's build does not use
  has no CSS. Enter/Space open it, as on Chatwoot's rows.
- `ensure()` keeps **exactly one** item where it belongs: a copy elsewhere (the first install's block in
  the `<nav>`, a re-rendered list, another account) is dropped and the item is drawn again.
- No list in the box → the old block at its end; no sidebar → the floating button, as before.
- `desk-bridge.spec`: the v4.15.1 sidebar (grid nav, groups with hidden sub-lists); last `<li>` with the
  leaves' classes, nothing straight in the `<nav>`; one item across a re-render of the sidebar and of
  the list alone; the stray copy dropped; keyboard; a flat sidebar.
- Checks: typecheck, lint, `desk:build` (no changes), jest 205 suites / 3177 tests — green.

## Next

1. The manor reviews `6e252a8`; with the owner's "yes" — merge into develop (`wts-finish`), then
   re-run the bridge for account 2 from the new develop (the same command), then reload the dashboard.
2. Check: the item sits under Settings in the list; the «Aura» tab in production as before.
3. `SESSION_WORKING_HOURS_ENABLED` stays off until the chatters fill in their hours (bff-dev first).
