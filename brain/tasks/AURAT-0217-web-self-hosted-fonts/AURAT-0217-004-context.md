# AURAT-0217-004 — context

Дата: 2026-11-18.

## Что в коде сейчас (aura-web develop `60bf412`)

- `index.html:10–15` — preconnect к `fonts.googleapis.com` / `fonts.gstatic.com` и stylesheet Google:
  Bricolage `opsz,wght@12..96,600..800`, Hanken `wght@400..700`, `display=swap`. Вариативные файлы, оптический
  размер работает (`font-optical-sizing: auto` по умолчанию). Так же грузит шрифты прототип дизайна
  (`Aura Web*.html`: `opsz,wght@12..96,…`).
- `features/pay/config/pay.ts:46` `STRIPE_FONT_CSS` — CSS Google для Elements; `ui/card-elements.tsx:70`
  `fonts: [{ cssSrc }]`; `lib/stripe-appearance.ts:34` — `fontFamily` из `--font-b`.
- `deploy/web/headers.conf:29` CSP: `style-src … fonts.googleapis.com`, `font-src 'self' fonts.gstatic.com`,
  `connect-src … fonts.googleapis.com` (Stripe.js читает `cssSrc` из нашей страницы, `AURAT-0212` v2).
  `app/__tests__/headers.test.ts:45` ждёт `fonts.googleapis.com` в `connect-src`.
- `deploy/web/nginx.conf` — `/assets/` (хэш Vite, год), всё прочее из `public/` — `no-cache`, без CORS.
- Веса в CSS: Hanken 400 / 500 (одно место — `advisor-row.module.css:101`) / 600 / 700, Bricolage 600 / 700 / 800.
  Кегли Bricolage до 44px (`clamp(…, 44px)`).
- reCAPTCHA (`shared/api/firebase.ts:120`) создаётся только при входе по телефону; в §12 (B8) она описана.

## Шрифты приложения (`AURAT-0156`, aura-app `e155f11`)

7 статичных TTF: Bricolage 400/600/700/800, Hanken 400/600/700; в каждом греческий (73–77 знаков) и
кириллица (98). Bricolage-статика — оптический размер 14: по замеру ширины строки против вариативного
Google на 32px она шире на ~2,4%, на 48px — на ~4,6%, на 96px — на ~12%. Покрытие — `exemplars.json`
(CLDR 48.2, 24 языка) в той же сборке.

## Прототип (scratchpad, fontTools 4.60.2 — та же версия, что у приложения)

- Латиница: вариативные файлы google/fonts `bbda7253` (тот же коммит донора, что в `AURAT-0156`), диапазоны
  Google latin + latin-ext, Bricolage `wght 600–800` + `opsz 12–96`, Hanken `wght 400–700`:
  Bricolage **94 КБ**, Hanken **30 КБ** woff2.
- Греческий + кириллица из статики приложения: **12–14 КБ** на начертание, 6 файлов.
- Все буквы 24 языков покрыты; в латинских файлах Google нет U+0301, U+2009, U+2010, U+2011, U+202F
  (последний — разделитель тысяч во французских ценах `Intl`) — в статике приложения они есть.
- Итого ≈ 207 КБ на диске; браузер качает только нужные: латиница 124 КБ, el/bg — по требованию.

## Stripe

`CssFontSource.cssSrc` — «relative or absolute URL» к CSS с `@font-face` (`@stripe/stripe-js`
`elements-group.d.ts:1109`). Сами файлы шрифта грузятся во фреймах Stripe (`js.stripe.com`) — шрифт с
чужого origin требует `Access-Control-Allow-Origin`.

## Противоречий нет

Бриф и `AURAT-0209-008` п. 2 совпадают; вопрос только в том, из чего собирать латиницу (см. спеку).
