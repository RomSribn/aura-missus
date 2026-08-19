# AURAT-0029-019 — Billing on, with the real verifier

Date: 2026-08-19
Status: `BILLING_ENABLED=true` in production, Play credentials live.

## Verified before the flag, not after

The whole point of `AURAD-0010` is that a fake verifier crediting real money is
the one unrecoverable mistake, so the credential was proven against Google
first, with a deliberately invalid purchase token:

| Endpoint | Response | Reading |
|---|---|---|
| `POST /edits` | **200** | app access works, API enabled |
| `/purchases/products/…/tokens/probe-invalid` | **401 → 400** | financial permission propagated |

That comparison is what made the diagnosis quick. When the purchases call
returned 401 while `/edits` returned 200, the cause was narrowed to the
**financial** permission specifically rather than to the key, the API or app
access. Google took ~12 minutes to propagate it — officially it can take up to
24 hours.

Final state: `HTTP 400 Invalid Value` — Google accepted the request and rejected
the token, which is the truth about an invented one. That is the pass condition.

## Confirmed after the flag

| Check | Result |
|---|---|
| `No Play service account configured` warnings | **0** — the real `GooglePlayVerifier` was selected, not the dev fake |
| Boot | `Nest application successfully started` |
| `/health/ready` | database and Redis reachable |
| `GET /v1/wallet` | **401**, not 404 |

The last one is the precise signal: with `BILLING_ENABLED=false` the entire
wallet surface answers **404** by design (`AURAD-0002`). A 401 means the route
exists and is asking for a Firebase token.

## Two defects of my own, caught before they mattered

**The Play private key was written multi-line.** The substitution left real
newlines in the value — 60 characters where the key is ~1750 — which cannot be
carried in an environment variable at all. Caught by measuring the line length
rather than eyeballing the file. Both keys now sit on one line with escaped
`\n`, which is what `FirebaseAdminService` and the Play verifier unescape.

**Play refused `versionCode 2`** as already used, so the bundle was rebuilt at
**3**. `versionName` stayed `1.0.0`: only the code must be unique, and the name
is what a user sees. The rebuilt bundle was re-checked for the origin — still
`bff.aura-app.cc`, still no `bff.invalid`, no LAN address, no tunnel.

## What billing being on does and does not mean

It means the server will now **verify** a purchase with Google and credit the
wallet from its own price table. It does **not** mean a purchase can be made
end to end:

- The app bundle currently deployed was built with `AURA_BILLING_ENABLED=false`
  and `AURA_STORE_BILLING_ENABLED=false` compiled in. **Turning billing on in
  the app needs another build.**
- Play Console still reports **"There is an issue with your payments profile"**,
  which blocks real purchases independently of any of this.

So the honest status is: the server half is ready and proven as far as it can be
without a real purchase. `TECH-DEBT #17` — "`GooglePlayVerifier` has never
spoken to Google" — is now **partly** paid: it has spoken, and been refused
correctly. What remains unexercised is a genuine purchase token, and with it the
check that `obfuscatedExternalAccountId` actually comes back, since the whole
"user A cannot redeem user B's token" guarantee rests on that field arriving.

## Still unproven, and independent of payments

The chat loop — app → BFF → Chatwoot → chatter's reply → app — has never run.
Chatwoot's inbox webhook has never fired, so `SAFE_FETCH_ALLOW_PRIVATE_NETWORK`
is still an assertion. It needs only the installed app, not billing.
