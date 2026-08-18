# AURAT-0028-007 — Execute

Date: 2026-08-18
Slave: slave-1, `feature/AURAT-0028-bff-url-and-env-tooling` off develop `6a9138b`
Status: **code written, staged, gates green — awaiting IDE review, not merged**

## What shipped

The app's backend address and its two rollout flags stopped being source and
became **build configuration**. `src/shared/config/env.ts` no longer branches on
`__DEV__` and no longer contains a placeholder host; it reads five values that
Babel inlines at transform time from `env/.env.<target>`.

Three targets ship: `dev`, `prod`, `tunnel`. Both consumers
(`shared/api/bff/http-client.ts:38`, `ws-client.ts:68`) are **byte-identical** —
`git diff` on them is empty, which was the stated test for whether the mechanism
leaks.

## 1 · The mechanism, and what was rejected

**Chosen: Babel-time inlining, driven by a dependency-free resolver the whole
toolchain shares.** `env/resolve.js` layers the env files and validates them;
`env/babel-plugin-aura-env.js` replaces `process.env.AURA_*` with literals.
`babel.config.js` calls the resolver and passes the values as *plugin options*,
`metro.config.js` folds the resolved fingerprint into `cacheVersion`, and Gradle
declares that same fingerprint as an input to the JS bundling task. One resolver,
one set of rules, four consumers.

### `react-native-config` — the New Architecture check was run, and it passed

The spec asked to verify this the way `AURAT-0025` had to for the gradient rather
than assume. It was verified against the published tarball (1.6.1), and **the
`AURAT-0025` concern does not apply**: the package ships a `codegenConfig` block
(`RNCConfigSpec`, `type: "modules"`), a `codegen/NativeConfigModule.js` spec
using `TurboModuleRegistry.get`, and separate `android/src/newarch` /
`android/src/oldarch` source sets. It is a real TurboModule, not a legacy view
riding the interop layer. It was **not** rejected on that ground, and saying it
was would have been convenient and false.

It was rejected on three others, all from its own source:

1. **It cannot satisfy the Jest requirement.** `index.js` is
   `require("./codegen/NativeConfigModule").default.getConfig().config` at module
   scope, on a `TurboModuleRegistry.get()` result that is nullable. Under Jest
   there is no native module, so that is a `TypeError` on import. Jest would have
   to be handed a hand-written mock — which means Jest would resolve *mock*
   values, not "the same values", which is precisely what the spec asked to
   prove.
2. **It has no failure mode.** Its own type is
   `{ [name: string]: string | undefined }`, and `android/dotenv.gradle` prints
   `*** Missing .env file ***` and carries on — the source even has a
   `// TODO: Fail Android builds if line doesn't match`. A missing host would
   reach `fetch("undefined/v1/...")`. The hard constraint here is the opposite:
   fail loudly at configuration time. A validation layer would have had to be
   written on top of it anyway.
3. **The one thing it buys, this app does not need.** Its distinguishing feature
   is exposing values to *native* code via `BuildConfig` and `Info.plist`. There
   are zero native consumers here — the only readers are two JS files. The cost
   of that unused feature is an `.xcconfig` plus a scheme Pre-action Run Script
   in the Xcode project (manual project surgery, unverifiable from a slave, and
   out of scope), and Gradle flavour plumbing, since `dotenv.gradle` picks its
   env file by parsing the Gradle task name.

**Build-type source swap** (`env.dev.ts` / `env.prod.ts`) was rejected for a
narrower reason: a generated or swapped file is state on disk. Build prod, then
run dev without regenerating, and the stale file is silently wrong — the same
class of bug that turned up in the Gradle bundling task below. Resolving from
the environment at every transform has no stale state to hold.

## 2 · The three targets

| `AURA_ENV` | Origin | Notes |
|---|---|---|
| `dev` (default) | `http://10.0.2.2:3000`, `http://localhost:3000` on iOS | only target with `AURA_ALLOW_CLEARTEXT=true` |
| `prod` | **empty** | fails the build until `AURAD-0005` lands and a real origin is committed |
| `tunnel` | **empty** | owner fills `env/.env.tunnel.local` with the https tunnel URL |

Settings are `AURA_BFF_ORIGIN`, `AURA_BFF_ORIGIN_IOS`, `AURA_BFF_WS_PATH`,
`AURA_BILLING_ENABLED`, `AURA_STORE_BILLING_ENABLED`, plus the target-level
`AURA_ALLOW_CLEARTEXT` which never reaches JS. Layering, lowest first:
`.env.<target>` → `.env.<target>.local` (gitignored) → the real process
environment. `env/README.md` is the reference.

`BFF_WS_URL` is derived from the same origin (`http`→`ws`, plus
`AURA_BFF_WS_PATH`) rather than configured separately. Two independent URL
settings are two places to change a host and one chance to forget — and the
manor's drift is itself evidence that the host does change.

**Neither flag was flipped.** Committed defaults are `false` for
`AURA_BILLING_ENABLED` and `AURA_STORE_BILLING_ENABLED` in all three targets,
and a test asserts it against the committed layer specifically, so a `.local`
file cannot make that assertion pass or fail.

## 3 · What the owner must put where — the manor override

The manor's working copy carries an uncommitted 8-line drift on `env.ts`
(`DEV_HOST_OVERRIDE = '192.168.31.55'`, `BILLING_ENABLED = true`). It has been
verified untouched by this task. After merge it must be **moved**, in this
order:

1. **Discard the old drift**, which will otherwise conflict — `env.ts` is
   rewritten by this task:

   ```sh
   cd project/manor/master/aura-app
   git checkout -- src/shared/config/env.ts
   ```

2. **Create `project/manor/master/aura-app/env/.env.dev.local`** — gitignored,
   never committed — with exactly:

   ```
   AURA_BFF_ORIGIN=http://192.168.31.55:3000
   AURA_BFF_ORIGIN_IOS=
   AURA_BILLING_ENABLED=true
   ```

3. **Confirm it took effect** before spending a device pass on it:

   ```sh
   npm run env:show
   ```

   Expected: `AURA_BFF_ORIGIN http://192.168.31.55:3000`,
   `AURA_BFF_ORIGIN_IOS null`, `AURA_BILLING_ENABLED true`.

The empty `AURA_BFF_ORIGIN_IOS=` line is not optional and not cosmetic — see
§6.2. Update the IP when the Mac's address changes; that is now a one-line edit
to an ignored file instead of a tracked source file kept out of every commit by
hand.

## 4 · Gates

`tsc --noEmit`, `eslint .`, and `jest` are green. **54 suites / 325 tests**, up
from 52 / 300 — 2 new suites, 25 new tests. Run twice, once with a
`env/.env.dev.local` present (the manor's state) and once without (a fresh
checkout); green both ways, which is the point of resolving the committed layer
separately in the tests.

`src/shared/config/__tests__/env.test.ts` is the Jest-without-a-bundler proof the
spec asked for. It compares the module's exports, per platform, against the
resolver Babel itself was handed. If the plugin had not run, `process.env` would
be Node's, the origin would be `undefined`, and the module would throw on import
before any expectation ran.

### Builds — which target each one used

Every one of these was run in slave-1. Nothing was started; no stack, no Metro.

| Command | Target | Result |
|---|---|---|
| `./gradlew :app:assembleDebug` | `dev` | **SUCCESS** |
| `./gradlew :app:assembleRelease` | `tunnel` (+ origin) | **SUCCESS**, signed APK |
| `./gradlew :app:bundleRelease` | `tunnel` (+ a *different* origin) | **SUCCESS**, AAB |
| `./gradlew :app:assembleRelease` | `prod` (+ origin) | **SUCCESS** |
| `./gradlew :app:bundleRelease` | `prod`, no origin | **FAILS loudly** — as designed |
| `react-native bundle --dev false` | `dev` | **FAILS loudly** — cleartext in a release bundle |
| `react-native bundle --dev false` | none set | **FAILS loudly** — a release must name its target |

The release artifacts were opened and checked, not just built. The signed
release APK's Hermes bytecode contains the configured origin and **not** the dev
origin; the AAB built with a second origin contains only that second one; no
hostname on the `.invalid` TLD appears in any of them.

That the `tunnel` and `prod` release builds succeed *through Gradle* is also the
proof that `AURA_ENV` survives the Gradle daemon into the bundler — it is not
assumed anywhere.

## 5 · Metro cache

`AURAT-0003`'s trap was confirmed to still exist and was then closed rather than
documented around. `@react-native/metro-babel-transformer`'s `getCacheKey()`
hashes the transformer file and the Babel *preset* — the project's
`babel.config.js` is not in it, so a config change alone would be served from a
stale cache. `metro.config.js` now sets `cacheVersion` to the resolved
configuration's fingerprint, which *is* part of Metro's transform cache key.

**Consequence: `--reset-cache` is not needed after switching target or editing an
env file.** It is still needed after editing `babel.config.js` itself. Same for
Jest: the values ride in as Babel plugin *options*, which are part of babel-jest's
cache key, so no `--clearCache` either.

## 6 · Two defects the gates found

Both were found by running the release gate rather than by reading the code, and
both are the exact failure this task exists to remove — a build that succeeds and
talks to the wrong host.

### 6.1 · Gradle reused the previous target's JS bundle

The first `AURA_ENV=prod ./gradlew :app:bundleRelease` printed
`> Task :app:createBundleReleaseJsAndAssets UP-TO-DATE` and **BUILD SUCCESSFUL**
— packaging the *tunnel* bundle into a prod AAB. `AURA_ENV` is an environment
variable, not a declared Gradle task input, so switching target does not
invalidate the bundling task.

Fixed in `android/app/build.gradle`: the resolved fingerprint (via
`env/fingerprint.js`) is declared as an input property on
`createBundle*JsAndAssets`. It is a lazy `Provider`, so only bundling tasks
evaluate it and ordinary tasks are unaffected, and the resolver's own message is
re-thrown as a `GradleException` so the failure reads properly instead of
`Process 'command 'node'' finished with non-zero exit value 1`. Verified: the
same target with a changed origin now re-runs the task, and the AAB carries only
the new origin.

### 6.2 · A half-overridden origin sent iOS to the wrong host

Reproducing the manor override surfaced this. Setting only `AURA_BFF_ORIGIN` in
`.env.dev.local` moves Android to the LAN IP while `AURA_BFF_ORIGIN_IOS` stays
behind at `localhost` from the committed `.env.dev` — so a **physical iPhone**,
the one device that needs the LAN IP, silently keeps the wrong address. The old
`DEV_HOST_OVERRIDE` did not have this shape: it overrode both platforms at once.

The resolver now refuses that combination, naming both files and both values, and
tells the owner to set `AURA_BFF_ORIGIN_IOS=` empty to mean "same origin on both
platforms". That is why step 2 of §3 has three lines and not two.

## 7 · `bff.invalid`

Gone from the app and from every build artifact. `grep -r "bff\.invalid"` over
the tree returns **exactly one hit**: `env/__tests__/resolve.test.js:120`, where
it is the *input* to the test that asserts the resolver rejects it. The guard is
broader than the string — any host on the reserved `.invalid` TLD is refused.

Deleting that occurrence too would have removed the regression guard, so it was
kept deliberately; flagging it here rather than quietly.

## 8 · Notes and limits

- **iOS needed no native wiring**, which was a deliberate consequence of choosing
  a JS-only mechanism. To build a non-default target from Xcode, export
  `AURA_ENV` in `ios/.xcode.env.local` (gitignored, already present and already
  sourced by the RN build script phase). Untested here — no iOS build was run
  beyond keeping the tree building, per scope.
- **Android release ABIs**: builds used the project default
  (`armeabi-v7a,arm64-v8a,x86,x86_64`); nothing was narrowed to make the gate
  cheaper.
- The `.example` reserved TLD is *not* rejected, only `.invalid`. It is used in
  test fixtures as a valid-looking host. Worth a glance when the real prod origin
  is committed under `AURAD-0005`.
- `npm run env:show` was added — it prints what a target resolves to without
  building anything. It is the check to run on the manor before a device pass.
- Build outputs in `android/app/build/outputs/` are from the probe builds above
  and carry throwaway origins. They are gitignored and are not shippable
  artifacts.

## 9 · Not done, on purpose

Hosting, domain, DNS, TLS (`AURAD-0005`). Flipping either flag (`AURAS-0002`,
owner's call). iOS release configuration beyond keeping it building
(`AURAF-0010` row 008). The device pass — dev target reaching the local BFF, and
a tunnel-configured release build reaching it over https — runs in **manor after
merge**, per slave rules.

## Next

IDE review of the staged change, then `008-review.md`. Nothing merges to
`develop` without explicit in-the-moment owner approval.
