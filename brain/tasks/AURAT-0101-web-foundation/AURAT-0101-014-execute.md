# AURAT-0101-014 — Execute: favicon

Date: 2026-10-20

## Files

- `public/favicon.svg` (new) — coral orb, 32×32 viewBox. The gradient stops sit closer to the
  centre than the logo's `.orb` (white → accent-soft 25% → accent 75%): the logo's own stops
  (55% / 100%) read as an almost white dot at 16 px on a light tab.
- `public/apple-touch-icon.png` (new) — 180×180, resized (`sips`) from the aura-app iOS app icon.
- `index.html` — `<link rel="icon" href="/favicon.svg" type="image/svg+xml">`,
  `<link rel="apple-touch-icon" href="/apple-touch-icon.png">`.

## Decisions

- The colours in the SVG are literal hex — a favicon is a static asset outside the page and cannot
  read CSS custom properties; they are the values of `--white`, `--accent-soft`, `--accent`.
- No `favicon.ico`: with a `<link rel="icon">` browsers do not request `/favicon.ico`. Re-checked
  in the manor after merge.

## Checks (slave-1)

lint (eslint + steiger) ✓ · typecheck ✓ · tests 123/123 ✓ · build ✓ (`dist/favicon.svg`,
`dist/apple-touch-icon.png` copied) · prettier ✓. Rendered at 16 / 32 / 64 px in headless Chrome.

Next: owner review → commit → merge gate → re-verify in the manor (no 404 in the console).
