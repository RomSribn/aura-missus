# AURAT-0010-006 — Execute

Date: 2026-08-04
Branch: `feature/AURAT-0010-app-paid-sessions` (slave-1). App repo NOT
committed — awaiting IDE review. `@aura/contracts` **is** committed and
pushed (owner-authorized in 005).

## `@aura/contracts` — v0.3.0 published

`main` @ `3c595d7`, tag `v0.3.0`, pushed to `github.com/RomSribn/aura-contracts`.

- `src/session.ts` rewritten to the BFF as-built: `Session` (uppercase
  `SessionStatus`, `bookedMinutes`, `priceMinorPerMinute`, `costMinor`,
  nullable `finishedAt`/`finishReason`), `SessionFinishReason`,
  `SessionPricing`, `BookSessionRequest` (`minutes` + uuid
  `idempotencyKey`), `ExtendSessionRequest`, `BookSessionResponse`
  (`session` + `balanceMinor`), `FinishSessionResponse`,
  `ActiveSessionResponse`. The v0 `PaidSession` placeholder is gone.
- `src/wallet.ts` rewritten: `WalletResponse` / `TopUpRequest` /
  `TopUpResponse` in integer minor units (the nested `Money` object is gone).
- `src/chat.ts`: `MessageDirection` gains `'system'`; `WsServerEvent` gains
  `session.updated`.
- `src/money.ts` / `src/advisor.ts`: unused `Money` and `Advisor` deleted,
  `Currency` and `AdvisorId` kept. README table refreshed.
- Verified: `tsc --noEmit`, `tsup` (ESM/CJS/dts), and a smoke parse of
  as-built payloads for every new schema **plus negative cases** (the v0
  lowercase status and a non-uuid key are rejected).

App dependency moved to `github:RomSribn/aura-contracts#v0.3.0` (npm needed
an explicit re-install: a plain `npm install` kept the cached v0.2.0 commit).

## App — created

- `src/entities/wallet/` — `api/wallet-api.ts` (`fetchWallet`,
  `topUpWallet`), `model/use-wallet.ts` (`useWallet`: balance, refresh,
  stub credit; inert when billing is off or signed out), `index.ts`.
  **Entity, not feature**: two unrelated slices read it — the booking
  pre-check and the Profile card.
- `src/features/paid-session/` — the whole flow:
  `api/sessions-api.ts` (pricing / active / book / extend / finish),
  `config/constants.ts` (`EXTEND_PROMPT_SECONDS` 120, `COUNTDOWN_TICK_MS`),
  `lib/remaining.ts` + `lib/format-countdown.ts` + `lib/blocks.ts` (pure),
  `model/use-paid-session.ts` (the state machine), `model/types.ts`,
  `ui/SessionBar.tsx`, `ui/SessionBlockSheet.tsx`, `index.ts`.
- `src/screens/chat-thread/ui/SessionMarker.tsx` — the red separator.
- `src/shared/lib/uuid.ts` — `randomUuid()` (non-cryptographic, documented).

## App — modified

- `shared`: `config/env.ts` (+`BILLING_ENABLED`), `config/navigation.ts`
  (Profile route param `{sheet?: 'topup'}` + `MainTabRouteProp`),
  `api/bff/http-client.ts` (+`BILLING_DISABLED_STATUS`), `lib/format.ts`
  (+`formatUsdMinor`), root public API updated.
- `features/chat`: `MessageAuthor` gains `'system'`; `map-message` maps
  directions through a table; `ChatProvider`'s WS handler became an explicit
  switch that ignores `session.updated` **by name**.
- `screens/chat-thread`: `use-chat-thread` calls `usePaidSession` and routes
  "Book now" (picker when billing is live, advisor profile otherwise) plus a
  `goTopUp` cross-tab jump; `MessageBubble` renders a marker instead of a
  bubble for system messages; the screen renders `SessionBar` + the picker.
- `screens/profile`: real wallet balance, the Top Up sheet wired to the stub
  credit (async in `use-profile`, the sheet stays render-only), and the
  `sheet=topup` deep link.

## Decisions made during implementation

1. **Paid session = feature, wallet = entity.** The session has one consumer
   and is a verb, so no `entities/*` twin of `entities/session` is created
   and the naming collision disappears entirely (G1/N1). The wallet has two
   consumers, so it sits in `entities` — that also avoids a
   feature→feature import between paid-session and Profile.
2. **The countdown is recomputed from `endsAt`, never decremented**, and
   reaching zero ends the block locally: `endsAt` is exactly when the BFF's
   finish job fires, so a refetch could only agree. This also makes the app
   immune to throttled timers.
3. **The idempotency key is kept across retries and only cleared on a
   definitive answer** (400/402/404/409). A network loss, a 5xx or an
   unparseable body all leave the outcome unknown, so the retry replays the
   same key and the BFF returns the existing session instead of charging
   twice. Consequence, accepted: if a lost booking actually landed and the
   user then picks a *different* block, the replay returns the original
   session — no charge, the safe direction.
4. **A 404 on the mount-time active-session read means the BFF's billing
   flag is off**, and the whole session UI stays hidden for that session of
   the app — the two flags can never disagree visibly.
5. **409 on booking flips the picker to extend** (and 409 on extend flips it
   back), after re-reading the truth — the user's next move is offered
   instead of an error.
6. **Extend posts no marker** (AURAD-0002), so the thread shows one pair of
   red lines per session however many blocks it took.
7. The Chats list and Home's continue-card show a marker line as the thread
   preview when it is the newest message. Left as is: it is what the thread
   last said, and the chatter's dashboard shows the same line.
8. `Alert` (model, never `ui/`) carries the forfeit warning with the exact
   minutes at stake, and the sheet repeats the rule before any money moves.

## Verification (slave-pure)

`npx tsc --noEmit` ✓ · `npm run lint` ✓ (0 problems) · `npm test` ✓
**30 suites / 126 tests** (was 21/73 — 53 new), including: the countdown
derivation and the near-end threshold, the block ending itself at zero, the
inert flag-off and signed-out paths, the BFF-billing-off 404, both
idempotency-key paths, 402/409 handling, extend, the early-finish forfeit
copy, marker mapping and in-thread ordering, `session.updated` leaving chat
state untouched, and the Top Up deep link.

Runtime behaviour (a real meter, real debits, markers from the live
Chatwoot) is manor verification after merge — plan in `004-spec` §9.

## Notes for the manor

- `npm install` is required (new contracts tag); if the lockfile still shows
  the v0.2.0 commit, run `npm install "github:RomSribn/aura-contracts#v0.3.0"`.
- The app flag `BILLING_ENABLED` in `src/shared/config/env.ts` ships **false**.
  Turn it on together with the BFF's, and seed `advisors` price rows first —
  an advisor without one is deliberately not bookable.

## Open issues

None blocking. Recorded for later: promoting `BffSocket` to a shared
multi-subscriber singleton if a second WS consumer ever appears (G2-b), and
the advisor catalog that would replace manual price rows (BFF TECH-DEBT 10).

Next: owner IDE review → commit (app repo) → 007-merge.
