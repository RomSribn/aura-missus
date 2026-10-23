# AURAT-0124-007 — Execute

Date: 2026-10-23
Ветка: `feature/AURAT-0124-web-coolify` (slave-1), не закоммичено — на ревью.

## Файлы aura-web

- `Dockerfile` (новый) — первая строка `# check=skip=SecretsUsedInArgOrEnv`; `build` на
  `node:22-alpine` (`git`, `npm ci --include=dev`, 8 `ARG VITE_*`, `sh deploy/web/build.sh`) →
  `nginx:alpine` (только `COPY`, порт 80).
- `.dockerignore` (новый) — все `.env*`, `node_modules`, `dist`, `.git`, `deploy/web/out/`, IDE.
- `deploy/web/build.sh` (новый) — пустое = не задано; обязательные три; форма `VITE_BFF_ORIGIN`
  как в `env.ts`; ключи Web App — оба или ни одного; рендер `headers.conf` (`http`→`ws`);
  `npm run build`.
- `deploy/web/nginx.conf` (новый) — `/assets/` immutable + `=404`; `/` — SPA-fallback, `no-cache`;
  gzip; `server_tokens off`; хостов нет.
- `deploy/web/headers.conf` (новый) — CSP по спеке, `nosniff`, `Referrer-Policy`, HSTS
  `max-age=31536000` без `includeSubDomains`; комментарии: причина `style-src 'unsafe-inline'` —
  reCAPTCHA (custom properties — CSSOM), `media-src 'self' blob:` для будущего плеера вложений.
- `.gitignore` — `deploy/web/out/`. `README.md` — раздел «Deploy».

## Проверка (слот, без серверов)

- `npm run lint`, `npm run typecheck` — чисто; `npm test` — 81 файл, 1428 тестов, зелёные.
- `docker build` с dev-значениями — ок, без предупреждения `SecretsUsedInArgOrEnv`;
  `nginx -t` в образе — ок; образ 98 МБ.
- В собранном `index.html` нет инлайн-скриптов; в бандле нет `eval(` / `new Function(` — для
  скриптов CSP без `unsafe-*` достаточно.
- Сборка в виде Coolify (`ARG` после каждого `FROM`, `NODE_ENV=production`):
  - без `VITE_BFF_ORIGIN` → `build.sh: VITE_BFF_ORIGIN is not set`, сборка падает;
  - `VITE_BFF_ORIGIN` со слэшем на конце → падает с объяснением;
  - только `VITE_FIREBASE_API_KEY` → `VITE_FIREBASE_APP_ID is not set`, падает;
  - пустые `VITE_BFF_WS_PATH`, `VITE_PSP_ENABLED`, ключи Web App → сборка проходит, в бандле их
    нет (дефолты `env.ts`).

## Решение по ходу

- **Поправка к спеке `005`.** «Нет `RUN` в финальной стадии → значений нет в истории» —
  неверно для Coolify: вставленный им `ARG` после `FROM` сам пишет значение в `docker history`
  (`ARG VITE_BFF_ORIGIN=https://…`), с `RUN` или без. Для веба это допустимо — значения и так в
  бандле; комментарий в `Dockerfile` говорит, что на этом ресурсе никогда не задаётся ничего,
  кроме публичных `VITE_*`. Без вставки Coolify (локальная сборка) в истории финального образа
  `VITE_*` нет.

## Дальше

Ревью владельца → коммит в ветку → merge gate → push в `develop` = первый деплой на web-dev →
живая проверка в маноре (список — спека `005`, «После мёржа»).
