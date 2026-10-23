# AURAT-0124-005 — Spec: aura-web в Coolify (web-dev)

Date: 2026-10-23
Status: draft
Тип: задача (без нового feature-файла; рамка — `AURAD-0020`, `AURAF-0020` стр. 125–127).

## Что появится в aura-web

| Файл | Что |
|---|---|
| `Dockerfile` | две стадии: `build` (`node:22-alpine`) → `nginx:alpine`, порт 80 |
| `.dockerignore` | `.git`, `node_modules`, `dist`, `coverage`, **все `.env*`**, логи, IDE, отчёты Playwright |
| `deploy/web/build.sh` | POSIX sh, запускается в стадии build: проверка env → CSP → `npm run build` |
| `deploy/web/nginx.conf` | `server` для `/etc/nginx/conf.d/default.conf` |
| `deploy/web/headers.conf` | шаблон заголовков безопасности; два плейсхолдера, заполняются при сборке |
| `README.md` | раздел «Deploy»: ресурс, переменные, что проверяет сборка |

Код `src/` не трогается.

## Стадия build

1. `apk add --no-cache git`; `COPY package*.json` → `npm ci --include=dev` (слой кэшируется,
   пока не меняется lock).
2. `ARG` на каждую `VITE_*`, которую читает `env.ts` (8 шт., включая `VITE_FIREBASE_AUTH_TEST_MODE`
   — прод-сборка его игнорирует, но ARG объявлен, чтобы список был полным).
3. `COPY . .`, `RUN sh deploy/web/build.sh`:
   - **пустое = не задано**: пустые `VITE_*` снимаются (`unset`) до сборки — тогда работают
     дефолты `env.ts` (`/ws`, `false`), а не падение в браузере (ловушка «панель не умеет
     absent», `AURAS-0004`);
   - **обязательные**: нет `VITE_BFF_ORIGIN`, `VITE_FIREBASE_AUTH_DOMAIN` или
     `VITE_FIREBASE_PROJECT_ID` → сборка падает с именем переменной;
   - `VITE_BFF_ORIGIN` — та же форма, что в `env.ts` (`^https?://[^/]+$`), иначе падение: из него
     строится CSP;
   - `VITE_FIREBASE_API_KEY` / `VITE_FIREBASE_APP_ID` — оба или ни одного, иначе падение (то же
     правило `env.ts`, иначе вход молча выключен);
   - рендер `headers.conf`: `@BFF_ORIGIN@` → `https://bff-dev.aura-app.cc`,
     `@BFF_WS_ORIGIN@` → `wss://bff-dev.aura-app.cc` (`http` → `ws`, как `env.ts`);
   - `npm run build` (`tsc -b && vite build`).
4. `# check=skip=SecretsUsedInArgOrEnv` с комментарием: `VITE_*` публичны по устройству
   (`AURAD-0020`), ключ Firebase web — не секрет.

## Стадия nginx

Только `COPY` (`dist` → `/usr/share/nginx/html`, `nginx.conf`, отрендеренный `headers.conf`) —
ни одного `RUN`, поэтому build-переменные не попадают в историю отдаваемого образа.

- `listen 80`, `server_name _` — хостов нет; `server_tokens off`; gzip для js/css/json/svg.
- `location /assets/` — `try_files $uri =404`, `Cache-Control: public, max-age=31536000,
  immutable`. Отсутствующий чанк — **404, не index.html** (старая вкладка после деплоя не получит
  HTML вместо JS).
- `location /` — `try_files $uri /index.html` (SPA-fallback), `Cache-Control: no-cache` — для
  `index.html` и нехэшированных `favicon.svg` / `apple-touch-icon.png`.
- Заголовки — `include headers.conf` в каждом `location` (в nginx `add_header` в `location`
  отменяет серверные):
  - `Content-Security-Policy` (ниже), `X-Content-Type-Options: nosniff`,
    `Referrer-Policy: strict-origin-when-cross-origin`.

### CSP

```
default-src 'self';
script-src 'self' https://www.google.com/recaptcha/ https://www.gstatic.com/recaptcha/;
style-src 'self' 'unsafe-inline' https://fonts.googleapis.com;
font-src 'self' https://fonts.gstatic.com;
img-src 'self' data: blob: https:;
connect-src 'self' @BFF_ORIGIN@ @BFF_WS_ORIGIN@
            https://identitytoolkit.googleapis.com https://securetoken.googleapis.com;
frame-src https://www.google.com/recaptcha/ https://recaptcha.google.com/recaptcha/;
object-src 'none'; base-uri 'self'; form-action 'self'; frame-ancestors 'none'
```

- `img-src https:` — хост аватаров и карт таро задаёт BFF своей переменной
  (`*_ASSETS_BASE_URL`), у dev и prod он свой и может смениться без релиза веба.
- `style-src 'unsafe-inline'` — `style` с custom properties (правило 3) и стили reCAPTCHA.
- Скриптам `'unsafe-inline'` / `'unsafe-eval'` не даётся. Проверю по собранному `dist`: в
  `index.html` нет инлайн-скриптов, в бандле нет `eval` / `new Function`.
- Режим — **enforce** (не Report-Only): ошибка ломает только web-dev, и манор её увидит при
  проверке в браузере.

## Проверка в слоте (без серверов)

`npm run lint`, `npm run typecheck`, `npm test` (без изменений `src` — регресс не ожидается),
`docker build` с dev-значениями; `docker build` без `VITE_BFF_ORIGIN` и с пустым
`VITE_PSP_ENABLED`; `docker run --rm <image> nginx -t` и вывод отрендеренного `headers.conf` —
контейнер не слушает порт, это не preview-сервер.

## После мёржа (манор)

Первый деплой — push в `develop`. Проверить на `https://web-dev.aura-app.cc`: `/`,
`/advisors/<id>` прямым заходом и reload (SPA-fallback), заголовки `index.html` (`no-cache`, CSP) и
`/assets/*` (`immutable`), `/assets/nope.js` → 404, `X-Robots-Tag: noindex` (от Coolify), вход по
SMS (reCAPTCHA под CSP), сокет, картинки, консоль без CSP-нарушений. Вход и запросы к BFF заработают
только после `AURAT-0125` (origin в BFF) и Authorized domains в Firebase — оба руками владельца.

## Brain

- `AURAS-0004`: строка `aura-web` в таблице Services, «Deploys» — ветка → окружение для веба,
  отличие от BFF (`VITE_*` build-time и публичны). Правлю после живой проверки.
- `AURAF-0020` стр. 125–127: отметка, что web-dev работает.

## Не в задаче

BFF (`AURAT-0125`), Firebase Authorized domains, прод-ресурс и релиз `develop` → `main` (после
релиза BFF с `AURAT-0122`), лендинг (`AURAT-0126`), Apple Pay / `.well-known`, HSTS, healthcheck.
