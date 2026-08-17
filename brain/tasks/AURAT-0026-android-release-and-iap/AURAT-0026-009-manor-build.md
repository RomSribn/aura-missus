# AURAT-0026 — 009 manor build

Date: 2026-08-18

Owner reported the Android build failing after the merge. Reproduced, diagnosed,
fixed. **No code changed** — the branch is not at fault — but two things here are
worth keeping.

## What failed

`:react-native-iap:compileDebugKotlin` in the manor, 460 errors, all of the form
`Unresolved reference 'NitroModules' / 'core' / 'NullType'` — i.e. the entire
`com.margelo.nitro.*` package missing from the classpath.

## Where it did *not* fail

`./gradlew :app:assembleDebug` in **slave-1**: exit 0, zero errors, 5m16s. Same
commit, same lockfile, same package versions (`react-native-iap` 16.3.1,
`react-native-nitro-modules` 0.36.5). Autolinking resolved identically in both
(`projects` lists the same two Gradle projects), and
`:react-native-iap:dependencies --configuration debugCompileClasspath` printed
byte-identical trees including `project :react-native-nitro-modules`.

So: not the code, not the dependency graph. Manor-local build state.

## Cause

In the manor, `:react-native-nitro-modules:compileDebugKotlin` reported
**UP-TO-DATE while producing zero class files** — 0 in `build/tmp/kotlin-classes`
against 148 in the slave, from the same 14 Kotlin sources.

The sequence that produced it is mine, from `008`: the first `npm install` died
on a dropped SSH connection, the retry left the tree looking installed, and then
`npm ci` **deleted `node_modules` outright** — taking every library's
`android/build/` output directory with it — while Gradle's task history in
`android/.gradle` survived and went on asserting those outputs were current.
`react-native-iap` then compiled against an empty nitro.

Fixed by deleting only regenerable state — `android/.gradle`, `android/build`,
`android/app/build`, and the two libraries' `android/build` — and rebuilding:
**BUILD SUCCESSFUL in 6m38s**, 320 tasks executed, 0 errors. Installed on
SM-A505FN (`R58M37RG00M`) and launched: process alive, no `FATAL` /
`AndroidRuntime` in logcat, `cc.silvermind.aura/.MainActivity`, versionName
`1.0.0`. Both packages now sit on the device, the old `com.psychoapp` beside it,
which is the intended outcome of not deleting the old Firebase app.

## A wrong turn, recorded because the method was the problem

First diagnosis was "the aborted install truncated the packages", from comparing
`find | wc -l` between the trees: 4877 files vs 745. That was a measurement
artifact — the slave had *built*, so its count included `android/build/` and
`.cxx/`. Counting sources only gives 725 / 279 in **both**. Comparing two trees
where one has been built and the other has not is not a comparison.

## The real gap in this task's gating

`007` gated on `bundleRelease` and nothing else. **Debug was never built** until
the owner hit it — and a device run is a debug build. It happens to pass (proved
above in the slave), so nothing shipped broken, but the gate did not cover the
variant the app is actually run in.

**Rule for anything touching native dependencies: build `assembleDebug` as well
as `bundleRelease`, and do it in the slave *and* in the manor after merge.** The
release-only gate is what let a two-variant question be answered with one
variant's evidence.

Second, narrower rule: **after `npm ci` in a tree that has been built, clear
`android/.gradle` too.** `npm ci` removes build outputs Gradle still has history
for, and the failure it produces points at the wrong library.

## A second failure, from the same root: Metro 500 on `split-on-first`

With the APK installed, the app red-screened:

```
The development server returned response error code: 500
While trying to resolve module `split-on-first` from
node_modules/query-string/index.js … this package specifies a `main` module
field that could not be resolved (…/split-on-first/index). Indeed, none of
these files exist
```

`index.js` **was** on disk, the package is byte-identical to the slave's
(1.1.0, no `main`, no `exports` — so plain `index.js` resolution), and the
slave had bundled the same graph without complaint. Restarting Metro with
`--reset-cache` changed nothing, which is what ruled the cache out.

It was **watchman**. `npm ci` recreated ~600 directories under `node_modules`
in one go; watchman dropped the subscription — it had been printing
`Recrawled this watch … MustScanSubDirs UserDropped` in every build log for a
while — and went on serving Metro a file list from before. Metro asks watchman
what exists, watchman does not mention `split-on-first/index.js`, Metro reports
it missing. `--reset-cache` clears Metro's own cache and **not** watchman's,
which is why it looked like a disk problem and was not.

Fixed exactly as watchman's own warning says: `watchman watch-del <root>` +
`watchman watch-project <root>`, then Metro restarted. Bundle now `200`,
8,595,896 bytes. On the device: `Running "PsychoApp" with {"rootTag":1,
"fabric":true}`, Firebase auth initialising, no `FATAL`, no red screen.

(`"PsychoApp"` there is correct and deliberate — the JS component name was left
alone when the rename was scoped to Android, and `MainActivity` carries a
comment saying so.)

Only deprecation warnings remain in the log, all pre-existing: the
`@react-native-firebase` namespaced API against its v22 migration, and
`InteractionManager`. Neither belongs to this task.

**So `npm ci` in a built tree costs three cleanups, not one:** `node_modules`
(npm does it), Gradle's task history in `android/.gradle`, and the watchman
watch. Miss either of the last two and the error points somewhere else entirely
— at a random library's Kotlin, or at a two-file package that is plainly there.

## Unchanged

Device pass is still open, and the checks in `008` still stand — the app
launching proves the rename compiles and installs, not that phone-OTP and push
survived the Firebase re-registration. Those are the two that fail quietly.
