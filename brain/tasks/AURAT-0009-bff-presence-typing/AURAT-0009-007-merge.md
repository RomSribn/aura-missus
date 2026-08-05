# AURAT-0009-007 — Merge

Date: 2026-08-05
Owner-approved in the moment (merge gate), then `bin/wts-finish slave-1`.

- Feature branch: `feature/AURAT-0009-bff-presence-typing`
- Feature commit: `1944e18` (36 files, +1344/−19)
- Manor `develop` after merge: **`8c3734e`** (`Merge feature/AURAT-0009-bff-presence-typing`)
- Push to origin: ✓ `62b0575..8c3734e  develop -> develop`
- Idle slaves 2–5 refreshed to the new master.

Missus reported "Already up to date" — correct: docs are still uncommitted by
design and land as one commit at task close (step 8), released with
`wts-release`. Slave-1 stays on the feature branch for post-merge step files.

## Verify in the manor (runtime — not provable in a slave)

Stack: `docker compose up --build` in the manor, `CHATWOOT_*` pointed at the dev
`Channel::Api` inbox, app on the local BFF.

1. **Typing appears live.** Chatter types in the Chatwoot dashboard → the
   persona indicator shows in the app within a second or so.
2. **Typing clears on stop.** Stop typing → indicator clears in ~4–6s (Chatwoot's
   own `typing_off` at 4s idle). Sending the reply clears it too.
3. **Typing clears on timeout.** Kill the webhook mid-burst (or stop the tunnel)
   → the indicator clears at `TYPING_TTL_SECONDS` (45s), not before.
4. **Private note raises nothing.** Switch the dashboard composer to the private
   note tab and type → **no** indicator in the app.
5. **Presence follows availability.** Toggle the chatter's availability
   Online → Busy → Offline in Chatwoot → the persona dot follows within one poll
   (30s). `busy` must read as offline.
6. **Service User alone does not fake it.** With only the BFF's service User
   "online", the dot stays off — confirms the `/api/v1/profile` exclusion works
   against the real instance.
7. **Presence on connect.** Background/foreground the app (fresh WS handshake) →
   dots are correct immediately, without waiting a poll.
8. **Availability endpoint reachable.** Watch for a repeated
   "agent availability read failed" warning: if the service token is refused on
   `assignable_agents`, switch to `/inboxes/{id}/assignable_agents` or `/agents`
   (one line in `ChatwootClient.fetchInboxAvailability`) — the fallbacks the spec
   pre-cleared.
9. **Logs stay clean.** No agent name, email or id anywhere; no message content.
   The typing payload carries all three on the wire, so this is the real check
   that the seam holds.
