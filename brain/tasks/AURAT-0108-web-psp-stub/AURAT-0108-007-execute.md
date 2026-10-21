# AURAT-0108-007 — Execute

Date: 2026-10-20
Slave: slave-1, branch `feature/AURAT-0108-web-psp-stub` (aura-web from `develop` `79bf311`).
Not committed — staged for review. Owner's review fixes — `008` (folded in below).

## Done (by spec `005` + approval `006`)

- **shared**: `PSP_ENABLED = import.meta.env.DEV && import.meta.env.VITE_PSP_ENABLED === 'true'`
  — a build constant in `env.ts`, re-exported by `config/payments.ts` — the one flag the app reads;
  routes `/checkout?payment=` and `/psp-sandbox?payment=&return=` (`return` — resolved with
  `new URL(value, location.origin)`, same origin only, `pathname + search + hash`; tests incl.
  `%09` / `%0A`); `loadPage`
  (full page load to the provider and back). `.env.example` says how to turn it on.
- **entities/wallet**: `topUpWallet` — the BFF top-up stub `POST /v1/wallet/top-ups`
  (`TopUpRequest` / `TopUpResponse.parse`, invalidates `Wallet`); only the fake provider calls it.
- **features/pay**:
  - port: `PaymentMethodId = 'balance' | 'card' | 'wallet'`; `TopUpProvider` (`startCard`,
    `payWithWallet`, `status`) — what a real PSP implements through the BFF;
  - `lib/top-up-plan.ts` — ported `payPlan` of the app (`AURAT-0099`, staged branch) with its tests,
    without the store ladder; `lib/wallet-brand.ts`; `lib/pending.ts` (record schema, tests);
  - `model/pending-store.ts` — the card payment in `sessionStorage` (payment id, the booking's key,
    advisor, minutes, start, amount) + the one-shot "declined" notice for the sheet;
  - `model/settle-top-up.ts` — status every 2 s up to 60 s (a failed ask is not an answer), then the
    booking from the balance under the attempt's key;
  - `usePay` — with `PSP_ENABLED` and a short balance: the top-up plan, `payByCard` (record, then
    the hosted page), `payByWallet` (test wallet sheet → poll → booking, "Still confirming…" after
    10 s); outcomes `declined`, `processing`, and after a credit `taken` / `failed` /
    `notBookable` carrying the credited amount; the key is reset only by a definite booking answer;
  - `usePaymentReturn` — `/checkout`'s return: poll, book, Booked; declined → back to the sheet
    with "Nothing was charged"; cancelled → back silently; credited but not booked → a notice and
    the way on ("Try again" under the same key);
  - fake provider: `fake-psp.ts` (its books in `sessionStorage`, scenarios), `fake-provider.ts`
    ("webhook" = the stub; stub error → stays `pending`), `fake-wallet-prompt.ts` (tests);
  - `PayActions` — plan line, wallet button (brand + translated accessible name), "Pay $X" card
    button, the provider note; flag off — unchanged, the temporary line stays; `PayNotice`;
    `TestWallet` (dev, English).
- **pages/checkout**: the return page (lock orb, "Confirming your payment" / "Still confirming…",
  `SessionSummary`, outcome notice + "Pick another time" / "Try again" / "Browse advisors" / "OK");
  without a payment of this tab — the old redirect. Route `pushed` (no tab bar on phones).
- **pages/psp-sandbox** (new, dev): the fake hosted page — Approve, Approve slowly (15 s), Never
  confirm, 3-D Secure (Pass / Fail), Decline, Cancel; back by a full page load. Registered only with
  `PSP_ENABLED`, outside the app shell, lazy chunk.
- **Strings**: `pay` +10 keys, new namespace `checkout-page` — 24 languages; sandbox and test
  wallet — English only (rule 9 exception).
- **AURAF-0020**: row 007 UI ✓; Context — the task's decisions and the correction to
  `AURAT-0107-005` gap 8 (end-to-end success — on the local BFF stack). No backlog row and no BFF
  task (owner, `008`); the real PSP's gaps become rows from 036 at the task's close.

## Decisions during implementation

- The fake is cut out of a production build by the build constant, not by `import()`: three
  entries are behind `PSP_ENABLED` — the sandbox route (lazy, `HydrateFallback`),
  `createFakeProvider` in `useTopUpProvider` (null when off) and the `TestWallet` render — and Rollup
  drops the fake provider, its books and the sandbox chunk. The sandbox page and the provider share
  the fake's books through `features/pay`'s public API.
- **Criterion**: after `VITE_PSP_ENABLED=true npx vite build`,
  `grep -l 'aura.fake-psp\|Approve slowly' dist/assets/*` finds nothing (checked: nothing, no
  sandbox chunk; what stays is the `/psp-sandbox` path string in the routes table and the
  real-PSP return code — `aura.pending-payment`).
- Back from the hosted page restored from the bfcache: `pageshow` with `persisted` resets the sheet
  from "Booking…" (the attempt's key stays); test.
- Wallet payments keep no `sessionStorage` record (they never leave the page); a reload mid-poll
  ends as "processing" would — the money lands on the balance, no booking.
- A 402 after a credit (should not happen) → back to the sheet, which shows the short balance.
- Tests: `asyncUtilTimeout` 4 s and `testTimeout` 20 s in the Vitest setup — under a full run the
  router-level tests flaked on the 1 s / 5 s defaults (also on `develop` `79bf311`: 3 failures in a
  full run); with them three full runs were stable. Its own commit (owner, `008`).
- `advisors.test.tsx` pins the clock (Date only, still running) to 10:00 local — "the next 4 slots"
  no longer depends on the hour of the run. Its own commit (owner, `008`).

## Checks

`npm run lint` (eslint + Steiger) ✓, `npm run typecheck` ✓, `npm run build` ✓, prettier ✓, the
criterion above ✓. `npm test` 942/942, three full runs in a row; `advisors.test.tsx` green under
`TZ` Europe/Kyiv, Pacific/Auckland, America/Los_Angeles, UTC. New — `psp.test.tsx` 14 scenarios
(plan and buttons; balance covers → as before; card round trip to Booked with the record's key;
3-D Secure fail; cancel; back out of the bfcache; slot taken after the credit; lost booking retried
under the same key; reload of the return page; unknown payment; "Still confirming…" then Booked;
stub 503 → processing, no booking; wallet approve; wallet cancel / decline), `fake-provider` 6,
`top-up-plan` 9, `pending` 2, `wallet-brand`, routes, env.

## Open / for review

- `payPlan` comes from the unmerged app branch `AURAT-0099` — re-sync if it changes there.
- Translations: native review welcome (ga, mt first).
- Manor check (after merge), an account with a balance below a session's price, the values in
  `.env.development.local` (`.env.local` loses to the committed `.env.development` — `010`),
  `npm run dev` restarted after the change:
  - success to Booked — `VITE_BFF_ORIGIN=http://localhost:3010` (the BFF manor's docker stack publishes 3000 on host 3010;
    `NODE_ENV=development`, CORS lets `http://localhost:5173` in) + `VITE_PSP_ENABLED=true`;
  - on bff-dev — decline, cancel, failed 3-D Secure and `processing`.
- At close: the real PSP's gaps (top-up creation, status for the poll, webhook, `returnUrl`
  allow-list, amount rule) — `AURAF-0020` rows from 036. Among them: Back from the provider's page
  after paying resets the sheet (bfcache, `pageshow`) although the money may have gone — with a real
  PSP, `pageshow` checks the payment's record and leads to `/checkout?payment=`.
