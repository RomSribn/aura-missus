# AURAT-0108-004 — Context

Date: 2026-10-20

## Sources

- Brain: `AURAT-0107` 005/006/007/010/012/015; `AURAF-0020` (rows 006, 007, 011, backlog 024–028);
  `AURAF-0009` (PSP, backlog); `AURAF-0019` (one-tap pay in the app, draft); `AURAI-0007`
  «Заготовка под PSP»; `AURAD-0009`, `AURAD-0019` Р4.
- Web handoff: README §4.2–4.3, §8; NAVIGATION §2.4, §4, §5, §6; prototype `web-modals.jsx`
  (`PayActions`, `CardSheet`), `web-funnel.jsx` (`FunnelPay`).
- Mobile handoff: `CHECKOUT.md` (§0 rules, `payPlan`, §3 outcomes and copy), `OFFER.md`.
- Code: aura-web `develop` `79bf311` — `features/pay`, `features/book-session`, `widgets/book-sheet`,
  `pages/checkout`, `entities/wallet`, `shared/config/env.ts`; aura-app `slave-1`
  `feature/AURAT-0099-one-tap-session-pay` (staged, **not merged**): `features/store-topup`
  (`pay-plan.ts`, `use-checkout.ts`, `store-rail.ts`, `PayNotice.tsx`); aura-bff `master`
  (`wallet.controller.ts`, `wallet.service.ts`, `sessions.service.ts`, `web-origins.ts`, `Dockerfile`);
  `@aura/contracts` `v0.22.0`.

## Key findings

1. **The port is ready to be extended.** `PaymentMethodId = 'balance'`; `PaymentMethod.pay(attempt)
   → PayOutcome`; `usePay` holds the key until a definite outcome; `PayActions` has the temporary
   short-balance line (marked, `AURAT-0107-006` §8). `VITE_PSP_ENABLED` already exists in
   `env.ts` (`pspEnabled`, default false, `false` in `.env.development` and `.env.test`) and has no
   consumer yet. `/checkout` redirects to the draft's sheet (or the catalog).
2. **A card / wallet payment cannot return an outcome in one call.** The hosted page leaves the app
   (redirect) and comes back to `/checkout`; the key of the booking and the attempt must survive
   the full page load (`sessionStorage`, like the draft). The port needs a provider half
   (start a top-up → status) under the `card` / `wallet` methods.
3. **The dev top-up stub is closed on bff-dev.** `POST /v1/wallet/top-ups` (`TopUpRequest
   {amountMinor, idempotencyKey}` → `TopUpResponse`, in contracts since v0.3.0) answers **503** when
   `NODE_ENV=production`, and the BFF image sets `NODE_ENV=production` for every deployed
   environment, bff-dev included (`Dockerfile:54`, `env.schema.ts:520`). It credits only on a local
   BFF. **`AURAT-0107-005` BFF gap 8 was wrong** ("bff-dev credits without payment").
   Store rails `/top-ups/google|apple` need a real store token — unusable from the web.
4. **No PSP anything in BFF / contracts**: no intent endpoint, no top-up status, no webhook, no slot
   hold (`SessionStatus` has no pending; availability "is an offer, never a reservation").
   402 carries cost and balance only inside the message text. CORS allows `Authorization`,
   `Content-Type` — keys travel in the body, enough.
5. **Two designs of the payment.** Web handoff: card / Apple Pay / Google Pay pay the session
   directly (`due = total − balance`, "Use balance" toggle, `Pay $X` → hosted page, both buttons
   always drawn). Mobile `CHECKOUT.md` + `AURAF-0019` + the decisions: money goes **into the
   balance first** (whole dollars, rounded up, the rest stays), then the same booking with its key;
   "Use my balance" only when `0 < balance < cost`, on by default; a debt is settled first. The
   decisions (`AURAD-0009`, `AURAD-0019` Р4, `AURAI-0007`, `001`) take the mobile shape.
6. **Outcomes and copy exist in the app** (`CHECKOUT.md` §3, `PayNotice.tsx`): nothing charged
   (store error), closed sheet — silent, slot taken after the credit — "$X is on your balance — pick
   another time", pending — "We'll add it to your balance when it clears. No session is booked until
   then.", credited but booking failed — "Try again — it will pay from your balance". The app has
   **no polling**; the web must poll ("Still confirming…" > 10 s, NAVIGATION §4).
7. **The rounding rule is in an unmerged app branch** (`AURAT-0099`, `pay-plan.ts`):
   `storeUsd = ceil((cost − fromBalance) / 100)`, `fromBalance = balance < 0 ? balance : partial &&
   useBalance ? balance : 0`. The ladder cap ($1–$120) is the store's, not the PSP's.

## Contradictions (for the spec)

- Handoff "card pays the session" vs decisions "card tops up the wallet" → decisions win (`001`).
- Handoff "Use balance" toggle vs a top-up of the shortfall → decided in the spec.
- `AURAT-0107-005` gap 8 vs the BFF code → the BFF code (finding 3).
- NAVIGATION §4 "slot taken → toast, back to Book" vs `CHECKOUT.md` "money on balance, pick another
  time" → after a top-up the money has moved, the mobile copy is the true one.

Next: spec (005).
