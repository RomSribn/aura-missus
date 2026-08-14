# AURAT-0015-001 — Initial

Date: 2026-08-14
Context: minted from **manor** (štab); execution slave is **slave-1** on
`feature/AURAT-0015-session-surface-in-chat`, branched off aura-app `develop`
@ `80a37be`.

## What the user said

> «минти AURAT-0015 и раскладывай по слейвам»

Following the design-handoff round 2 intake (workspace `a88cbb5`), whose brief
listed nine changes: sessions are chat-only; the session runs in the same thread
as free chat with no gating; a new `SessionBanner`; system dividers in the
transcript; chats-list markers + sorting; a chat-header action swap; session
lifecycle helpers driven by the server clock; booking polish; and five new icons.

## What actually happened before this file

Scoping surfaced that the round contradicts a ratified, already-shipped decision
(`AURAD-0002`). That was put to the owner as **`AURAD-0008`**, who ratified
**option B** in the same turn: keep the shipped monetization model, build only
the in-thread session surface, defer the booking flow until a PSP exists.

So the requested "split across slaves" collapsed from four parallel tasks to
**one**: rows 001–005 of `AURAF-0008` are a single dependency chain (the helpers
feed the banner, the chats list and the header swap), and splitting them across
slave-0 and slave-1 would buy nothing but merge conflicts in the same files.
`AURAT-0016..0018` stay reserved and parked.

## Next

`002-check.md` — what already exists in the brain and the code.
