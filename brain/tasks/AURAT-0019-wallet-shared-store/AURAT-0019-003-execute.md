# AURAT-0019-003 — Execute

Date: 2026-08-14
Slave: slave-0, `feature/AURAT-0019-wallet-shared-store` off develop `94cfc91`
Status: **code written, staged — awaiting review, then the merge gate**

## What changed

- **`entities/wallet/model/wallet-store.ts`** (new) — module store on the
  `advisorCatalog` pattern: subscribers, a shared in-flight promise, a
  generation counter, and a terminal `disabled` state for the BFF's 404.
- **`use-wallet.ts`** — same public shape (`enabled / balanceMinor / loading /
  refresh / topUp`) read through `useSyncExternalStore`. **No consumer had to
  change**; the per-hook state and its identity effect are gone.
- **`use-wallet-sync.ts`** (new) + one call in `app/index.tsx` — load on
  sign-in, reset on sign-out, one owner instead of N racing consumers.
- **`use-paid-session.ts`** — a booking now publishes `result.balanceMinor`
  into the store instead of firing `refreshWallet()`. The 402 path still
  re-reads: a refusal carries no balance, and the server's word is the point.
- **`use-profile.ts`** — the Top-Up special case is deleted; there is no stale
  copy left to paper over.

## The catch worth recording

The first green run was **green for the wrong reason**. `use-paid-session`'s
test mocks `@/entities/wallet` with `useWallet` only, so `walletStore` was
`undefined` and `walletStore.setBalance(...)` threw inside a `.then` — swallowed
as an unhandled rejection. All 18 tests still passed, because `setSession` runs
before the throw and the old `expect(mockWallet.refresh).toHaveBeenCalled()` was
already satisfied by `loadPricing`'s refresh, not by the booking's.

Two things came out of that:

1. the assertion now names the real behaviour —
   `expect(mockWalletStore.setBalance).toHaveBeenCalledWith(8_010)` plus
   `expect(mockWallet.refresh).not.toHaveBeenCalled()`;
2. the mock exposes `walletStore` through a **getter**. `jest.mock` factories
   hoist above the `const`, so an eager reference hands the module under test
   `undefined` — which is exactly how the hole opened in the first place.

## Verification

| Gate | Result |
|---|---|
| `tsc --noEmit` | clean |
| `eslint src __tests__` | clean |
| `jest` | **41 suites / 193 tests green** (was 39 / 182) |
| Release bundle (android, `--dev false`) | built |

New tests:

- `wallet-store.test.ts` — one request for concurrent readers, a debit published
  with no fetch, the known balance surviving a transient failure, 404 →
  `disabled` and terminal, and **a fetch started before sign-out that cannot
  land after it**.
- `use-wallet.test.tsx` — two consumers (Profile card, block picker) reading one
  balance, and the regression itself: a debit in one is visible in the other
  with no refresh and no second request.
- `use-paid-session.test.tsx` — the booking publishes the server's figure and
  asks for nothing.

## Not verified here

The device pass: book a block in a thread, then open Profile and see the
debited balance with no refresh; top up in Profile and see the block sheet
agree; sign out and watch the balance drop.

## Next

Review → merge gate (explicit owner approval) → device check → `004-approved.md`.
