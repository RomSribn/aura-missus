# AURAT-0068-001 — Target `staging`: internal testing на `bff-dev`

Дата: 2026-09-14
Слот: `aura-app-manor/slave-0`, ветка `feature/AURAT-0068-app-staging-target`
от `develop` = `cf08f8d`
Репозиторий: `aura-app`

## Запрос владельца (дословно)

Вопрос из манора и выбранный ответ:

> «Шаг 4: заводить задачу на новый target приложения `staging`
> (env/.env.staging → bff-dev, скрипты aab/apk собирают internal testing с
> AURA_ENV=staging)?» — «Да, через слот (Recommended)»

## Контекст из манора (2026-09-14)

- Единственное окружение Coolify переименовано `production` → `development`:
  данные там тестовые, настоящий прод будет создан с нуля при запуске
  (`AURAI-0004`, `AURAS-0004`).
- BFF отвечает на `https://bff-dev.aura-app.cc` (сертификат выпущен, `/health`
  200). Старый `https://bff.aura-app.cc` оставлен вторым доменом только ради уже
  установленных тестовых сборок; его уберут, когда internal testing пересоберётся
  на новый адрес, а при запуске он достанется настоящему проду.
- Webhook Chatwoot переведён на bff-dev, inbox переименован в `Aura (dev)`.
- Что нужно в `aura-app`:
  - новый target `staging` — `env/.env.staging` с
    `AURA_BFF_ORIGIN=https://bff-dev.aura-app.cc`;
  - `env/.env.prod` **не менять** — это адрес будущего прода;
  - резолвер (`env/resolve.js`) подхватывает любой `env/.env.<target>` без правок
    кода; release-сборка требует https и явный `AURA_ENV`;
  - скрипты `aab` / `apk` в `package.json` жёстко используют `AURA_ENV=prod`
    (+ billing-флаги инлайном) — internal testing должен собираться с
    `AURA_ENV=staging`; **переключить или добавить `aab:staging` — решить в
    спеке**;
  - обновить таблицу targets в `env/README.md`;
  - тест `env/__tests__/resolve.test.js:307` проверяет prod-origin — не ломать.
