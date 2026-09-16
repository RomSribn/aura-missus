# AURAT-0073-004 — Контекст

Дата: 2026-09-16

## Что прочитано

- brain: `AURAT-0042-008` (спека BFF-половины, D4/D5), `AURAT-0042-115`
  (находка 1), `AURAT-0074-001` (параллельная задача про логи),
  `AURAS-0004` (§ Backups, § A restore brings deleted accounts back,
  § R2 tokens), `AURAD-0013` и `AURAT-0064-009` (как заводили
  `aura-user-media`), `AURAD-0015`.
- код (`develop` @ `781957a`): `modules/account/*`, `src/account-erasure.ts`,
  `operator-cli.module.ts`, `modules/storage/*`, `jobs/queues.ts`,
  `jobs/account-erasure.*`, `config/env.schema.ts`, `prisma/schema.prisma`,
  миграция `20260916120000_account_deletion`, `Dockerfile`, `README.md`.

## Что есть в коде

- `AccountDeletionService.erase` после коммита отключает сокеты, ставит две
  джобы `account-erasure` (сразу и после `IN_FLIGHT_GRACE_MS` = 5 мин) и пишет
  лог `{ userId } 'account erased'`. `AccountErasureService.eraseIfRecreated`
  пишет тот же лог с `recreatedDuringDeletion: true`.
- `AccountErasureService.complete(erasureId)` — повторяемые шаги вне базы;
  запись закрывается (`completedAt`) только на финальном проходе. Очередь:
  10 попыток от 5 с; sweep каждые 10 мин без ограничения по времени.
- `account_erasures`: `userId` уникален, откуда пришёл запрос, не хранится.
- CLI `account:erase -- --user | --phone` вызывает
  `deleteForOperator`: надгробие → «already erased», строки нет → ошибка
  `no account with id`, живая сессия → `ConflictException`.
- R2 знает только `storage/r2-object-storage.service.ts`, клиент один
  (`AVATAR_STORAGE_*`), порт `ObjectStorage` без чтения списка ключей.
- `env.schema.ts`: группа `AVATAR_STORAGE_*` — «все четыре или ни одной»,
  обязательна при `NODE_ENV=production`.

## Факты, от которых зависит спека

1. **`Dockerfile` ставит `ENV NODE_ENV=production` в образ.** Значит,
   `development` (`bff-dev`) тоже работает с `production`, и всё, что схема
   требует «в проде», нужно и там. Новые переменные, обязательные в проде,
   должны появиться в Coolify `development` **до** мёржа в `develop`, иначе
   деплой dev не стартует.
2. **Токен R2 ограничивается бакетом, не префиксом.** «Префикс с отдельным
   токеном» из заглушки в R2 не получить; отдельный токен = отдельный бакет.
3. **Сроки бэкапов** (`AURAS-0004`): прод — в R2 14 копий / 30 дней (что
   раньше), локально 3 / 7 дней; dev — без ограничений.
4. `AURAS-0004` уже описывает повтор удалений по логу `account erased` —
   этот раздел надо переписать под журнал.
5. В R2 четыре бакета, у каждого свой токен (`AURAS-0004` § R2 tokens);
   `aura-backups` закрыт для BFF, и так должно остаться.
6. Прод на 2026-09-16 без пользователей, dev — тестовые данные. Завершённые
   до релиза удаления в журнал не попадут; в проде таких нет.

## Противоречия

Нет. Заглушка допускает «отдельный бакет или префикс с отдельным токеном» —
второе в R2 невозможно (факт 2), поэтому в спеке остаётся только отдельный
бакет.
