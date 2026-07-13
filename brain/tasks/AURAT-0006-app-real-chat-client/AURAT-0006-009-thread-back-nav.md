# AURAT-0006-009 — Follow-up: back from thread landed on Home

Date: 2026-07-12
Branch: `feature/AURAT-0006-thread-back-nav` (slave-1)

Owner found on device: leaving the advisor chat put them on Home, not the
Chats list.

**Root cause** (pre-existing since AURAF-0002/0003, surfaced by real
usage): every cross-tab jump — `navigate(CHATS, { screen: CHAT_THREAD })`
from advisor profile / Home / Sessions / notification deep link — mounts
the nested stack with the target as its **only** route (React Navigation
ignores `initialRouteName` for nested navigates). Back can't pop inside
the stack, bubbles to the tab navigator, whose default `backBehavior`
is the first tab → Home. Same latent bug for jumps to ADVISOR_PROFILE.

**Fix**: `initial: false` on all 7 nested jump sites (4 thread entries
incl. `navigation-ref` deep link, 3 profile entries) — the stack root
(chats/advisors list) renders beneath, back leads to the list. Root-level
jumps (`ADVISORS_LIST`) untouched.

Gates: tsc ✓ · eslint ✓ · jest 21/73 ✓. Merge gate passed (owner) —
merged into develop and pushed to origin; slave-1 released. BFF-side
`62b0575` (414 fix) also pushed to aura-bff develop this session.
