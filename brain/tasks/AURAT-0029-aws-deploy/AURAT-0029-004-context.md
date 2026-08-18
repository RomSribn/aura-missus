# AURAT-0029-004 — Context

Date: 2026-08-18
Sources: `AURAD-0004`, `AURAD-0005`, `AURAS-0001`, `AURAS-0002`, the two compose
files, the BFF Dockerfile, and the app's transport policy.

## Findings

**1 · Sizing is small and known.** Seven containers, of which four are stateful
(two Postgres, two Redis). Chatwoot's rails + sidekiq is the memory-hungry part;
the BFF is a single Node process. A `t3.large` / `m6i.large` class instance is
the honest starting point, with data on its own EBS volume so the instance stays
disposable. Graviton (`t4g`/`m7g`) is cheaper **if** the Chatwoot image has an
arm64 tag for the pinned version — which dev already relies on, so this is worth
checking rather than assuming x86.

**2 · TLS is the hard requirement, not a nicety.** Android release builds forbid
cleartext (`usesCleartextTraffic` false via the RN Gradle plugin) and iOS ATS
sets `NSAllowsArbitraryLoads` false. So a plain-http host is not "degraded" for
the app — it is unusable, and only in release, which is the worst place to find
out. Two hostnames need certificates: the BFF and Chatwoot.

**3 · Chatwoot's webhook must reach the BFF.** `AURAD-0005` has Chatwoot post to
the inbox's `webhook_url` with an HMAC signature. Co-located on one host that
can stay internal, which is simpler and safer than exposing it — but the
`webhook_url` recorded in the inbox must then be the internal address, and that
is exactly the kind of value that gets set once and forgotten.

**4 · A public HTTPS endpoint is owed to Google.** `AURAS-0002` step 8 pushes
refund notifications from Pub/Sub. That subscription cannot be created until
this task produces a reachable endpoint, so this unblocks the refund follow-up
(`AURAF-0010-006`), which is currently unbuildable rather than merely unbuilt.

**5 · Secrets multiply here.** Production needs: Chatwoot's own secret key base
and service-User token, the BFF's Firebase Admin credential, Postgres passwords,
and the three `GOOGLE_PLAY_*` values without which the BFF **refuses to boot**
when billing is on. Dev keeps these in gitignored `.env` files by hand — a habit
`AURAT-0028` is currently retiring on the app side for the same reason it is
wrong here.

**6 · The ledger changes the backup question.** `TECH-DEBT #7` was paid in
`AURAT-0027`: `ledger_entries` is append-only at the database. That guarantee is
worth nothing without a backup that has been **restored**, and the moment real
Play money lands, this stops being an ops detail. A backup nobody has restored
is a belief, not a backup.

## Contradiction logged

None between sources. The open tension is placement (finding in `003`): one host,
two manors, and `AURAD-0006`'s one-manor-per-deploy-unit rule did not anticipate
a shared machine.

## Next

`005-spec.md`.
