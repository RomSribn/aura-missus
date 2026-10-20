# AURAT-0101-013 — Fix: favicon

Date: 2026-10-20
Owner: «запусти, проверь сам» → verify in the manor → «Сначала favicon».

## Manor verify (develop `3b49ccd`, `npm run dev`, headless Chrome)

Passed: shell (logo + Home / Advisors / Chats / Sessions, active link, client navigation);
GuestGate on `/chats`, `/chats/abc`, `/sessions`, `/me` («Log in» does not crash);
`/nowhere` → «Page not found» → «Go home» → `/`; phone 390 — tab bar pinned to the bottom with
labels, hidden on `/checkout` and `/advisors/abc`; 820 px — icon-only links in the header;
`de-DE` → German nav and gate, `<html lang="de">`, only `de` locale chunks; `ja-JP` → English;
no request to the BFF or Firebase in guest-only mode.

Found: `/favicon.ico` → 404 — a console error on the first page load. The handoff has no favicon.

## Fix

- `public/favicon.svg` — the orb of the nav logo (token colours `--white` → `--accent-soft` →
  `--accent`), vector, transparent background.
- `public/apple-touch-icon.png` — 180×180 from the mobile app icon
  (aura-app `ios/.../AppIcon.appiconset/App-Icon-1024x1024@1x.png`), so the home-screen icon
  matches the app.
- `index.html` — `<link rel="icon">` + `<link rel="apple-touch-icon">`.

Next: execute in slave-1 → owner review → commit → merge gate → re-verify in the manor.
