# AURAT-0101-004 — Context

Date: 2026-10-20

Sources checked:
- Brain: `AURAD-0019`, `AURAI-0007` (FSD map, phases 1 and 3), `AURAF-0020` (row 008), stub `AURAT-0102`
  (BFF: CORS, `/ws` Origin, `@Public` catalog/profile — lands before Advisors/Auth screens).
- Rules: `.claude/aura-web-build-rules.md`, skills `react-web-app`, `fsd`.
- Handoff: web `README.md`, `STRUCTURE.md`, `NAVIGATION.md` §1, §4, §5; `src/styles/tokens.css`,
  `src/components/ui/{primitives,Icon}.tsx`, `layout/TopNav.{tsx,css}`; mobile `MOTION_AND_ICONS.md`, `icons/`.
- aura-app `cc71ef4`: `src/shared/api/bff/{http-client,account-deleted,refusal-code,server-clock,ws-client}.ts`
  + their tests; `.eslintrc.js` (`no-restricted-imports` patterns); `env/.env.{dev,staging}`
  (`bff-dev.aura-app.cc`, WS path `/ws`); Firebase project `aura-2781b`.
- `@aura/contracts` v0.22.0: `ApiError`, `ACCOUNT_DELETED = 'account_deleted'`, `WsServerEvent`; peer `zod ^3.23`.
- `aura-web` develop `7296499`: README + .gitignore only. Node 22.23 / npm 10.9 locally.

Key findings:
- Handoff `tokens.css` mixes tokens with base classes that hold raw literals (shadows, durations,
  easings, `#111`, `#fff`). Rule 3 wants those as tokens → port 1:1 and lift the remaining literals into
  named tokens; keep the handoff's global utility classes (`.wrap`, `.only-phone`, `.only-desktop`).
- Handoff `Icon.tsx` has 40 glyphs (the app's 36 + `percent`, `sale`, `briefcase`, `coin`).
- The app's `bffRequest` throws 401 without a token. On the web guests must read `@Public` routes
  (AURAT-0102), so the web base query sends no `Authorization` for a guest — a deliberate divergence.
- The prototype's `Sheet` has no focus trap / focus return; rules require both.
- Firebase web app config (apiKey, authDomain, appId) is not in any repo — the web app must be registered
  in Firebase project `aura-2781b` (owner, console); values go to `VITE_FIREBASE_*` (public by design).
- Contradiction: rule 5 "exports with zero consumers do not merge" vs the stub's list of ui atoms
  (Field, Toggle have no consumer until the auth/profile screens). Raised to the owner in the spec.

Next: 005-spec.
