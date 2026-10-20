# AURAT-0103-013 — Approved

Date: 2026-10-20
Owner: «Принято» after the manor check of `develop` `9443576` against bff-dev (guest without a
token: catalog of 8 advisors, −50% offer from pricing, filters and sort in the URL, profile with
slots and reviews, phone: Filters sheet, Back, action bar).

Done — public catalog `/advisors` and profile `/advisors/:id` (`AURAF-0020` rows 001, 002, UI ✓).
Code: `aefc5db` on `develop` (merge `9443576`).

Carried forward:
- Backlog `AURAF-0020-014…016` — server-side filters/sort/pages, infinite scroll for the catalog
  and reviews (tasks to be minted in `aura-app-manor`).
- Translations not reviewed by native speakers (agents flagged: name-in-sentence in cs/hr/fi/hu/
  pl/sk/sl, inflected «Aura» in et/fi/hu, mt, lv).
- Book / slots are deep links `?book=1&slot=` until the auth (gate + resume) and booking
  (Book sheet) tasks; Free chat → `/chats/:id` until the chat task.
