# AURAT-0027 — 010 execute (fixes from manor verification)

Date: 2026-08-18
Branch: `feature/AURAT-0027-bff-play-purchase-verification`, on top of the
merged `445a3f6`. **Staged, not committed.**

Gates: `tsc --noEmit` clean · `eslint` clean · `jest` **33 suites / 398 tests**
(was 32 / 394).

## Changes — three files, no behaviour change on the money path

| File | Change |
|---|---|
| `wallet.controller.ts` | `@HttpCode(HttpStatus.OK)` on `redeemGooglePlay` |
| `fake-play.verifier.ts` | the comment table says **409**, not 404 |
| `wallet.controller.spec.ts` | **new** — pins declared status against sent status |

### Why 200 and not 201

The house convention on POST is `@ApiCreatedResponse` (sessions cancel /
extend / finish), so consistency argued for 201. It loses: this endpoint's
defining property is idempotency, a replay creates **nothing**, and the replay
is the expected path because the app retries by design (`AURAD-0010`).
`201 Created` would be false on every retry. Moving the code to the
already-published 200 also breaks no promise, where moving the doc to 201 would.

### The test, and why it is metadata introspection

Nothing in Nest makes `@ApiOkResponse` and the status actually sent agree — the
decorator only writes documentation, and the default is **201 for POST, 200 for
everything else**. That asymmetry is the entire trap, so the test computes the
sent status the way Nest does (explicit `@HttpCode`, else the verb's default)
and asserts the declared success statuses are exactly that one.

Reading `swagger/apiResponse` and `HTTP_CODE_METADATA` is internal-key
territory, and that is a real cost — a Nest upgrade could reshape it. It buys
the only assertion that fails on the actual defect, and the alternative (a
Fastify `inject` test) needs the global Firebase guard and Prisma stood up,
which a slave may not do.

**Mutation-checked rather than assumed:** with `@HttpCode` removed, 2 of the 4
cases fail; restored, all 4 pass. A green test that cannot go red is worse than
no test.

The generic case is written over all three wallet routes, so the next endpoint
that declares a status it does not send fails here instead of in a generated
client. `getWallet` initially failed my first draft of the rule — correctly:
`GET` defaults to 200, so `@ApiOkResponse` on it is right. The rule was wrong,
not the code, and it now accounts for the verb.

## Not changed, deliberately

`POST /sessions/:id/finish` and `/cancel` document `201 Created` for operations
that create nothing — the same semantic smell, pre-existing, off this task's
path. Widening a post-merge fix into the sessions controller trades a real
cosmetic issue for a real regression risk.

## Still true, unchanged by any of this

`GooglePlayVerifier` has never spoken to Google (`TECH-DEBT #17`,
`AURAS-0002` step 7). Everything verified in the manor ran against the dev
verifier — which refused a real-shaped token rather than stamping it, exactly as
designed.

## Next

Owner review of this diff, then the merge gate again (`011-merge`).
