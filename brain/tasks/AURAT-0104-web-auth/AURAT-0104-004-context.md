# AURAT-0104-004 — Context

Date: 2026-10-20

## Sources

- `AURAF-0020` rows 003–004; `AURAD-0019`; `AURAI-0007` (FSD map: `features/auth-by-phone`,
  `features/require-auth`, `entities/user`, `widgets/top-nav`).
- Web handoff: README §3, §4.4, §7, §8, §9; NAVIGATION §0, §1.1, §1.2, §3.1, §3.5, §4, §5, §6;
  STRUCTURE (`requireAuth(reason, then)`); prototype `web/web-auth.jsx`, `web/web-app.jsx`,
  `web/web-kit.jsx`; `src/components/auth/AuthFlow.tsx`, `layout/TopNav.tsx`.
- Mobile handoff: `AUTH_PHONE_SMS.md` (keypad superseded by `AURAT-0044`), `PROFILE_FORMS.md`
  (owner correction `AURAT-0062`: no «Skip for now»).
- aura-app (read-only): `shared/lib/{phone,email,birth-date}.ts`, `shared/config/{auth,sms-regions,
  countries,legal}.ts`, `screens/phone-auth/{lib,model}`, `screens/verify-otp/model`,
  `screens/create-account`, `features/profile-form`, `entities/user`, `features/sign-out`,
  `shared/api/firebase/auth.service.ts` (`handleAuthError`).
- aura-bff (read-only): `modules/profile/profile.controller.ts`, `firebase-auth.guard.ts`,
  `sessions.controller.ts`, `common/web/web-origins.ts`.
- `@aura/contracts` v0.22.0 (= HEAD): `ProfileResponse`, `ProfilePatchRequest`,
  `MIN/MAX_DISPLAY_NAME_LENGTH` (2 / 64), `MAX_EMAIL_LENGTH`, `MIN_BIRTH_YEAR`, `ACCOUNT_DELETED`.
- aura-web `develop` @ `9443576`: `shared/api/firebase.ts` (`getIdToken`, `signOut`,
  `useAuthStatus`, SDK off without the Web App), `base-query.ts` (`public` routes, 401 retry,
  `ACCOUNT_DELETED`), `app/session/use-account-session.ts` (`resetApiState` on guest),
  `dialog` slice (`auth` kind, unregistered), `DialogHost` (history entry per dialog), GuestGate,
  `Field`, `Toggle`, `Avatar`, `Sheet`, CTA deep links of `AURAT-0103`.

## Findings

1. **BFF needs no change.** `GET /v1/me` creates the user on first touch and answers a new person
   with nulls (never 404); `PATCH /v1/me` takes `ProfilePatchRequest` (`.strict()`, name trimmed
   2–64, email `""`/`null` erases, `phoneE164` refused) and answers the whole profile. CORS allows
   `Authorization`; origins come from `WEB_ALLOWED_ORIGINS`. No sign-out endpoint; FCM devices are
   app-only (`platform: ios|android`) — web push stays out.
2. **Person-dependent answers with a guest variant:** `…/sessions/pricing` (a guest is always
   offer-eligible) and `…/sessions/availability` (a person's own bookings are subtracted). They
   must be re-asked when who is signed in changes. `GET /v1/advisors` is the same for everyone.
3. **«New person» rule (app):** after the code, force-read `/v1/me`; `ready` and no `displayName`
   → Create Account; a failed read → into the app (never blocks). No `isNew` on the wire — the
   handoff's `verify → {isNew}` API does not exist.
4. **Skip conflict.** Web handoff: «Skip for now» allowed (`auth_profile_skip`), CTA by reason.
   App: owner removed Skip (`AURAT-0062`) — a name is the only way out. `AURAF-0020-003` reads
   «заполняет … или пропускает».
5. **Name rule:** web handoff ≥ 1 char; app and contract 2–64 trimmed, no character rule.
6. **Marketing opt-in default:** web handoff ON; app OFF at sign-up (GDPR, `AURAT-0042-108`),
   consent always sent explicitly.
7. **Phone:** handoff hard-codes `+34` and 9 digits; app: `libphonenumber-js` (new dependency
   here), per-country length, a picker of the 35 SMS regions (Firebase `allowlistOnly` of
   `aura-2781b`), default country from the locale region else ES, `+…` paste splits into country +
   number, unsupported region from the number itself. Country names in the app are a static
   English table — web needs them in the current language (`Intl.DisplayNames`).
8. **Code:** 6 digits (`OTP_LENGTH`), auto-verify 480 ms after the last digit, resend after 48 s,
   failure = shake + clear + message. Firebase error codes → copy in `handleAuthError` (port as
   i18n keys). Legal line + links `aura-app.cc/terms|privacy`, «18 or older» (app copy).
9. **Web transport:** `signInWithPhoneNumber` + invisible `RecaptchaVerifier` → `ConfirmationResult`
   (not serializable — lives in the flow, not Redux). The app's `AUTH_TEST_MODE` maps to
   `auth.settings.appVerificationDisabledForTesting` (works with Firebase test numbers only).
10. **Resume.** Every resume in stage 1 is a URL: book → `/advisors/:id?book=1[&slot=]`, Free chat →
    `/chats/:id`, Chats / Sessions in the nav → their page, Log in → stay. The `DialogHost` closes a
    dialog by stepping back off its entry — «close and go to X» needs its own path, or the step back
    races the navigation.
11. **Top nav:** guest — Log in + Get started; Get started scrolls to the Ask field on Home, which is
    not built (`/` renders nothing). Signed in — balance (wallet task), bell (v2), avatar → `/me`
    (`/me` is stage 2, renders nothing). No sign-out exists in the web UI.
12. **Avatar photo** is `GET /v1/avatars/:id` with a token — not an `<img src>`; monogram only here.

Next: spec (005).
