# AURAT-0029-018 — The app points at the deployment; Play access is one grant away

Date: 2026-08-19
Status: prod bundle built and verified. Billing still off, deliberately.

## The one line `AURAS-0002` predicted

`aura-app/env/.env.prod` had `AURA_BFF_ORIGIN=` empty by design — a prod build
was made to **fail at configuration time** rather than compile an unreachable
placeholder into a release binary where it could only be discovered on a user's
phone (`AURAT-0028`). It now reads:

```
AURA_BFF_ORIGIN=https://bff.aura-app.cc
```

with a note that `AURAD-0005` landed on Hetzner rather than AWS.

`AURA_ENV=prod node env/show.js` resolves the target before anything is built:

```
target      prod
AURA_BFF_ORIGIN             https://bff.aura-app.cc
AURA_BILLING_ENABLED        false
AURA_STORE_BILLING_ENABLED  false
```

## The bundle was checked, not just built

`bundleRelease` succeeded and signed — 61.7 MB — but a successful build proves
nothing about *what address is inside it*, and that is exactly the class of
defect `AURAT-0028` existed to close. So the AAB was unzipped and its JS bundle
searched:

| String | Present |
|---|---|
| `bff.aura-app.cc` | **yes** |
| `bff.invalid` | no — the placeholder did not survive |
| `192.168…` | no — no dev LAN address leaked |
| `trycloudflare` | no — no tunnel address leaked |

Two signature files present.

**Not committed.** The `.env.prod` change sits uncommitted in `aura-app-manor`'s
manor checkout: that workspace takes changes through a slave rather than
directly on `develop`, and the owner has not reviewed the diff. **Not uploaded**
either — publishing to Play is the owner's action and no session holds Play
Console access.

## Google Play billing: everything is in place except one propagation

`BILLING_ENABLED` stays **false**. The three `GOOGLE_PLAY_*` values are now
known — the package is `cc.silvermind.aura`, the service account is
`play-billing-api@aura-2781b` — but the credential does not yet work, and
turning the flag on before it does would be the mistake `AURAD-0010` was written
to prevent.

The confusion worth recording, because it cost real time: **there are two Google
service accounts and they are not interchangeable.**

| Account | Purpose | State |
|---|---|---|
| `firebase-adminsdk-fbsvc@aura-2781b` | verifies the app's ID token on every request | working |
| `play-billing-api@aura-2781b` | verifies a *purchase* with Google before crediting the wallet | credential valid, app access pending |

The in-app purchase flow already worked, which is what made this feel already
done — but that is the client half. The app talks to Play Billing directly; no
service account is involved. The server half is the BFF asking
`androidpublisher.googleapis.com` whether a purchase token is real, and that is
the entire point of `AURAD-0010`: **the app must not credit its own balance.**

Two further traps, both hit:

- **A service account can exist with `No keys`.** Cloud Console listed
  `play-billing-api` as Enabled while holding no credential at all — there was
  nothing to download, which is why no JSON could be found. Keys are created
  separately, and shown once.
- **Play Console's "Setup → API access" page no longer exists.** Access is
  granted from **Users and permissions → Invite new users**, pasting the service
  account's email like any other user's.

App-level permissions are what matter — *View financial data* (its own
description says "access the Purchases API") and *Manage orders and
subscriptions*. Account-level permissions are **not** required and were left
empty: the credential lives in the server's environment, and a grant that spans
every app in the developer account buys nothing.

## Verified against Google rather than assumed

A probe with a deliberately invalid purchase token separates the three failures,
which are indistinguishable from the app:

| Response | Meaning |
|---|---|
| **404 / 400** | access works — Google says that token does not exist, which is true of an invented one |
| **401 / 403** | the account has no access to this app, or the grant has not propagated |
| error before any status | the key itself is wrong |

Currently: **key valid** (Google issues an access token), **401 on the app** —
the invitation shows Active in Play Console, so this is propagation. A poll is
watching for it.

Had billing been switched on in this state, every real purchase would have taken
the buyer's money and failed verification with a 401 — charged, not credited,
and the ledger is append-only.

## Also outstanding, and not ours

Play Console reports **"There is an issue with your payments profile"**. It is
independent of everything above and blocks real purchases regardless of how
correct the API access is.

## Still unproven

The loop — app → BFF → Chatwoot → chatter's reply → app — has never run
end to end. Chatwoot's inbox webhook has never fired, so
`SAFE_FETCH_ALLOW_PRIVATE_NETWORK` remains a claim. That is the next thing worth
doing, and it needs neither billing nor Play.
