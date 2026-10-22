# AURAD-0020 — Веб на своём поддомене `web.aura-app.cc`, лендинг остаётся на apex; оба сайта — статикой из git на Cloudflare Pages

Date: 2026-10-23
Status: accepted (owner-ratified 2026-10-23)

## Decision

Веб-клиент (`aura-web`, `AURAD-0019`) живёт на своём origin: `https://web.aura-app.cc` — прод
(ветка `main`, `bff.aura-app.cc`), `https://web-dev.aura-app.cc` — dev (ветка `develop`,
`bff-dev.aura-app.cc`). Лендинг с `/privacy/` и `/terms/` остаётся на `https://aura-app.cc` и
переезжает в git — отдельной папкой в `aura-web`, отдельным деплоем. Путь `aura-app.cc/web/`
отклонён. Оба сайта — статикой из git на Cloudflare Pages; Netlify с ручной загрузкой
(`AURAS-0004`) выводится после переезда лендинга.

## How it works

- **Ветка = окружение**, как у BFF (`AURAS-0004`): Pages собирает `main` в прод, `develop` — в dev.
  Переменные `VITE_*` задаются в Pages по окружениям: прод-сборка `.env.development` не читает.
  Релиз веба — merge `develop` → `main` через merge gate; если веб опирается на то, чего нет в
  `main` BFF, сначала релиз BFF.
- **BFF:** в `WEB_ALLOWED_ORIGINS` — только точные origin веба: прод `https://web.aura-app.cc`,
  dev `https://web-dev.aura-app.cc` и `http://localhost:5173`. **`https://aura-app.cc` в список не
  входит никогда** — лендинг вне периметра BFF.
- **Firebase:** оба хоста — в Authorized domains и в ограничения браузерного ключа, если они
  заданы.
- **Заголовки веба** — в репозитории (`_headers`): `index.html` без кэша, хэшированные `/assets/*`
  immutable, CSP. Dev-хост закрыт от индексации.
- **Лендинг:** пути `/privacy/` и `/terms/` (с редиректом на форму со слэшем) не меняются — на них
  ссылаются приложение (`shared/config/legal.ts`) и листинги сторов; `www` → apex. Маркетинговые
  скрипты (пиксель, аналитика) ставятся только сюда; куки атрибуции — на `.aura-app.cc`, их видят
  оба сайта. Рядом с кнопками сторов — «Open in browser» → `web.aura-app.cc`.
- **Файлы домена для веба** (Apple Pay `/.well-known/apple-developer-merchantid-domain-association`,
  `apple-app-site-association` под ссылки на веб) отдаёт хост веба, не apex.

## Why

- **Origin — граница доверия.** Сессия Firebase веба лежит в `localStorage`
  (`browserLocalPersistence`), её читает любой скрипт того же origin; CORS и проверка `Origin` на
  `/ws` в BFF доверяют origin целиком. На общем origin лендинг со всеми будущими маркетинговыми
  скриптами оказался бы внутри периметра.
- **Независимые релизы:** правка privacy/terms (уже бывала блокером листинга, `AURAT-0040`) не
  ждёт сборки веба и merge gate, правка лендинга не передеплоивает приложение (`AURAD-0019`: у
  веба свой каденс).
- **Веб написан под корень:** свой `/` (`AURAT-0112`), ссылки от `window.location.origin`
  (`.ics`). Префикс `/web/` — налог на каждую ссылку за пределами роутера.
- **Поддомен ничего не стоит:** для браузера это тот же сайт (куки на `.aura-app.cc`), BFF
  авторизует bearer-токеном с `credentials: false`.
- **Pages, а не Coolify и не ручная загрузка:** зона и прокси apex уже в Cloudflare, статика
  без лимита трафика, SPA-fallback; Coolify — один сервер без CDN; ручная загрузка — без истории.

Отклонено: `aura-app.cc/web/` (общий origin, связанные релизы, префикс); маршрут `/web/*`
правилом Cloudflare на отдельный деплой (развязывает релизы, но origin остаётся общим). SEO
одного домена — единственный плюс пути, а SSR/SEO вне scope `AURAF-0020`. Когда дойдёт до
пререндера каталога и профилей, публичные страницы без сессии можно отдать и с apex — отдельным
решением.

Задачи: `AURAT-0124` (веб на Pages), `AURAT-0125` (BFF: origin и релиз), `AURAT-0126` (лендинг в
git).
