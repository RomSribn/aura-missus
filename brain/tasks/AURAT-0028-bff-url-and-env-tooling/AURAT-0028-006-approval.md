# AURAT-0028-006 — Approval

Date: 2026-08-18
Status: **approved — implementation may start in slave-1**

## What the owner approved

`005-spec.md` as written: pick the configuration mechanism on evidence rather
than convention, replace the `__DEV__` branch, make both rollout flags
configurable without changing their committed `false` defaults, carry the
manor's local override across, and keep Jest, Metro and a release build honest.

## The open question, answered

**Three targets, including the arbitrary-https one.** That target is the point:
it lets a release build reach a tunnel to the manor Mac, so the Google Play rail
can be proven end to end while the BFF is still local and observable — without
waiting on `AURAD-0005` hosting.

## Standing constraints carried into execution

- **Verify the mechanism on the New Architecture before building on it.**
  `AURAT-0025` found a legacy Paper component silently mis-measured under Fabric
  interop; a native config module deserves the same check, not the same
  assumption.
- **`bff.invalid` must not survive.** With no host configured the build fails
  loudly at configuration time — never quietly resolves to a placeholder.
- **Do not flip a flag.** `BILLING_ENABLED` and `STORE_BILLING_ENABLED` stay
  `false` in committed defaults; when they go true is the owner's call under
  `AURAS-0002`.
- **Move the manor override, do not drop it.** The uncommitted `env.ts` drift
  (LAN IP + billing on) is deliberate and documented in `AURAT-0010`/`0011`.
  `007-execute.md` must tell the owner exactly what to put where, or the next
  manor device pass talks to the wrong host.
- Say which target each build used; run the release gate for more than one.
- Work happens **only in slave-1**; the device pass runs in manor after merge.
- Nothing merges to `develop` without explicit in-the-moment owner approval.

## Next

`007-execute.md` — written in slave-1 after the code, before the IDE review.
