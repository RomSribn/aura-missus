# AURAT-0107-011 — Execute (fix `010`)

Date: 2026-10-20

- `pages/advisor`: "Next available" slots are buttons (`aria-pressed`), the soonest chosen by
  default (`.selected` replaces the first-child highlight). Book session — the sheet on the time
  chosen here; if none was chosen explicitly, on the tab's draft time, else the soonest (`soonest`
  seed — the draft keeps precedence over the default highlight). All dates & times — the sheet
  without a time. The phone action bar's Book behaves as Book session. Guests: Book's link carries
  the chosen time through sign-in (`?book=1&slot=`).
- Tests: `advisors.test` (slots are choices, Book carries the chosen time, All dates without);
  `booking.test` — opening through Book session, a new scenario "a time chosen on the profile is
  the one the sheet opens on; All dates opens without one".
- No new strings. Checks: lint ✓, typecheck ✓, tests 881/881 ✓, build ✓, prettier ✓.

Not committed — staged for review.
