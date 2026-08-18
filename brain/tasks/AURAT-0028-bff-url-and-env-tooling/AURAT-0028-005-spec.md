# AURAT-0028-005 — Spec

Date: 2026-08-18
Slave: slave-1, `feature/AURAT-0028-bff-url-and-env-tooling` off develop `6a9138b`
Status: **awaiting owner approval — no code written**

## Goal

Make the app's backend address and its two rollout flags **configurable per
build**, so a release AAB can talk to a real host — and so configuring this app
stops meaning "edit a tracked file and never commit it".

## Scope

### 1 · Pick the mechanism, with evidence

Evaluate the three options in `004` and take one. **Verify the choice on the New
Architecture before building on it** — check for `codegenConfig` and a Fabric
story exactly the way `AURAT-0025` had to for the gradient. A native config
module that turns out to be a legacy view is the same defect wearing a different
hat.

Record *why* in `007-execute.md`, including what was rejected.

### 2 · Replace the `__DEV__` branch

`BFF_HTTP_URL` / `BFF_WS_URL` come from configuration, not from the bundler
flag. `__DEV__` may remain as the fallback default, never as the switch — a
release bundle pointed at staging must be expressible.

`BILLING_ENABLED` and `STORE_BILLING_ENABLED` become configurable in the same
mechanism. **Their committed defaults do not change in this task** (`false` and
`false`); when they go true is `AURAS-0002` and the owner's call.

The two consumers (`shared/api/bff/http-client.ts:38`,
`ws-client.ts:68`) should not need to change at all. If they do, the mechanism
is leaking.

### 3 · Three environments, one of them provable today

- **dev** — the current local behaviour, LAN IP or `adb reverse`, http allowed.
- **prod** — https, no default invented. If no host exists when this lands, the
  value stays empty and the build fails loudly at configuration time rather than
  quietly resolving to a placeholder. `bff.invalid` must not survive.
- **A third target that points at an arbitrary https host**, so a Cloudflare or
  ngrok tunnel to the manor Mac proves the whole rail before `AURAD-0005` is
  executed. This is the owner's cheap path to a real purchase and the reason to
  not hard-code a single production domain.

### 4 · Carry the manor's local override across

The manor's working copy holds an uncommitted 8-line drift on `env.ts` (LAN IP
+ `BILLING_ENABLED` flipped). **Move it, do not drop it**: after this task the
same override must be expressible in the new mechanism, in a file the
`.gitignore` covers, and `007-execute.md` must say exactly what the owner has to
put where. Otherwise the next manor device pass silently talks to the wrong host.

### 5 · Keep the toolchain honest

- **Jest** resolves the same values with no bundler running — add the test that
  proves it.
- **Metro** may need `--reset-cache` after a Babel change; if so, say it in the
  execute file. `AURAT-0003` lost time to exactly this.
- The **release gate** for this task includes `assembleRelease` (or
  `bundleRelease`), not just `assembleDebug` — the whole point is a release
  build, and `AURAT-0026` already learned to build both.

## Out of scope

Hosting, choosing a domain, DNS, TLS certificates (`AURAD-0005`). Flipping any
flag to `true`. iOS release configuration beyond keeping it building —
`AURAF-0010` row 008 is deferred until Apple clears.

## Acceptance

- A release build configured with an https host reaches that host; no
  `bff.invalid` anywhere in the tree.
- Switching target changes the URL with **no edit to a tracked source file**.
- Committed defaults keep both flags `false`.
- Manor's local override reproduced through the new mechanism, documented.
- Gates green in the slave: tsc / eslint / jest **and** a release build.
- Device pass in manor after merge: dev target still reaches the local BFF, and
  a tunnel-configured release build reaches it over https.

## Resolved by the owner (2026-08-18)

**All three targets, including the arbitrary-https one.** It is what makes a real
Google Play purchase provable before `AURAD-0005` is executed — the owner can
point a release build at a tunnel to the manor Mac and exercise the whole rail
with the BFF still local and its logs in reach.

Consequence to hold: three targets are three things that can be wrong, so the
execute file must state plainly which target a given build was made with, and
the release gate must be run for more than one of them.
