# AURAT-0124-011 — Approved

Date: 2026-10-23
Status: done

## Слова владельца

> Принято (проверка в маноре после деплоя на `https://web-dev.aura-app.cc`).

## Итог

- aura-web: `Dockerfile` (`node:22-alpine` → `nginx:alpine AS final`, `/srv/aura`, `nginx -t` в
  сборке), `deploy/web/build.sh` (пустое = не задано, обязательные, все правила `env.ts`, строгий
  origin, рендер CSP), `deploy/web/nginx.conf` (SPA-fallback `no-cache`, `/assets/*` `immutable`,
  404 без кэша), `deploy/web/headers.conf` (CSP, `nosniff`, `Referrer-Policy`, HSTS),
  `.dockerignore`, README «Deploy». Код `49d3422`, develop `280988a` — первый деплой web-dev.
- Brain: `AURAS-0004` — строка `aura-web` в Services, раздел «The web client», пять мест при
  переезде хоста BFF (+ `VITE_BFF_ORIGIN` веба); `AURAF-0020` — web-dev работает.

## Дальше (не в задаче)

- `AURAT-0125` — origin веба в BFF (`WEB_ALLOWED_ORIGINS`), руками владельца; Firebase
  Authorized domains — владелец. До них вход по SMS и запросы к BFF на web-dev не работают.
- Прод-ресурс `aura-web` (`production`, `main`, `web.aura-app.cc`) и релиз `develop` → `main` —
  после релиза BFF с `AURAT-0122`.
- `AURAT-0126` — лендинг в git.
- Плеер аудио/видео вложений — добавить `media-src 'self' blob:` в `headers.conf`.
