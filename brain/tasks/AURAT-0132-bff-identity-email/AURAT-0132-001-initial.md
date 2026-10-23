# AURAT-0132-001 — Initial (исполняется в `aura-bff-manor`)

Date: 2026-10-23
Решение: `AURAD-0021`, разбор `AURAI-0008` (`brain/investigations/AURAI-0008-web-sign-in-methods/`).
Выдан в `aura-app-manor` по просьбе владельца («давай, выдавай», 2026-10-23). Не начата, слот не назначен.

Аккаунты без телефона и подтверждённая почта (`AURAD-0021` Р1, Р5):

- `FirebaseAuthGuard` (`firebase-auth.guard.ts:96-99`) и WS-шлюз (`chat.gateway.ts:62-75`): кроме
  `uid` / `phone_number` — `email`, `email_verified`, `firebase.sign_in_provider` в `AuthUser`;
  `ensureUser` пишет `email` только при `email_verified` и не затирает.
- `PATCH /v1/me` `email` — неподтверждённое поле «for receipts» для телефонных аккаунтов; не
  перезаписывает подтверждённую.
- `POST /v1/auth/oauth/link-by-email` — **только если** проверка `AURAT-0133` на web-dev покажет,
  что Firebase не впускает Google / Apple в uid с той же подтверждённой почтой: проверить ID token
  провайдера (JWKS Google / Apple, аудитория, `email_verified`) → custom token этого uid.
- Операторский CLI удаления (`src/account-erasure.ts`) — `--email`.
- Метрика: доля офферов первой сессии у аккаунтов без телефона (`AURAD-0021` Р6).
