# AURAT-0105-004 — Context

Date: 2026-10-20

## Sources

- `AURAF-0020` row 005; `AURAD-0019` (Р5); `AURAI-0007` (FSD map: entity `message`, features
  `send-message`, `tarot-pick`, widgets `conversation-list`, `chat-thread`, `advisor-rail`, page
  `chats`); `AURAF-0007`, `AURAF-0012`, `AURAF-0013`, `AURAF-0018`; `AURAD-0001…0003`, `AURAD-0011`.
- Web handoff: README §1, §2, §4.5, §6, §7, §8; NAVIGATION §1.1, §2.1, §2.8, §3.3, §3.4, §4, §6;
  STRUCTURE; prototype `web/web-chats.jsx`, `web/web.css`, `web/web-kit.jsx`,
  `src/components/chat/Messages.tsx`; sheet `Aura Web - Chats.html`; superseded `Aura Web - Plan.html`
  §03 (tablet: 2 columns).
- Mobile handoff: README (chat, tab bar), `SESSIONS_BOOKING.md` §5b, `DAILY_CARD_TAROT.md`,
  `CHAT_ATTACHMENTS.md`, `MOTION_AND_ICONS.md`.
- aura-app (read-only): `features/chat` (`ChatProvider` + 2 tests, `lib/map-message`, `chat-api`,
  `attachment-rules`), `features/tarot-spread` (`lib/fan-layout`, `model/use-spread`, `config/copy`),
  `screens/chats` (`lib/preview`, `model/use-chats`), `screens/chat-thread`, `shared/api/bff/ws-client`.
- aura-bff (read-only): `modules/chat` (controller, service, prisma repo, attachment intake,
  attachments controller), `modules/delivery/{chat.gateway,delivery.service}.ts`,
  `modules/presence/{presence,typing}.service.ts`, `modules/tarot`, `modules/sessions` (markers,
  invite token), `common/web/web-origins.ts`, `app.setup.ts` (rate limit).
- `@aura/contracts` v0.22.0 (= HEAD `003040a`): `chat.ts` (`Message`, `HistoryQuery`,
  `HistoryResponse`, `SendMessageRequest`, `SendRefusalCode`, `WsServerEvent`), `tarot.ts`
  (`MessageSpread`, `PickSpreadCardResponse`), `session.ts` (`SessionInvite`, `SessionPricing`),
  `advisor.ts` (`greeting`, no `online`).
- aura-web `develop` @ `2cf2a03`: `shared/api/ws-client.ts` (no consumer), `base-query.ts`,
  `server-clock.ts`, `firebase.ts` (`onIdentityChange`, `useAuthStatus`), `app/session`,
  `PrivateRoute` + `gate('chats')`, routes `/chats`, `/chats/:advisorId` (`element: null`),
  `NAV_ITEMS`, `entities/advisor` (catalog in RTK Query), `entities/session` (pricing, offer, billing
  state), Free chat links of `AURAT-0103`/`AURAT-0104`.

## Findings — data (BFF as is)

1. **No conversation list, no read marks, no unread counts** — neither BFF, contract nor app. The app
   builds the list from history per catalog advisor (8 personas); rows = threads with messages; order
   = insertion (not recency). No unread badge anywhere in the app.
2. **History** `GET /v1/advisors/:id/messages?after|before|limit|deletedFrom`: `limit` 1–100 (50
   default), pages always ascending, order by desk position; no cursor / `before` → newest page;
   `after` wins over `before`; **an unknown cursor silently means "no cursor"** (newest page); no
   `hasMore` (short page = end); `deletedIds` only with `deletedFrom` (ids ≥ that position, cap 200).
   GET never creates a conversation: unknown advisor → empty 200. The app never pages back.
3. **Send** `POST …/messages {content ≤ 4000 trimmed, idempotencyKey 8–64}` → 201 `Message`;
   creates the conversation itself (the `PUT …/conversation` route is not needed; the contract
   comment says POST — stale). Key is permanent per conversation: a retry returns the stored message.
   Refusals with `code`: `message_empty` 400, `refused_by_agent_desk` 422 (+ attachment codes);
   without `code`: 502 desk down (retryable), Zod 400, 429 (plugin body). Unknown well-formed advisor
   id → a real conversation is created (no FK) — `:advisorId` must come from the catalog.
4. **Message** `{id, advisorId, direction user|advisor|system, content, createdAt, attachments[],
   idempotencyKey (user only), spread?, sessionInvite?}`. Attachments have no URL: bytes via
   `GET /v1/attachments/:id` with Bearer (fetch → blob URL; 404 = gone). Spread:
   `{picked:null}` | `{picked:{position,at}, card:{id,name,keywords,daily,imageUrl}}`; `imageUrl` is a
   public asset URL (like `avatarUrl`) — `<img src>` works. `sessionInvite: {}` — empty by design
   (`AURAF-0013`: **no duration, no price** on the card — owner decision; the booking sheet names the
   numbers). Session markers: `direction:'system'`, exact English «Your session has started» /
   «Your session has finished», nothing machine-readable; the app colours by `/\bstarted\b/` and never
   rewrites the text.
5. **WS** `/ws?token=`: server→client only; `message.new` (advisor + system messages only — **own
   messages are never echoed**, not even to the person's other devices), `message.deleted`,
   `typing.update` (advisor typing from Chatwoot, on transitions, server TTL 45 s → `false`; not
   cleared by a new message), `presence.update` (one global «an agent is online», sent per advisor the
   person has a conversation with, snapshot on connect only if already known), `session.updated`
   (paid session — not this task). Protocol ping 30 s. Close 4403 «forbidden origin» / 4401
   «unauthorized» / 4401 `ACCOUNT_DELETED` — **all after `open`**. No «registered» frame.
6. **Tarot pick** `POST /v1/tarot/spread/:messageId/pick {position 0..6}` → `{card, position,
   pickedAt}`; atomic, first pick wins (repeat → 200 with the first); 404 for foreign / deleted /
   unknown. No WS event — another device sees the pick only by re-reading that message.
7. **Rate limit** 120 req/min per IP on every REST route (attachments included); `/ws` exempt.
   **CORS has no `exposedHeaders`**: `Date` is unreadable cross-origin → `recordServerTime` gets
   `null`, `serverNow()` silently runs on the device clock (also for the slots of `AURAT-0103`).
8. **Pricing** `…/sessions/pricing` (guest ok): 404 when billing is off (and «not bookable»).

## Findings — web handoff vs app vs data

9. Desktop 3 columns `340 · 1fr · 320` (list · thread · rail); phone: list, then thread with back
   arrow, rail hidden. Nothing for 761–1180 (at 761 the thread would be ~100 px); Plan.html (superseded)
   said 2 columns + panel. `/chats` without id on desktop — not specified; the prototype always has a
   thread open.
10. **Tab bar in the thread (phone):** web handoff shows it (only Pay / profile hide it); mobile hides
    it (pushed, «design allows both»).
11. **Unread badge:** web handoff — on the Chats link and per row (count of unread conversations,
    hidden for guests and at 0). App — none. Data — none.
12. **Typing:** app renders three dots (one advisor at a time, no timeout); web handoff draws nothing.
13. **Search chats:** a static field in the prototype, no behaviour anywhere; app has none.
14. **Composer:** web — single-line, «Write a message…», paperclip (v2), send always teal; app —
    single-line, return sends, send teal only with text. Enter/Shift+Enter: web defines it only for
    Ask (Enter = ask, Shift+Enter = newline). 4000 is enforced only by the server.
15. **Tarot:** web — big plum card 560, fan of 7 with hover lift, click, flip 520 ms after the answer,
    result stays as the big flipped card + «You chose {card}» + keywords; app — drag fan 266, compact
    result + divider. Keyboard: not drawn (Plan.html mentions it).
16. **Invite:** web — minutes + struck price + inline Quick book + «Not now»; app — no price, no
    minutes, offer line `{pct}% OFF First Session — applied for you`, CTA → booking, no dismiss
    (`AURAF-0013`). The stub asks for «price from pricing» — contradicts `AURAF-0013`; to decide.
17. **Bubbles:** me — coral, advisor — card with border, no avatar, time inside 11 px; day separators
    and system lines — centred pill. App: no day separators (date dropped in `mapMessage`), ✓/✓✓.
18. **Rail:** photo, name, tagline, rating, price `/min`, Quick book (row 006), View profile, privacy
    note. Header: calendar icon → Book (row 006).

## Findings — web code

19. `BffSocket` resets backoff on `open` → 4401/4403 (sent after open) reconnect every ~1 s forever;
    no fatal close; no forced token refresh on 4401. The app's twin has the same reset (a fix goes to
    both sides — app task via `aura-app-manor`).
20. `app/session/use-account-session.ts` is the place that already follows identity
    (`resetApiState`); the socket should live there (start signed-in, stop guest, restart on change).
21. Routes `/chats`, `/chats/:advisorId` exist behind `PrivateRoute` with `element: null`; Chats nav
    item is gated for guests; `useAdvisor` reads the cached catalog (unknown id → `null`).
22. `entities/session` already has `useSessionPricing` (billing `on|off|unknown|loading`, `offerPct`).
    `PriceTag`, `OffChip`, `Avatar`, `EmptyState`, `IconButton`, `Sheet` exist in `shared/ui`.
23. Rule «events update RTK Query cache, never a parallel store» — presence/typing are not REST
    answers; they go into cache entries of their own (`queryFn` + `updateQueryData`).

Next: spec (005).
