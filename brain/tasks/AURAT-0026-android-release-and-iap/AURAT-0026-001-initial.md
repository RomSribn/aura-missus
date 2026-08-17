# AURAT-0026 — 001 initial

Date: 2026-08-17
Slave: slave-1
Branch: `feature/AURAT-0026-android-release-and-iap` (off develop `bf2411a`)

## What the owner asked (close to their words)

> Подготовь релиз андроид приложения, новый package name приложения
> `cc.silvermind.aura`. Нужно так же подготовить реализацию IAP платежей,
> по началу для android, т.к. apple еще на рассмотрении. Посмотри, можно ли
> сделать что-то без явного одобрения моей кандидатуры. Используй эту либу и
> доку для подключения https://www.openiap.dev/docs/setup/react-native

Three things in one ask:

1. **Prepare an Android release** of the app.
2. **Rename the package to `cc.silvermind.aura`** (today: `com.psychoapp`).
3. **Prepare IAP payments, Android first** — Apple's side is still under
   review. Explicitly: *find out how much can be done without the owner's
   developer-account candidacy being approved.* Library named by the owner:
   `react-native-iap` per <https://www.openiap.dev/docs/setup/react-native>.

## Manor briefing carried in with the task

- This manor is the ID-counter authority. `AURAT-0026` reserved here before
  this file was written; slave-1 was detached and bootstrapped by `wts-start`.
- The money model is decided and shipped — `AURAD-0002` (wallet is the only
  money source, ledger append-only, a running block is non-refundable) and
  `AURAD-0009` (a session is a scheduled slot paid from the wallet, refund
  full ≥24h / half <24h, only before it starts). **Nothing here may invent a
  second money model.**
- Top-up is where IAP belongs. `POST /v1/wallet/top-ups` exists but is a stub
  that 503s in production (`AURAT-0007`); a PSP was out of scope in
  `AURAF-0007` and named a hard prerequisite in `AURAD-0008`; `AURAF-0009` is
  the card-rail feature. Google Play Billing is therefore a **new money rail
  entering the wallet** — very likely its own `AURAD` decision plus a BFF task.
  **The app must never credit its own balance from a client-side purchase.**
- The rename touches Firebase, not only Gradle: `google-services.json` and
  `GoogleService-Info.plist` are keyed by package / bundle id, and the debug
  keystore SHA-1/SHA-256 are registered in the Firebase console (`AURAT-0001`,
  which also records the project is on the **Spark** plan). FCM push
  (`AURAT-0006`) and phone-OTP auth both break if the rename lands without
  re-registration.
- App runs the New Architecture on both platforms. iOS bundle id is currently
  `org.reactjs.native.example.PsychoApp`.

## Next

`002-check` — what already exists in the brain for release/packaging/payments.
