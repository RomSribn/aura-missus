# AURAT-0010-004 — Spec (implementation)

Date: 2026-08-04
Status: draft — awaiting owner approval
Branch: `feature/AURAT-0010-app-paid-sessions` (slave-1)

App side of `AURAF-0007` items 006/007 (+ the read half of 008) against the
live BFF of `AURAT-0007/0008`. Written on the recommended answers to G1–G4
(N1 · G2-a · G3-a · delete the dead contract shapes) — the four are listed
again in §11 for approval, and only §1, §3 and §7 change if the owner picks
differently.

Everything obeys the FSD hard rules: public APIs + `@/` alias, model/lib
split, render-only screen `ui/`, theme tokens only, memoized rows, no dead
exports, no PII in logs.

---

## 1. `@aura/contracts` 0.3.0 (prerequisite, own repo)

Ground truth = `aura-bff/src/contracts/{session,wallet,message}.ts`.
Package convention (unchanged): one PascalCase const per schema, plus an
inferred type of the same name.

**`src/session.ts` — rewritten** (the v0 `PaidSession` / lowercase
`SessionStatus` placeholder goes):

```ts
export const SessionStatus       = z.enum(['ACTIVE', 'FINISHED']);
export const SessionFinishReason = z.enum(['EXHAUSTED', 'ENDED_EARLY']);

export const Session = z.object({
  id: z.string(),
  advisorId: AdvisorId,
  status: SessionStatus,
  bookedMinutes: z.number().int().positive(),        // incl. extensions
  priceMinorPerMinute: z.number().int().positive(),  // booking snapshot
  costMinor: z.number().int().positive(),            // total charged
  startedAt: z.string(),
  endsAt: z.string(),                                // moves on extend
  finishedAt: z.string().nullable(),
  finishReason: SessionFinishReason.nullable(),
});

export const BookSessionRequest   = z.object({
  minutes: z.number().int().positive(),              // one of the blocks
  idempotencyKey: z.string().uuid(),
});
export const ExtendSessionRequest = BookSessionRequest;
export const BookSessionResponse  = z.object({ session: Session, balanceMinor: z.number().int() });
export const FinishSessionResponse= z.object({ session: Session });
export const ActiveSessionResponse= z.object({ session: Session.nullable() });
export const SessionPricing       = z.object({
  priceMinorPerMinute: z.number().int().positive(),
  blocks: z.array(z.object({ minutes: z.number().int().positive(),
                             costMinor: z.number().int().positive() })),
});
```

**`src/wallet.ts` — rewritten** to the as-built `WalletResponse
{balanceMinor, currency}`, `TopUpRequest {amountMinor (int, >0, ≤1_000_000),
idempotencyKey uuid}`, `TopUpResponse {entryId, balanceMinor, currency}`.

**`src/chat.ts`** — `MessageDirection` gains `'system'` (BFF-authored
session markers); `WsServerEvent` gains
`{type: 'session.updated', advisorId, session: Session}`. The forward
`presence.update` / `typing.update` events stay (still `AURAT-0009`).

**`src/money.ts` / `src/advisor.ts`** — drop the unused `Money` and
`Advisor` objects, keep `Currency` and `AdvisorId` (G4).

Ship: `npm run typecheck` + `npm run build` (tsup ESM/CJS/dts) + a
node smoke-parse of one real payload of each new schema → commit → **tag
`v0.3.0`, push `main` + tag**. App: `package.json` dependency
`github:RomSribn/aura-contracts#v0.3.0`, `npm install`.

The BFF keeps its local copy (migrating it stays recorded BFF debt).

## 2. `shared` additions

- `config/env.ts` — `export const BILLING_ENABLED = false;` The client half
  of the `AURAD-0002` rollout flag: with it `false` no session UI mounts and
  no billing endpoint is ever called. Commented as "mirror of the BFF's
  `BILLING_ENABLED`; both must be on".
- `lib/uuid.ts` — `randomUuid()`, RFC-4122-shaped v4 from `Math.random`,
  documented as **non-cryptographic** (it is an idempotency key, not a
  secret; the BFF scopes keys per wallet).
- `lib/format.ts` — `formatUsdMinor(cents)` (delegates to `formatUsd`), the
  one place cents become "$1.99". Exported from the shared root with the
  rest.

## 3. `features/paid-session` — the new slice

```
features/paid-session/
├── api/sessions-api.ts    fetchPricing · fetchActiveSession · bookSession
│                          · extendSession · finishSession  (zod-parsed)
├── api/wallet-api.ts      fetchWallet · topUpWallet
├── config/constants.ts    EXTEND_PROMPT_SECONDS (120) · TICK_MS (1000)
├── lib/remaining.ts       remainingSeconds(endsAt, now) — pure, clamped ≥0
├── lib/format-countdown.ts  seconds → "M:SS" / "MM:SS"
├── lib/blocks.ts          pricing + balance → BlockOption[] (cost label,
│                          affordable flag)
├── model/use-paid-session.ts   the orchestration hook
├── model/use-wallet.ts    balance read + stub top-up (G3)
├── model/types.ts         PaidSessionControls, BlockOption, PickerMode
├── ui/SessionBar.tsx      active-session bar (controlled, presentational)
├── ui/SessionBlockSheet.tsx  block picker on the shared BottomSheet
└── index.ts               hook + the two components + types
```

### 3.1 `api/` — thin, typed, no business rules

Each function is one `bffRequest` + one contract parse; paths are exactly
the BFF's (`/v1/advisors/:id/sessions/pricing|active`, `/v1/advisors/:id/sessions`,
`/v1/sessions/:id/extend|finish`, `/v1/wallet`, `/v1/wallet/top-ups`),
`advisorId` / `sessionId` URL-encoded. No retries here — `bffRequest`
already refreshes a 401 once, and everything else is a decision the model
makes from `BffApiError.status`.

### 3.2 `model/use-paid-session.ts` — the whole flow in one hook

`usePaidSession(advisorId)` → `PaidSessionControls`:

| field | meaning |
|---|---|
| `enabled` | `BILLING_ENABLED` **and** the server did not 404 the mount call |
| `active` | the running `Session`, or `null` |
| `remainingSeconds`, `countdownLabel` | derived from `active.endsAt`, ticking 1 Hz |
| `nearEnd` | `remainingSeconds <= EXTEND_PROMPT_SECONDS` |
| `picker` | `{visible, mode: 'book'|'extend', blocks, balanceMinor, priceLabel, loading, submitting, error}` |
| `openPicker` / `openExtend` / `closePicker` | picker control |
| `confirm(minutes)` | books or extends by mode |
| `endEarly()` | non-refundable confirm → finish |
| `goTopUp()` | jump to Profile → Top Up (G3) |

Behaviour:

- **Mount** (only when `BILLING_ENABLED` and signed in): `fetchActiveSession`.
  A `404` means the server flag is off → `enabled = false`, nothing else is
  ever requested for this thread. Any other failure leaves the UI hidden and
  is retried on the next foreground.
- **Countdown** is derived, never stored as a duration: one `setInterval`
  while a session is active, recomputing from `endsAt`. At zero the hook
  refetches `…/sessions/active` once — the meter has finished the block at
  the same instant server-side — and clears `active` when it comes back
  `null`/`FINISHED`. The red "finished" marker arrives independently through
  the chat feed.
- **Foreground** (`AppState` → `active`) refetches the active session, so a
  block that expired while the app was backgrounded is already gone when
  the user looks.
- **Picker open** fetches pricing and wallet balance in parallel. Pricing
  `404` → "This advisor isn't bookable yet" (the `AURAT-0008` D1 rule: no
  advisors row = no price, never a default). Blocks costing more than the
  balance render disabled with a "Top up" affordance — the **balance
  pre-check**, before any money call.
- **Booking** generates one `idempotencyKey` per attempt, held in a ref: a
  failed *network* call keeps the key so a retry replays server-side instead
  of double-charging; a definitive answer (success, 402, 409, 400, 404)
  clears it. `409` (an active session already exists) refetches the active
  session and flips the picker to `extend` — the state the user actually
  wanted. `402` shows the insufficient-balance state with the top-up route.
- **Extend** posts to the same window; on success `endsAt` moves and *no*
  marker appears (`AURAD-0002` — markers bracket the session, extensions
  don't repeat them).
- **Early finish** goes through an `Alert` in the model (never in `ui/`)
  spelling out the forfeit: *"End session? The remaining X min are
  non-refundable and will not be returned to your balance."* Confirm →
  `finishSession` → `active = null`.

Signed out, or with the flag off, the hook is fully inert (no timers, no
requests) — the same discipline `ChatProvider` follows.

### 3.3 `ui/` — presentational only

- **`SessionBar`** — renders nothing without an active session. Otherwise a
  bar under the thread header: teal-soft while the block runs
  (`Session · 07:32 left`, `Extend` soft button, `End` ghost button), coral
  once `nearEnd` (`Ends in 1:59 · Extend?`) — the near-end prompt is the bar
  changing state, not a modal that interrupts a conversation.
- **`SessionBlockSheet`** — `BottomSheet` with the advisor's per-minute
  price as the subtitle and one card per server block (`10 min · $19.90`),
  the `TopUpSheet` card-grid pattern reused; unaffordable cards disabled
  with the balance line and a `Top up` link; footer button
  `Book · $19.90` / `Extend · $19.90` with a spinner while submitting;
  error states inline. Copy states the rule once, plainly: *"Blocks are
  non-refundable once started."*

## 4. Markers in the thread (`features/chat` + `screens/chat-thread`)

- `model/types.ts` — `MessageAuthor` gains `'system'`.
- `lib/map-message.ts` — `direction: 'system'` → `from: 'system'`; the text
  is the server's own line ("Your session has started/finished"), never
  re-invented client-side.
- `model/ChatProvider.tsx` — the WS handler becomes an explicit switch:
  `message.new` / `typing.update` / `presence.update` handled,
  `session.updated` **explicitly ignored** (G2-a) with the reason in a
  comment. This removes the latent bug where the current `else` branch would
  write `presence[advisorId] = undefined` for any new event type.
- `screens/chat-thread/ui/SessionMarker.tsx` (new, memoized) — centered
  coral hairline separator with the marker text; `MessageBubble` returns it
  for `from === 'system'`, so markers stay id-ordered inside the same
  FlatList, exactly as the BFF stores them.

## 5. Wiring

- `screens/chat-thread/model/use-chat-thread.ts` calls `usePaidSession(advisorId)`
  and re-exports the bundle; `openBooking` becomes: session UI enabled →
  open the picker; otherwise → today's navigate-to-profile.
- `screens/chat-thread/ui/ChatThreadScreen.tsx` renders `<SessionBar/>`
  under the header and `<SessionBlockSheet/>` at the root — both driven by
  props from the model hook, no logic of their own.
- `screens/profile` (G3) — `use-profile` reads the real balance through
  `features/paid-session`'s wallet hook when billing is enabled (falling
  back to today's `$0.00` placeholder when off), and `TopUpSheet`'s Pay
  button calls the stub top-up, closing on success and surfacing failures
  inline.
- `shared/config/navigation.ts` — `Profile` route params gain an optional
  `{sheet?: 'topup'}` so the picker's "Top up" can cross tabs and land with
  the sheet open. Contract change only; the app layer is untouched.

## 6. Tests (slave-pure — no network, no native, no timers left running)

- `sessions-api` / `wallet-api`: paths, bodies, contract parsing, error
  propagation as `BffApiError`.
- `lib`: `remaining` (clamping, past `endsAt`), `format-countdown`,
  `blocks` (affordability edges: cost == balance, cost > balance).
- `use-paid-session` (fake timers): inert when the flag is off; inert when
  signed out; mount 404 → permanently hidden; countdown ticks and hits zero
  → refetch → cleared; `nearEnd` flips exactly at the threshold; book happy
  path sets the session; **the same `idempotencyKey` is reused across a
  network retry and a fresh one is used after a definitive error**; 402 →
  insufficient state; 409 → refetch + extend mode; extend moves `endsAt`;
  early finish confirms first, then clears.
- `map-message`: `'system'` mapping. `ChatProvider`: a `session.updated`
  frame leaves `presence`/`threads` untouched.
- Rendering: `SessionBar` (hidden / running / near-end), `SessionBlockSheet`
  (blocks, disabled unaffordable, not-bookable), `ChatThreadScreen` (marker
  renders; with the flag off there is no bar and Book now still navigates).
- Existing 21 suites / 73 tests stay green and unmodified except where the
  new prop bundle reaches them.
- Gates: `npm run lint`, `npx tsc --noEmit`, `npm test`.

## 7. Out of scope (explicit)

BFF changes of any kind; PSP / real card payments (the top-up stays the
BFF's stub, refused in production); advisor catalog — the BFF `advisors`
price rows stay manual SQL (TECH-DEBT row 10), so **an advisor with no row
is simply not bookable in the app**; scheduling a block for later; a "Book a
session" CTA on the advisor profile (Start free chat is unchanged); the
Sessions tab and its seed bookings; presence/typing (`AURAT-0009`);
session history / receipts; offline queueing; iOS APNs.

## 8. Acceptance mapping (from 001-check)

| Acceptance | Covered by |
|---|---|
| Flag off ⇒ v1 unchanged | §2 flag + §3.2 inert hook + §5 fallbacks; test in §6 |
| Book now → block picker with server prices | §3.1 pricing + §3.3 sheet |
| Balance pre-check | §3.2 picker-open parallel wallet fetch, affordability in `lib/blocks` |
| Booking is idempotent | §3.2 key-per-attempt ref; §6 test |
| Live countdown | §3.2 derived from `endsAt`, 1 Hz |
| Extend near the end | §3.2 `nearEnd` + §3.3 bar state → picker in extend mode |
| Early finish warns about the forfeit | §3.2 `Alert` copy |
| Red markers in the thread | §4 |

## 9. Manor verification plan (post-merge, flag on)

1. Flag off in the app: thread identical to today; no `/v1/sessions*` or
   `/v1/wallet` request leaves the device (proxy/log check).
2. BFF `BILLING_ENABLED=true`, `SESSION_BLOCK_MINUTES=1,10,20,30`, price
   rows inserted for the seed advisors; app flag on, `npm install` (new
   contracts tag) + rebuild.
3. Unregistered advisor → picker says "not bookable"; no booking possible.
4. Empty wallet → blocks disabled, Top up → Profile sheet → stub credit →
   balance updates in Profile and in the picker.
5. Book a 1-min block → wallet debited exactly `1 × price`, red "started"
   marker in the thread **and** the activity line in the Chatwoot dashboard,
   countdown runs.
6. Wait it out → block finishes at `endsAt`, red "finished" marker, bar
   disappears; kill/reopen mid-block → session and countdown restored.
7. Extend near the end → `endsAt` moves, second SESSION_CHARGE, **no**
   extra marker.
8. End early → forfeit warning → finished marker, no refund entry;
   repeat → idempotent.
9. Double-tap Book / airplane-mode retry → exactly one ledger charge.

## 10. Risks

- The `@aura/contracts` bump is load-bearing: on v0.2.0 a single SYSTEM
  marker in history silently kills thread sync (002 §"contract drift").
  **`BILLING_ENABLED` must not be switched on anywhere until this task is
  merged and shipped.**
- The countdown trusts device time. Skew shifts only the *display* and the
  extend prompt; every charge and the actual finish are server-side.
- `Math.random` UUIDs: collision risk is negligible and scoped per wallet;
  worst case is a 409 the UI already handles.

## 11. Decisions for approval

1. **G1 naming** — new slice `features/paid-session`; `entities/session`
   (seed bookings) untouched.
2. **G2 live sync** — no WS `session.updated` subscription in v1; local
   countdown + refetch; `ChatProvider` fixed to ignore the event explicitly.
3. **G3 wallet scope** — read `GET /v1/wallet` for the pre-check *and* the
   real Profile balance, plus the existing Top Up sheet wired to the BFF's
   stub credit (all behind the client flag).
4. **G4 contracts** — align session/wallet/chat to as-built, delete the
   unused `Money` / `Advisor` shapes, **publish `v0.3.0` (tag + push to
   GitHub `main`)** and move the app dependency to the tag.
