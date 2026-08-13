# AURAT-0013-004 — Context

Date: 2026-08-13

## Sources checked

| Source | Trust | What it gave |
|---|---|---|
| `prisma/schema.prisma` | ground truth | `Advisor` = `id` + `priceMinorPerMinute` only; `Conversation.advisorId` has **no FK** on purpose |
| `src/contracts/*` | ground truth | local copy, **not** the package (TECH-DEBT #11); `advisorIdSchema` = `[A-Za-z0-9_-]{1,64}` |
| `src/modules/sessions/*` | ground truth | `AdvisorsRepository` lives inside `sessions`, behind `BillingEnabledGuard` |
| `src/config/env.schema.ts` | ground truth | zod, fail-fast; comment: "Prices are NOT config — they live in the advisors table" |
| `aura-app` `AdvisorRow.tsx` | ground truth | renders `{role} · {price}/min` **unconditionally** |
| `aura-contracts` repo | ground truth | separate repo, `main` clean, tags `v0.2.0`/`v0.3.0` |
| `AURAD-0001` personas / `AURAD-0005` per-env / `AURAT-0008` D1 | high | constraints below |
| `TECH-DEBT.md` | high | #10 is what this closes; #11, #12, #13 are adjacent |

## Findings that shape the design

**1. `@aura/contracts` is not a BFF dependency.** The BFF keeps a hand-written
mirror in `src/contracts/`; the app consumes the real package pinned at
`github:RomSribn/aura-contracts#v0.3.0`. TECH-DEBT #11 says explicitly to adopt
the package *"in one dedicated pass rather than inside a feature task"*. So this
task follows the existing pattern: a local `src/contracts/advisor.ts` for the
BFF, plus an `Advisor` shape released in `aura-contracts` **v0.4.0** for the app
to import in the follow-up task. The drift risk is #11's, not new here — but it
does mean the same shape gets written twice, deliberately.

**2. `Conversation.advisorId` carries no foreign key, by design** — "Free chat
never touches this table". Widening `advisors` must not add one: a conversation
with an advisor later deactivated must keep working, and free chat must never
depend on a catalog row existing.

**3. The catalog cannot sit behind `BillingEnabledGuard`.** `AdvisorsRepository`
today lives in the `sessions` module, all of which 404s when billing is off. The
catalog is v1 free-chat surface — the app needs the list to render at all. So
the model moves to a **new `advisors` module**, unguarded, and `sessions` imports
it instead of owning it.

**4. Price must be returned even with billing off.** `AdvisorRow` renders
`{role} · {price}/min` with no flag check, so a catalog that hides price until
billing is on would blank the list's subtitle in v1. Price ships in the catalog
response unconditionally — it is display data. Booking stays gated: it is
`POST /advisors/:id/sessions` that the flag protects, and AURAT-0008 D1 (no row ⇒
not bookable) is unchanged.

**5. Personas, not people** (`AURAD-0001`). The catalog describes personas; it
must never expose a Chatwoot agent, and `online` stays out of the table —
presence is computed and pushed, not stored (TECH-DEBT #13).

**6. Migrations are hand-written SQL** under
`prisma/migrations/<utc-stamp>_<name>/migration.sql`.

## Contradiction found

The brief said *"бамп `@aura/contracts` 0.3.0 → 0.4.0"* as if the BFF consumed
it. It does not (finding 1). Resolved as: bump the package **for the app**, and
add the local mirror **for the BFF** — both, not either.

## Open, non-blocking

`ADVISOR_ASSETS_BASE_URL` has no value yet — the user created the bucket but has
not given its public URL. Code lands complete; the env value is a deploy input.

## Next

Step 005 — spec.
