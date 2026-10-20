# AURAT-0101-003 — Understand

Date: 2026-10-20

Build the empty-but-real `aura-web` foundation on which every screen task lands: the Vite + React 19 +
TS-strict app with RTK Query, `@aura/contracts@v0.22.0`, the full lint/typecheck/test/build tooling
(FSD direction enforced by ESLint + Steiger from day one), the `shared` layer (tokens, breakpoints,
routes, env, base API / base query / WS client ported from aura-app, ui atoms) and the `app` layer
(providers, layouts, dialog host, guest guard). No screens and no business slices — routes render
placeholders owned by `app`/`shared` only as far as needed to compose the router.

Out: deploy/CI, Playwright, any `pages/*` with real content, entities/features.

Next: 004-context.
