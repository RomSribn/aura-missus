# AURAT-0108-010 — Fix: the flag did not turn on from `.env.local`

Date: 2026-10-21

## What the owner saw

Dev server against bff-dev, `VITE_PSP_ENABLED=true` in `.env.local`: the Book sheet with a $0.00
balance shows the flag-off line «Top up in the Aura app» — no plan line, no card / wallet buttons.

## Cause

Vite loads `.env`, `.env.local`, `.env.[mode]`, `.env.[mode].local` in that order, later wins
(`getEnvFilesForMode`, vite `config.js`). The committed `.env.development` sets
`VITE_PSP_ENABLED=false`, so it overrides `.env.local`; the same holds for `VITE_BFF_ORIGIN`. The
instruction of `005` / `006` / `007` («`.env.local` манора») was wrong; the code is right.

## Done (staged, not committed)

- `.env.example`, `.env.development`, the doc comment of `shared/config/env.ts`: an override of a
  value `.env.development` sets goes to `.env.development.local`.
- `006` item 2 and `007` manor check — `.env.development.local`.

## For the check now

`.env.development.local` next to `package.json` (gitignored by `.env.*`):
- success to Booked: `VITE_BFF_ORIGIN=http://localhost:3010` (the BFF manor's docker stack — container port 3000 is
  published on host 3010) + `VITE_PSP_ENABLED=true`;
- bff-dev failure branches: `VITE_PSP_ENABLED=true` only.
Then restart `npm run dev`.

Next: the owner's check; this fix rides with the close (commit + merge on confirmation).
