# AURAT-0028-003 — Understand

Date: 2026-08-18

## What the user wants

A release build that talks to a real backend, so an AAB can go to Play and a
real purchase can be attempted.

## What that actually requires

Two things, and the second is the one worth doing properly:

1. **A production URL the release build uses** instead of `bff.invalid`.
2. **A way to set it per build** that is not "edit a tracked file and remember
   not to commit it" — which is how this app is configured today, and how the
   manor has been carrying a LAN IP and a flipped billing flag for weeks.

## Scope boundary

This task makes the app **addressable**. It does not host anything, does not
choose a domain, and does not touch `AURAD-0005`'s topology. If no host exists
yet, the deliverable still lands: the value becomes configurable and the
placeholder stops being compiled in.

It also should not smuggle in a flag flip. `BILLING_ENABLED` and
`STORE_BILLING_ENABLED` become *configurable* here; deciding when they go true
belongs to `AURAS-0002` and the owner.

## The cheap path the owner has open

A TLS tunnel to the manor Mac satisfies the app's https requirement without any
hosting, which means this task's output can be proven end to end before
`AURAD-0005` is executed. Worth designing for: whatever mechanism lands must
make "point this build at an arbitrary https host" a one-line change, not a
rebuild of the configuration story.

## Next

`004-context.md`.
