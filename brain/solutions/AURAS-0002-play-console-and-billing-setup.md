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

**Done 2026-08-18.** Play Console → *Test and release → Setup → App signing*
(the old *Setup → App integrity* path is gone; what lives under *Protected with
Play* is the Integrity/anti-abuse side, not signing keys). *Download
certificate* yields three `.der` files. **`deployment_cert.der` is the app
signing certificate** and the one Play signs with today; `hybrid_classical` and
`hybrid_pqc` belong to Google's post-quantum signing rollout.

All three are registered for `cc.silvermind.aura` in Firebase project
`aura-2781b` — ten fingerprints in total, five keys in SHA-1 and SHA-256:

```
debug                            5e8f1606…  fac61745…
upload                           45957a77…  61c3f587…
Play app signing (deployment)    3441a8d7…  82f5cd6c…
Play hybrid classical            11642f9c…  be881e5f…
Play hybrid PQC                  bf5183db…  f6569815…
```

Only the deployment pair is required today. The hybrid pair was added as
insurance: if Google ever distributes builds signed under the post-quantum
scheme, the symptom would be phone-OTP failing on Play installs again, and the
cause would be non-obvious. They cost nothing — they are Google's own keys for
this same app.

Without it, phone-OTP fails Play Integrity on builds installed **from Play**
while the same build sideloaded works — an easy failure to misdiagnose.

Two corrections to what this step used to say, both learned the hard way:

- **The certificate does not wait for step 3.** It is generated when the app is
  created with Play App Signing enrolled, not on first upload. This file
  previously claimed otherwise, which sent a session hunting for a missing
  upload that was not the problem.
- **`google-services.json` does not carry SHA fingerprints here.** They appear
  in it only for Google Sign-In OAuth clients, and this app authenticates only
  by phone. Re-downloading it after touching certificates changes nothing and
  proves nothing — the state lives in the Firebase project, readable with the
  Management API (`.../androidApps/{appId}/sha`).

**Watch the form.** Editing an existing fingerprint row instead of adding a new
one silently deletes it. That happened here: both **debug** fingerprints were
removed from the app before anyone noticed, which would have broken phone-OTP on
local debug builds — the exact thing the next device pass runs. They were
restored from `android/app/debug.keystore`. After any change to this list, read
it back rather than trusting the form.

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

**Testers need Spanish phone numbers.** Phone-OTP is the app's only sign-in and
the Firebase project allows it from exactly one country — `["ES"]`, verified
live 2026-08-18. A tester elsewhere cannot create an account, so they cannot
reach the Top Up sheet at all, and the failure looks like "the SMS never
arrives" rather than anything to do with Play. Recorded as item 1 of the app's
`TECH-DEBT.md`; widening it is a Firebase Console change plus a cost decision.

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

**The console flow changed — the owner found this 2026-08-18.** Play Console no
longer has a *Setup → API access* page, and no longer asks you to link a Google
Cloud project. The service account is now created in Google Cloud directly and
granted its rights from Play Console's *Users and permissions*.

That removes a step and adds a trap: **linking used to enable the Google Play
Android Developer API for you.** Nothing does now. Verified on 2026-08-18 that
`androidpublisher.googleapis.com` is *not* among the 40 APIs enabled on
`aura-2781b` — so without this, the BFF's first real verification fails with a
`403 SERVICE_DISABLED` at the worst possible moment.

1. **Google Cloud → APIs & Services → enable `androidpublisher.googleapis.com`**
   (Google Play Android Developer API), in the project that will own the service
   account. This is the step the old linking did implicitly.
   **Done for `aura-2781b` on 2026-08-18** (`gcloud services enable`, verified
   present in the enabled list).
2. **Google Cloud → IAM & Admin → Service Accounts** → create a dedicated one.
   Do not reuse `firebase-adminsdk-fbsvc@aura-2781b…`: it already holds the keys
   to auth, and a leaked key should not cost both.
3. **Keys → Add key → JSON** → download.
4. **Play Console → Users and permissions → Invite new user** → paste the
   service account's email → grant it, on `cc.silvermind.aura`, **View financial
   data** and **Manage orders and subscriptions**.
5. Hand the BFF `GOOGLE_PLAY_PACKAGE_NAME`,
   `GOOGLE_PLAY_SERVICE_ACCOUNT_EMAIL` (the JSON's `client_email`) and
   `GOOGLE_PLAY_SERVICE_ACCOUNT_KEY` (its `private_key`). All three or it falls
   back to the fake verifier — see the update below.
6. The BFF then calls `androidpublisher.purchases.products.get(packageName,
   productId, token)` and credits only on a *purchased* state.

Permissions do not propagate instantly — allow up to a day before concluding
something is wrong.

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

### Update 2026-08-18 — steps 1 and 2 are done

The owner holds an approved developer account and has created the app under
`cc.silvermind.aura`. The account is an **organisation**, which matters more
than it looks: it is exempt from the closed-testing requirement in step 1, so
the 12-testers-for-14-continuous-days clock that would otherwise sit between
here and production does not apply. Step 9 is a questionnaire, not a fortnight.

Step 3 is therefore the live edge. The package is still not claimed — that
happens on the first upload, not on creating the app.

## Watch out

- **Billing Library 8+ is required for any upload from 31 Aug 2026.** We ship
  Play Billing **9.1.0** via `react-native-iap` 16.3.1, so this is satisfied —
  but a downgrade of that dependency would silently break publishing.
- **Google's cut** is 15% of the first $1M/year, 30% above. A $10 tier nets
  about $8.50 (`AURAD-0010`, open question).
- **Play Billing is likely mandatory** for these top-ups, not optional
  (`AURAD-0010`): the sessions are digital services consumed in-app, so the
  card rail of `AURAF-0009` should not be the Android one.
- **`versionCode` is spent on upload, not on release.** Play refuses a second
  AAB carrying a number it has already seen, and the number is invisible to
  users — `versionName` is the string they read. The first upload used 1;
  `develop` now carries 2. Bump it *before* building, or find out from a
  rejected upload.
- **A tunnel URL is not durable.** It changes on every tunnel restart, and the
  origin is compiled into the AAB — so a tunnel-built upload stops working the
  moment the tunnel is recycled. Fine for proving the rail, not something to
  leave on a track and forget.
