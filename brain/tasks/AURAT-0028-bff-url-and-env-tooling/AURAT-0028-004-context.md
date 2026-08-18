# AURAT-0028-004 — Context

Date: 2026-08-18
Sources: `AURAD-0005`, `AURAS-0002`, `AURAF-0010`, `AURAT-0010`/`0011` (the
env drift), the slave tree, and the app's Android/iOS network policy.

## Findings

**1 · The surface is tiny; the wiring is the work.** Two consumers, one file,
four exports. Whatever mechanism is chosen, the diff in `src/` should stay
small — most of the change is Gradle, Xcode, Babel/Metro and `.gitignore`.

**2 · Options, with the trade the project actually faces.**

| | |
|---|---|
| **`react-native-config`** | The conventional answer: a `.env` per flavour, values readable from JS *and* from native (Gradle/Info.plist). Heaviest wiring, and its New-Architecture story on RN 0.85 must be **verified, not assumed** — the same trap that made the gradient a legacy view in `AURAT-0025`. |
| **Babel-time inlining** (`babel-plugin-transform-inline-environment-variables` or a small custom plugin) | No native module at all, so nothing to break under Fabric; values are compiled in from the shell environment. Cannot be read by native code — which this app does not need. |
| **Build-type source swap** (`env.dev.ts` / `env.prod.ts` picked by Metro or a Babel alias) | No dependency whatsoever, entirely explicit, but the choice becomes bundler configuration and drifts from the standard everyone expects. |

Whatever is chosen must survive the two things this project already knows bite:
a **cache-stale Metro** after Babel config changes (`AURAT-0003`: it resolved
only after `npm start -- --reset-cache`), and **Jest**, which must keep resolving
the same values without a running bundler.

**3 · `__DEV__` is the wrong switch to keep.** It is a *bundler* flag, not an
environment: a release bundle pointed at staging is a legitimate build this
app currently cannot express. The condition should become the configured
environment, with `__DEV__` at most a default.

**4 · The secret question.** Nothing here is a secret — a BFF base URL is public
by definition, and everything sensitive already lives server-side. So `.env`
files may be committed *if* they hold only non-secret defaults, and the
`.gitignore` story should say which file is local-only rather than leaving it to
habit. That is the whole reason the manor's drift exists.

**5 · Do not break the manor's local override on landing.** Its uncommitted
`env.ts` drift is deliberate and documented. If `env.ts` stops being the place
that value lives, the migration has to *move* the override rather than delete
it, and say so in the execute file — otherwise the next device pass in manor
silently talks to the wrong host.

## Contradiction logged

None between sources. The only tension is convention (`react-native-config` is
what a reviewer expects) versus risk (a native module on a New-Architecture app
that already had one legacy-interop defect this month).

## Next

`005-spec.md`.
