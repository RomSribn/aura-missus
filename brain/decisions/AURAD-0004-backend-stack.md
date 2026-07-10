# AURAD-0004 — The Aura BFF is Node + TypeScript on NestJS, Postgres + Redis

Date: 2026-07-09
Status: accepted (owner-ratified 2026-07-09)

## Decision

The Aura backend-for-frontend (`AURAI-0002` Option B) is **Node.js + TypeScript
on NestJS**, backed by **PostgreSQL** (wallet, ledger, mapping) and **Redis**
(queues), deployed as a container **co-located with the Chatwoot instance**.
Real-time to the app = **FCM push** (background) + a **WebSocket** (live
foreground). Closes O3 of `AURAI-0002`.

## How it works

- **Runtime / language:** Node.js + **TypeScript** — same language and type
  modelling as the RN app, so message / session / wallet DTOs can be **shared**,
  not re-declared, and the team context-switches once.
- **Framework:** **NestJS** — its modules/DI fit the four shapes this BFF needs
  (app REST, a Chatwoot webhook receiver, background jobs, a WS gateway) as
  first-class citizens; Fastify adapter for throughput.
- **Datastore:** **PostgreSQL** — the wallet + append-only ledger + the
  `(user, advisor) → conversation` map need transactional integrity; one
  relational DB covers it. Chatwoot runs its **own** Postgres — we do not share
  it.
- **Jobs / queues:** **Redis + BullMQ** — webhook processing, the reconciliation
  poll, FCM fan-out and session-meter ticks run as **retried** background jobs,
  decoupled from request latency (matters given Chatwoot's 5s, no-retry webhook —
  `AURAI-0002` §2.4).
- **Identity:** **Firebase Admin SDK (Node)** verifies the app's ID token on
  every request; the Chatwoot User token + inbox `hmac_token`/`secret` live in
  server secrets, never on device.
- **Real-time to app:** **FCM** (`@react-native-firebase/messaging`) for
  background delivery + a **WebSocket** (NestJS gateway) for live foreground
  updates — both fed from the same stored message, so they can't diverge.
- **Hosting:** a **Docker** container on a managed container host + **managed
  Postgres/Redis**, deployed **close to Chatwoot** to keep the webhook→push path
  fast. Exact provider deferred to O7/ops.

## Why

- One language across app + backend (TS) shrinks the team's surface and lets the
  chat/session/wallet types be shared rather than duplicated.
- NestJS gives REST + webhook + jobs + WS as structured modules — less glue than
  bare Express/Fastify, lighter than a polyglot stack.
- Postgres is the boring, correct choice for money (wallet/ledger integrity);
  Redis/BullMQ absorbs Chatwoot's unreliable webhook with retries + back-pressure.
- Co-location keeps the "advisor replied" latency (webhook → push) low, which is
  the user-perceived speed of the whole product.

Assumption: does **not** fix cloud provider or **Chatwoot self-host vs Cloud** —
that is O7. A PSP for top-ups (`AURAF-0007` NOT-in-scope) is a separate choice.
If the team's real strength is another stack (Go, Elixir, or Rails alongside
Chatwoot), that overrides the TS default — flag before build.

Informed by `AURAI-0002`, `AURAF-0007`. Unblocks `AURAF-0007` implementation.
