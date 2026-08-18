# AURAT-0027 — 009 fix: published status, and a comment that lied

Date: 2026-08-18
Source: owner verification in the manor, post-merge (`445a3f6`).

## Verification result first

All three checks ran, and the rail went further than asked.

- **Migration** applied on a **populated** database (wallets from the 14 Aug
  runs), which is the only way the per-row check means anything.
- **5 wallets / 5 distinct `purchaseAccountId`** — `gen_random_uuid()` was
  evaluated per row. The failure mode named in the migration comment (one
  shared store id, hence anyone redeeming anyone's purchase) **did not
  happen**.
- **Trigger rejects `UPDATE` and `DELETE`** with the exact text and
  `restrict_violation`, and an `INSERT` still passes — so the table is
  append-only, not read-only. `TECH-DEBT #7` is genuinely paid.
- **12 of 14 rail cases as specified**; the two misses were the owner's
  expectations, not defects. Every refusal path answered as designed, and a
  real-shaped Play token was refused without crediting.
- **Race, run unprompted and the most valuable thing here:** four concurrent
  redeems of one fresh token → **one** credit, three `replayed: true`, all four
  pointing at the same `entryId`, balance moved by 2500 once. That is the
  unique constraint deciding the race *inside* the credit transaction, which is
  exactly what `AURAD-0010` asks for and what a read-then-write could not give.
  `balance = Σ ledger` held across all five wallets.

## Two defects, both mine, neither touching money

### 1. The endpoint's published status is a lie (real, client-facing)

`redeemGooglePlay` carries `@ApiOkResponse` but no `@HttpCode`, and Nest's
default for `POST` is **201**. So the service answers 201 while the OpenAPI it
publishes promises 200. Confirmed in the metadata: `swagger/apiResponse` has a
`200` key and `__httpCode__` is absent.

It breaks nothing today — the app's `bffRequest` branches on `response.ok`, so
201 passes — but the OpenAPI exists *specifically* so a typed client can be
generated from it (`AURAD-0004`), and a strict generated client would treat
every successful top-up as an unexpected status.

**Fixed toward 200, not toward 201.** The house convention elsewhere is
`@ApiCreatedResponse` on POST (sessions cancel / extend / finish all do that),
so consistency would argue for 201. It loses on the merits: this endpoint's
defining property is idempotency, a replay creates **nothing**, and the replay
is the *expected* path — the app retries by design (`AURAD-0010`). `201 Created`
would be false on every retry. Aligning the code to the already-published 200
also changes no promise, where changing the doc to 201 would.

Noted in passing, not changed: `POST /sessions/:id/finish` and `/cancel` have
the same semantic smell (documented `201 Created` for something that creates
nothing). Pre-existing, cosmetic, off this task's path — left alone
deliberately rather than widened into a post-merge diff.

### 2. `fake-play.verifier.ts` documents a 404 it never returns

The comment table in the dev verifier ends `anything else → 404`. The service
answers **409** (`Purchase could not be verified`) — deliberately, because 404
is what `BillingEnabledGuard` returns across the whole wallet surface, so the
app could not tell "unknown purchase" from "wallet does not exist here". That
reasoning is written down in `007-execute.md` and in the controller; the
verifier's comment was simply never updated to match.

Worth naming plainly: this is the failure mode that documentation has and code
does not — the table was right in the task record and wrong in the file a
reader would actually open.

## Also fixing my own instruction

The `UPDATE` probe I handed over in `008-merge.md` was bare. Had the trigger
*not* installed, it would have corrupted a ledger row rather than reporting
that it could. The owner wrapped both probes in `BEGIN … ROLLBACK` and added the
`INSERT` control. `008`'s commands are superseded by that shape.

## Scope

Three files, no behaviour change to the money path:

- `wallet.controller.ts` — `@HttpCode(HttpStatus.OK)`.
- `fake-play.verifier.ts` — the comment says 409.
- `wallet.controller.spec.ts` (new) — pins that the status Nest sends is one
  the OpenAPI fragment declares, so this class of drift fails a test instead of
  a generated client.

## Next

`010-execute`.
