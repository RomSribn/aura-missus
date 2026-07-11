# AURAT-0007-004 — Understand

Date: 2026-07-11

Build the **BFF side** of AURAF-0007 item 008: a per-user prepaid USD wallet
backed by an append-only ledger in Postgres, a balance API, and a **stubbed**
top-up flow (PSP integration is explicitly out of scope) — all gated by a
`billing_enabled` feature flag that defaults to **off**, so v1 free chat ships
unchanged.

Boundary note: the 001-check scope line "wire the existing Top Up sheet" is
app-repo work (aura-app-manor consumes this API, same as AURAT-0006 consumes
AURAT-0005). This manor delivers the API + flag; the sheet wiring happens app-
side against the published contract.

No paid consumption here — AURAT-0008 adds session charges. But the ledger
schema must already accommodate them (entry types, signed amounts) so 0008 is
additive only.
