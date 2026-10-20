# AURAT-0104-007 — Execute

Date: 2026-10-20
Slave: slave-1, `feature/AURAT-0104-web-auth`. Not committed — staged for review.

## Code (`aura-web`)

- **deps** — `libphonenumber-js` (as the app), `react-hook-form`, `@hookform/resolvers@5`
  (v6 has a broken peer on `effect@4`); `resolveJsonModule` for the example numbers.
- **shared**
  - `api/firebase.ts` — `sendSignInCode(e164, language)` (one invisible `RecaptchaVerifier` per
    attempt, cleared after; SMS in the UI language) → `verificationId`;
    `confirmSignInCode(verificationId, code)` (`PhoneAuthProvider.credential` +
    `signInWithCredential`, so a reload can still confirm); `PhoneSignInError` keeps only the code
    (region allowlist read off the text, as the app); `onIdentityChange` (uid change after the
    restore, uid never leaves the module); `isSignInAvailable`; test mode →
    `appVerificationDisabledForTesting`.
  - `config/env.ts` — `VITE_FIREBASE_AUTH_TEST_MODE` (ignored in a production build);
    `config/legal.ts` — `LEGAL_URLS` (port); tokens `--error`, `--dur-shake`.
  - `lib/` — ports with tests: `phone.ts`, `email.ts`, `birth-date.ts` (only the string spread →
    `split('')` for lint).
  - `model/dialog.ts` — the auth dialog contract: `AuthReason`, `AuthIntent`, `AuthStart`
    (`phone | name | restore`), `openAuthDialog`, `authDialogParams`.
  - `ui/` — `Field` (error, onBlur, maxLength, autoFocus), `Sheet` (`eyebrow`, `back`), `Button`
    (`type="submit"`), `ButtonLink` (`onClick`); `useModal` reads the trigger on first render and
    leaves an `autoFocus` field focused.
- **entities/user** — `getMe` / `updateMe` (`ProfileResponse.parse`, body
  `ProfilePatchRequest.parse`, the answer replaces the cache); `useViewer` (`needsName` = read and
  no name; a failed read never asks), `useReadViewer`, `useSaveViewer`; `ViewerAvatar` (monogram,
  person glyph without a name).
- **features/auth-by-phone** — dialog `auth`, loaded lazily (phone library + form out of the main
  chunk):
  - phone: country `<select>` of the 35 SMS regions (`Intl.DisplayNames`, browser region else
    ES), per-country format/length, `+…` paste moves the country, number of a non-SMS region
    named, coupon, legal + reCAPTCHA lines with links;
  - code: 6 cells over one `one-time-code` input, check 480 ms after the 6th digit, shake + clear
    + message on refusal, resend after 48 s counted from the send;
  - name: «Tell us who you are» (RHF + Zod, contract bounds 2–64; email after blur; date mask and
    check from the app; opt-in off), no Skip, CTA by reason, PATCH sends name + consent + what
    changed;
  - Firebase codes → 13 messages (`handleAuthError` of the app as keys);
  - `sessionStorage` `aura.auth` per step (`code`: verification id, E.164, sent-at), forgotten on
    unmount / finish, 15 min TTL, `to` must be a site path; `useRestoreSignIn` reopens it once
    per load (phone/code for a guest, name for a signed-in person).
- **features/require-auth** — `useGate` (`gate`, `gateLink`: guest → sign-in, nameless → name
  step, otherwise follow; modified clicks left to the browser; sign-in off → plain links);
  `useGateOnArrival` (guest on `?book=1` asked once per history entry, stays on the page).
- **pages** — advisors: tile Chat free / Book gated; advisor: slots, All dates, Book session, Free
  chat (and the phone action bar) gated, arrival gate on `?book=1`; **me** (interim, lazy): name or
  «Add your name» → name step, phone, Log out (forgets the attempt, `/`).
- **app** — `auth` registered; `DialogHost` `onLeave(to)` replaces the dialog's entry (Back from
  the destination returns to the page) and renders dialogs in `Suspense`; nav: Log in (guest) /
  avatar → `/me` (signed in), nothing while Firebase loads, Chats and Sessions gated; GuestGate
  without a CTA when sign-in is off; `PrivateRoute` in `Suspense`; account session: every identity
  change → `resetApiState` (mounted screens re-ask — tested), restore of a pending sign-in;
  `.grecaptcha-badge` hidden.
- **Strings** — namespaces `auth-by-phone`, `me-page`, `app` (`nav.logIn`, `nav.profile`); en +
  23 EU languages, each in the language's existing register.

## Checks

`npm run lint` (eslint + steiger), `tsc -b`, `vitest` — 37 files / 437 tests, `vite build`,
`prettier --check` — all green. New tests: ports, SMS regions, countries / default country, auth
errors, countdown, pending attempt (parse, TTL, site path, storage blocked), name patch, the
dialog end to end with Firebase mocked (18), gate and arrival gate, nav right side and gated
Chats with Back, `/me`, Firebase wrapper (code only, region text, identity change), cache reset →
refetch, env test mode.

Bundle: main chunk 497 → 509 kB (gzip 157 → 161); the dialog (55 kB) and the phone library
(160 kB) load on first open. Vite warns about the main chunk > 500 kB (it was 497 before).

## Decisions during implementation

- Tests run with a Firebase config (`.env.test`), so the nav's Log in shows in app tests.
- The web's country names come from `Intl`, not the app's English table; the app's country-search
  is not ported (a native `<select>`).
- `verification` copy says «this browser … reload», not the app's «update to the latest version».
- Ask / `reason: 'ask'` and Get started are not built (no Home); row 004 is ✓ for Book, slot,
  Free chat, Chats / Sessions.

## Docs

- `AURAF-0020`: UI ✗ → ✓ in 003 (without «или пропускает», decision 1) and 004; a context line.

## For the manor (after merge)

Firebase Web App keys and test numbers in `.env.local` (spec §«Проверка в маноре»); then: Log in
from the nav, Book / slot / Free chat as a guest → resume, a new number → name step, reload on
the code step, `/me` → Log out, price and slots re-read after sign-in.
