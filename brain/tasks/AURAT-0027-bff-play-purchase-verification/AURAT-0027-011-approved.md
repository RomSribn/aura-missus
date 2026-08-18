# AURAT-0027 — 011 approved

Date: 2026-08-18
Status: **done**. Owner reviewed the post-merge fixes and approved
("посмотрел, ок — мёржь и закрывай задачу").

## What shipped

The BFF half of the Google Play top-up rail (`AURAD-0010`), in two commits on
`feature/AURAT-0027-bff-play-purchase-verification`:

| | |
|---|---|
| `a9ba336` | the rail — merged as `445a3f6` |
| `1064d07` | 200 where the OpenAPI says 200, + the stale-comment fix |

- **`purchaseAccountId` on `GET /v1/wallet`** — a `wallets` column defaulted by
  Postgres to `gen_random_uuid()`. Verified in the manor on a populated
  database: **5 wallets, 5 distinct ids**, so the default was evaluated per row
  and there is no shared store id.
- **`POST /v1/wallet/top-ups/google`** — verify with Google, credit from the
  server's own tier table. Every refusal path exercised by hand.
- **Idempotency on the `purchaseToken`**, by unique constraint inside the credit
  transaction. Proven by a race the owner ran unprompted: four concurrent
  redeems of one token → one credit, three `replayed: true`, one `entryId`,
  balance moved once.
- **`TECH-DEBT #7` paid** — `ledger_entries` is append-only at the database:
  `UPDATE` and `DELETE` raise, `INSERT` still passes.
- `balance = Σ ledger` held across all five wallets.

## Decided during the task

| | |
|---|---|
| Real Google client | **built now**, not deferred — strict Zod parse, refuses on anything unexpected |
| Refunds (`AURAF-0010-006`) | **follow-up** — needs `AURAS-0002` step 8; would be dead code today |
| `TECH-DEBT #7` | **taken here** |
| Unverifiable purchase | **409, not 404** — 404 is what the billing flag already returns |
| Play token idempotency | **its own table**, because a column on `ledger_entries` would reject the refund row |
| Success status | **200, not 201** — a replay creates nothing, and it is the expected path |

## What this task did NOT prove

`GooglePlayVerifier` has **never spoken to Google**. `AURAS-0002` step 7 (linked
GCP project + service account) is the owner's and is not done, so everything
verified in the manor ran against the dev verifier — which refused a real-shaped
Play token rather than stamping it, which is the behaviour, not a gap.

Logged as **`TECH-DEBT #17`** with the specific thing to check on the first real
purchase: that Google actually returns `obfuscatedExternalAccountId`. The entire
"user A cannot redeem user B's token" guarantee rests on that field arriving,
and nothing testable here proves it does.

## Follow-ups left behind

1. **Refund subscriber** (`AURAF-0010-006`) — RTDN + `ONE_TIME_PRODUCT_CANCELED`
   → compensating negative entry. Gated on `AURAS-0002` step 8. **ID to mint in
   `aura-app-manor`.**
2. **`AURAS-0002` step 7** — the owner's, and now the only thing between this
   code and a real purchase.
3. **Cosmetic, unclaimed:** `POST /sessions/:id/finish` and `/cancel` document
   `201 Created` for operations that create nothing.

## Next

Missus committed as one commit, then `wts-release slave-1`.
