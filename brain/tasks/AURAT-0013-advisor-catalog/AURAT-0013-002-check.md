# AURAT-0013-002 — Check existing state

Date: 2026-08-13

## Result: fresh task, nothing to resume

`brain/tasks/` holds AURAT-0001, 0004–0011 and this new folder. No prior task
folder covers the advisor catalog — the grep hits for "advisor catalog" are all
**references to its absence**, not work on it:

| File | What it says |
|---|---|
| `AURAT-0006-003-context.md` | app syncs history per seed advisor; no list endpoint |
| `AURAT-0008-006-spec.md` | D1 — `advisors` table is the price authority, rows registered manually |
| `AURAT-0009-001/002` | app delta-syncs each seed advisor; "the BFF has no advisor catalog" |

So the catalog has been named as missing by three prior tasks and built by none.

## Feature coverage

`AURAF-0007-real-chat-backend` (Status: in-progress) does **not** carry a scope
row for the catalog. Its scope is the chat itself (001–005 free chat, 006–008
paid behind the flag); rows 001–005 are complete per AURAT-0009. The catalog is
a follow-up that AURAF-0007 explicitly leaned on but never owned — the app's
hardcoded `ADVISORS` array was the stand-in that let AURAF-0007 ship.

**Decision: this stays a task, no new `AURAF` minted.** It has one concrete
deliverable with a known shape. If the catalog later grows an admin/registration
surface — as `TECH-DEBT #10` anticipates — that is when a feature and its
`AURAD` are worth minting, in `aura-app-manor`.

## Tech debt this closes

`aura-bff/TECH-DEBT.md` **#10** — *"`advisors` rows are registered manually (SQL
insert; no catalog, no admin surface, no app↔BFF advisor sync)"*.

Adjacent, **not** closed here:
- **#12** `GET /v1/conversations` — the app rebuilds its thread list by
  delta-syncing every seed advisor. Once the catalog is an endpoint, "every seed
  advisor" becomes "every advisor the catalog returns", so #12 gets easier but
  stays open.
- **#13** presence is inbox-wide, not per persona — unaffected; `online` keeps
  coming from presence, not from this table.

## Brain sync warning

The slave's missus branched from manor missus @ `b41203e`. `aura-app-manor`'s
missus is **`[ahead 1]`** — `AURAT-0012` exists there and is **not pushed**, so
it is absent from this clone. Nothing here depends on it, but the shared brain
is out of sync and that commit should be pushed. (Known failure mode: the
release script masks missus push failures.)

## Next

Step 003 — parse intent.
