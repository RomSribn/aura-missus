# AURAT-0103-003 — Understand

Date: 2026-10-20

A guest (and a signed-in person) opens the public catalog `/advisors` and an advisor's profile
`/advisors/:id` in aura-web, with the data the BFF gives a guest after `AURAT-0102`: the catalog
(one `GET /v1/advisors` for both screens), the per-block price with the first-session offer and
the free slots. Filters and sort run on the client and live in the URL; on phones Filters is a
Sheet, and Back closes an open dialog first. Guest CTAs that belong to later tasks (sign-in gate,
Book sheet) must lead somewhere real without stub handlers — the spec decides where.

Next: context (004).
