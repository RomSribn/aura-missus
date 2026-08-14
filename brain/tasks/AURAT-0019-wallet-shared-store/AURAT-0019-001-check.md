# AURAT-0019-001 — Check

Date: 2026-08-14
Slave: slave-0, `feature/AURAT-0019-wallet-shared-store` off develop `94cfc91`
Found by: the owner, during the AURAT-0015 device pass.

## Symptom

Profile's balance card keeps a stale figure after a paid block is bought in a
chat thread. Observed: card reads `$5.04`, a 1-min block for `$3.20` is booked,
the block sheet immediately reads `$1.84` — and Profile still says `$5.04` until
the Top Up sheet is opened, at which point it corrects itself.

## Root cause

`entities/wallet/model/use-wallet.ts` holds **per-consumer local state**. There
is no shared store, so each caller owns a private `balanceMinor`:

- `usePaidSession` (chat thread) calls `refreshWallet()` after a booking — that
  updates *its own* copy;
- `screens/profile` fetched once when its tab mounted and never re-reads.

`screens/profile/model/use-profile.ts:57-67` already carries a partial patch for
exactly this, and names it:

> `// The balance may have moved since this tab last rendered — a booking in the`
> `// chat thread spends from the same wallet.`

It refreshes only on opening the Top Up sheet, which is precisely the one path
where the owner saw the number correct itself.

## The second finding

`BookSessionResponse` carries `balanceMinor` beside `session` — the server's
authoritative post-debit balance. `use-paid-session.ts:275` **discards it** and
fires a `GET /v1/wallet` instead. So today the app pays for an extra round trip
*and* lands the answer in the wrong copy.

`TopUpResponse` carries it too, and that one is used.

## Provenance

Pre-existing, from **`AURAT-0010`** (app paid sessions) — not a regression of
`AURAT-0015`, which never touched the wallet. `AURAT-0015` did wire
`useFocusEffect` for *session* state in the chats list; the wallet simply never
had an equivalent trigger, although `refresh`'s own JSDoc advertises one
("screen focus, after a booking, after a top-up").

## Next

`002-spec.md`.
