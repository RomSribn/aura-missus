# AURAT-0104-001 — Initial (заглушка; исполняется в `aura-web-manor`)

Date: 2026-10-20
Выдан в `aura-app-manor` для `AURAF-0020` (веб-клиент), этап 1 — строки 003 и 004
scope (колонка UI), шаг «Auth» (порядок — Р5 `AURAD-0019`). Опирается на каркас
`AURAT-0101` (`shared/api/firebase.ts`, slice `dialog` с видом `auth`, GuestGate) и на
`AURAT-0103` (CTA гостя пока — deep links, «Назад» закрывает диалог).

Что нужно: один поток входа и регистрации в окне `auth` — README §4.4, NAVIGATION
§1.1, §3.5, §4, §5 веб-хендоффа; мобильные `AUTH_PHONE_SMS.md` и `PROFILE_FORMS.md`.

- **Вход.** Firebase JS SDK: `signInWithPhoneNumber` + невидимая reCAPTCHA, проект
  `aura-2781b` — тот же uid, что в приложении (чаты, кошелёк, оффер общие). Код —
  **6 цифр** (`OTP_LENGTH` приложения), а не 4 из хендоффа: одно скрытое поле
  `autocomplete="one-time-code"`, проверка на последней цифре, повторная отправка по
  таймеру, «change» — назад к номеру. Страна и формат номера — по логике приложения
  (`screens/phone-auth/lib/{device-country,country-search}.ts`, `shared/lib/phone.ts`),
  а не «+34 и 9 цифр» прототипа. Заголовок по причине (ask / book / null), купон-тизер.
- **Новый человек** — по правилу приложения: после входа `GET /v1/me`, нет
  `displayName` → «Tell us who you are», `PATCH /v1/me`, «Skip for now» можно. Поля и
  проверки — `features/profile-form` приложения и `PROFILE_FORMS.md`; расхождения с
  веб-хендоффом (email, дата рождения, маркетинговое согласие) — в спеку. React Hook
  Form + Zod (правила веба), схемы — `@aura/contracts`.
- **Gate с resume** (строка 004): действие гостя (слот, Book session, All dates, Free
  chat / Chat free; Chats и Sessions в навигации — NAVIGATION §1.1) открывает вход и
  после успеха продолжает с теми же данными: book → `?book=1&slot=` того же советника,
  Free chat → `/chats/:advisorId`, Log in → остаётся на странице. Намерение переживает
  перезагрузку (sessionStorage). Вошедшему gate не мешает.
- **Шапка справа:** гость — **Log in**; вошедший — аватар-монограмма → `/me`. Баланс
  «· Top up» — с задачей кошелька или брони. **Get started** ведёт к полю Ask на Home,
  которой ещё нет, — решить в спеке.
- **Смена статуса.** Вход и выход сбрасывают ответы, зависящие от человека: цена и
  слоты закешированы как гостевые, а оффер `AURAT-0103` берётся из pricing с токеном.
  Выход в UI — страница `/me` этапа 2; решить в спеке, нужен ли он раньше.
- Ошибки Firebase (неверный или просроченный код, много попыток, сеть, reCAPTCHA) —
  понятные тексты; номер телефона и uid не попадают в логи (правило PII).
- Перенос из aura-app только нужного, копией с тестами и шапкой
  `// Ported from aura-app <path> (<ID>)`. Новые строки — сразу на все 24 языка
  (правило 9).

BFF ожидается без изменений: CORS пропускает `Authorization`, пользователь создаётся
при первом запросе, как у приложения. Если спека найдёт пробел — отдельная задача для
`aura-bff-manor`, ID выдаётся в `aura-app-manor`.

Вне задачи: Home и Ask → `/match`, Book sheet и оплата, чат, кошелёк и баланс в
шапке, страница `/me` (этап 2), веб-push.

Проверка в маноре: для живого входа нужна Firebase Web App в `aura-2781b`
(`VITE_FIREBASE_API_KEY` и `VITE_FIREBASE_APP_ID` в `.env.local` манора) — это
действие владельца, сейчас их нет. Без реальных SMS — тестовые номера Firebase
(Authentication → Sign-in method → Phone); `localhost` в Authorized domains по
умолчанию. Старт — `wts-task` в `aura-web-manor`, спека на одобрение владельцу.
