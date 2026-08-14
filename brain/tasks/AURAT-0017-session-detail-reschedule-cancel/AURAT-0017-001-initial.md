# AURAT-0017-001 — Initial

Date: 2026-08-14
Context: invoked from **manor** (štab) as `/wts-task AURAT-0017`. Execution slave
is **slave-1**, `feature/AURAT-0017-session-detail-reschedule-cancel`, branched
off aura-app `develop` @ `20d2467`.

## What the user asked

> `/wts-task AURAT-0017`

No further wording — the task was already minted and described in
`active-work.md`, so the ask is "run the lifecycle for the task that is already
on the board".

## The task as the board describes it

`AURAF-0008` rows **008–010**, unparked by `AURAD-0009`:

- **008** — Session detail: state-coloured hero eyebrow, detail rows, one
  always-enabled "Open chat" footer.
- **009** — Reschedule with the change preview + the 4-hour policy.
- **010** — Cancel sheet, both refund tiers driven by `hoursUntil`, mirrored
  server-side.

The board also records *why* it is still open: `AURAT-0016` deliberately left the
Sessions cards with a single "Open chat" action, because Reschedule needs the
screen this task builds.

## Note on step ordering

The board's entry for this task was written before `AURAT-0022/0023/0024`
landed, so a minimum of state-checking happened *before* this file — enough to
confirm the task's premise still holds (it does, and is now better supported:
`GET /v1/sessions`, `PATCH /v1/sessions/:id` and the cancel route all exist
server-side). Recorded here rather than presented as if the check came later.

## Next

`002-check.md` — brain and code state.
