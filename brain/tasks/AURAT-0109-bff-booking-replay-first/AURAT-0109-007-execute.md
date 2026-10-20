# AURAT-0109-007 — Execute

Дата: 2026-10-20
Слот: slave-3, ветка `feature/AURAT-0109-bff-booking-replay-first` (не закоммичено, всё в stage)

## Сделано (по спеке `005`, без отступлений)

- `sessions.repository.ts` — абстрактные `findBookReplay({ userId, advisorId, idempotencyKey })`
  и `findExtendReplay({ sessionId, walletId, minutes, idempotencyKey })`; в комментарии
  зафиксировано, что тело повтора не сравнивается (решение владельца, `006`).
- `prisma-sessions.repository.ts`:
  - `findBookReplay` — `session.findFirst` по ключу и `conversation: { userId, advisorId }`,
    баланс — `wallet.findUniqueOrThrow({ userId })`; без замков и записей;
  - `findExtendReplay` — сессия по id + общий помощник `replaysExtend`;
  - `replaysExtend(client, session, input)` — правила повтора продления в одном месте (ключ
    брони → 409; запись журнала другого типа/суммы → 409; та же сумма → повтор), им же теперь
    пользуется `extendLocked` внутри транзакции. Поведение транзакции не изменилось.
- `sessions.service.ts`:
  - `book()` — `ensureUser` → `findBookReplay` → (нет) прежние проверки и транзакция;
  - `extend()` — `requireOwnedSession` → кошелёк → `findExtendReplay` → (нет)
    `requireAllowedBlock` → `sessions.extend()`.
- Тесты: `sessions.service.spec.ts` — `book — replay` (6) и `extend › replay` (6);
  `prisma-sessions.repository.spec.ts` — `findBookReplay` (2), `findExtendReplay` (6).
- Brain: `AURAF-0008` → Resolved questions, пункт 5.

## Проверки (в слоте)

- `typecheck`, `lint`, `build` — ок.
- `jest` целиком: 1595/1597; 2 падения — `backoffice.smoke.spec.ts` (HTTP-смоук `AURAT-0075`)
  под нагрузкой полного прогона; отдельно — 15/15. К задаче не относится.
- Попутно: в слоте были устаревшие `node_modules` (`@aura/contracts` 0.20.0 при `v0.22.0` в
  `package.json`) и Prisma-клиент — `npm ci` + `prisma generate`; в репозиторий это не попадает.

## Открытое

- Рантайм-проверка — в маноре после merge (сценарии в `005`, «Проверка в маноре»), затем
  выкладка на `bff-dev`.
- Пробел №2 веба (зафиксировать «тело не сравнивается» в `@aura/contracts`) — за
  `aura-app-manor`, здесь не трогали.
