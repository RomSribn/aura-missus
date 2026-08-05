# AURAT-0010-007 — Merge

Date: 2026-08-04
Merged: `feature/AURAT-0010-app-paid-sessions` → `develop` @ **`6199939`**
(code commit `2d8c776`), via `wts-finish slave-1` after an explicit
owner-approved merge gate.

## What happened at the gate

The manor working tree was **dirty with three unrelated local edits** —
`src/shared/config/env.ts` (`DEV_HOST_OVERRIDE = '192.168.31.55'` plus a
comment explaining why a physical device needs the LAN IP),
`src/screens/home/ui/TarotBanner.tsx` (a banner-padding fix), and the
`ios/` artefacts of a `pod install`. Since this branch also edits `env.ts`,
git would have refused the merge.

Resolution (owner-chosen): stash **only** `env.ts`, merge, pop it back — the
machine-specific IP stays local and never reaches `develop`, and the merge
result carries both changes (the override and the new `BILLING_ENABLED`
flag, verified after the pop). The `ios/` artefacts and the banner fix were
left untouched.

The banner fix belonged to no task, so it was minted as **AURAT-0011
home-tarot-banner-padding** (counter bumped to 0012) rather than being
committed to the integration branch unreviewed — manor rules forbid feature
work there. The edit itself is still sitting in the manor tree as that
task's starting point.

## Not pushed

`git push origin develop` failed: `aura-app`'s origin is the **HTTPS** URL
and this session has no GitHub credentials (`could not read Username for
'https://github.com'`). `wts-finish` treats the push as best-effort, so the
merge stands locally and `develop` remains unpushed — the same standing debt
recorded since AURAF-0001. `@aura/contracts` pushed fine because its remote
is SSH; **re-pointing `aura-app`'s origin to SSH would close this.**

## Manor verification (post-merge, slave-pure gates)

`npm install "github:RomSribn/aura-contracts#v0.3.0"` (the plain
`npm install` keeps the cached v0.2.0 commit) → contracts 0.3.0 resolved.
Then `npx tsc --noEmit` ✓ · `npm run lint` ✓ · `npm test` ✓ **30 suites /
126 tests**.

## Device checklist still to run in the manor

The flag ships **off**, so the first pass costs nothing:

1. Flag off (both sides): the thread is the v1 free chat — no session bar, no
   picker, "Book now" still opens the advisor profile; no `/v1/sessions*` or
   `/v1/wallet` request leaves the device.
2. Turn on the BFF's `BILLING_ENABLED` **and** the app's, set
   `SESSION_BLOCK_MINUTES=1,10,20,30`, and **insert `advisors` price rows for
   the seed advisors** — without a row an advisor is deliberately not
   bookable (AURAT-0008 D1), which is itself worth seeing once.
3. Empty wallet → blocks disabled → Top up → stub credit → balance updates in
   Profile and in the picker.
4. Book the 1-minute block: wallet debited exactly `1 × price`, red "started"
   marker in the thread and the activity line in the Chatwoot dashboard,
   countdown running.
5. Let it run out: block finishes at `endsAt`, red "finished" marker, bar
   gone. Kill and reopen mid-block → session and countdown restored.
6. Extend near the end → `endsAt` moves, a second SESSION_CHARGE, **no** extra
   marker. End early → forfeit warning → finished marker, no refund entry;
   repeat → idempotent.
7. Double-tap Book / airplane-mode retry → exactly one ledger charge.

## Follow-ups recorded

- **AURAT-0011** — the Home banner fix (minted here).
- `develop` unpushed; re-point `aura-app` origin to SSH.
- Missus is **not** committed from the slave — the manor commits the brain at
  task close, as for AURAT-0008.

Next: device verification above → `008-approved` once the owner accepts.
