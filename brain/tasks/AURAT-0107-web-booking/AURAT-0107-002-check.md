# AURAT-0107-002 — Check

Date: 2026-10-20
Slave: slave-1, branch `feature/AURAT-0107-web-booking` (master from `develop` @ `708d7f6`,
missus from `8787a7e` — the local stub commit, not on origin yet).

- Task folder exists with the stub `001-initial.md` only (minted in `aura-app-manor`). Fresh
  work, nothing executed.
- `AURAT-0103` done: `entities/session` (pricing, availability, guest offer), deep link
  `?book=1&slot=`. `AURAT-0104` done: gate with resume (`reason: 'book'`). `AURAT-0105` done:
  booking CTAs in the chat lead to `?book=1`; its step 014 names booking as next.
- `AURAT-0106` (BFF exposes `Date` / `Retry-After`) — in progress in `aura-bff-manor`; the web
  does not depend on it.
- Feature: `AURAF-0020`, rows 006 (booking from balance) and 007 (card / wallet on a fake PSP
  behind a flag), UI column.

Next: understand (003).
