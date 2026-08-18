# AURAT-0027 — 002 check

Date: 2026-08-17
Context: `slave-1`, both repos on
`feature/AURAT-0027-bff-play-purchase-verification`, clean, off `develop`
`eda5339`.

## Brain

Task folder existed with `001-initial.md` only — written by `aura-app-manor`
as the handoff brief. Nothing executed here yet, so this is the first BFF-side
step. **ID already minted; no `wts-start`, no counter bump.**

Read in the order the brief asks:

| Doc | What it settles |
|---|---|
| `AURAD-0010` | **The spec.** Five ratified points; ordering and the token-as-idempotency-key are decisions, not choices |
| `AURAD-0002` | Wallet is the only money source; ledger append-only; `balance = Σ ledger` |
| `AURAD-0009` | Sessions ride the same wallet; the ledger already has a credit direction (`SESSION_REFUND`) |
| `AURAS-0002` | The owner's Play Console runbook. **Step 7 (GCP project + service account JSON) is what gates the real Google call** |
| `AURAF-0010` | Scope table. Rows 001–005 app-done / BE ✗; row 006 (refunds) is ours |
| `AURAT-0026-007-execute.md` | The app half as actually built, including two decisions that changed the contract |

## Contract — read from the package, not from prose

`@aura/contracts` **v0.7.0** is installed in the app manor
(`aura-app-manor/project/manor/master/aura-app/node_modules/@aura/contracts`,
`package.json` says `0.7.0`). Shapes taken from `dist/index.js` /
`dist/index.d.ts` rather than from the spec text, because `AURAT-0026`
amended two fields *after* `005-spec.md` was written:

```ts
WalletResponse          { balanceMinor, currency, purchaseAccountId?: string.min(1).max(64) }
GooglePlayTopUpRequest  { purchaseToken: string.min(1), productId: string.min(1) }   // no amount, no packageName
GooglePlayTopUpResponse { entryId, balanceMinor, currency, creditedMinor: int.nonneg, replayed: boolean }
```

The BFF does not consume the package — `src/contracts/` is a hand-kept mirror
(**TECH-DEBT #11**), so these get mirrored, and pinned by a spec file the way
`message.spec.ts` / `session.spec.ts` already pin theirs.

## Code as it actually stands

- `src/modules/wallet/` — `wallet.controller.ts` (`GET /v1/wallet`,
  `POST /v1/wallet/top-ups`), `wallet.service.ts`, `wallets.repository.ts`
  (abstract) + `prisma-wallets.repository.ts`, `billing-enabled.guard.ts`.
- `WalletService.getBalance` returns `{ balanceMinor, currency }` — **no
  `purchaseAccountId`**, which is exactly why the app's rail is off.
- `credit()` is the money-path pattern already in place: `$transaction` +
  `SELECT … FOR UPDATE` on the wallet row, append entry, update cached balance.
  It is **TOPUP-only** and keyed on `(walletId, idempotencyKey)` unique.
- `LedgerEntryType` = `TOPUP | SESSION_CHARGE | SESSION_REFUND`. Amounts are
  signed. `@@unique([walletId, idempotencyKey])` on `ledger_entries`.
- The stub `POST /v1/wallet/top-ups` 503s in production (`AURAT-0007`) —
  untouched by this task.
- `TECH-DEBT #7` (DB-level append-only on `ledger_entries`) is flagged by the
  brief as worth taking here: this is the first rail where an **outside party**
  (Google) can reverse an entry.

## Nothing already built for this

No `google`/`play`/`purchase` anything in `src/`. Fresh work, on top of a
money path that already has the right transaction shape.

## Next

`003-understand`.
