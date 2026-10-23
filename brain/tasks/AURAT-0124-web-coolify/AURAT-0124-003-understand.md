# AURAT-0124-003 — Understand

Date: 2026-10-23

Владелец завёл ресурс `aura-web` (development, `develop`, Dockerfile, порт 80,
`web-dev.aura-app.cc`) и build-time `VITE_*` в Coolify. Нужно, чтобы push в `develop` собирал и
отдавал веб: `Dockerfile` в корне aura-web (сборка `node:22-alpine` → `nginx:alpine`), конфиг
nginx (SPA-fallback, кэш, CSP) и `.dockerignore`. Сборка обязана падать на неполной конфигурации,
а не выкатывать белый экран. Живую проверку делает манор после мёржа (= первого деплоя).
