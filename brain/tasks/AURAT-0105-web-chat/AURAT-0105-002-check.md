# AURAT-0105-002 — Check

Date: 2026-10-20
Slave: slave-1, branch `feature/AURAT-0105-web-chat` (master from `develop` @ `2cf2a03`,
missus from `9c613db` — the local stub commit, not on origin yet; origin has nothing newer).

- Task folder exists with the stub `001-initial.md` only (minted in `aura-app-manor`). Fresh
  work, nothing executed.
- `AURAT-0101` done: `shared/api/ws-client.ts` (`BffSocket`, no consumer yet),
  `server-clock`, `refusal-code`. `AURAT-0103` done: catalog in RTK Query, pricing and offer,
  deep link `?book=1`. `AURAT-0104` done: sign-in, `onIdentityChange` → `resetApiState`, gate
  with resume (Free chat → `/chats/:advisorId`); the chats badge was moved to this task
  (`AURAT-0104-005` §5).
- Feature: `AURAF-0020`, row 005 (chat), UI column.

Next: understand (003).
