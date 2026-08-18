# AURAT-0028-002 — Check existing state

Date: 2026-08-18

## Brain

- **`AURAD-0005`** — hosting topology is already decided: self-host Chatwoot CE
  in an EU region with the BFF co-located, GCP europe-west by default. This task
  does **not** re-open that; it makes the app able to *address* whatever that
  decision produces.
- **`AURAS-0002`** — the Play runbook. Its step 3 needs an AAB that a licensed
  tester can actually use, which is what this task unblocks.
- **`AURAF-0010`** row **007** (Play Console) is the owner's and all `—`; rows
  001–005 are app-done and BFF-done. Nothing in that feature covers the URL.
- No prior task covers app configuration or build variants. Fresh ground.

## Code (ground truth, slave-1 @ `6a9138b`)

`src/shared/config/env.ts` is the whole surface — four exports:

| Export | Committed value |
|---|---|
| `BFF_HTTP_URL` | `__DEV__` ? `http://<host>:3000` : **`https://bff.invalid`** |
| `BFF_WS_URL` | `__DEV__` ? `ws://<host>:3000/ws` : **`wss://bff.invalid/ws`** |
| `BILLING_ENABLED` | `false` |
| `STORE_BILLING_ENABLED` | `false` |

Consumers are exactly two, both in `shared/api/bff`: `http-client.ts:38` and
`ws-client.ts:68`. So the blast radius of changing how the value is produced is
small — the risk is in the build wiring, not the call sites.

## The habit this replaces

The manor's working copy carries an **uncommitted** 8-line drift on this same
file: `DEV_HOST_OVERRIDE` set to a LAN IP *and* `BILLING_ENABLED` flipped to
`true`. It has survived several merges by being stashed and restored by hand,
and it is on the record in `AURAT-0010` and `AURAT-0011` as something to protect.

That is the real cost of having no env tooling: the only way to configure this
app is to edit a tracked file and then remember never to commit it. One slip
ships a developer's LAN IP, or flips a billing flag, to everyone.

## Platform constraints found

- **Android release forbids cleartext.** The manifest carries
  `android:usesCleartextTraffic="${usesCleartextTraffic}"`, a placeholder React
  Native's Gradle plugin sets `true` for debug and `false` for release. So the
  production URL must be **https**, and a plain-http host will fail silently in
  release only.
- **iOS ATS matches**: `NSAllowsArbitraryLoads` `false`,
  `NSAllowsLocalNetworking` `true` — local dev over http is allowed, anything
  public must be TLS.

## Next

`003-understand.md`.
