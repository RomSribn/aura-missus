# AURAD-0006 — The BFF is its own repo + its own wts manor; types shared via a contracts package; brain stays unified under AURA

Date: 2026-07-10
Status: accepted (owner-ratified 2026-07-10)

## Decision

The Aura BFF (`AURAD-0004`: NestJS) ships as a **separate git repository**
served by a **new, dedicated wts manor** (`aura-bff-manor`), mirroring
`chatwoot-manor` — **not** a monorepo folded into the RN app, and **not** a
second master inside `aura-app-manor`. Shared TypeScript contracts
(message / session / wallet / advisor DTOs) travel through a small **versioned
`@aura/contracts` package**, not a shared repo tree. The **missus knowledge base
stays single** for the whole product: the current aura brain is **extracted from
the `aura-app-manor` workspace wrapper into a standalone `aura-missus` git repo**
(`PROJECT=AURA`) that **both manors clone as their missus** — so any agent
session in either manor natively reads and writes the same decisions / features /
tasks. The **AURA** prefix stays single across app + BFF; the repo/manor split is
a code+runtime boundary only, not a product-tracking boundary. Extends the ops
shape of `AURAD-0004` / `AURAD-0005`.

## How it works

- **One deploy-unit = one manor** (the established pattern): `aura-app-manor`
  (RN, `PROJECT_PREFIX=AURA`) and `chatwoot-manor` (`PROJECT_PREFIX=CW`) already
  follow it. The BFF is a third deploy-unit (Docker container, GCP europe-west,
  its own Postgres/Redis — `AURAD-0004`/`AURAD-0005`), so it gets
  **`aura-bff-manor`**: its own `.wts/config`, `bin/wts-*`, `.claude/`,
  `CLAUDE.md`, `active-work.md`, and slave slots.
- **Its own build rules.** The manor's `CLAUDE.md` is tuned to NestJS
  (modules/DI, BullMQ jobs, the Chatwoot webhook receiver, append-only ledger
  integrity, Firebase-Admin guard) — kept clear of the RN/FSD rules in
  `.claude/aura-build-rules.md`, which do not apply to a backend.
- **Runtime model fits the manor rules.** A backend can only be verified against
  a live stack (Postgres + Redis + a dev Chatwoot — `AURAT-0004` deps). Its own
  manor owns that runtime; slaves stay code-only (lint/build/typecheck/unit),
  full-stack verification happens in the BFF manor after merge — the same
  discipline `chatwoot-manor` already uses, and the reason the RN manor forbids
  full-stack in slaves.
- **Shared types without a monorepo.** `@aura/contracts` (versioned package —
  published registry or git dependency) holds the request/response + domain DTOs
  both sides speak; the RN app and the BFF each depend on it. This delivers the
  `AURAD-0004` "shared, not re-declared" goal without merging repositories.
- **Unified brain via a shared `aura-missus` repo.** Today the aura brain is
  *trapped* inside the `aura-app-manor` workspace wrapper (tracked by the wrapper
  repo itself, no remote), so a session in another manor cannot see it. We
  **promote it to a standalone `aura-missus` git repo** (`brain/PROJECT=AURA`),
  and **both `aura-app-manor` and `aura-bff-manor` clone it** as their missus
  (`setup.sh` reads the prefix from the clone's `brain/PROJECT`). `AURAT-0004…0008`
  and `AURAF-0007` continue to live there under **AURA**; any agent session in
  either manor reads/writes the same brain, and `wts-task` works natively in
  both. `aura-bff-manor` is a code+runtime workspace, not a separate product
  tracker. **ID-counter caveat:** `active-work.md` (and its counters) is
  per-workspace, so new AURA IDs are minted from **one** canonical workspace
  (aura-app-manor) to avoid collisions; the BFF manor consumes/executes existing
  specs.
- **RN repo untouched.** `RomSribn/aura-app` keeps its current shape (native
  Firebase config, iOS/Android projects, Metro, FSD) — no restructure into
  `apps/*`.

## Why

- **Runtime model diverges.** The RN manor's "no full stack in slaves, verify in
  manor" rules are RN-shaped; a BFF needs Docker+PG+Redis to prove anything. A
  dedicated manor gives it the right runtime model — exactly why Chatwoot got its
  own manor.
- **Consistency.** The one-manor-per-deploy-unit pattern already holds
  (aura-app, chatwoot); the BFF slots straight into that row.
- **No risky migration of a live app.** Monorepo-ifying a mid-development RN
  repo (native builds, FSD) is disruptive for a benefit — shared types — that a
  contracts package delivers more cheaply.
- **Independent cadence.** The BFF can deploy many times a day; app releases go
  through store review. Separate repos/manors decouple them.
- **wts fits.** The framework maps one manor → one master repo; a separate manor
  is the grain-aligned choice. Adding a second master into `aura-app-manor`
  would fight that model.

**Dev loop (grounds the topology):** the BFF is developed against a live stack —
`chatwoot-manor` runs Chatwoot (docker) with a dev `Channel::Api` inbox + service
User + Agent Bot (`AURAD-0005` ops, `AURAT-0004` dep); `aura-bff-manor` runs
Postgres + Redis + the Nest BFF (docker) pointing at that Chatwoot over HTTP
(Application API out, `webhook_url` back). Code is edited in BFF slaves
(typecheck/unit) and the full app→BFF→Chatwoot→push loop is verified in the BFF
manor. The mobile app points its API base at the local BFF and imports
`@aura/contracts`. Chatwoot stays a separate repo/manor — the link is runtime
config (token + webhook), not code coupling.

Execution (ops follow-up, done via the canonical scaffolder at
`personal/backend-structure-template/manor/setup.sh`):
1. Extract the current `brain/` into a new **`aura-missus`** repo (`PROJECT=AURA`);
   rewire `aura-app-manor` to clone it as its missus.
2. Create **`RomSribn/aura-bff`** (Nest skeleton, `develop` branch).
3. `WORKSPACES_HOME=…/ai-manors setup.sh <aura-bff-url> <aura-missus-url>` →
   scaffolds `aura-bff-manor` cloning both; verify `.wts/config` (`PROJECT=AURA`,
   `MASTER_BRANCH=develop`).
4. Stand up `@aura/contracts` (package location TBD) + the dev Chatwoot instance.

Assumption: a small `@aura/contracts` package is enough to keep the app↔BFF
types in sync (no full monorepo toolchain now); revisit if the shared surface
grows or a third TS consumer appears. Brain extraction is a fresh-repo import
(current content + one commit) — full doc history remains in the `aura-app-manor`
wrapper log; no `filter-repo` surgery required.

Informed by `AURAI-0002`, `AURAD-0004`, `AURAD-0005`, `AURAF-0007`,
`AURAT-0004`. Unblocks scaffolding the BFF manor + repo for `AURAT-0004`.
