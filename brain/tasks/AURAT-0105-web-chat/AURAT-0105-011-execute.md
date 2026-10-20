# AURAT-0105-011 — Execute (fix `010`: smoother end of the tarot reveal)

Date: 2026-10-20

## Done

- Timeline (`features/tarot-pick/config/spread.ts`): turn at 560 ms (as the app) → flip 600 ms →
  **hold face up 700 ms** (`HOLD_MS`) → **fold away 450 ms** (`CLOSE_MS`) → the closed card. The
  app resolves 60 ms after the turn (`RESOLVE_AT_MS = 1220`); the web difference is recorded in the
  port header of `use-tarot-pick.ts`.
- New phase `closing` in `SpreadState`: the fan stays mounted while it folds — the plum card
  collapses from its own height (`grid-template-rows: 1fr → 0fr`) and fades.
- The closed card comes in with `settle-in` (fade + rise + slight scale, `--dur-settle` and the
  app's settle easing); the divider «You chose …» follows a beat later.
- Flip and close durations go to CSS from the config (`--flip-ms`, `--close-ms` on the fan) — one
  source; token `--dur-flip` removed.

## Checks

typecheck ✓ · lint ✓ · tests 48 / 719 ✓ (timeline test: turned at 560, still the fan and folding at
+1300, closed card at +450) · build ✓ · prettier ✓.

Next: owner review in the IDE.
