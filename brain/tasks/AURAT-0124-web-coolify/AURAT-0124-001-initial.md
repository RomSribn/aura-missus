# AURAT-0124-001 — Initial (исполняется в `aura-web-manor`)

Date: 2026-10-23
Решение: `AURAD-0020` (веб на своём поддомене, ресурс Coolify). Платформа — `AURAS-0004`.
ID выдан в `aura-app-manor/active-work.md` (абзац «AURAD-0020 / AURAT-0124 / AURAT-0125 /
AURAT-0126»), новых не минтить.
Слот: `slave-1`, ветка `feature/AURAT-0124-web-coolify` (master и missus).

## Слова владельца

> всё добавил, запускай 0124

## Контекст из `aura-app-manor` (не слова владельца)

- В aura-web: `Dockerfile` в корне, конфиг nginx, `.dockerignore`.
- Сборка — первая стадия: `node:22-alpine`, `git` (контракты из
  `github:RomSribn/aura-contracts#v0.24.0`), `npm ci --include=dev` (Coolify передаёт
  `NODE_ENV=production`), `npm run build` (`tsc -b && vite build` — минимальный гейт).
- Явный `ARG` на каждую `VITE_*` из `src/shared/config/env.ts`; сборка падает без
  `VITE_BFF_ORIGIN`, `VITE_FIREBASE_AUTH_DOMAIN`, `VITE_FIREBASE_PROJECT_ID` (env.ts проверяет их
  только в браузере → белый экран).
- Финал — `nginx:alpine`, порт 80: SPA-fallback, `index.html` no-cache, `/assets/*` immutable,
  CSP. Хостов в конфиге nginx нет (noindex на dev ставит Coolify/Traefik). CSP — без
  runtime-переменных (из `VITE_BFF_ORIGIN` при сборке или оба origin).
- Ресурс Coolify заведён владельцем, сверен 2026-10-23: проект `aura`, окружение `development`,
  ресурс `aura-web`, ветка `develop`, Dockerfile `/Dockerfile`, base `/`, порт 80,
  `https://web-dev.aura-app.cc`. Build-time переменные: `VITE_BFF_ORIGIN`, `VITE_BFF_WS_PATH`,
  `VITE_FIREBASE_API_KEY`, `VITE_FIREBASE_APP_ID`, `VITE_FIREBASE_AUTH_DOMAIN`,
  `VITE_FIREBASE_PROJECT_ID`, `VITE_PSP_ENABLED`. Auto-deploy по push в `develop`.
- Не в задаче: BFF (`AURAT-0125`), Firebase Authorized domains (владелец), лендинг
  (`AURAT-0126`). Живая проверка на web-dev — манор после деплоя. Прод-релиз веба — после релиза
  BFF.
