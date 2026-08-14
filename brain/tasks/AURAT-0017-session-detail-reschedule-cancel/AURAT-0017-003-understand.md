# AURAT-0017-003 — Understand

Date: 2026-08-14

## What the user wants

Close the last unbuilt third of the design round: give a booked session a
**screen of its own**, and from it the two things you can do to a slot before it
starts — **move it** and **cancel it**.

Today a booked session can be created (`AURAT-0016`, `AURAT-0022`), can start
itself, and can be watched while it runs (`AURAT-0015`). It cannot be inspected,
moved or cancelled from the app at all — the Sessions card offers only "Open
chat", and the server's reschedule and cancel routes have no caller.

Concretely (`AURAF-0008` 008–010, handoff §5 / §6 / §7):

- **Session detail** — plum hero whose eyebrow carries the state (gold relative
  day when scheduled → teal "IN PROGRESS · N MIN LEFT" → gold "COMPLETED"),
  detail rows, Reschedule, Cancel, and one always-enabled footer button that
  opens the chat thread. No join step, no second Message button.
- **Reschedule** — the same date strip and slot grid as booking, preselected to
  the current slot, a change preview that appears only once the pick differs,
  and the server's 4-hour refusal surfaced honestly.
- **Cancel sheet** — two refund tiers, ≥24h full and <24h half.

## What it is not

- Not a new payment path. `AURAD-0009` keeps the wallet; a refund credits the
  balance back.
- Not a change to a session that is already **running** — that stays
  non-refundable, and early end is the existing `finishSession`.
- Not the reminder or add-to-calendar work (`AURAF-0008` row 012).

## The thing that needs a decision

The design shows an **exact refund amount inside the sheet, before the user
confirms** ("$54.70 goes back to your balance"). The contract returns
`refundedMinor` only in the **response to the cancel**, and its own comment says
the app "renders the figure, it never decides the policy". There is no preview
endpoint. So the amount the sheet must show up front does not exist yet.
Resolution options are in `005-spec.md`.

## Next

`004-context.md`.
