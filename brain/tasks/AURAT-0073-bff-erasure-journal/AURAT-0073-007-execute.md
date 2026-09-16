# AURAT-0073-007 — Сделано в слоте

Дата: 2026-09-16
Где: `slave-2`, ветка `feature/AURAT-0073-bff-erasure-journal`. **Не
закоммичено** — ждёт ревью владельца.

## Проверка

`npm run lint` — чисто · `npm run typecheck` — чисто · `jest` — 79 наборов,
1040 тестов, все зелёные · `npm run build` — собирается.

Prettier: новые и изменённые мной строки отформатированы. В
`env.schema.spec.ts`, `avatar.service.spec.ts`, `r2-object-storage.service.ts`
остались старые расхождения, они были и на `develop` — не трогал.

## Файлы — `aura-bff`

| Файл | Что |
|---|---|
| `src/config/env.schema.ts` | `ERASURE_JOURNAL_*` (4 переменные). Проверка эндпоинта — общий `r2Endpoint()`, проверка группы — общий `requireBucket()` вместо `requireAvatarStorage()`. Сообщения об ошибках для аватаров не изменились |
| `src/modules/storage/object-storage.port.ts` | `list(prefix)`; токен `ERASURE_JOURNAL_STORAGE` |
| `src/modules/storage/r2-object-storage.service.ts` | адаптер собирается на один бакет (`R2Bucket`), фабрики `avatarStorage` / `erasureJournalStorage`; `list` по страницам, `removeAll` на нём |
| `src/modules/storage/storage.module.ts` | два провайдера-фабрики |
| `prisma/schema.prisma`, `prisma/migrations/20260916200000_account_erasure_source/` | enum `AccountErasureSource`, nullable колонка `source` — только expand |
| `src/modules/account/erasure-journal.ts` (новый) | `ErasureJournal`: ключ `erasures/<ISO>_<userId>.json`, тело `{userId, requestedAt, source}` (zod), `record`, `readAll` |
| `src/modules/account/account-erasure.repository.ts`, `prisma-account-erasure.repository.ts` | `ErasureSource`, `source` в `erase` и `ErasureRecord` |
| `src/modules/account/account-erasure.service.ts` | запись в журнал первым шагом каждого прохода; сбой → `error` в лог, остальные шаги идут, в конце ошибка → повтор, запись не закрывается; пересозданный аккаунт наследует `source` |
| `src/modules/account/account-deletion.service.ts` | `source` (`app` / `operator`); `repeatFromJournal()` → `erased` / `already-erased` / `not-found` / `refused` / `failed`, дубли `userId` берутся один раз |
| `src/modules/account/account.module.ts` | провайдер `ErasureJournal` |
| `src/account-erasure.ts` | `parseTarget` → `parseCommand`, режим `--journal`: строка на аккаунт, итог, выход 1 при отказе или сбое |
| `README.md`, `.env.example` | журнал, `--journal`, переменные |
| тесты | новый `erasure-journal.spec.ts`; дополнены спеки deletion/erasure service, репозитория, R2, env, CLI, smoke, `avatar.service.spec` (фейк получил `list`) |

## Файлы — brain

- `solutions/AURAS-0004`: § A restore brings deleted accounts back — процедура
  по журналу (шаг «до восстановления выписать незакрытые `account_erasures`»,
  затем `--journal`); строки нового бакета в таблице окружений и в § R2 tokens
  (помечены шагами A/B этой задачи).

## Отступления от спеки

- `deploy/env/bff.env.example` **не менял**: это файл эпохи AWS, в нём нет даже
  `AVATAR_STORAGE_*`. Переменные описаны в `.env.example`, где лежат остальные
  бакеты.

## Попутно

- В `node_modules` слота был `@aura/contracts` 0.18.0 при lockfile 0.19.0
  (`tsc` падал на `src/contracts/account.ts` ещё до правок). Сделан `npm ci`.
  В репозитории это ничего не меняет.

## Открыто

- Шаг A (бакет, правило 45 дней, токен, переменные в Coolify `development`)
  нужен **до мёржа в `develop`**: без переменных dev-деплой не стартует.
- Шаг B — до релиза в `main`.
