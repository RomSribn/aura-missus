# AURAT-0107-010 — Fix: a slot on the profile selects, Book opens

Date: 2026-10-20

Owner, verifying in the manor: a click on a "Next available" time opens the Book sheet at once —
«Нужно открывать шторку при нажатии на бук. иначе получается что кнопка бесполезная». The URL
not changing is as designed (the sheet is a dialog over the profile).

Change (overrides NAVIGATION §2.7 "slot → Book sheet pre-filled"):
- A slot in "Next available" is a choice (`aria-pressed`), not a link; the soonest is chosen by
  default (it is the one the card already highlights).
- **Book session** opens the sheet with the chosen time; the phone action bar's Book (no slots on
  phones) — the same, i.e. the soonest. **All dates & times** opens the sheet without a time.
- A guest chooses a time freely; Book asks to sign in and resumes with that time
  (`?book=1&slot=`), as before.
