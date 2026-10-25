# AURAT-0124-009 — Execute (правки ревью `008`)

Date: 2026-10-23
Не закоммичено — на ревью.

## Что изменено

- `deploy/web/nginx.conf`: у `Cache-Control … immutable` в `/assets/` снят `always` (404 больше
  не кэшируется на год; причина — в комментарии); `root /srv/aura`.
- `Dockerfile`: `FROM nginx:alpine AS final`; `dist` → `/srv/aura` (дефолтные `index.html` /
  `50x.html` образа не отдаются); `RUN nginx -t` в финальной стадии; формулировка про директиву
  парсера — «читают только выше первого комментария, пустой строки или инструкции».
- `deploy/web/build.sh`:
  - пустые `VITE_*` — по `env | sed`, без списка и `eval`;
  - origin — `^https?://[A-Za-z0-9.-]+(:[0-9]+)?$` (строже `env.ts` намеренно: значение идёт в
    `sed` и строку nginx);
  - `VITE_BFF_WS_PATH` — с `/`, без пробелов; `VITE_PSP_ENABLED`, `VITE_FIREBASE_AUTH_TEST_MODE` —
    `true` / `false` (или не заданы).
- `deploy/web/headers.conf`: шапка — «два плейсхолдера в connect-src ниже», без литералов.
- `README.md`: правила `env.ts` и `nginx -t` в разделе Deploy.

## Проверка (сборка в виде Coolify: `ARG` после `FROM`, `NODE_ENV=production`)

Падает с именем переменной: нет origin; origin с `|`; origin с `;script-src *`;
`VITE_PSP_ENABLED=False`; `VITE_FIREBASE_AUTH_TEST_MODE=yes`; `VITE_BFF_WS_PATH=ws`; ключ без
App ID. Проходит: `http://localhost:3010` (порт) с пустыми необязательными — `connect-src` с
`http://localhost:3010 ws://localhost:3010`, `RUN nginx -t` успешен, в `/srv/aura` нет `50x.html`.
Ответы контейнера (404 без `immutable`) — в слоте не запускал (без серверов), сверка — манору.
