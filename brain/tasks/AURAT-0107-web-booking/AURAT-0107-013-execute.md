# AURAT-0107-013 — Execute (fixes `010`, `012`)

Date: 2026-10-20

- `010` (slot selects, Book opens) — see `011`.
- `012`: the sheet (`widgets/book-sheet`) writes `?book=1&slot=<chosen>` onto **its own** history
  entry (only over the advisor's profile, only once the dialog host has pushed and marked that
  entry — otherwise the params would land on the page entry below); the slot follows the choice.
  The arrival hook still makes the link's entry plain first, so the stack is
  `[profile] → [profile?book=1&slot= (dialog)]`.
- Dialog host: a dialog whose URL names itself (`DIALOGS_OWNING_URL` = `book`) does not carry its
  URL onto the entry below on close (the Filters sheet still does) — that carry was what reopened
  the sheet. The dialog-entry mark (`isDialogEntry`, `DialogEntryState`) moved to
  `shared/model/dialog.ts` so the sheet can see it.
- Tests (`booking.test`): the URL names the sheet and the chosen time while open; Back from Booked
  → plain profile, no dialog; closing → plain; choosing another time updates `slot`; a reload
  (same entry, same state) reopens the sheet on that time. `app-shell.test` mock gets
  `DIALOGS_OWNING_URL`.
- Checks: lint ✓, typecheck ✓, tests 882/882 ✓, build ✓, prettier ✓. No new strings.

Not committed — staged for review.
