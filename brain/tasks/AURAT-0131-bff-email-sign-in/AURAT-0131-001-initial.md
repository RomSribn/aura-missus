# AURAT-0131-001 — Initial (исполняется в `aura-bff-manor`)

Date: 2026-10-23
Решение: `AURAD-0021`, разбор `AURAI-0008` (`brain/investigations/AURAI-0008-web-sign-in-methods/`).
Выдан в `aura-app-manor` по просьбе владельца («давай, выдавай», 2026-10-23). Не начата, слот не назначен.

Вход почтой (`AURAD-0021` Р3), контракты — `AURAT-0130`:

- `POST /v1/auth/email` `@Public` → `202 { attemptId }`, ответ одинаковый для любой почты.
  Попытка в Redis: хэши кода (6 цифр) и токена ссылки (32 байта), TTL 15 мин, новая гасит старую.
- `POST /v1/auth/email/verify` `@Public` (`{ email, code }` | `{ token }`) → `getUserByEmail` /
  `createUser({ email, emailVerified: true })` → `createCustomToken(uid)`, `isNew`.
- Привязка из профиля: `POST /v1/me/email`, `/v1/me/email/verify` → Admin `updateUser(uid,
  { email, emailVerified: true })`; почта у другого uid → `409 email_in_use`.
- Письмо через Resend (env, отправитель `send.aura-app.cc`): кнопка-ссылка
  `https://<веб>/auth/email?t=…` и код; 24 языка; код в теме.
- Лимиты (Redis): почта — 1 / 60 с и 5 / ч; IP — 20 / ч; 5 неверных кодов гасят попытку; 3
  сожжённые — пауза 15 мин; сравнение за постоянное время. Почта, код, токен — не в логи.
- В BFF сейчас нет почты вовсе; глобальный rate limit — 120/мин на IP в памяти; Redis есть
  (`REDIS_CLIENT`). `createCustomToken` подписывает ключом сервис-аккаунта `FIREBASE_*`.
