# AURAT-0105-006 — Approval

Date: 2026-10-20

Owner: «давай по рекомендациям» — spec `005` approved with every recommendation:

1. Unread badge — «new during this visit» (in memory, cleared by opening the thread / reload);
   server read marks → backlog.
2. Typing — three dots in the thread (cleared on `typing:false`, the advisor's `message.new`,
   socket drop).
3. Search chats — not rendered.
4. `/chats` without id on desktop — `replace` to the freshest thread; none → empty state.
5. 761–1180 — two columns (list · thread), rail hidden; boundary = existing 1180.
6. Tab bar in the thread on phones — hidden (pushed flow).
7. Enter sends / Shift+Enter newline on a fine pointer; touch — Enter = newline, send by button.
8. Session markers — the two exact BFF texts translated by key; unknown system text as is;
   machine-readable marker → backlog.
9. Invite card — no price, no minutes (`AURAF-0013`), offer line only.

BFF gaps: none changed in this task. Owner to mint in `aura-app-manor` now: `…-bff-expose-headers`
(`exposedHeaders: Date, Retry-After`). Backlog (recorded in `AURAF-0020`): fan-out of the user's own
messages, socket `ready` frame + the same `ws-client` fix in the app, tarot pick event,
machine-readable marker, `GET /v1/conversations` + read marks, contract `POST`→`PUT` comment.

Next: execute (007).
