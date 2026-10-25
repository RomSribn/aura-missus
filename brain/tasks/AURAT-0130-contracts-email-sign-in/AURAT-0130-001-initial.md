# AURAT-0130-001 — Initial (`aura-contracts`)

Date: 2026-10-23
Решение: `AURAD-0021`, разбор `AURAI-0008` (`brain/investigations/AURAI-0008-web-sign-in-methods/`).
Выдан в `aura-app-manor` по просьбе владельца («давай, выдавай», 2026-10-23). Не начата, слот не назначен.

Новая минорная версия `@aura/contracts` для входа почтой (`AURAD-0021` Р1, Р3, Р5):

- `EmailSignInStartRequest { email, language }` → `EmailSignInStartResponse { attemptId }`;
- `EmailSignInVerifyRequest` — `{ email, code }` | `{ token }` → `CustomTokenResponse
  { customToken, isNew }`;
- привязка почты из профиля — те же формы для `/v1/me/email`;
- `LinkByEmailRequest { providerIdToken }` → `CustomTokenResponse` (если понадобится, см. `AURAT-0132`);
- отказы: `email_code_invalid`, `email_attempt_expired`, `email_rate_limited`, `email_in_use`;
- `ProfileResponse` — `emailVerified`; комментарии `profile.ts:7-10`, `:133-135` («телефон —
  ключ аккаунта») переписать.

Бамп тега в BFF и вебе — отдельными коммитами.
