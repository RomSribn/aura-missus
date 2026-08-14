# AURAT-0020-002 — Execute

Date: 2026-08-14
Status: **code written, staged — awaiting review, then the merge gate**

## The rule this establishes

**Two sheet modals never live at once.** Whatever opens a second sheet — on this
screen or another — waits until the first is *gone*, not merely told to go.

## What changed

- **`shared/ui/bottom-sheet/BottomSheet.tsx`** — a new optional `onClosed`, and
  the modal's own `visible` is now separate state from "is this component
  mounted". Closing runs the slide-out, then:
  - **iOS** drops the modal's `visible`, and `Modal.onDismiss` — the completion
    of `dismissViewControllerAnimated:` — is what unmounts the sheet and fires
    `onClosed`. The sheet is provably gone, not asked to go.
  - **Android** has no `onDismiss` (RN implements it for iOS only) and no
    presentation to deadlock, so the slide-out ending is the signal.

  The callback is read through a ref, so a caller need not memoize it to be
  heard.

- **`use-paid-session.ts`** — `goTopUp` now only starts the close and sets a
  pending flag; the new `sheetClosed()` is what calls `onTopUp`. A sheet closed
  by hand therefore never wanders off to Profile, and the handoff fires once.

- **`SessionBlockSheet` / `ChatThreadScreen`** — `onClosed` is threaded through
  to the hook.

`goTopUp` is the **only** cross-screen navigation out of a sheet in this app
(checked across all five `BottomSheet` consumers), so this closes the class, not
just the instance.

## Verification

| Gate | Result |
|---|---|
| `tsc --noEmit` | clean |
| `eslint src __tests__` | clean |
| `jest` | **42 suites / 199 tests green** (was 41 / 193) |
| Release bundle (android, `--dev false`) | built |

New `BottomSheet.test.tsx` pins the contract that is the fix: closing drops the
native modal but **does not yet claim to be gone**, the simulated `onDismiss` is
what reports it, and only then does the sheet leave the tree.

Two tests in `use-paid-session.test.tsx` changed because they pinned the old,
broken behaviour — that `goTopUp` navigates synchronously. They now assert the
opposite, plus that a hand-closed sheet does not navigate and that the handoff
cannot fire twice.

## Not verified here

The device pass, which is the only thing that can prove it: chat → block sheet →
Top up → Profile opens **with** its Top Up sheet and the screen is alive. Worth
re-checking the ordinary closes too (block sheet dismissed by scrim, Language and
Edit sheets on Profile), since `BottomSheet` is shared by all of them.

## Next

Review → merge gate → device check → `003-approved.md`.
