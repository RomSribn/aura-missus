# AURAT-0101-007 — Execute

Date: 2026-10-20
Slave: slave-1, `feature/AURAT-0101-web-foundation`. Changes staged, **not committed** (owner reviews in IDE).

## Done (aura-web)

- Tooling: `package.json` (Vite 7.3, React 19.3, react-router 7.18, RTK 2.13, react-redux 9.3,
  firebase 12.19, zod 3.25, `@aura/contracts#v0.22.0`; TS 5.9, ESLint 9, Vitest 3, Steiger 0.7,
  Prettier 3), `tsconfig{,.app,.node}.json` (strict + `noUncheckedIndexedAccess` +
  `exactOptionalPropertyTypes`, `@/` alias), `vite.config.ts` (alias, Vitest, firebase chunk),
  `eslint.config.js` (typescript-eslint strict-type-checked, react-hooks, jsx-a11y,
  `no-restricted-imports` FSD patterns, `no-console`, style-literal and `dangerouslySetInnerHTML`
  bans, `ui/` render-only bans), `steiger.config.js`, `.prettierrc.json`, `.env.example`, `.env.test`,
  `.nvmrc`, `index.html` (fonts), README.
- `shared/config`: `tokens.css` (handoff 1:1 + phone scale; inline literals lifted into tokens —
  shadows, motion, `--white`, scrim, radii `--r-sm/--r-field/--r-pill`, `--s18/--s56/--s72`, sheet widths),
  `breakpoints.ts`, `routes.ts` (paths, builders, `?q` `?cat` `?book&slot` `?id` parsers), `env.ts`
  (Zod, fail-fast), `icons.ts` (40 glyphs).
- `shared/api`: `firebase.ts` (lazy init, `getIdToken`, `signOut`, `useAuthStatus`), ported from aura-app
  `server-clock`, `refusal-code`, `account-deleted`, `base-query` (RTK `BaseQueryFn`), `ws-client`
  (+ `WsServerEvent.safeParse`); `base-api.ts` (no endpoints).
- `shared/model/dialog.ts`, `shared/lib` (`cx`, `useModal` — focus trap / Esc / scroll lock / focus
  return, `useNarrow`), `shared/ui` (Button, EmptyState, Field, Icon, IconButton, Sheet, Toggle).
- `app`: `main.tsx`, `root.tsx`, `state/store.ts`, `session/use-account-session.ts`
  (`ACCOUNT_DELETED` → sign out; guest → `resetApiState`), `router/` (route table with `handle`:
  `pushed`, `gate`), `layouts/app-layout` (logo + 4 links → phone tab bar; pushed flows hide it),
  `dialog-host` (registry `config/dialogs.ts`, empty; closes on route change), `guards/` (PrivateRoute +
  GuestGate), `errors/` (NotFound, RouteError), `config/` (copy, nav, dialogs), `styles/global.css`.

## Checks (in slot)

`npm run lint` (eslint + steiger) ✓ · `npm run typecheck` ✓ · `npm test` — 10 files, 66 tests ✓ ·
`npm run build` ✓ (index 465 kB / 146 kB gz + firebase 67 kB) · `prettier --check` ✓.
Lint rules verified on a throwaway violating file (app import, deep shared import, `../../../`,
timer / `useNavigate` in `ui/`, style literal, `dangerouslySetInnerHTML` — all reported).

## Decisions during implementation

- Guest access is opt-in per endpoint: `extraOptions: { public: true }` (006). Without it a guest
  request is a 401 before the network, as in the app.
- No response at all → `{ status: 'FETCH_ERROR' }` instead of a throw (RTK Query base queries must not
  throw); the cause is not kept (could carry the URL).
- Versions: kept the majors approved in the spec (Vite 7, RR 7, ESLint 9, Vitest 3, TS 5.9, zod 3 —
  contracts peer `^3.23`), although newer majors exist (Vite 8, RR 8, ESLint 10, TS 7, zod 4).
- Steiger: `segments-by-purpose` forbids `providers` / `store` in `app` → `app/state`, `app/session`,
  `app/root.tsx`. `no-layer-public-api` off for `shared/index.ts` only (rules: one root `@/shared`).
- Spacing literals ≥ 12px replaced by tokens; where the handoff value was off-scale (13, 15, 22, 26)
  the nearest token is used.
- Routes render `element: null` until their page task plugs in `@/pages/<name>`.

## Open / known

- `npm audit`: 12 advisories, all in dev tooling (vitest/tinypool, steiger/braces) and in
  `@firebase/firestore` (grpc) that the app never imports. Not fixed here — fixing means newer majors.
- Back button closing the open dialog first (NAVIGATION §5) — with the first real dialog (auth).
- `useNarrow`, `BffSocket`, `BILLING_DISABLED_STATUS`, route parsers, `Field`, `Toggle` have no
  production consumer yet (spec-approved foundation exception).
- Manor before `npm run dev`: Firebase Web App in `aura-2781b` + `.env.local` (owner); BFF CORS for the
  web origin is `AURAT-0102`.

Next: owner review in IDE → commit → merge gate.
