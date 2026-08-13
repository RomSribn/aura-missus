# AURAT-0013-008 — Endpoint verification (what a slave can actually prove)

Date: 2026-08-13

The user asked to check the endpoint works before committing. Runtime
verification against a live Postgres is **manor-only** — a slave may not start
the stack. So the check was split into what is provable offline and what is not,
rather than reported as one word.

## Verified here — `advisors.controller.spec.ts` (new, 4 cases)

Boots a real Nest + Fastify app over the controller with a mocked service and
drives it through `app.inject()`: no port, no DB, no Redis, no Chatwoot. This is
the first HTTP-level spec in the repo — every other spec constructs classes by
hand, which cannot catch a routing mistake.

| Case | Why it is worth a test |
|---|---|
| `GET /v1/advisors` → 200, service called once | URI versioning is applied in `app.setup.ts`, not in the controller — a controller that compiles can still be mounted at the wrong path |
| body parses against `advisorsResponseSchema` | the response is checked against the shared contract, not against itself |
| `GET /advisors` (unversioned) → 404 | pins that the app's `/v1` path is the real one |
| empty catalog → `200 {advisors: []}` | an empty list is a valid catalog, not a 404 |

Full sweep after the addition: **lint ✓ · tsc ✓ · 214 tests / 26 suites ✓ ·
build ✓**.

## NOT verified — needs the manor

Nothing below can be exercised without live infrastructure, and none of it should
be reported as working:

1. `prisma migrate deploy` applies the migration on a populated DB.
2. `prisma db seed` inserts all eight rows (the `ts-node` seed path has never
   been run — the config wiring is new).
3. A real `GET /v1/advisors` returns those rows through Firebase auth.
4. `avatarUrl` values resolve — the composition is unit-tested, but only against
   a real response does it prove the bucket keys match.
5. Booking still resolves a price after the repository moved modules
   (`BILLING_ENABLED=true`).
6. The retired-advisor cleanup SQL in step 007.

## Next

Commit master (user approved: "если все окей, то комить"). Missus stays
uncommitted until task close, per the skill. Merge is a separate ask.
