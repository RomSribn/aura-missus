# AURAT-0209-015 — Сверка манора: правки к промптам `014` и ворота 4

Дата: 2026-11-18. Манор сверил `014` с живыми страницами и кодом веба. П. 1–3 приводят промпты в
соответствие с уже одобренным текстом, отдельного «да» не нужно. Промпты ниже **заменяют**
соответствующие места `014`.

## 1. Промпт 2 (/privacy/), п. 8

Ссылка «Stripe's cookie policy» → `https://stripe.com/legal/cookies-policy`. Раньше стояла
`stripe.com/cookie-settings` — это страница «Cookie settings», а не политика.

## 2–3. Промпт 3 (/delete-account/) — целиком взамен `014`

Шаги веба сверены по `aura-web`: Profile → Legal → «Delete my account» (`me-sections.tsx:268`) →
шторка → «Delete account»; при активной сессии удаление недоступно; затем «Your account has been
deleted.».

```text
Update the "Delete your Aura account" page (https://aura-app.cc/delete-account/).

Change ONLY what is listed below. Keep everything else exactly as it is now.

1. Header: set "Last updated" to [DATE], and change the "App" value from "Aura (Google Play, App Store)" to "Aura (web, Google Play, App Store)".

2. Section 01 "In the app": keep the four steps as they are, and add this paragraph after them:

In the web app at web.aura-app.cc, open Profile and choose "Delete my account" under Legal, then tap "Delete account" to confirm. The same rules apply: your account is deleted straight away and you are signed out.

3. Section 04, list "Kept": replace the end of the first item ", for at least seven years as Estonian accounting law requires — without your name, phone number or anything else that identifies you;" with:

, for at least seven years as Estonian accounting law requires — without your name or phone number; they still carry the payment references accounting needs, such as the store's order number or Stripe's payment reference;

4. Footer: directly under the line "© Silvermind OÜ. …", add one line in the same small footer style:

Silvermind OÜ · Registry code 17345387 · Lõõtsa tn 5, 11415 Tallinn, Estonia · support@aura-app.cc · [PHONE]

("support@aura-app.cc" is a mailto link.)

Sections 02 and 03 and the rest of section 04 stay exactly as they are.
```

Проверить в маноре до отправки: выходит ли веб после удаления из аккаунта («you are signed out»).
По коду показывается «Your account has been deleted.» и «Done»; если выхода нет, убрать из фразы
«and you are signed out».

## 4. Веб: ссылка «Refund & cancellation policy»

Сейчас ведёт на `/terms/` без якоря (`me-sections.tsx:265`), а по решению `006` п. 2 — на `#s07`.
Однострочник, добавлен в скоуп `AURAT-0218` (шаг `AURAT-0218-002`).

Та же сверка нашла фразу «…without anything that identifies you.» в шторке удаления аккаунта — в
вебе (`features/delete-account`) и в приложении (`features/account-deletion`). После правки она
расходится с Privacy §07. Добавлено в `AURAT-0216-006`: оба клиента, 24 языка.

## 5. Ворота 4: `AURAT-0216` в проде до публикации

Фраза §07 «When you book or extend a session, we also ask you to confirm…» верна только с `0216`
(BFF + веб; Android — ближайшим релизом). Ворота 1 открывают брони на вебе, поэтому порядок такой:

прод-веб → `AURAT-0217` → `AURAT-0216` в проде → номер телефона → публикация `0209` → анкета Stripe.

**Остаточный риск:** старые версии приложения галочку не покажут.

## 6. «После публикации»

Если самая низкая цена за минуту поднимется выше $2.20, строку цен на лендинге править в тот же
день: иначе «from $2.20/min» вводит в заблуждение.
