# AURAS-0002 — Play Console and Google Play Billing setup

Date: 2026-08-17
Status: active — **owner-executed**; nothing here can be done from a session

## Problem

Half of a Google Play Billing integration is not code. `AURAT-0026` shipped
everything that can be built and tested locally; the rest is a sequence of
console steps gated on an approved developer account, and it has to exist
written down or it becomes an unanswerable "what's left?" every time the
subject comes up.

Grounded in `AURAD-0010`. App half `AURAT-0026`, BFF half `AURAT-0027`.

## Solution

Run these in order. Each step unlocks the next — that ordering is the whole
point, and it is why the work cannot simply be "done later in one sitting".

### 1. Developer account

Register at <https://play.google.com/console> ($25, one-off) and pass identity
verification. **Personal vs organisation matters**: a personal account created
after 13 Nov 2023 must later run a closed test with **12 testers opted in for
14 continuous days** before it may even *apply* for production access.
Organisation accounts are exempt. The 14 days start when the twelfth tester
opts in, so if production timing matters, this is the decision that sets it.

### 2. Create the app

Create the app under package **`cc.silvermind.aura`**. The package is not
reserved until the first upload — nothing before this point claims the name.
Listing title: **Aura — Psychic Reading** (22 of the 30 allowed characters).
The launcher label in the build is the short "Aura" on purpose.

### 3. Upload the first AAB

```bash
cd android
# A release build must name its target — there is no default (AURAT-0028).
AURA_ENV=tunnel ./gradlew :app:bundleRelease   # https tunnel to the manor Mac
AURA_ENV=prod   ./gradlew :app:bundleRelease   # once AURAT-0029 has deployed it
# → app/build/outputs/bundle/release/app-release.aab
```

**This step now also decides which backend the AAB talks to.** Before
`AURAT-0028` it did not, because it could not: the release bundle compiled in an
unresolvable placeholder, so an uploaded build reached nothing and this step
could produce an artifact that proved little. A target with no host, or a
cleartext `http` host, now fails the build instead.

Until the backend is deployed, use **`tunnel`**: run the BFF on the manor Mac,
expose it over https (`cloudflared tunnel --url http://localhost:3000`), and put
the URL in `aura-app/env/.env.tunnel.local` — gitignored, never committed:

```
AURA_BFF_ORIGIN=https://<subdomain>.trycloudflare.com
```

`npm run env:show` prints what a target resolves to; run it before building
rather than discovering the wrong host on a device. The tunnel URL changes every
time the tunnel restarts, so a re-upload needs a re-build. Details in
`aura-app/env/README.md`.

Signing comes from `android/keystore.properties`; the upload keystore lives
outside the repo (see `keystore.properties.example`). Upload to the **internal
testing** track. This is what makes the in-app products screen usable.

Accept **Play App Signing** (the default). Google then holds the app signing
key and yours is only an *upload* key — which is why losing it is recoverable.

### 4. Register the Play app-signing certificate in Firebase

Play Console → *Setup → App integrity* → copy the **app signing** certificate's
SHA-1 and SHA-256, and add them to the Firebase Android app for
`cc.silvermind.aura`. Without it, phone-OTP fails Play Integrity on builds
installed **from Play** — while the same build sideloaded works, which makes it
an easy failure to misdiagnose. (`AURAT-0026` already registered the debug and
upload certificates; only Google's own is missing, and it does not exist until
step 3.)

### 5. Create the four products

*Monetise → Products → In-app products*, all **consumable one-time** products:

| Product ID | Credits |
|---|---|
| `aura.topup.usd10` | $10.00 |
| `aura.topup.usd25` | $25.00 |
| `aura.topup.usd50` | $50.00 |
| `aura.topup.usd100` | $100.00 |

The IDs must match `features/store-topup/config/products.ts` **exactly** — the
app drops any tier Play does not return, so a typo shows up as a missing card
rather than an error. Set the base price in USD and let Google generate local
prices; the app displays Google's price and credits the tier's nominal amount
(`AURAD-0010`).

### 6. Licence testers

*Setup → Licence testing*: add the tester Google accounts. They buy with test
cards and are never charged. They must also be on the internal-testing track
and install **from Play** — a sideloaded build cannot transact, and that alone
accounts for most "it doesn't work" reports.

**The uploaded build must have the rollout flags on, or there is nothing to
transact with**: with them off no wallet or Top Up UI mounts at all. Since
`AURAT-0028` they are per-build configuration whose committed default is
`false`, so turning them on is a line in the same gitignored `.local` file, not
a commit:

```
AURA_BILLING_ENABLED=true
AURA_STORE_BILLING_ENABLED=true
```

The BFF's own `BILLING_ENABLED` must be on too — **both halves are required**,
and with the server's off every billing route 404s, which the app reads as "not
live" and hides the UI either way (`AURAD-0002`). Flipping these for real, and
for whom, stays the owner's call under this file.

### 7. Server-side verification (unblocks `AURAT-0027`)

1. Play Console → *Setup → API access* → link a Google Cloud project.
2. Create a service account; grant it **View financial data** and
   *Manage orders and subscriptions* on the app.
3. Download the JSON key and hand it to the BFF as a secret.
4. The BFF calls `androidpublisher.purchases.products.get(packageName,
   productId, token)` and credits only on a *purchased* state.

Reads over the Play Developer API are quota-limited (order of 200k/day), which
is far above anything this rail will produce.

### 8. Refund notifications

Create a Pub/Sub topic, set it as the app's **Real-time developer
notifications** endpoint, and give the service account publish rights. The BFF
subscribes and writes a compensating negative ledger entry on
`ONE_TIME_PRODUCT_CANCELED`. The Voided Purchases API is the periodic sweep
for anything a lost notification missed.

### 9. Production

Only after the closed-testing requirement from step 1 is satisfied, apply for
production access and answer the feedback questionnaire.

## Current Behavior

Done in `AURAT-0026`: package `cc.silvermind.aura`, an upload keystore and a
signed AAB, the Firebase Android app with debug + upload SHAs, and the whole
client purchase flow — dormant behind `STORE_BILLING_ENABLED`, which also
requires Android, a live wallet and a server-minted `purchaseAccountId`. Since
`AURAT-0028` that flag is build configuration (`AURA_STORE_BILLING_ENABLED`,
committed `false`) rather than a constant in a tracked source file.

Not done, and not doable from here: every step above.

## Next

Steps 1–3 are the unblocking sequence; nothing else can start until an AAB is
on a track. Step 7 is what `AURAT-0027` waits on.

### Update 2026-08-17 — the BFF half is built, so step 7 is now the only blocker

`AURAT-0027` shipped the server side: `POST /v1/wallet/top-ups/google`, the
server-side tier table, the `purchaseToken` unique constraint, and
`purchaseAccountId` on `GET /v1/wallet` — the last of which is what lets the app
switch the rail on at all. The real Play Developer API client is written too;
it has simply never been given credentials.

So **step 7 no longer unblocks work, it unblocks proof**. Two consequences worth
knowing before running it:

- Hand the JSON key to the BFF as `GOOGLE_PLAY_PACKAGE_NAME`,
  `GOOGLE_PLAY_SERVICE_ACCOUNT_EMAIL` and `GOOGLE_PLAY_SERVICE_ACCOUNT_KEY`
  (the JSON's `private_key`). **A production deployment with `BILLING_ENABLED`
  on now refuses to boot without all three** — deliberately: the fallback is a
  dev verifier, and a dev verifier that credits real money is the mistake
  `AURAD-0010` exists to prevent.
- The first real purchase is the moment to check that Google actually returns
  `obfuscatedExternalAccountId`. The entire "user A cannot redeem user B's
  token" guarantee rests on that field arriving, and no test we can run proves
  it does.

Step 8 (RTDN) now gates a follow-up task rather than `AURAT-0027`: the refund
subscriber was deliberately not built against a topic that does not exist.

### Update 2026-08-18 — the AAB now has to name its backend (`AURAT-0028`)

Step 3 used to be runnable with no thought about *where* the uploaded build
points. That was not a convenience, it was the defect: `__DEV__` is false in a
release bundle, so every AAB this runbook ever produced compiled in the
deliberate placeholder `https://bff.invalid`. A licence tester could install it,
open it, and reach nothing — and no amount of Play Console work would have fixed
an address baked into the binary.

`AURAT-0028` made the address and both rollout flags per-build configuration
across three targets (`dev` / `prod` / `tunnel`), and made a misconfigured build
**fail rather than ship**. Three consequences for this runbook:

- **Step 3's command changed.** A release build with no `AURA_ENV` now stops
  with an error naming the available targets, instead of silently defaulting.
  The old one-liner in this file would have failed for anyone following it.
- **Steps 3–6 became provable before hosting exists.** The `tunnel` target
  points a real signed release at an https tunnel to the manor Mac, so the whole
  Play rail — upload, licence tester, real purchase, server verification — can
  be exercised with the BFF still local and its logs in reach. That is the cheap
  path to step 7's proof without waiting on `AURAD-0005` / `AURAT-0029`.
- **Step 6 gained a prerequisite that was previously invisible.** The flags now
  have to be switched on in the build the testers install, and doing so no
  longer means editing a tracked file.

When `AURAT-0029` finishes deploying the backend to AWS `eu-central-1`, the work
here is one line: commit the real origin into `aura-app/env/.env.prod`, which
until then is deliberately empty and fails the build.

## Watch out

- **Billing Library 8+ is required for any upload from 31 Aug 2026.** We ship
  Play Billing **9.1.0** via `react-native-iap` 16.3.1, so this is satisfied —
  but a downgrade of that dependency would silently break publishing.
- **Google's cut** is 15% of the first $1M/year, 30% above. A $10 tier nets
  about $8.50 (`AURAD-0010`, open question).
- **Play Billing is likely mandatory** for these top-ups, not optional
  (`AURAD-0010`): the sessions are digital services consumed in-app, so the
  card rail of `AURAF-0009` should not be the Android one.
- **A tunnel URL is not durable.** It changes on every tunnel restart, and the
  origin is compiled into the AAB — so a tunnel-built upload stops working the
  moment the tunnel is recycled. Fine for proving the rail, not something to
  leave on a track and forget.

## Update 2026-08-19 — step 7 as it actually goes now

Done during `AURAT-0029`, and three things differ from what this document says.

**"Setup → API access" no longer exists.** Google removed the page; the direct
links redirect to Home. The service account is created in **Google Cloud
Console**, and access to the app is granted in **Play Console → Users and
permissions → Invite new users**, pasting the service account's email like any
other user. Its App permissions need *View financial data, orders, and
cancellation survey responses* and *Manage orders and subscriptions* — account
level permissions are not required.

**Creating the service account is not the same as creating its key.** A service
account can sit in Cloud Console showing `No keys` — the account exists, the
credential does not, and there is nothing to download. Keys → Add key → Create
new key → JSON. It is shown once.

**Verify the credential before turning billing on**, because the two failures
look identical from the app and only one of them is yours to fix. A valid key
that has not been granted app access authenticates fine and then gets
`401 insufficient permissions` on every purchase — the buyer is charged and the
wallet is not credited.

The check, against a deliberately invalid purchase token:

```bash
node -e '
const {GoogleAuth} = require("google-auth-library");
const d = require("/path/to/play-service-account.json");
(async () => {
  const auth = new GoogleAuth({ credentials: d,
    scopes: ["https://www.googleapis.com/auth/androidpublisher"] });
  const client = await auth.getClient();
  const res = await client.request({ validateStatus: () => true, url:
    "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/"
    + "cc.silvermind.aura/purchases/products/aura.topup.usd10/tokens/probe-invalid" });
  console.log(res.status);
})();'
```

Read it this way:

| Status | Meaning |
|---|---|
| **404** (or 400) | **Correct.** Google accepted the request and says that token does not exist — which is the truth about an invented one. Access works |
| 401 / 403 | The account has no access to this app in Play Console, or the grant has not propagated yet (allow a few minutes) |
| failure before any status | The key itself is wrong |

Only after a 404 does `BILLING_ENABLED=true` make sense. Before it, the service
refuses to boot anyway — deliberately (`AURAD-0010`), because the fallback is
the dev verifier and a fake verifier that credits real money is the one
unrecoverable mistake.

**Also seen, and unrelated to any of the above:** Play Console showed *"There is
an issue with your payments profile"*. That blocks real purchases regardless of
how correct the API access is; it is fixed under Payments settings.

**Values for this app:** `GOOGLE_PLAY_PACKAGE_NAME=cc.silvermind.aura`, and the
service account is `play-billing-api@aura-2781b` — the **same GCP project as
Firebase** but a **different** service account. The Firebase one verifies ID
tokens; this one verifies purchases. They are not interchangeable, and the
similarity is the easiest way to lose an hour here.
