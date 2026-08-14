# AURAT-0020-001 — Check

Date: 2026-08-14
Slave: slave-0, `feature/AURAT-0020-sheet-navigation-deadlock` off develop `e9de091`
Found by: the owner, during the AURAT-0019 device pass (iPhone, iOS).

## Symptom

From a chat thread → block sheet → **"Top up"**: the app navigates to Profile,
but the screen is **dead**. No Top Up sheet appears at all, nothing on the page
responds, and only the tab bar still works. It stays dead **until the app is
restarted**; switching tabs and coming back does not clear it.

Opening Top Up directly from the Profile card works normally, which isolates the
fault to the cross-screen path.

## Root cause

Two native modals overlap in time.

`usePaidSession.goTopUp` did both things in one tick:

```ts
const goTopUp = useCallback(() => {
  setVisible(false);   // the block sheet starts its 200ms close
  onTopUp?.();         // and the navigation leaves immediately
}, [onTopUp]);
```

`BottomSheet` stays mounted for the whole slide-out (`rendered` is only cleared
in the animation's completion callback) and is built on the core `Modal`.
Profile then mounts a **second** `Modal` as soon as its
`route.params.sheet === 'topup'` effect runs. For ~200 ms two native modals are
alive; on iOS the second presentation is refused while the first is still
presented, and what remains is a transparent modal over the whole app that
swallows every touch.

## Why the signal exists to fix it properly

Read out of the shipped RN 0.85 sources rather than assumed:

- `Libraries/Modal/Modal.js` — `onDismiss` is **iOS only** ("OnDismiss is
  implemented on iOS only"), and it is deliberately routed through a
  modal-identifier event rather than a native callback, because *"the view will
  be destroyed before the callback is fired"*.
- `React/Views/RCTModalHostViewManager.m` — the event is emitted from the
  completion block of `dismissViewControllerAnimated:completion:`, i.e. once the
  modal is provably gone.

So iOS can tell us exactly when the sheet has left. Android has no such event —
and no presentation to deadlock either — so the slide-out ending is the signal
there.

## Provenance

Pre-existing from **`AURAT-0010`**, which wired `goTopUp`. Neither `AURAT-0015`
nor `AURAT-0019` touched it: `AURAT-0019` removed a wallet refresh from
`use-profile`'s `openSheet`, while this path reaches the sheet through
`route.params`, bypassing `openSheet` entirely.

## Next

`002-execute.md`.
