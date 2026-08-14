# AURAT-0015-008 — Approved

Date: 2026-08-14
Status: **done — owner-approved after a device pass**

## What the owner verified

The in-thread session surface, on a physical iPhone against the live BFF and
Chatwoot: the live banner under the chat header with its counter and progress
bar, the header swapping to **"Extend +1 min"** (the smallest block the server
offered — the design's literal 15 never appeared), the teal "YOUR SESSION HAS
STARTED" / ink-3 "YOUR SESSION HAS FINISHED" dividers bracketing the paid window
in scroll-back, and the block sheet reached by tapping the banner, carrying
"End session early" in its new home. Reported as working.

## Deliberately not verified

**The skewed-clock check was not run** — the owner chose not to. It was the
task's headline acceptance: with the device clock deliberately ±5 minutes out,
the countdown must still agree with the server's meter.

What stands behind it instead: a unit test in `use-paid-session.test.tsx` sets
the device clock five minutes fast and asserts the countdown still reads
`10:00`, plus `server-clock.test.ts` covering a fast device, a slow device, the
half-round-trip correction and a missing `Date` header. So the logic is pinned;
what remains unproven is only that a real iOS clock offset behaves the way the
test models it.

Recorded rather than quietly dropped: if a countdown ever disagrees with the
meter in the field, this is the first thing to re-check.

## Shipped

`AURAF-0008` rows 001–005. Merged into develop (`94cfc91`, code `fb441a7`,
user-approved merge gate) and pushed; brain pushed. Gates green in slave-1 and
re-verified in manor after the merge: tsc / eslint / jest, **39 suites / 182
tests** (was 34 / 142), plus a release bundle.

Rows 006–012 stay parked per `AURAD-0008`; `'scheduled'` and the banner's
starting-soon variant were deliberately not built.

## Found during this pass, not caused by it

- **`AURAT-0019`** — Profile's balance went stale after a block was bought in a
  chat (pre-existing, `AURAT-0010`). Minted, built, merged, approved same day.
- **`AURAT-0020`** — the block sheet's "Top up" leaves the Profile screen dead
  until an app restart (pre-existing, `AURAT-0010`).

## Debt logged, not minted

- The BFF ships **no machine-readable marker kind**, so the divider's tone is
  matched against the server's own wording. Unknown copy takes the quiet tone —
  a reworded line loses a colour, never its divider.
- There is **no sessions-list endpoint**, so the chats list fans out one
  `/sessions/active` per thread (BFF `TECH-DEBT #12` territory).

slave-1 released.
