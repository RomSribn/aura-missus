# AURAT-0013-012 — Approved

Date: 2026-08-13
Status: **done**

The owner approved the manor verification ("апрувлю, давай"). AURAT-0013 is
closed: the advisor catalog is on `develop` @ `b0ee16a` and proven against a live
stack — migration, seed, endpoint, avatar resolution, booking, cleanup (step 011).

## What this task actually changed

The `advisors` table stopped being a two-column price list maintained by hand and
became the catalog the app reads. Eight real advisors replaced the six placeholder
personas the app had been shipping in its own bundle; their threads were deleted in
the manor as a reviewed step, not as a migration side effect. Closes
`aura-bff/TECH-DEBT.md` **#10**.

## Carried out of this task

**For whoever deploys next — `ADVISOR_ASSETS_BASE_URL` is required and has no
default.** Staging and prod must have it set *before* moving to `b0ee16a`, or the
service fails at boot validation rather than degrading. The manor `.env` did not
have it, which is how this was found (step 011).

**Follow-ups, none blocking:**

1. **TECH-DEBT #11 is now more expensive than when it was written.** With
   `@aura/contracts` v0.4.0 the advisor shape exists in two places, and step 009
   already recorded a divergence: `AdvisorId` is `z.string().min(1)` in the package
   and `[A-Za-z0-9_-]{1,64}` in the BFF. The app `safeParse`s and drops mismatches
   quietly, so drift here surfaces as "the feature silently does nothing". Worth
   its own task.
2. **`aura-contracts` has no test setup at all** (step 009) — a shared contract
   covered only from the consumer side.
3. **`@fastify/static` is a dependency registered nowhere** (step 007), dead since
   it was added.
4. **One orphan conversation on `advisoor-test-1`** survives on the dev DB — an old
   manual test row with a typo, outside the retirement list, now pointing at an
   advisor that has no catalog row. Left deliberately (step 011).
5. **Unverified in this environment:** Chatwoot-side conversation provisioning and
   the session activity markers — Chatwoot is not reachable from the manor stack.
   Neither was changed by this task.

## Next

`wts-release slave-1` (asked separately), then `active-work.md`.
