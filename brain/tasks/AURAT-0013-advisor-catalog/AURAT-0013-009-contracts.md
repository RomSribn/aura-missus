# AURAT-0013-009 — @aura/contracts v0.4.0 released

Date: 2026-08-13
Repo: `aura-contracts` (separate from the manor) — `main` @ `b2d9783`, tag `v0.4.0`
Status: **pushed to origin** (owner approved: "тегай и пуш")

## What shipped

`src/advisor.ts` gains `Advisor`, `AdvisorCategory`, `AdvisorsResponse` alongside
the existing `AdvisorId`. **Additive only** — no existing schema changed, so
v0.3.0 consumers keep compiling. Version 0.3.0 → 0.4.0; README's shape table,
pin example and a v0.4.0 note updated.

The file's old comment had gone stale and was rewritten: it claimed a persona DTO
here would be "a shape nothing sends and nothing reads", which was true only
while the BFF had no catalog.

## Verified, not assumed

1. **Package build** — `typecheck` ✓, `tsup` ✓ (esm + cjs + dts).
2. **Cross-mirror check.** The BFF keeps its own copy of the contract
   (TECH-DEBT #11), so the two can drift silently. Took the eight seed rows,
   mapped them exactly as `AdvisorsService` maps them, and parsed them with the
   **package** schema: all eight pass, `AdvisorsResponse` accepts the whole body,
   unknown keys (`avatarKey`, `sortOrder`) are stripped. The mirrors agree today.
3. **The pin the app will actually use.** Clean directory,
   `npm install github:RomSribn/aura-contracts#v0.4.0` → resolves, `prepare`
   builds `dist/` (index.cjs/.js/.d.ts/.d.cts), `Advisor` is exported, and the
   real BFF payload parses. This is the step that would have caught a missing
   devDependency or a broken `prepare`.
4. **Origin state** — `main` in sync, `refs/tags/v0.4.0` dereferences to
   `b2d9783`.

## Decision taken alone

**`AdvisorId` left as `z.string().min(1)`**, not tightened to the BFF's
`[A-Za-z0-9_-]{1,64}`. The app `safeParse`s and drops a mismatch quietly, so a
stricter shared schema surfaces as "the feature silently does nothing" rather
than as an error — the exact failure mode TECH-DEBT #11 describes. Aligning the
two belongs in the dedicated contracts pass, not in a shape addition. Recorded in
the schema's own comment so the next reader does not "fix" it by accident.

## Noted, not fixed

`aura-contracts` has **no test setup at all** — no jest, no `test` script. The
advisor shape is covered only from the BFF side (`contracts/advisor.spec.ts`).
Standing up a test harness inside this task would be scope creep, but a shared
contract with zero tests of its own is worth a follow-up.

## Next

Unblocks the app task: it can now pin `#v0.4.0` and import `Advisor`.
Still open for AURAT-0013 itself: merge to `develop` (needs an explicit ask) and
the six manor verifications in step 008.
