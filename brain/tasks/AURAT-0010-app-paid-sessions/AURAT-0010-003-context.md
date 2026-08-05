# AURAT-0010-003 — Context (gaps & decisions needed)

Date: 2026-08-04

## G1 — Where the paid session lives, and what to call it

`entities/session` is taken by the Sessions-tab seed bookings (designs
12/13: a scheduled "1:1 video" with a date, a time and a reminder). A paid
chat session is a different noun: a metered window inside the durable
thread (`AURAD-0002/0003`).

FSD gives the way out: the paid session is a **verb** the user performs
(book a block / extend it / end it), with one consumer today (the chat
thread) — that is a **feature**, not an entity. Its data shape comes from
`@aura/contracts`, so no parallel entity type is needed at all. With that,
the collision only concerns the slice's *name*:

- **N1 (recommended) — `features/paid-session`.** Uses the exact vocabulary
  of `AURAD-0002` ("a paid session is a fixed block of minutes"); no
  existing code renamed; the two "session" words never meet in one layer.
- **N2 — `features/session-booking`.** Verb-shaped, unambiguous, longer;
  every import reads `@/features/session-booking`.
- **N3 — rename `entities/session` → `entities/booking`, then use
  `features/session`.** Cleanest long-term vocabulary (the Sessions tab
  really lists appointments), but renames shipped code and its tests for a
  slice that is pure seed data and will be rewritten anyway when bookings
  get a backend.

## G2 — How the app learns a session changed

The BFF emits WS `session.updated`, but that socket is owned by
`ChatProvider` (`features/chat`), and a feature may not import another
feature. Options:

- **G2-a (recommended) — no session WS subscription in v1.** Every session
  transition is either (i) the app's own call (book / extend / finish, each
  returning the new session), or (ii) the meter finishing the block **at
  exactly `endsAt`**, which the app already knows. So a local countdown plus
  a refetch of `…/sessions/active` on mount, on foreground and when the
  countdown hits zero is *exactly* as accurate as the push — and the red
  "finished" marker still arrives live through the chat socket. The
  contracts still gain the event (the BFF sends it), and `ChatProvider` is
  fixed to ignore it explicitly instead of mangling presence.
- **G2-b — promote the socket to a shared multi-subscriber singleton** so
  both features can listen. Architecturally the "right" shape, but it
  rewrites `ChatProvider`'s socket lifecycle and its test suite for no
  behavioural gain today. Recorded as a follow-up if a second WS consumer
  ever appears (presence in `AURAT-0009` stays inside chat).

## G3 — How much wallet to wire

The balance pre-check needs `GET /v1/wallet`, which is also the endpoint the
Profile card's hardcoded `$0.00` is waiting for (`AURAF-0007-008`, App
column). And a booking needs *money in the wallet* — with nothing wired, the
manor can only fund a test session by hand (curl/SQL).

- **G3-a (recommended) — read + stub top-up.** Wire `GET /v1/wallet` for
  the pre-check and for the real Profile balance, **and** point the existing
  `TopUpSheet` Pay button at `POST /v1/wallet/top-ups` (the stub credit).
  All of it behind the client flag, so with billing off the Profile card
  keeps showing today's `$0.00` placeholder. Makes the manor verification a
  pure device flow. Cost: the app now has a "payment" button that credits
  without taking money — invisible in production (flag off) and refused by
  the BFF there anyway.
- **G3-b — read only.** Pre-check + real Profile balance; the Top Up sheet
  stays inert; the manor funds wallets by curl before testing.
- **G3-c — pre-check only.** Nothing in Profile changes. Smallest diff,
  leaves a wired balance in one screen and a fake one in another.

## G4 — `@aura/contracts` v0.3.0: scope of the alignment

`session.ts` and `wallet.ts` get rewritten to the BFF as-built shapes (§1 of
the spec) and `chat.ts` gains `'system'` + `session.updated`. Two extra
questions ride along:

- The package still carries **`Money {amountCents, currency}`** and a
  speculative **`Advisor {…, pricePerMinuteCents, avatarUrl}`** — neither
  exists on any BFF endpoint (advisors are app seed data; money crosses the
  wire as `*Minor` integers) and neither has a consumer. **Recommendation:
  delete both**, keep `Currency` and `AdvisorId`. Alternative: leave them as
  forward declarations.
- Publishing: bump `0.3.0`, build, **tag `v0.3.0` and push `main` + tag to
  `github.com/RomSribn/aura-contracts`**, then move the app dependency from
  `#v0.2.0` to `#v0.3.0`. Pushing is an outward action — needs the same
  explicit authorization the owner gave for v0.2.0 in `AURAT-0006-005`.

The BFF keeps compiling against its own `src/contracts/` copy; migrating it
onto the package stays recorded BFF debt (unchanged by this task).

## Smaller calls (settled in the spec, listed for visibility)

- **`idempotencyKey`** must be a UUID (BFF zod). Hermes has no
  `crypto.randomUUID`; rather than add `uuid` + `react-native-get-random-values`
  for one string, `shared/lib` gets a ~6-line non-cryptographic v4
  generator, documented as such. The key is generated **once per booking
  attempt** and reused while the user retries, so a timed-out request
  replays instead of double-charging.
- **Two flags, one truth.** The client flag hides the UI; the server flag
  404s the routes. If the client flag is on while the server's is off, the
  mount-time `…/sessions/active` call 404s and the app silently keeps all
  session UI hidden — the safe direction, and it also covers "this advisor
  has no price row".
- **`Book now` when billing is off** keeps today's behaviour (navigate to
  the advisor profile) — it is design chrome from screen 10, not session UI.
- **Markers** render from `direction: 'system'` messages already in the
  chat feed, so they belong to `features/chat` + the thread screen, not to
  the new slice — no cross-feature import.
- **No new design assets.** The block picker reuses `BottomSheet` and the
  `TopUpSheet` card-grid pattern; the marker is a coral hairline separator
  (`theme.colors.accent` — the app's red). No new literals, no new tokens.
