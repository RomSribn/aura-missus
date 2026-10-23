# AURAT-0124-004 — Context

Date: 2026-10-23

## Код aura-web (ground truth)

- `src/shared/config/env.ts` читает 8 `VITE_*`: `BFF_ORIGIN` (обяз., `^https?://[^/]+$`),
  `BFF_WS_PATH` (default `/ws`), `FIREBASE_AUTH_DOMAIN`, `FIREBASE_PROJECT_ID` (обяз.),
  `FIREBASE_API_KEY` / `FIREBASE_APP_ID` (оба или ни одного; пустая строка = не задано),
  `FIREBASE_AUTH_TEST_MODE` (enum, в прод-сборке игнорируется), `PSP_ENABLED` (enum; в прод-сборке
  выключен константой `DEV`). Проверка — только в браузере, при импорте.
- **Пустая строка ломает enum/regex**: `VITE_BFF_WS_PATH=""`, `VITE_PSP_ENABLED=""` →
  `Invalid build configuration` в браузере. Coolify не умеет «не задано» — хранит пустую строку
  (`AURAS-0004`, «a panel cannot express absent»).
- `vite build` (mode production) читает `.env`, `.env.local`, `.env.production*`; переменные
  окружения процесса важнее файлов. `.env.development` в прод-сборку не попадает.
- `@aura/contracts` — `git+ssh://…aura-contracts.git#474c5cb` в lock; BFF собирается в Coolify с
  тем же (`apk add git`, `npm ci --include=dev`) — повторяем его `Dockerfile`.
- Что грузит страница (для CSP):
  - скрипты — только свои чанки Vite + reCAPTCHA (`RecaptchaVerifier`, invisible):
    `www.google.com/recaptcha/`, `www.gstatic.com/recaptcha/`; iframe reCAPTCHA —
    `www.google.com/recaptcha/`, `recaptcha.google.com/recaptcha/`;
  - Firebase — `initializeAuth` без `popupRedirectResolver` → нет iframe `authDomain` и
    `apis.google.com`; сеть — `identitytoolkit.googleapis.com`, `securetoken.googleapis.com`;
  - BFF — `fetch` (REST, вложения как blob) и WebSocket `ws(s)://<origin><path>`;
  - картинки — `avatarUrl` / `imageUrl` таро собирает BFF из `ADVISOR_ASSETS_BASE_URL` /
    `TAROT_ASSETS_BASE_URL` (хост зависит от окружения BFF), вложения — `blob:`;
  - стили — свои + Google Fonts (`fonts.googleapis.com` / `fonts.gstatic.com`), `style` атрибуты
    с custom properties (правило 3) и инлайн-стили reCAPTCHA → нужен `'unsafe-inline'` для стилей;
  - `.ics` — `blob:` + `download`, без навигации.

## Платформа (`AURAS-0004`)

- Coolify передаёт `NODE_ENV=production` в сборку → `npm ci --include=dev`.
- Build-time переменные попадают в метаданные образа (`docker history`, предупреждение
  `SecretsUsedInArgOrEnv`). Для веба `VITE_*` публичны (`AURAD-0020`); в финальной стадии нет
  ни одного `RUN`, поэтому их нет и в истории отдаваемого образа.
- Нет healthcheck и гейта: старый контейнер снимается сразу после старта нового. nginx со статикой
  стартует мгновенно; плохая сборка падает в стадии build и не выкатывается.
- noindex на dev — тумблер Coolify (Traefik `X-Robots-Tag`), не наш конфиг.

## Противоречий нет

Бриф манора, `AURAD-0020` и код согласованы.
