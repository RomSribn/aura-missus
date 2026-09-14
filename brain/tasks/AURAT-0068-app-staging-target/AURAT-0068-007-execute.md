# AURAT-0068-007 — Исполнено

Дата: 2026-09-14
Слот: `aura-app-manor/slave-0`, ветка `feature/AURAT-0068-app-staging-target`
от `develop` = `cf08f8d`. **Не закоммичено** — ждёт ревью владельца.

## Файлы

| Файл | Что |
|---|---|
| `env/.env.staging` | новый: `AURA_BFF_ORIGIN=https://bff-dev.aura-app.cc`, оба billing-флага и `AURA_AUTH_TEST_MODE` — `false`; шапка объясняет три имени одного окружения |
| `package.json` | `aab` / `apk` → `aab:staging` / `apk:staging`, флаги инлайном те же |
| `env/__tests__/resolve.test.js` | состав targets `['dev', 'prod', 'staging', 'tunnel']`; новый `points staging at the hosted development backend`; `staging` в стороже флагов |
| `env/README.md` | строка `staging` в таблице, строка `prod` — «not live yet» вместо «empty until AURAD-0005»; абзацы про `dev` ≠ `staging` и про то, чем сейчас является `bff.aura-app.cc`; раздел «Release builds» |
| `env/resolve.js` | пример в отказе release-бандла без `AURA_ENV` — `AURA_ENV=staging` (только текст) |
| `src/shared/config/env.ts` | комментарий со списком targets |

Не тронуты: `env/.env.prod`, логика резолвера, `android/`, `ios/`. Тест
prod-origin на месте — строка `307` та же, новый тест вставлен после него.

## По ходу

- Таблицу в README выровнял `prettier` — файл и раньше был в его формате.
- Тест staging-origin закреплён литералом, как prod: переезд хоста делается
  дважды и сознательно.

## Проверка в слоте

| Что | Результат |
|---|---|
| `jest` | **785** тестов, 112 наборов — зелёно (было 784, +1 новый) |
| `tsc --noEmit` | чисто |
| `npm run lint` | чисто |
| `prettier --check` по изменённым | чисто |
| `AURA_ENV=staging npm run env:show` | `bff-dev.aura-app.cc`, iOS `null`, флаги `false` (`.local`-файлов в слоте нет) |
| `AURA_ENV=staging NODE_ENV=production node env/fingerprint.js` | exit 0 — release-политику проходит |
| то же без `AURA_ENV` | exit 1, «one of: dev, prod, staging, tunnel», пример — `AURA_ENV=staging` |
| JS release-бандл (`react-native bundle --dev false`, staging + флаги) | `https://bff-dev.aura-app.cc` — 1 вхождение, `bff.aura-app.cc` — **0** |

`bundleRelease` не запускался — как и записано в спеке: нативного изменения нет,
подпись требует keystore вне репозитория.

## Открытое

Ничего в коде. После мержа — шаги манора из `005` (versionCode 18,
`npm run aab:staging`, установка из Play, проверка `BILLING_ENABLED` в Coolify
`development`), при закрытии — `AURAS-0002` шаг 3.
