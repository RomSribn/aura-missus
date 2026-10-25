# AURAT-0124-006 — Approval

Date: 2026-10-23
Status: approved with changes

## Слова владельца

> Да, делай, решения 1–4 — да.

Правки к спеке `005`:

1. `# check=skip=SecretsUsedInArgOrEnv` — **первой строкой** `Dockerfile`, пояснение после: директива
   парсера, стоящая после комментария, считается комментарием.
2. Причина `style-src 'unsafe-inline'` — инлайн-стили reCAPTCHA. Custom properties React ставит
   через CSSOM (`style.setProperty`), CSP его не ограничивает.
3. В `headers.conf` — `Strict-Transport-Security: max-age=31536000` без `includeSubDomains`; там же
   комментарий: для аудио/видео во вложениях понадобится `media-src 'self' blob:`.

## Сверка манора с Coolify 4.4.7 на ВМ (не слова владельца)

Переменные приходят как `--build-arg`; Coolify сам вставляет `ARG` после каждого `FROM`;
`use_build_secrets` у ресурса выключен; `.env` пишется в папку сборки только после сборки.
Следствие: явные `ARG` в стадии build — для чтения и для локальной сборки; в стадии nginx `ARG`
появятся от Coolify, но без `RUN` в истории образа их нет.
