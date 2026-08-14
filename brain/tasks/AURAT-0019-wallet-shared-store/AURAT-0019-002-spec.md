# AURAT-0019-002 — Spec

Date: 2026-08-14
Approach chosen by the owner in conversation (2026-08-14): **shared store**, not
a focus-refresh patch.

## Goal

One balance in the app, owned in one place, carrying the number the server
already told us. No screen may disagree with another about how much money the
user has.

## Scope

### 1 · `entities/wallet/model/wallet-store.ts` (new)

Module-level store on the `advisorCatalog` pattern (`AURAT-0014`): `subscribe` /
`getState` / `load` / `setBalance` / `reset`, with a **generation counter** so a
fetch started before sign-out cannot land after it, and a shared in-flight
promise so concurrent consumers make one request.

State: `{ balanceMinor: number | null, status: 'idle' | 'loading' | 'ready' |
'error' | 'disabled' }`. `disabled` is the BFF's 404 (its billing flag is off) —
terminal, exactly as `serverEnabled` is terminal today.

### 2 · `useWallet()` keeps its signature

`enabled / balanceMinor / loading / refresh / topUp`, now read through
`useSyncExternalStore`. **No consumer changes** — Profile and the block sheet
compile untouched.

### 3 · The debit stops being a refetch

`usePaidSession.confirm()` writes `result.balanceMinor` into the store instead of
calling `refreshWallet()`. That is the server's own post-debit figure, so the
number is authoritative, arrives with the booking, and reaches every screen at
once. One fewer request per booking, and no window in which two screens disagree.

`topUp` likewise publishes `TopUpResponse.balanceMinor` to the store.

### 4 · Identity

`useWalletSync()` in `app/index.tsx`, mirroring `useAdvisorCatalogSync()`: load
on sign-in, reset on sign-out. The per-hook `useEffect` that reset the balance on
`userUid` change goes away — with N consumers it would be N resets racing.

### 5 · Cleanup

The `openSheet` special case in `use-profile.ts:57-67` is deleted: there is no
longer a stale copy for it to paper over.

## Out of scope

The payment rail itself — booking, pricing, the forfeit rule, the top-up stub.
This moves *where the balance lives*, never how money moves.

## Acceptance

- Book a block in a chat thread → Profile's card shows the debited balance with
  no refresh, no tab switch, no sheet.
- Top up in Profile → the block sheet's "Balance" line agrees immediately.
- Sign out → balance drops; a fetch started before sign-out cannot repopulate it.
- With `BILLING_ENABLED` off, or the BFF's flag off, nothing is requested and no
  wallet UI renders (unchanged).
- Booking issues **no** `GET /v1/wallet` — the response already carried it.
- Slave gates green: tsc / eslint / jest.

## Next

`003-execute.md`, then the owner's device check → `004-approved.md`.
