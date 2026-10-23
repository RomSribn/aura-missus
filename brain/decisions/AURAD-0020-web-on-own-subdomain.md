# AURAD-0020 — Веб на своём поддомене `web.aura-app.cc`, лендинг остаётся на apex; оба сайта — ресурсами Coolify на нашей ВМ

Date: 2026-10-23
Status: accepted (owner-ratified 2026-10-23; площадка — Coolify вместо Cloudflare Pages, решение
владельца в тот же день)

## Decision

Веб-клиент (`aura-web`, `AURAD-0019`) живёт на своём origin: `https://web.aura-app.cc` — прод
(ветка `main`, `bff.aura-app.cc`), `https://web-dev.aura-app.cc` — dev (ветка `develop`,
`bff-dev.aura-app.cc`). Лендинг с `/privacy/` и `/terms/` остаётся на `https://aura-app.cc` и
переезжает в git — отдельной папкой в `aura-web`, отдельным деплоем. Путь `aura-app.cc/web/`
отклонён. Оба сайта — ресурсами Coolify на нашей ВМ (`AURAS-0004`), как BFF и Chatwoot; Netlify
с ручной загрузкой выводится после переезда лендинга.

## How it works

- **Ресурс `aura-web`** в проекте `aura`: в `production` — ветка `main`, домен
  `https://web.aura-app.cc`; в `development` — ветка `develop`, `https://web-dev.aura-app.cc`.
  Push в ветку — деплой её окружения, как у BFF. Релиз веба — merge `develop` → `main` через merge
  gate; если веб опирается на то, чего нет в `main` BFF, сначала релиз BFF.
- **Сборка — `Dockerfile` в репозитории**, не настройки панели: стадия на `node:22-alpine` с `git`
  (контракты ставятся из git) и `npm ci --include=dev` (Coolify передаёт `NODE_ENV=production` в
  сборку, `AURAS-0004`), затем `npm run build` — typecheck остаётся минимальным гейтом; отдаёт
  `nginx:alpine` с конфигом из репозитория: SPA-fallback, `index.html` без кэша, хэшированные
  `/assets/*` immutable, CSP. Dev-хост закрыт от индексации.
- **`VITE_*` — build-time переменные** окружения в Coolify, в отличие от BFF, где всё runtime:
  Vite вшивает их в бандл. Они публичны по устройству (адрес BFF, web-конфиг Firebase); секрет
  среди них не появляется никогда.
- **DNS:** `web` и `web-dev` → `37.27.199.90`, DNS-only, как `bff.` и `chat.`; сертификат —
  Traefik / Let's Encrypt. Репозиторий приватный: GitHub App Coolify нужен доступ к
  `RomSribn/aura-web`.
- **BFF:** в `WEB_ALLOWED_ORIGINS` — только точные origin веба: прод `https://web.aura-app.cc`,
  dev `https://web-dev.aura-app.cc` и `http://localhost:5173`. **`https://aura-app.cc` в список не
  входит никогда** — лендинг вне периметра BFF.
- **Firebase:** оба хоста — в Authorized domains и в ограничения браузерного ключа, если они
  заданы.
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
- **Coolify (владелец):** одна площадка и один способ деплоя на всё, без новой учётки. Отказоустойчивость
  не теряется: без BFF на той же ВМ веб бесполезен. Ресурсов хватает (замер 2026-10-23): на хосте
  доступно 4,3 ГБ, nginx со статикой — десятки МБ, пик сборки — около 0,75 ГБ (на маноре
  `tsc -b` 663 МБ / 10,6 с, `vite build` 749 МБ / 4,4 с, `dist` 4,1 МБ). Принято: нет CDN
  (статика из Хельсинки, аудитория — ЕС), сборка на прод-хосте в момент деплоя — как у BFF.

Отклонено: `aura-app.cc/web/` (общий origin, связанные релизы, префикс); маршрут `/web/*`
правилом Cloudflare на отдельный деплой (развязывает релизы, но origin остаётся общим);
Cloudflare Pages (CDN и сборка вне хоста, но вторая площадка рядом с Coolify — владелец выбрал
Coolify). SEO одного домена — единственный плюс пути, а SSR/SEO вне scope `AURAF-0020`. Когда
дойдёт до пререндера каталога и профилей, публичные страницы без сессии можно отдать и с apex —
отдельным решением.

Задачи: `AURAT-0124` (веб в Coolify), `AURAT-0125` (BFF: origin и релиз — руками владельца),
`AURAT-0126` (лендинг в git).
