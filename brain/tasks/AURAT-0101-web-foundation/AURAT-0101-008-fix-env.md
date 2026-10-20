# AURAT-0101-008 — Fix: app must start without a Firebase Web App

Date: 2026-10-20
Owner, reviewing 007: «без этих енвов я не смогу даже запустить приложение?» — yes: `env.ts` threw on
any missing `VITE_*`, a white page before React mounted. Owner approved both fixes:

1. Commit `.env.development` with the values already known (BFF origin `bff-dev`, WS path, Firebase
   auth domain and project id of `aura-2781b`) — `npm run dev` works right after a clone.
2. `VITE_FIREBASE_API_KEY` / `VITE_FIREBASE_APP_ID` optional: without them Firebase is not initialised
   and everyone is a guest (shell + GuestGate). Setting them in `.env.local` turns sign-in on with no
   code change. Malformed values (and one of the pair without the other) still fail at start.

Next: 009-execute.
