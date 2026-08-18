# AURAT-0027 — 006 approval

Date: 2026-08-17
Result: **approved**, all three decisions taken as recommended.

| | Decision | Chosen |
|---|---|---|
| **D1** | Real Google client now, or a follow-up? | **Build it now** — hand-rolled `fetch` client, service-account JWT via `google-auth-library`, Google's response parsed strictly with Zod and refused on anything unexpected |
| **D2** | Refunds (`AURAF-0010-006`) now? | **Follow-up task** — no Pub/Sub topic (`AURAS-0002` step 8) and no reachable trigger, so it would be dead code (build rule 8). Schema accommodates it; row 006 stays ✗ |
| **D3** | `TECH-DEBT #7` here? | **Take it** — `BEFORE UPDATE OR DELETE` trigger on `ledger_entries` |

No changes requested to the rest of `005-spec.md`.

## Next

`007-execute`. Nothing is committed until the owner has read the diff in the
IDE (skill step 6f).
