# AURAT-0018-009 — Merge

Date: 2026-08-14

## What ran

`wts-finish slave-1`, after explicit approval in the turn.

- Feature branch: `feature/AURAT-0018-bff-scheduled-sessions`
- Feature commit: `de32959`
- Merge commit / manor `develop`: **`44418b2`** (`b0ee16a..44418b2`)
- Pushed to origin: **yes** — manor `develop` verified `## develop...origin/develop`
  with no ahead/behind markers.
- 27 files, +2616 / −294.

## Missus

Reported *"Already up to date — no commits to merge"*, which is correct at this
stage: the task's docs stay uncommitted until close (step 6.5.8), so there was
nothing to merge. Manor missus verified in sync with origin.

The script's *"warning: missus push failed (remote may be absent)"* is the known
false alarm it prints when there is nothing to push. It is **not** a false alarm
once missus actually carries commits — at release, manor missus must be re-checked
for an `[ahead]` marker rather than trusted to the script's exit code.

The slave stays on the feature branch for the post-merge docs.

## Verification is manor work — nothing below is proven yet

None of this could run in a slave. In the manor, on `44418b2`:

1. **Both migrations apply** on the populated dev DB — the enum file first, then
   the columns/backfill/index one. Old sessions keep their status; `startsAt` equals
   the old `startedAt`; `advisorId` matches the conversation's.
2. **`balance == Σ ledger` holds** across book → cancel at both tiers (a slot >24h
   out refunds in full; one <24h refunds the floored half) and across
   book → activate → finish.
3. **Cancel twice → one refund.** Cancel a running session → 409.
4. **Two clients racing one advisor slot → exactly one wins**, the other gets 409.
   This is the check the advisor-row lock and the partial unique index exist for.
5. **A booked slot activates on time**, posts the started marker, pushes
   `session.updated`, and the meter finishes it.
6. **Chatwoot attributes** walk `scheduled` → `active` → `none`, and
   `aura_session_starts_at` carries the slot.

Deploy note: the four new `SESSION_SLOT_*` / `SESSION_BOOKING_*` vars all have
defaults, so nothing new is required in `.env`. But the boot check refuses any
environment whose `SESSION_BLOCK_MINUTES` exceeds `SESSION_SLOT_STEP_MINUTES`.

## Next

Owner verifies in the manor → `010-approved.md` or a fix step.
