# AURAF-0009 — Real payments (PSP)

Type: product
Status: backlog — **not started**
Priority: P1 (blocks nothing today; unblocks several things that are parked)

## What

Connect a real payment provider so money can enter the product. Today the wallet
is credited by a **BFF stub** that takes no payment and refuses to run in
production (`AURAT-0007`), so every balance in the app is dev-only.

Minted 2026-08-14 because the PSP had been referenced across a dozen documents
for months — as the reason things were deferred — without ever having an ID of
its own. This is that ID.

## Why it exists

Things already waiting on it, each recorded elsewhere:

- **The Top Up sheet is theatre.** It shows amounts and a "Visa ···· 4242" row
  and credits the wallet without charging anyone (`AURAT-0007`, `AURAT-0019`).
- **The Review screen's card row** ships **disabled, marked "Soon"**
  (`AURAT-0016`). The owner chose to keep it visible as a signpost; this feature
  is what turns it on.
- **`AURAD-0008` deferred the whole booking half** because the design pays by
  card. `AURAD-0009` then removed the PSP from the critical path by paying the
  slot from the wallet — so the card became an *addition* to Review rather than
  a prerequisite for it. That is the shape this feature lands into.
- **BFF `TECH-DEBT #7`** — DB-level append-only enforcement on `ledger_entries`
  is explicitly wanted *before* billing is enabled anywhere real.

## Scope sketch (not a spec)

- Provider choice and its own decision record (fees, EU/SCA, payouts to
  chatters, refunds) — the first real question, and not a technical one.
- Card capture and charge on top-up; the wallet stays the internal rail, so
  sessions and refunds keep working exactly as `AURAD-0009` describes.
- Webhooks and reconciliation: a top-up is only real when the provider says so,
  which makes the credit asynchronous for the first time.
- Refunds to the card vs to the balance — `AURAD-0009` refunds a cancelled
  session to the **balance**; money leaving the product is a different question.
- Production guards: the stub must become unreachable, not merely discouraged.

## NOT in scope

Paying an advisor a slot directly by card (bypassing the wallet). The wallet is
the rail by `AURAD-0002` and `AURAD-0009`; a second rail is a separate decision.

## Open questions

1. Which provider, and does it settle in EUR or USD? The wallet is USD minor
   units end to end (`AURAD-0002`).
2. Does the −$5 first-session credit survive real money, and who funds it?
3. Do chatters get paid through the same provider, or is payout a separate
   rail entirely?
