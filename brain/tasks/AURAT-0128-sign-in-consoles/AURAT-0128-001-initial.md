# AURAT-0128-001 — Initial (делает владелец в консолях, без слота)

Date: 2026-10-23
Решение: `AURAD-0021`, разбор `AURAI-0008` (`brain/investigations/AURAI-0008-web-sign-in-methods/`).
Выдан в `aura-app-manor` по просьбе владельца («давай, выдавай», 2026-10-23). Не начата, слот не назначен.

Настроить провайдеров входа для веба — чек-лист `AURAI-0008` раздел 11:

- **Firebase `aura-2781b`:** включить Google, Apple, Facebook; Email/Password и Email link — **не**
  включать; «Link accounts that use the same email»; бюджет-алерт  рядом с  (первый
  реальный счёт за SMS — после ~2026-11-26).
- **Google OAuth:** consent screen (Aura, логотип, privacy / terms, `aura-app.cc`, In production);
  web client — origins `https://web-dev.aura-app.cc`, `https://web.aura-app.cc`, redirect URI
  `…/__/auth/handler` для каждого + `https://aura-2781b.firebaseapp.com/__/auth/handler`.
- **Apple:** Services ID (домены и Return URLs как выше), ключ Sign in with Apple → Team ID, Key ID,
  `.p8` в Firebase; Email Communication — отправители писем входа и Chatwoot с SPF (релей Apple).
- **Meta:** Meta App `4422398391357112` → продукт Facebook Login, redirect URI как выше; Privacy,
  Terms, User data deletion, иконка, категория; App ID и Secret → Firebase; режим Live; уровень
  доступа `public_profile` / `email` (Advanced может потребовать Business Verification).
- **Resend:** отправитель писем входа на `send.aura-app.cc`; Pro (/мес) — до рекламы на веб
  (free — 100 писем в сутки вместе с Chatwoot).

Нужна до проверки `AURAT-0133` на web-dev.
