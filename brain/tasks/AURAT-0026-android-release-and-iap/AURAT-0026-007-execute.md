# AURAT-0026 — 007 execute

Date: 2026-08-17
Branch: `feature/AURAT-0026-android-release-and-iap` (off develop `bf2411a`)

Two commits, because the two halves have to be revertable apart: the rename is
load-bearing for anything reaching Play, and the store client is dormant code
that nobody can exercise yet.

---

## Commit 1 — Android identity and a real release build

| File | Change |
|---|---|
| `android/app/build.gradle` | `namespace` + `applicationId` → `cc.silvermind.aura`; `versionName "1.0.0"`; a real `signingConfigs.release` read from `keystore.properties`; a task guard that **fails** `assembleRelease` / `bundleRelease` when it is missing |
| `android/app/src/main/java/cc/silvermind/aura/{MainActivity,MainApplication}.kt` | moved from `com/psychoapp/`, `package` updated |
| `android/app/src/main/res/values/strings.xml` | `app_name` → `Aura` |
| `android/app/google-services.json` | regenerated for the new package |
| `android/keystore.properties.example` | new, committed |
| `.gitignore` | `android/keystore.properties` |

**The guard is the point of the signing change.** The template shipped
`release { signingConfig signingConfigs.debug }`, which is not a missing
feature but a trap: it produces a release build Play rejects, silently.
Replacing it with a silent fallback would have been the same trap. A missing
`keystore.properties` now stops the build with a sentence telling the reader
what to copy and where.

**Keystore.** RSA-4096, PKCS12, valid to 2054, at `~/.aura/aura-upload.keystore`
— outside every worktree, so manor and all slaves share one copy and no
`git clean` reaches it. `android/keystore.properties` points at it by absolute
path and is untracked (verified with `git check-ignore`). Its password was
rotated after it was accidentally echoed into the session transcript; the key
itself is unchanged, so the fingerprints below are the originals. In a PKCS12
store the key password is always the store password, which is why
`-storepasswd` alone was the whole rotation and `-keypasswd` refuses to run.

**`getMainComponentName()` still returns `"PsychoApp"`,** with a comment saying
why: it has to equal `AppRegistry.registerComponent` in `index.js`, which is
shared with iOS, and the owner scoped the rename to Android. Renaming it would
have been a cosmetic change that breaks the iOS entry point.

**Firebase** (owner-approved in-session; Management API, credentials already on
this machine):

```
androidApps/1:1022442840784:android:b8d3a0523d52b9fad734d5   cc.silvermind.aura
  debug   SHA-1  5e8f16062ea3cd2c4a0d547876baa6f38cabf625
          SHA-256 fac61745…033b9c
  upload  SHA-1  45957a77609b47974a350fb85393a3328f29841f
          SHA-256 61c3f587…37bb8b
```

The old `com.psychoapp` app was **left registered** — deleting it would strand
every build already installed on a device. The regenerated
`google-services.json` conveniently carries both clients, so a device on either
package still resolves. Project settings (Spark plan, SMS region allowlist
`[ES]`) were not touched.

Still missing and impossible today: **Google's own app-signing certificate**,
which does not exist until the first Play upload. Its absence is invisible
until a build installed *from Play* tries phone-OTP — `AURAS-0002` step 4.

---

## Commit 2 — the store top-up client

**Dependencies**: `react-native-iap@^16.3.1` + `react-native-nitro-modules@^0.36.5`,
and `@aura/contracts` → `#v0.7.0`. No Gradle edits were needed: the library
ships its own `NitroIap_*` defaults and takes `rootProject.ext` where it exists,
and the store flavour defaults to `play`.

**New slice `features/store-topup/`** — `config/products.ts` (tiers),
`api/store-topup-api.ts` (redeem), `model/use-store-topup.ts` (the whole
orchestration), `model/types.ts`, `index.ts`, plus tests.

**Touched**: `shared/config/env.ts` (`STORE_BILLING_ENABLED`),
`shared/lib/format.ts` (`formatUsdMinorCompact`), `entities/wallet`
(`purchaseAccountId` through the store and the hook), `screens/profile`
(sheet takes tiers, `use-profile` picks the rail),
`screens/profile/config/constants.ts` (tier constants deleted),
`jest.setup.js` (native mock), `tsconfig.json` (see below).

### Decisions taken during implementation

**1. `obfuscatedAccountId` is server-minted, not hashed client-side.** The spec
said "a one-way hash of the Firebase uid". Building that needs a crypto
dependency RN does not have, and it is the weaker design anyway: an app that
can derive its own id can derive anybody's. So `WalletResponse` gained an
optional `purchaseAccountId` and the app just passes it through. Zero new
dependencies and a stronger check. It also gives the rail a natural gate — no
id means the BFF has not shipped `AURAT-0027`, so the rail stays off instead of
inventing a value. `AURAD-0010` was updated to match.

**2. No `packageName` in the redeem request.** The spec had one. It cannot
protect anything — the BFF asks Google about its own package, so a foreign
token is simply not found — while `PurchaseAndroid.packageNameAndroid` is
typed nullable, so including it adds a field that can only fail. Dropped from
the contract before it shipped.

**3. A tier Play does not sell is not offered.** `fetchProducts` answers only
for SKUs that exist and are published; an unknown one is dropped from the grid
rather than rendered into a card that opens Google's sheet on an error. So a
typo in a product id shows up as a missing card — which is what `AURAS-0002`
warns about.

**4. `tsconfig` pins `react-native-iap` to its shipped declarations.** The
package's `exports` map lists a `react-native` condition pointing at raw
`src/`, so `tsc` compiled the library's own TypeScript — which uses `process`
and `global` and fails in an app that deliberately has no Node types. The
alternative was adding `@types/node`, which puts Node globals over the whole
app (and, e.g., changes what `setTimeout` returns). A single `paths` entry
sends **tsc only** at `lib/typescript`; Metro and Jest resolve it normally.

**5. A purchase delivered twice is consumed once.** Found while re-reading the
hook, not by a test: Play hands the same purchase over from *both*
`getAvailablePurchases` at connect and the update listener. Redeeming twice is
harmless — the BFF keys on the token and answers `replayed` — but the second
`finishTransaction` fails, and the hook would have reported that as "that
didn't go through" to a user whose credit had in fact landed. A per-session set
of handled tokens now guards the sequence, and a token is released back out of
it when the redeem fails, so a genuine retry still happens on the next mount.
Pinned by a test that delivers the same purchase down both paths.

**6. Tier constants moved, not copied.** `TOP_UP_AMOUNTS` /
`DEFAULT_TOP_UP_AMOUNT` were deleted from `screens/profile/config/constants.ts`.
A tier is an amount *and* a SKU, and two lists would drift into crediting an
amount nobody sold. Both rails now read `TOP_UP_TIERS`.

### The ordering, which is the actual product

`redeem → publish balance → finishTransaction(isConsumable)`. Consuming first
turns a lost round trip into money taken with nothing delivered. Left
un-consumed, a purchase comes back from `getAvailablePurchases()` at the next
mount and is retried; if we never manage it, Google auto-refunds after three
days. Two tests pin exactly this: the call order, and that a refused redeem
leaves the purchase unconsumed.

---

## Gates

- `npx tsc --noEmit` — clean.
- `npx eslint .` — clean.
- `npx jest` — **52 suites / 300 tests** (was 51 / 286).
- `./gradlew :app:bundleRelease` — run for commit 1 alone, then again with the
  Nitro native module in (4m31s, CMake across all four ABIs), then once more so
  the artifact matches the final tree. Every one produced a signed AAB;
  `keytool -printcert -jarfile` names `CN=Aura, O=Silvermind, C=ES`, SHA-1
  `4595…841F` — our upload certificate, not Android's debug one — and the
  bundled manifest carries `cc.silvermind.aura` and `1.0.0`.

Two things checked on the built artifact rather than taken from the docs,
because both are the kind of claim that is embarrassing to get wrong:

- `com.android.vending.BILLING` **is** in the merged release manifest (the
  library contributes it; no manual edit was needed);
- the release runtime classpath resolves
  `io.github.hyochan.openiap:openiap-google:3.3.1 → com.android.billingclient:billing:9.1.0`,
  which is what clears Google's 31 Aug 2026 Billing-8 publishing gate.

## What this does *not* prove

No purchase has been made, and none can be until the developer account clears
(`AURAS-0002`). The tests prove the ordering and the refusal paths — the parts
that lose money when wrong — not that Play talks to us.

A release build also cannot reach a backend: `env.ts` still ships
`https://bff.invalid` for production, and the RN Gradle plugin turns cleartext
off for release. That is unchanged by this task and is the `AURAD-0005`
hosting follow-through.

## For manor, after merge

`npm install` (three dependency changes) and **`cd ios && pod install`** — the
new library autolinks on iOS too, so `Podfile.lock` needs regenerating there.
It was deliberately **not** run here: `AURAT-0025` recorded that a `pod install`
on this machine churns ~140 lines on a CocoaPods 1.15.2 → 1.16.2 drift that does
not belong to this branch.

## Also shipped

- `AURAD-0010` — ratified, amended per decisions 1 and 2 above.
- `AURAF-0010` — scope table, rows 001–005 marked owner-approved and app-done.
- `AURAS-0002` — the Play Console runbook.
- `AURAT-0027` — BFF task brief (executed in `aura-bff-manor`).
- `@aura/contracts` **v0.7.0** — committed, tagged and pushed
  (`3dff17a`, owner-approved in-session).

## Next

Staged for IDE review, uncommitted. `008-*` after the owner's read.
