# AURAT-0026 — 003 understand

Date: 2026-08-17

## What the owner wants

Get the Android app to the point where it can actually be shipped to Google
Play under its real identity — `cc.silvermind.aura` instead of the RN
template's `com.psychoapp` — and get in-app purchases built far enough that
nothing is waiting on code once the developer account clears. Android first,
deliberately: the Apple developer account is still under review.

The third clause is the one that shapes the plan more than the other two:
**"посмотри, можно ли сделать что-то без явного одобрения моей кандидатуры"** —
work out what can genuinely be finished while the Play developer account is
still unapproved, and do that, rather than blocking the whole subject on a
signup queue. So the deliverable is explicitly split by what the account gates
and what it does not.

## What that implies, given the decisions already in force

An IAP purchase on Android is **a top-up of the existing wallet**, not a new
way to pay for a session. `AURAD-0002` makes the wallet the only money source
and the ledger the only record; `AURAD-0009` keeps sessions paid from the
wallet. So Play Billing enters the product at exactly one point — the Top Up
sheet — and everything downstream (booking, blocks, refunds) is untouched.

And the app **must never credit its own balance**: the BFF owns the wallet, so
a Play purchase is a *claim* the app hands to the server, which verifies it
against Google and appends the ledger entry. That is a new money rail with
real integrity requirements (verification, idempotency, replay, refunds), which
is decision-shaped, not just code-shaped.

## Two questions to put to the owner before the spec

1. **Rename scope** — Android package only, or the whole `PsychoApp` identity
   (iOS bundle id, Xcode target, `app.json`, `package.json`, launcher label)?
   iOS is not being released, but the bundle id is registered in Firebase and
   the current iOS dev flow works; changing it costs an APNs/provisioning
   re-verify that buys nothing while Apple is still reviewing.
2. **Upload keystore** — generate it here now (gitignored, credentials in a
   local, untracked properties file), or wire the signing config to read a
   keystore the owner creates themselves? It is a durable owner asset, so the
   default is not obvious.

## Next

`004-context`.
