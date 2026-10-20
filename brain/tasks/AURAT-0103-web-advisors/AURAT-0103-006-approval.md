# AURAT-0103-006 — Approval

Date: 2026-10-20
Owner approved spec `005` without edits. Answers:
1. Guest offer — from the pricing answer (recommended): active when any block has
   `creditMinor > 0`, `pct` from the longest block's credit / subtotal; profile — its advisor's
   pricing, catalog — the first catalog advisor's pricing (one cached request). The signed-in
   person moves to `wallet.firstSessionOffer` with the wallet task.
2. CTAs before the auth and booking tasks — deep links: Free chat / Chat free → `/chats/:advisorId`;
   slot / Book session / All dates / Book → `/advisors/:id?book=1[&slot=…]`.

Execution.
