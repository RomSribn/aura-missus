# AURAT-0019-004 — Approved

Date: 2026-08-14
Status: **done — owner-approved after a device pass**

## What the owner verified

Balance synchronisation works: a block bought in a chat thread leaves the
Profile card showing the debited amount, with no refresh, no tab dance and no
Top Up sheet needed to force a re-read. That was the whole point of the task.

## Shipped

Merged into develop (`e9de091`, code `01df13e`, user-approved merge gate) and
pushed; `origin/develop` in sync, brain pushed (`59c6d84`). Gates green in
slave-0 and re-verified in manor after the merge: tsc / eslint / jest,
**41 suites / 193 tests** (was 39 / 182), plus a release bundle.

The wallet is now one module-level store on the `advisorCatalog` pattern;
`useWallet` kept its shape, so no consumer changed. A booking publishes
`BookSessionResponse.balanceMinor` — the server's own post-debit figure — into
the store, which removed both the staleness window and one request per booking.

## Left on the record

- Not separately exercised on device: sign-out dropping the balance, and the
  top-up direction (Profile → block sheet agreeing). Both are covered by unit
  tests; neither was part of the reported symptom.
- The near-miss worth remembering: the first green test run was green for the
  wrong reason — a `jest.mock` factory hoists above the `const` it closes over,
  so `walletStore` reached the module under test as `undefined` and its
  `setBalance` threw into a swallowed rejection while every assertion still
  held. Fixed by exposing the store through a getter and asserting the real
  behaviour. See `003-execute.md`.

## Follow-up found during this pass

**`AURAT-0020`** — the block sheet's "Top up" navigates to Profile and leaves the
screen dead until an app restart: two `BottomSheet` modals overlap in time
(`goTopUp` closes one and navigates in the same tick, and the sheet stays
mounted through its 200 ms close). Pre-existing from `AURAT-0010`; this task did
not touch that path.

slave-0 released.
